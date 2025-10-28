class Audience {
  final int? id;
  final String name;
  final int? capacity;
  final int? audienceTypeId;
  final int? buildingId;
  final int? responsibleTeacherId;
  final String? notes;

  Audience({
    this.id,
    required this.name,
    this.capacity,
    this.audienceTypeId,
    this.buildingId,
    this.responsibleTeacherId,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'audience_type_id': audienceTypeId,
        'building_id': buildingId,
        'responsible_teacher_id': responsibleTeacherId,
        'notes': notes,
      };

  factory Audience.fromMap(Map<String, dynamic> map) => Audience(
        id: map['id'] as int?,
        name: map['name'] as String,
        capacity: (map['capacity'] as num?)?.toInt(),
        audienceTypeId: map['audience_type_id'] as int?,
        buildingId: map['building_id'] as int?,
        responsibleTeacherId: map['responsible_teacher_id'] as int?,
        notes: _asNullableString(map['notes']),
      );
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}


