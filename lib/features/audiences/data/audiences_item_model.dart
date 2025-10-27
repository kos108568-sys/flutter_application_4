import 'dart:convert';

class AudiencesItemModel {
  int? id;
  String name;
  String type;
  int capacity;
  String boss;
  String? building;
  List<String> equipment;

  AudiencesItemModel({
    this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.boss,
    this.building,
    required this.equipment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'capacity': capacity,
      'boss': boss,
      'building': building,
      'equipment': jsonEncode(equipment),
    };
  }

  factory AudiencesItemModel.fromMap(Map<String, dynamic> map) {
    return AudiencesItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: (map['type'] as String?) ?? '',
      capacity: (map['capacity'] as num).toInt(),
      boss: (map['boss'] as String?) ?? '',
      building: map['building'] as String?,
      equipment: _parseEquipment(map['equipment']),
    );
  }

  static List<String> _parseEquipment(dynamic value) {
    if (value == null) return <String>[];
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        // fallback: comma separated
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return <String>[];
  }
}
