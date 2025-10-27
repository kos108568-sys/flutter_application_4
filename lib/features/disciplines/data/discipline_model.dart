class DisciplineModel {
  int? id;
  String name;
  String teacher;
  String? groupCode;
  int? semester;
  int hours;
  int createdAt; // epoch millis

  DisciplineModel({
    this.id,
    required this.name,
    required this.teacher,
    this.groupCode,
    this.semester,
    int? hours,
    int? createdAt,
  })  : hours = hours ?? 0,
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'teacher': teacher,
        'group_code': groupCode,
        'semester': semester,
        'hours': hours,
        'created_at': createdAt,
      };

  factory DisciplineModel.fromMap(Map<String, dynamic> map) => DisciplineModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        teacher: (map['teacher'] as String?) ?? '',
        groupCode: map['group_code'] as String?,
        semester: (map['semester'] as num?)?.toInt(),
        hours: (map['hours'] as num?)?.toInt() ?? 0,
        createdAt: (map['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

