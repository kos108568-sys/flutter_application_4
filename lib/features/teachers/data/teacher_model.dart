class TeacherModel {
  int? id;
  String fullName;
  List<int> curatorGroupIds;
  List<int> subjectIds;
  List<int> audienceIds;

  TeacherModel({
    this.id,
    required this.fullName,
    List<int>? curatorGroupIds,
    List<int>? subjectIds,
    List<int>? audienceIds,
  })  : curatorGroupIds = curatorGroupIds ?? <int>[],
        subjectIds = subjectIds ?? <int>[],
        audienceIds = audienceIds ?? <int>[];
}

