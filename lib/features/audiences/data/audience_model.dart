class Audience {
  final int? id;
  final String name;
  final String? type;
  final int? capacity;
  final int? buildingId;
  final int? teacherId;
  final String? notes;
  final List<int> lessonTypeIds;

  Audience({
    this.id,
    required this.name,
    this.type,
    this.capacity,
    this.buildingId,
    this.teacherId,
    this.notes,
    List<int>? lessonTypeIds,
  }) : lessonTypeIds = lessonTypeIds ?? const [];

  Audience copyWith({
    int? id,
    String? name,
    String? type,
    int? capacity,
    int? buildingId,
    int? teacherId,
    String? notes,
    List<int>? lessonTypeIds,
  }) {
    return Audience(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      buildingId: buildingId ?? this.buildingId,
      teacherId: teacherId ?? this.teacherId,
      notes: notes ?? this.notes,
      lessonTypeIds: lessonTypeIds ?? this.lessonTypeIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'capacity': capacity,
      'building_id': buildingId,
      'teacher_id': teacherId,
      'notes': notes,
    };
  }

  factory Audience.fromMap(
    Map<String, dynamic> map, {
    List<int>? lessonTypeIds,
  }) {
    return Audience(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: _asNullableString(map['type']),
      capacity: (map['capacity'] as num?)?.toInt(),
      buildingId: (map['building_id'] as num?)?.toInt(),
      teacherId: (map['teacher_id'] as num?)?.toInt(),
      notes: _asNullableString(map['notes']),
      lessonTypeIds: lessonTypeIds,
    );
  }
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
