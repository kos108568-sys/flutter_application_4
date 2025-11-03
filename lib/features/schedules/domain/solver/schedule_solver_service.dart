import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../schedules/data/lesson_model.dart';
import '../../../schedules/data/lessons_repository.dart';
import '../../../gst/data/group_subject_teachers_repository.dart';
import 'schedule_request_builder.dart';
import 'schedule_solver_models.dart';

class ScheduleSolverService {
  ScheduleSolverService({
    required ScheduleRequestBuilder requestBuilder,
    required GroupSubjectTeachersRepository gstRepository,
    required LessonsRepository lessonsRepository,
    this.pythonExecutable = 'python3',
    List<String>? pythonArgs,
    String? solverScriptPath,
  })  : _requestBuilder = requestBuilder,
        _gstRepository = gstRepository,
        _lessonsRepository = lessonsRepository,
        _solverScriptPath = solverScriptPath ?? p.join('scripts', 'solver', 'main.py'),
        _pythonArgs = pythonArgs ?? const [];

  final ScheduleRequestBuilder _requestBuilder;
  final GroupSubjectTeachersRepository _gstRepository;
  final LessonsRepository _lessonsRepository;
  final String pythonExecutable;
  final String _solverScriptPath;
  final List<String> _pythonArgs;

  /// Полная генерация расписания: собирает запрос, вызывает Python-решатель,
  /// затем записывает полученные пары в локальную БД (заменяя текущие).
  Future<ScheduleSolution> solveAndApply({
    DateTime? periodStart,
    DateTime? periodEnd,
    bool replaceExisting = true,
  }) async {
    final request = await buildRequest(periodStart: periodStart, periodEnd: periodEnd);
    final solution = await _invokeSolver(request);
    if (replaceExisting) {
      await _lessonsRepository.clearAll();
    }
    await _applySolution(request, solution);
    return solution;
  }

  /// Формирует `ScheduleRequest` на основе текущих данных БД.
  Future<ScheduleRequest> buildRequest({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final inferred = await _inferPeriod(
      forcedStart: periodStart,
      forcedEnd: periodEnd,
    );
    return _requestBuilder.build(
      periodStart: inferred.start,
      periodEnd: inferred.end,
    );
  }

  Future<ScheduleSolution> _invokeSolver(ScheduleRequest request) async {
    final tempDir = await Directory.systemTemp.createTemp('schedule_solver');
    try {
      final requestPath = p.join(tempDir.path, 'request.json');
      final requestFile = File(requestPath);
      await requestFile.writeAsString(jsonEncode(request.toJson()), flush: true);

      final scriptPath = p.normalize(p.absolute(_solverScriptPath));
      final args = ['--request', requestPath];
      final commands = _pythonCandidates();
      ProcessResult? result;
      ProcessException? lastError;
      for (final executable in commands) {
        try {
          result = await Process.run(executable, [..._pythonArgs, scriptPath, ...args]);
          if (result.exitCode == 0) {
            break;
          }
        } on ProcessException catch (e) {
          lastError = e;
          continue;
        }
      }
      if (result == null) {
        throw ScheduleSolverException(_pythonNotFoundMessage(lastError));
      }
      if (result.exitCode != 0) {
        if (result.exitCode == 9009) {
          throw ScheduleSolverException(_pythonNotFoundMessage(lastError));
        }
        throw ScheduleSolverException(
          'Solver exited with code ${result.exitCode}\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}',
        );
      }
      if (result.stdout is! String) {
        throw ScheduleSolverException('Solver produced non-text output.');
      }
      final Map<String, dynamic> jsonMap = jsonDecode(result.stdout as String);
      return ScheduleSolution.fromJson(jsonMap);
    } on FormatException catch (e) {
      throw ScheduleSolverException('Invalid solver JSON response: $e');
    } on IOException catch (e) {
      throw ScheduleSolverException('Failed to execute solver: $e');
    } on ScheduleSolverException {
      rethrow;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  List<String> _pythonCandidates() {
    final candidates = <String>[];
    if (pythonExecutable.isNotEmpty) {
      candidates.add(pythonExecutable);
    }
    final envExec = Platform.environment['PYTHON_EXECUTABLE'];
    if (envExec != null && envExec.isNotEmpty && !candidates.contains(envExec)) {
      candidates.add(envExec);
    }
    const defaults = ['python3', 'python', 'py', 'py.exe'];
    for (final cmd in defaults) {
      if (!candidates.contains(cmd)) {
        candidates.add(cmd);
      }
    }
    return candidates;
  }

  String _pythonNotFoundMessage(ProcessException? error) {
    final base = 'Не удалось найти интерпретатор Python.\n'
        'Установите Python 3 и убедитесь, что команды "python", "python3" или "py" доступны в PATH.\n'
        'Либо передайте путь/аргументы через ScheduleSolverService.pythonExecutable и pythonArgs.';
    if (error == null) return base;
    return '$base\nПодробности: ${error.message}';
  }

  Future<void> _applySolution(ScheduleRequest request, ScheduleSolution solution) async {
    final lessonTypeNameById = {
      for (final lt in request.lessonTypes) lt.id: lt.name,
    };
    final slotOrderById = {
      for (final slot in request.timeSlots) slot.id: slot.order,
    };

    for (final lesson in solution.lessons) {
      final slotOrder = slotOrderById[lesson.slotId];
      if (slotOrder == null) {
        continue;
      }
      final typeName = lessonTypeNameById[lesson.lessonTypeId] ?? 'Неизвестно';
      final lessonModel = LessonModel(
        disciplineId: lesson.disciplineId,
        type: typeName,
        teacherId: lesson.teacherId,
        audienceId: lesson.audienceId,
        groupId: lesson.groupId,
        pairNo: slotOrder,
        dayOfWeek: lesson.date.weekday - 1,
        date: lesson.date,
        subgroup: lesson.subgroup ?? 'Вся группа',
      );
      await _lessonsRepository.insertWithSync(lessonModel);
    }
  }

  Future<_Period> _inferPeriod({
    DateTime? forcedStart,
    DateTime? forcedEnd,
  }) async {
    if (forcedStart != null && forcedEnd != null) {
      return _Period(start: forcedStart, end: forcedEnd);
    }

    final assignments = await _gstRepository.getAllGST();
    DateTime? minStart;
    DateTime? maxEnd;
    for (final gst in assignments) {
      final start = _parseDate(gst.startDate);
      final end = _parseDate(gst.endDate);
      if (start != null) {
        minStart = _earlier(minStart, start);
      }
      if (end != null) {
        maxEnd = _later(maxEnd, end);
      }
    }

    final now = DateTime.now();
    final start = forcedStart ?? minStart ?? DateTime(now.year, 9, 1);
    final end = forcedEnd ?? maxEnd ?? start.add(const Duration(days: 120));
    if (end.isBefore(start)) {
      return _Period(start: start, end: start.add(const Duration(days: 7)));
    }
    return _Period(start: start, end: end);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  DateTime _earlier(DateTime? current, DateTime candidate) =>
      current == null || candidate.isBefore(current) ? candidate : current;

  DateTime _later(DateTime? current, DateTime candidate) =>
      current == null || candidate.isAfter(current) ? candidate : current;
}

class ScheduleSolverException implements Exception {
  ScheduleSolverException(this.message);
  final String message;

  @override
  String toString() => 'ScheduleSolverException: $message';
}

class _Period {
  const _Period({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
