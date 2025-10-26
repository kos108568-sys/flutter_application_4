class AudienceTypeModel {
  int? id;
  String typeName;
  String? description;
  String? equipment;

  AudienceTypeModel({
    this.id,
    required this.typeName,
    this.description,
    this.equipment,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type_name': typeName,
        'description': description,
        'equipment': equipment,
      };

  factory AudienceTypeModel.fromMap(Map<String, dynamic> map) => AudienceTypeModel(
        id: map['id'] as int?,
        typeName: map['type_name'] as String,
        description: map['description'] as String?,
        equipment: map['equipment'] as String?,
      );
}
