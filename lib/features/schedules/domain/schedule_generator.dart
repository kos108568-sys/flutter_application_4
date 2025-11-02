import 'dart:math';
import '../../audiences/data/audience_model.dart';
import '../../audiences/data/audiences_repository.dart';
import '../../gst/data/group_subject_teacher_model.dart';
import '../../gst/data/group_subject_teachers_repository.dart';
import '../data/lesson_model.dart';
import '../data/lessons_repository.dart';

class ScheduleGenerator {
  final LessonsRepository lessonsRepo;
  final GroupSubjectTeachersRepository gstRepo;
  final AudiencesRepository audiencesRepo;

  ScheduleGenerator({
    required this.lessonsRepo,
    required this.gstRepo,
    required this.audiencesRepo,
  });

  // Pairs per day available in UI (0..4)
  static const int pairsPerDay = 5;

  Future<void> generate({int? groupId}) async {
    final assignments = groupId != null
        ? await gstRepo.getByGroup(groupId)
        : await gstRepo.getAllGST();
    if (assignments.isEmpty) return;

    final audiences = await audiencesRepo.getAllAudiences(orderBy: 'name ASC');

    // Keep incremental list of created lessons to check conflicts within this run
    final List<LessonModel> planned = [];
    final Set<String> seen = {};

    bool teacherBusy(DateTime date, int pairNo, int teacherId) =>
        planned.any((l) => _sameYMD(l.date, date) && l.pairNo == pairNo && l.teacherId == teacherId);
    bool groupBusyOn(DateTime date, int pairNo, int gid, String subgroupLabel) {
      return planned.any((l) => _sameYMD(l.date, date) && l.pairNo == pairNo && l.groupId == gid &&
          (l.subgroup == subgroupLabel || l.subgroup == 'Вся группа' || subgroupLabel == 'Вся группа'));
    }
    bool audienceBusy(DateTime date, int pairNo, int aid) =>
        planned.any((l) => _sameYMD(l.date, date) && l.pairNo == pairNo && l.audienceId == aid);

    // Precompute per-assignment weekly template and remaining pairs
    final plans = <_AssignmentPlan>[];
    for (final a in assignments) {
      final gId = a.groupId, tId = a.teacherId, dId = a.disciplineId;
      if (gId == null || tId == null || dId == null) continue;
      final start = _parseDate(a.startDate);
      final end = _parseDate(a.endDate);
      if (start == null || end == null || !start.isBefore(end.add(const Duration(days: 1)))) continue;
      final hours = a.totalHours ?? 0;
      if (hours <= 0) continue;
      final totalPairs = (hours / 2).ceil();
      final weeks = _weeksBetween(start, end).clamp(1, 10000);
      final weeklyPairs = max(1, (totalPairs / weeks).round());
      final rng = Random(gId * 10007 + dId * 101);
      final days = _pickDays(rng, weeklyPairs); // 0..4 (Mon..Fri)
      final dist = _distributeEvenly(weeklyPairs, days.length);
      plans.add(_AssignmentPlan(a, start, end, totalPairs, weeklyPairs, days, dist));
    }
    if (plans.isEmpty) return;

    // Iterate weeks across overall range
    final minStart = plans.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final maxEnd = plans.map((p) => p.end).reduce((a, b) => a.isAfter(b) ? a : b);
    DateTime weekStart = _mondayOf(minStart);
    while (!weekStart.isAfter(maxEnd)) {
      // Day -> list of contributions (per assignment for this week)
      final Map<int, List<_Contrib>> dayMap = {for (var d = 0; d < 5; d++) d: []};
      for (final p in plans) {
        if (p.remaining <= 0) continue;
        for (int i = 0; i < p.days.length; i++) {
          final dayIdx = p.days[i];
          final date = weekStart.add(Duration(days: dayIdx));
          if (date.isBefore(p.start) || date.isAfter(p.end)) continue;
          final can = min(p.dist[i], p.remaining);
          if (can <= 0) continue;
          dayMap[dayIdx]!.add(_Contrib(p, can));
        }
      }

      for (int dayIdx = 0; dayIdx < 5; dayIdx++) {
        final contribs = dayMap[dayIdx]!;
        if (contribs.isEmpty) continue;
        final date = weekStart.add(Duration(days: dayIdx));
        final totalCount = contribs.fold<int>(0, (s, c) => s + c.count);
        // Find contiguous block to place the entire day's pairs without gaps
        final startSlot = _findConsecutiveFreeSlot(
          date,
          totalCount,
          (p) => groupBusyOn(date, p, contribs.first.plan.assignment.groupId!, _subgroupLabel(contribs.first.plan.assignment.subgroup)) ||
              teacherBusy(date, p, contribs.first.plan.assignment.teacherId!),
        );
        if (startSlot == null) continue;

        // Build an order without repeating same discipline consecutively
        final sequence = <_ContribUnit>[];
        final remain = contribs.map((c) => _ContribUnit(c.plan, c.count)).toList();
        int idx = 0;
        int? lastDisc;
        while (sequence.length < totalCount) {
          bool progressed = false;
          for (int i = 0; i < remain.length; i++) {
            final u = remain[i];
            if (u.count <= 0) continue;
            final dId = u.plan.assignment.disciplineId!;
            if (lastDisc != null && dId == lastDisc) continue;
            sequence.add(_ContribUnit(u.plan, 1));
            u.count -= 1;
            lastDisc = dId;
            progressed = true;
            break;
          }
          if (!progressed) {
            // All remaining are same discipline; take one anyway
            for (int i = 0; i < remain.length; i++) {
              if (remain[i].count > 0) {
                sequence.add(_ContribUnit(remain[i].plan, 1));
                remain[i].count -= 1;
                lastDisc = remain[i].plan.assignment.disciplineId!;
                break;
              }
            }
          }
          idx++;
        }

        // Place sequence contiguously
        for (int k = 0; k < sequence.length; k++) {
          final pairNo = startSlot + k;
          final plan = sequence[k].plan;
          final gId = plan.assignment.groupId!;
          final tId = plan.assignment.teacherId!;
          final dId = plan.assignment.disciplineId!;
          final aid = _pickFreeAudience(audiences, (aid) => audienceBusy(date, pairNo, aid));
          if (aid == null) continue;
          final key = _key(gId, date, pairNo, '1 подгруппа');
          if (seen.contains(key)) continue;
          planned.add(LessonModel(
            disciplineId: dId,
            type: '',
            teacherId: tId,
            audienceId: aid,
            groupId: gId,
            pairNo: pairNo,
            dayOfWeek: date.weekday - 1,
            date: date,
            subgroup: _subgroupLabel(plan.assignment.subgroup),
          ));
          seen.add(key);
          plan.remaining -= 1;
        }
      }

      weekStart = weekStart.add(const Duration(days: 7));
      // Stop if all done
      if (plans.every((p) => p.remaining <= 0)) break;
    }

    for (final l in planned) {
      await lessonsRepo.insertWithSync(l);
    }
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  static DateTime _mondayOf(DateTime dt) {
    return dt.subtract(Duration(days: dt.weekday - 1));
  }

  static int _weeksBetween(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return (days / 7).ceil();
  }

  // Pick up to 5 distinct days (0..4) with RNG; if weeklyPairs > 5, all 5 days are used
  static List<int> _pickDays(Random rng, int weeklyPairs) {
    final days = [0, 1, 2, 3, 4];
    days.shuffle(rng);
    final count = min(5, max(1, min(weeklyPairs, 5)));
    return days.take(count).toList();
  }

  // Distribute n across k buckets as evenly as possible
  static List<int> _distributeEvenly(int n, int k) {
    if (k <= 0) return [];
    final base = n ~/ k;
    var rem = n % k;
    return List.generate(k, (i) => base + (i < rem ? 1 : 0));
  }

  // Find first start position for a consecutive block within [0, pairsPerDay)
  static int? _findConsecutiveFreeSlot(DateTime date, int length, bool Function(int pairNo) busy) {
    for (int start = 0; start + length <= pairsPerDay; start++) {
      bool ok = true;
      for (int p = start; p < start + length; p++) {
        if (busy(p)) { ok = false; break; }
      }
      if (ok) return start;
    }
    return null;
  }

  static bool _sameYMD(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _key(int groupId, DateTime date, int pairNo, String subgroup) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$groupId|$y-$m-$d|$pairNo|$subgroup';
  }

  static String _subgroupLabel(String? code) {
    switch ((code ?? 'all').toLowerCase()) {
      case '1':
      case 'one':
        return '1 подгруппа';
      case '2':
      case 'two':
        return '2 подгруппа';
      default:
        return 'Вся группа';
    }
  }

  static int? _pickFreeAudience(List<Audience> audiences, bool Function(int aid) isBusy) {
    for (final a in audiences) {
      final id = a.id;
      if (id == null) continue;
      if (!isBusy(id)) return id;
    }
    return null;
  }
}

class _AssignmentPlan {
  final GroupSubjectTeacher assignment;
  final DateTime start;
  final DateTime end;
  final int totalPairs;
  final int weeklyPairs;
  final List<int> days; // 0..4
  final List<int> dist; // per day
  int remaining;
  _AssignmentPlan(this.assignment, this.start, this.end, this.totalPairs, this.weeklyPairs, this.days, this.dist)
      : remaining = totalPairs;
}

class _Contrib {
  final _AssignmentPlan plan;
  final int count;
  _Contrib(this.plan, this.count);
}

class _ContribUnit {
  final _AssignmentPlan plan;
  int count;
  _ContribUnit(this.plan, this.count);
}
