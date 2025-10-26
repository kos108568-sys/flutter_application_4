class SubjectModel {
  int? id;
  String name;
  int hours;
  String semester; // "1", "2" or "year"
  int createdAt; // epoch millis

  SubjectModel({
    this.id,
    required this.name,
    required this.hours,
    required this.semester,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'hours': hours,
        'semester': semester,
        'created_at': createdAt,
      };

  factory SubjectModel.fromMap(Map<String, dynamic> map) => SubjectModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        hours: (map['hours'] as num?)?.toInt() ?? 0,
        semester: (map['semester'] as String?) ?? '1',
        createdAt: (map['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      );
}

