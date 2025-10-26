import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'audience_type_model.dart';
import 'audiences_item_model.dart';

class AudiencesRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<AudiencesItemModel>> getAll({String? search, String? orderBy}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('(a.name LIKE ? OR at.type_name LIKE ? OR IFNULL(t.full_name, "") LIKE ?)');
      final query = '%${search.trim()}%';
      args..add(query)..add(query)..add(query);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final order = orderBy ?? 'a.name ASC';
    final rows = await db.rawQuery('''
      SELECT a.*, at.type_name, t.full_name AS head_teacher_name
      FROM audiences a
      INNER JOIN audience_types at ON at.id = a.type_id
      LEFT JOIN teachers t ON t.id = a.head_teacher_id
      $whereSql
      ORDER BY $order
    ''', args);
    return rows.map((row) => AudiencesItemModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<List<AudiencesItemModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT a.*, at.type_name, t.full_name AS head_teacher_name
      FROM audiences a
      INNER JOIN audience_types at ON at.id = a.type_id
      LEFT JOIN teachers t ON t.id = a.head_teacher_id
      ORDER BY a.id DESC
      LIMIT ?
    ''', [limit]);
    return rows.map((row) => AudiencesItemModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<int> insert(AudiencesItemModel audience) async {
    final db = await _db;
    return db.insert('audiences', audience.toMap()..remove('id'));
  }

  Future<int> update(AudiencesItemModel audience) async {
    if (audience.id == null) return 0;
    final db = await _db;
    return db.update(
      'audiences',
      audience.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [audience.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('audiences', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AudienceTypeModel>> types() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM audience_types ORDER BY type_name ASC');
    return rows.map((row) => AudienceTypeModel.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<int> upsertType(AudienceTypeModel type) async {
    final db = await _db;
    if (type.id == null) {
      return db.insert('audience_types', type.toMap()..remove('id'));
    }
    return db.update(
      'audience_types',
      type.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final typeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audience_types')) ?? 0;
    if (typeCount == 0) {
      await db.insert('audience_types', {
        'type_name': 'Компьютерная',
        'description': 'Оснащена ПК и проектором',
        'equipment': 'ПК, проектор, маркерная доска',
      });
      await db.insert('audience_types', {
        'type_name': 'Лекционная',
        'description': 'Большая вместимость, проектор',
        'equipment': 'Проектор, звуковая система',
      });
      await db.insert('audience_types', {
        'type_name': 'Лабораторная',
        'description': 'Рабочие места для практики',
        'equipment': 'Лабораторное оборудование',
      });
    }

    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audiences')) ?? 0;
    if (count > 0) return;
    final audienceTypes = await types();
    if (audienceTypes.isEmpty) return;
    final computerType = audienceTypes.firstWhere((t) => t.typeName == 'Компьютерная', orElse: () => audienceTypes.first);
    final lectureType = audienceTypes.firstWhere((t) => t.typeName == 'Лекционная', orElse: () => audienceTypes.first);
    final labType = audienceTypes.firstWhere((t) => t.typeName == 'Лабораторная', orElse: () => audienceTypes.first);
    final samples = [
      AudiencesItemModel(
        name: '8-232',
        capacity: 40,
        typeId: computerType.id!,
        building: 'Учебный корпус А',
        equipmentList: const ['ПК', 'Проектор', 'Маркерная доска'],
      ),
      AudiencesItemModel(
        name: '4-301',
        capacity: 120,
        typeId: lectureType.id!,
        building: 'Учебный корпус Б',
        equipmentList: const ['Проектор', 'Звук', 'Микрофоны'],
      ),
      AudiencesItemModel(
        name: '5-108',
        capacity: 28,
        typeId: labType.id!,
        building: 'Учебный корпус А',
        equipmentList: const ['Лабораторные стенды', 'Спец. оборудование'],
      ),
    ];
    for (final audience in samples) {
      await insert(audience);
    }
  }
}
