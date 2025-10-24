import 'dart:convert';

class GroupModel {
  int? id;
  String name;
  int? size;
  List<int> disciplineIds;
  String? curator;
  int? course;
  String? specialty;

  GroupModel({
    this.id,
    required this.name,
    this.size,
    required this.disciplineIds,
    this.curator,
    this.course,
    this.specialty,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'size': size,
        'discipline_ids': jsonEncode(disciplineIds),
        'curator': curator,
        'course': course,
        'specialty': specialty,
      };

  factory GroupModel.fromMap(Map<String, dynamic> map) => GroupModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        size: (map['size'] as num?)?.toInt(),
        disciplineIds: _parseIds(map['discipline_ids']),
        curator: map['curator'] as String?,
        course: (map['course'] as num?)?.toInt(),
        specialty: map['specialty'] as String?,
      );

  static List<int> _parseIds(dynamic v) {
    if (v == null) return <int>[];
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) {
        return decoded.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {}
    return <int>[];
  }
}

