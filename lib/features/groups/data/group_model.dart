class GroupModel {
  int? id;
  String name;
  int? studentCount;
  int? course;
  String? speciality;
  String? department;
  int? curatorId;
  String? curatorName;
  List<int> subjectIds;

  GroupModel({
    this.id,
    required this.name,
    this.studentCount,
    this.course,
    this.speciality,
    this.department,
    this.curatorId,
    this.curatorName,
    List<int>? subjectIds,
  }) : subjectIds = subjectIds ?? <int>[];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'student_count': studentCount,
        'course': course,
        'speciality': speciality,
        'department': department,
        'curator_id': curatorId,
      };

  factory GroupModel.fromMap(Map<String, dynamic> map, {List<int>? subjectIds}) => GroupModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        studentCount: (map['student_count'] as num?)?.toInt(),
        course: (map['course'] as num?)?.toInt(),
        speciality: map['speciality'] as String?,
        department: map['department'] as String?,
        curatorId: map['curator_id'] as int?,
        curatorName: map['curator_name'] as String?,
        subjectIds: subjectIds ?? <int>[],
      );
}
