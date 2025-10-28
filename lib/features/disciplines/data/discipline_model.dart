class Discipline {
  final int? id;
  final String name;
  final int? lessonTypeId;
  final String? semester;

  Discipline({
    this.id,
    required this.name,
    this.lessonTypeId,
    this.semester,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'lesson_type_id': lessonTypeId,
        'semester': semester,
      };

  factory Discipline.fromMap(Map<String, dynamic> map) => Discipline(
        id: map['id'] as int?,
        name: map['name'] as String,
        lessonTypeId: map['lesson_type_id'] as int?,
        semester: _asNullableString(map['semester']),
      );
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

