import 'dart:convert';

class GroupModel {
  int? id;
  String name;
  int? size;
  List<int> disciplineIds;
  String? curator;
  int? course;
  String? specialty;

  // Новая схема
  int? curatorTeacherId;
  int? studentCount;
  int? departmentId;
  String? notes;

  GroupModel({
    this.id,
    required this.name,
    this.size,
    required this.disciplineIds,
    this.curator,
    this.course,
    this.specialty,
    this.curatorTeacherId,
    this.studentCount,
    this.departmentId,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'size': size,
        'discipline_ids': jsonEncode(disciplineIds),
        'curator': curator,
        'course': course,
        'specialty': specialty,
        'curator_teacher_id': curatorTeacherId,
        'student_count': studentCount,
        'department_id': departmentId,
        'notes': notes,
      };

  factory GroupModel.fromMap(Map<String, dynamic> map) => GroupModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        size: (map['size'] as num?)?.toInt(),
        disciplineIds: _parseIds(map['discipline_ids']),
        curator: _asNullableString(map['curator']),
        course: (map['course'] as num?)?.toInt(),
        specialty: _asNullableString(map['specialty']),
        curatorTeacherId: map['curator_teacher_id'] as int?,
        studentCount: (map['student_count'] as num?)?.toInt(),
        departmentId: map['department_id'] as int?,
        notes: _asNullableString(map['notes']),
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

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

