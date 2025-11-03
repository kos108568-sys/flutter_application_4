import 'package:meta/meta.dart';

@immutable
class ScheduleRequest {
  const ScheduleRequest({
    required this.period,
    required this.weeks,
    required this.timeSlots,
    required this.lessonTypes,
    required this.groups,
    required this.teachers,
    required this.audiences,
    required this.audienceLessonTypes,
    required this.assignments,
    required this.existingLessons,
  });

  final SchedulePeriod period;
  final int weeks;
  final List<ScheduleTimeSlot> timeSlots;
  final List<ScheduleLessonType> lessonTypes;
  final List<ScheduleGroup> groups;
  final List<ScheduleTeacher> teachers;
  final List<ScheduleAudience> audiences;
  final List<ScheduleAudienceLessonType> audienceLessonTypes;
  final List<ScheduleAssignment> assignments;
  final List<ScheduleExistingLesson> existingLessons;

  Map<String, dynamic> toJson() {
    return {
      'period': period.toJson(),
      'weeks': weeks,
      'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
      'lessonTypes': lessonTypes.map((e) => e.toJson()).toList(),
      'groups': groups.map((e) => e.toJson()).toList(),
      'teachers': teachers.map((e) => e.toJson()).toList(),
      'audiences': audiences.map((e) => e.toJson()).toList(),
      'audienceLessonTypes': audienceLessonTypes.map((e) => e.toJson()).toList(),
      'groupAssignments': assignments.map((e) => e.toJson()).toList(),
      'existingLessons': existingLessons.map((e) => e.toJson()).toList(),
    };
  }
}

@immutable
class SchedulePeriod {
  const SchedulePeriod({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

@immutable
class ScheduleTimeSlot {
  const ScheduleTimeSlot({
    required this.id,
    required this.order,
    required this.start,
    required this.end,
    this.kind,
  });

  final int id;
  final int order;
  final String start;
  final String end;
  final String? kind;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'start': start,
      'end': end,
      if (kind != null) 'kind': kind,
    };
  }
}

@immutable
class ScheduleLessonType {
  const ScheduleLessonType({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

@immutable
class ScheduleGroup {
  const ScheduleGroup({
    required this.id,
    required this.name,
    required this.size,
  });

  final int id;
  final String name;
  final int size;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
    };
  }
}

@immutable
class ScheduleTeacher {
  const ScheduleTeacher({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

@immutable
class ScheduleAudience {
  const ScheduleAudience({
    required this.id,
    required this.name,
    required this.capacity,
    required this.buildingId,
    this.preferredTeacherId,
  });

  final int id;
  final String name;
  final int capacity;
  final int? buildingId;
  final int? preferredTeacherId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'buildingId': buildingId,
      if (preferredTeacherId != null) 'preferredTeacherId': preferredTeacherId,
    };
  }
}

@immutable
class ScheduleAudienceLessonType {
  const ScheduleAudienceLessonType({
    required this.audienceId,
    required this.lessonTypeId,
  });

  final int audienceId;
  final int lessonTypeId;

  Map<String, dynamic> toJson() {
    return {
      'audienceId': audienceId,
      'lessonTypeId': lessonTypeId,
    };
  }
}

@immutable
class ScheduleAssignment {
  const ScheduleAssignment({
    required this.id,
    required this.groupId,
    required this.teacherId,
    required this.disciplineId,
    required this.lessonTypeId,
    required this.totalHours,
    required this.hoursPerLesson,
    required this.startDate,
    required this.endDate,
    this.subgroup,
  });

  final int id;
  final int groupId;
  final int teacherId;
  final int disciplineId;
  final int lessonTypeId;
  final int totalHours;
  final int hoursPerLesson;
  final DateTime startDate;
  final DateTime endDate;
  final String? subgroup;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'teacherId': teacherId,
      'disciplineId': disciplineId,
      'lessonTypeId': lessonTypeId,
      'totalHours': totalHours,
      'hoursPerLesson': hoursPerLesson,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (subgroup != null) 'subgroup': subgroup,
    };
  }
}

@immutable
class ScheduleExistingLesson {
  const ScheduleExistingLesson({
    required this.groupId,
    required this.teacherId,
    required this.audienceId,
    required this.disciplineId,
    required this.lessonTypeId,
    required this.date,
    required this.slotId,
    this.subgroup,
    this.isLocked = false,
  });

  final int groupId;
  final int teacherId;
  final int audienceId;
  final int disciplineId;
  final int lessonTypeId;
  final DateTime date;
  final int slotId;
  final String? subgroup;
  final bool isLocked;

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'teacherId': teacherId,
      'audienceId': audienceId,
      'disciplineId': disciplineId,
      'lessonTypeId': lessonTypeId,
      'date': date.toIso8601String(),
      'slotId': slotId,
      if (subgroup != null) 'subgroup': subgroup,
      'isLocked': isLocked,
    };
  }
}

@immutable
class ScheduleSolution {
  const ScheduleSolution({
    required this.lessons,
    required this.objectiveScore,
    required this.solverStats,
  });

  final List<ScheduledLesson> lessons;
  final num objectiveScore;
  final ScheduleSolverStats solverStats;

  Map<String, dynamic> toJson() {
    return {
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'objectiveScore': objectiveScore,
      'solverStats': solverStats.toJson(),
    };
  }

  factory ScheduleSolution.fromJson(Map<String, dynamic> json) {
    return ScheduleSolution(
      lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((e) => ScheduledLesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      objectiveScore: json['objectiveScore'] as num? ?? 0,
      solverStats: ScheduleSolverStats.fromJson(
        json['solverStats'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

@immutable
class ScheduledLesson {
  const ScheduledLesson({
    required this.assignmentId,
    required this.groupId,
    required this.teacherId,
    required this.audienceId,
    required this.disciplineId,
    required this.lessonTypeId,
    required this.date,
    required this.slotId,
    this.subgroup,
  });

  final int assignmentId;
  final int groupId;
  final int teacherId;
  final int audienceId;
  final int disciplineId;
  final int lessonTypeId;
  final DateTime date;
  final int slotId;
  final String? subgroup;

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'groupId': groupId,
      'teacherId': teacherId,
      'audienceId': audienceId,
      'disciplineId': disciplineId,
      'lessonTypeId': lessonTypeId,
      'date': date.toIso8601String(),
      'slotId': slotId,
      if (subgroup != null) 'subgroup': subgroup,
    };
  }

  factory ScheduledLesson.fromJson(Map<String, dynamic> json) {
    return ScheduledLesson(
      assignmentId: json['assignmentId'] as int,
      groupId: json['groupId'] as int,
      teacherId: json['teacherId'] as int,
      audienceId: json['audienceId'] as int,
      disciplineId: json['disciplineId'] as int,
      lessonTypeId: json['lessonTypeId'] as int,
      date: DateTime.parse(json['date'] as String),
      slotId: json['slotId'] as int,
      subgroup: json['subgroup'] as String?,
    );
  }
}

@immutable
class ScheduleSolverStats {
  const ScheduleSolverStats({
    required this.status,
    required this.solveTimeSec,
    required this.iterations,
  });

  final String status;
  final num solveTimeSec;
  final int iterations;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'solveTimeSec': solveTimeSec,
      'iterations': iterations,
    };
  }

  factory ScheduleSolverStats.fromJson(Map<String, dynamic> json) {
    return ScheduleSolverStats(
      status: json['status'] as String? ?? 'UNKNOWN',
      solveTimeSec: json['solveTimeSec'] as num? ?? 0,
      iterations: json['iterations'] as int? ?? 0,
    );
  }
}
