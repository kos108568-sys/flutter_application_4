class GroupSubjectTeacher {
  final int? id;
  final int groupId;
  final int teacherId;
  final int disciplineId;
  final int totalHours;
  final String? startDate;
  final String? endDate;
  final String? notes;
  final String? subgroup; // 'all', '1', '2'

  GroupSubjectTeacher({
    this.id,
    required this.groupId,
    required this.teacherId,
    required this.disciplineId,
    required this.totalHours,
    this.startDate,
    this.endDate,
    this.notes,
    this.subgroup,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'group_id': groupId,
        'teacher_id': teacherId,
        'discipline_id': disciplineId,
        'total_hours': totalHours,
        'start_date': startDate,
      'end_date': endDate,
      'notes': notes,
      if (subgroup != null) 'subgroup': subgroup,
    };

  factory GroupSubjectTeacher.fromMap(Map<String, dynamic> map) => GroupSubjectTeacher(
        id: map['id'] as int?,
        groupId: map['group_id'] as int,
        teacherId: map['teacher_id'] as int,
        disciplineId: map['discipline_id'] as int,
        totalHours: map['total_hours'] as int,
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
        notes: map['notes'] as String?,
        subgroup: map['subgroup'] as String?,
      );
}


