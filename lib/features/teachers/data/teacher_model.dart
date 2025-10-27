class TeacherModel {
  int? id;
  String fullName;
  int? curatorGroupId;
  String? department; // otdelenie
  int workloadHours; // raschet na osnove predmetov
  List<int> disciplineIds;
  List<int> audienceIds;
  List<int> taughtGroupIds;

  TeacherModel({
    this.id,
    required this.fullName,
    this.curatorGroupId,
    this.department,
    this.workloadHours = 0,
    required this.disciplineIds,
    required this.audienceIds,
    List<int>? taughtGroupIds,
  }) : taughtGroupIds = taughtGroupIds ?? const [];
}

