class LessonRule {
  final int? id;
  final int lessonTypeId;
  final int audienceTypeId;
  final bool allowed;

  LessonRule({
    this.id,
    required this.lessonTypeId,
    required this.audienceTypeId,
    this.allowed = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'lesson_type_id': lessonTypeId,
        'audience_type_id': audienceTypeId,
        'allowed': allowed ? 1 : 0,
      };

  factory LessonRule.fromMap(Map<String, dynamic> map) => LessonRule(
        id: map['id'] as int?,
        lessonTypeId: map['lesson_type_id'] as int,
        audienceTypeId: map['audience_type_id'] as int,
        allowed: (map['allowed'] ?? 1) == 1,
      );

  Map<String, dynamic> toSupabaseMap() => {
        if (id != null) 'id': id,
        'lesson_type_id': lessonTypeId,
        'audience_type_id': audienceTypeId,
        'allowed': allowed,
      };
}


