class TeacherModel {
  int? id;
  String fullName;
  int? curatorGroupId;
  List<int> disciplineIds;
  List<int> audienceIds;

  TeacherModel({
    this.id,
    required this.fullName,
    this.curatorGroupId,
    required this.disciplineIds,
    required this.audienceIds,
  });
}

