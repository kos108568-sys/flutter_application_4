class AudienceLessonType {
  final int? id;
  final int audienceId;
  final int lessonTypeId;

  const AudienceLessonType({
    this.id,
    required this.audienceId,
    required this.lessonTypeId,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'audience_id': audienceId,
      'lesson_type_id': lessonTypeId,
    };
  }

  factory AudienceLessonType.fromMap(Map<String, Object?> map) {
    return AudienceLessonType(
      id: (map['id'] as num?)?.toInt(),
      audienceId: (map['audience_id'] as num).toInt(),
      lessonTypeId: (map['lesson_type_id'] as num).toInt(),
    );
  }
}
