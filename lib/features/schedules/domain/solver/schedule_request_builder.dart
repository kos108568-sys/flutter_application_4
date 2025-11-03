import 'dart:async';

import '../../../audiences/data/audience_lesson_types_repository.dart';
import '../../../audiences/data/audiences_repository.dart';
import '../../../groups/data/groups_repository.dart';
import '../../../gst/data/group_subject_teachers_repository.dart';
import '../../../lesson_types/data/lesson_type_repository.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../schedules/data/lessons_repository.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../../time_slots/data/time_slot_repository.dart';
import 'schedule_solver_models.dart';

class ScheduleRequestBuilder {
  ScheduleRequestBuilder({
    required GroupsRepository groupsRepository,
    required TeachersRepository teachersRepository,
    required LessonTypeRepository lessonTypeRepository,
    required DisciplinesRepository disciplinesRepository,
    required TimeSlotRepository timeSlotRepository,
    required AudiencesRepository audiencesRepository,
    required AudienceLessonTypesRepository audienceLessonTypesRepository,
    required GroupSubjectTeachersRepository groupSubjectTeachersRepository,
    required LessonsRepository lessonsRepository,
    this.hoursPerLesson = 2,
  })  : _groupsRepository = groupsRepository,
        _teachersRepository = teachersRepository,
        _lessonTypeRepository = lessonTypeRepository,
        _disciplinesRepository = disciplinesRepository,
        _timeSlotRepository = timeSlotRepository,
        _audiencesRepository = audiencesRepository,
        _audienceLessonTypesRepository = audienceLessonTypesRepository,
        _groupSubjectTeachersRepository = groupSubjectTeachersRepository,
        _lessonsRepository = lessonsRepository;

  final GroupsRepository _groupsRepository;
  final TeachersRepository _teachersRepository;
  final LessonTypeRepository _lessonTypeRepository;
  final DisciplinesRepository _disciplinesRepository;
  final TimeSlotRepository _timeSlotRepository;
  final AudiencesRepository _audiencesRepository;
  final AudienceLessonTypesRepository _audienceLessonTypesRepository;
  final GroupSubjectTeachersRepository _groupSubjectTeachersRepository;
  final LessonsRepository _lessonsRepository;

  /// Количество академических часов в одной паре (по умолчанию 2).
  final int hoursPerLesson;

  Future<ScheduleRequest> build({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final period = SchedulePeriod(
      startDate: periodStart,
      endDate: periodEnd,
    );

    final timeSlots = await _buildTimeSlots();
    final lessonTypeNameToId = <String, int>{};
    final lessonTypes = await _buildLessonTypes(lessonTypeNameToId);
    final disciplineById = await _buildDisciplineMap();
    final groups = await _buildGroups();
    final teachers = await _buildTeachers();
    final audiences = await _buildAudiences();
    final audienceLessonTypes = await _buildAudienceLessonTypes();
    final assignments = await _buildAssignments(
      disciplineById: disciplineById,
      defaultStart: periodStart,
      defaultEnd: periodEnd,
      fallbackLessonTypeId: lessonTypes.isNotEmpty ? lessonTypes.first.id : 0,
    );
    final existingLessons = await _buildExistingLessons(
      periodStart,
      periodEnd,
      lessonTypeNameToId,
    );

    final weeks = _calculateWeeks(periodStart, periodEnd);

    return ScheduleRequest(
      period: period,
      weeks: weeks,
      timeSlots: timeSlots,
      lessonTypes: lessonTypes,
      groups: groups,
      teachers: teachers,
      audiences: audiences,
      audienceLessonTypes: audienceLessonTypes,
      assignments: assignments,
      existingLessons: existingLessons,
    );
  }

  Future<List<ScheduleTimeSlot>> _buildTimeSlots() async {
    final slots = await _timeSlotRepository.getAllTimeSlots();
    return slots
        .map(
          (slot) => ScheduleTimeSlot(
            id: slot.id ?? 0,
            order: slot.orderNumber,
            start: slot.startTime,
            end: slot.endTime,
            kind: slot.description,
          ),
        )
        .toList();
  }

  Future<List<ScheduleLessonType>> _buildLessonTypes(
    Map<String, int> lessonTypeNameToId,
  ) async {
    final types = await _lessonTypeRepository.getAllLessonTypes(orderBy: 'name ASC');
    final result = <ScheduleLessonType>[];
    for (final type in types) {
      final id = type.id;
      if (id == null) continue;
      result.add(ScheduleLessonType(id: id, name: type.name));
      lessonTypeNameToId[type.name.toLowerCase()] = id;
    }
    return result;
  }

  Future<List<ScheduleGroup>> _buildGroups() async {
    final allGroups = await _groupsRepository.getAllGroups(orderBy: 'name ASC');
    return allGroups
        .where((group) => group.id != null)
        .map(
          (group) => ScheduleGroup(
            id: group.id!,
            name: group.name,
            size: group.studentCount ?? group.size ?? 0,
          ),
        )
        .toList();
  }

  Future<List<ScheduleTeacher>> _buildTeachers() async {
    final allTeachers = await _teachersRepository.getAllTeachers(orderBy: 'full_name ASC');
    return allTeachers
        .where((teacher) => teacher.id != null)
        .map(
          (teacher) => ScheduleTeacher(
            id: teacher.id!,
            name: teacher.fullName,
          ),
        )
        .toList();
  }

  Future<List<ScheduleAudience>> _buildAudiences() async {
    final allAudiences = await _audiencesRepository.getAllAudiences(orderBy: 'name ASC');
    return allAudiences
        .where((audience) => audience.id != null)
        .map(
          (audience) => ScheduleAudience(
            id: audience.id!,
            name: audience.name,
            capacity: audience.capacity ?? 0,
            buildingId: audience.buildingId,
            preferredTeacherId: audience.teacherId,
          ),
        )
        .toList();
  }

  Future<List<ScheduleAudienceLessonType>> _buildAudienceLessonTypes() async {
    final mappings = await _audienceLessonTypesRepository.getAll();
    return mappings
        .where((mapping) => mapping.audienceId != null && mapping.lessonTypeId != null)
        .map(
          (mapping) => ScheduleAudienceLessonType(
            audienceId: mapping.audienceId!,
            lessonTypeId: mapping.lessonTypeId!,
          ),
        )
        .toList();
  }

  Future<Map<int, DisciplineInfo>> _buildDisciplineMap() async {
    final disciplines = await _disciplinesRepository.getAllDisciplines();
    final map = <int, DisciplineInfo>{};
    for (final discipline in disciplines) {
      final id = discipline.id;
      if (id == null) continue;
      map[id] = DisciplineInfo(
        lessonTypeId: discipline.lessonTypeId,
      );
    }
    return map;
  }

  Future<List<ScheduleExistingLesson>> _buildExistingLessons(
    DateTime periodStart,
    DateTime periodEnd,
    Map<String, int> lessonTypeNameToId,
  ) async {
    final lessons = await _lessonsRepository.getAll();
    final result = <ScheduleExistingLesson>[];
    for (final lesson in lessons) {
      final date = lesson.date;
      if (date.isBefore(periodStart) || date.isAfter(periodEnd)) continue;
      final lessonTypeId = lessonTypeNameToId[lesson.type.toLowerCase()] ?? 0;
      result.add(
        ScheduleExistingLesson(
          groupId: lesson.groupId,
          teacherId: lesson.teacherId,
          audienceId: lesson.audienceId,
          disciplineId: lesson.disciplineId,
          lessonTypeId: lessonTypeId,
          date: date,
          slotId: lesson.pairNo,
          subgroup: lesson.subgroup,
          isLocked: true,
        ),
      );
    }
    return result;
  }

  int _calculateWeeks(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return (days / 7).ceil();
  }

  Future<List<ScheduleAssignment>> _buildAssignments({
    required Map<int, DisciplineInfo> disciplineById,
    required DateTime defaultStart,
    required DateTime defaultEnd,
    required int fallbackLessonTypeId,
  }) async {
    final assignments = await _groupSubjectTeachersRepository.getAllGST();
    final result = <ScheduleAssignment>[];
    for (final gst in assignments) {
      final id = gst.id;
      if (id == null) continue;
      final disciplineInfo = disciplineById[gst.disciplineId];
      final lessonTypeId = disciplineInfo?.lessonTypeId ?? fallbackLessonTypeId;
      result.add(
        ScheduleAssignment(
          id: id,
          groupId: gst.groupId,
          teacherId: gst.teacherId,
          disciplineId: gst.disciplineId,
          lessonTypeId: lessonTypeId,
          totalHours: gst.totalHours,
          hoursPerLesson: hoursPerLesson,
          startDate: _parseDate(gst.startDate) ?? defaultStart,
          endDate: _parseDate(gst.endDate) ?? defaultEnd,
          subgroup: gst.subgroup,
        ),
      );
    }
    return result;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class DisciplineInfo {
  const DisciplineInfo({
    required this.lessonTypeId,
  });

  final int? lessonTypeId;
}
