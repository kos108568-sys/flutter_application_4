class AudienceEquipment {
  final int? id;
  final int audienceId;
  final int equipmentId;

  AudienceEquipment({this.id, required this.audienceId, required this.equipmentId});

  Map<String, dynamic> toMap() => {
        'id': id,
        'audience_id': audienceId,
        'equipment_id': equipmentId,
      };

  factory AudienceEquipment.fromMap(Map<String, dynamic> map) => AudienceEquipment(
        id: map['id'] as int?,
        audienceId: map['audience_id'] as int,
        equipmentId: map['equipment_id'] as int,
      );
}


