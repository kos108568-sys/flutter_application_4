import 'dart:convert';

class AudiencesItemModel {
  int? id;
  String name;
  int capacity;
  int typeId;
  String? typeName;
  int? headTeacherId;
  String? headTeacherName;
  String? building;
  List<String> equipmentList;

  AudiencesItemModel({
    this.id,
    required this.name,
    required this.capacity,
    required this.typeId,
    this.typeName,
    this.headTeacherId,
    this.headTeacherName,
    this.building,
    List<String>? equipmentList,
  }) : equipmentList = equipmentList ?? <String>[];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'capacity': capacity,
        'type_id': typeId,
        'head_teacher_id': headTeacherId,
        'building': building,
        'equipment_list': jsonEncode(equipmentList),
      };

  factory AudiencesItemModel.fromMap(Map<String, dynamic> map) => AudiencesItemModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        capacity: (map['capacity'] as num).toInt(),
        typeId: (map['type_id'] as num).toInt(),
        typeName: map['type_name'] as String?,
        headTeacherId: map['head_teacher_id'] as int?,
        headTeacherName: map['head_teacher_name'] as String?,
        building: map['building'] as String?,
        equipmentList: _parseEquipment(map['equipment_list']),
      );

  static List<String> _parseEquipment(dynamic value) {
    if (value == null) return <String>[];
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
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
