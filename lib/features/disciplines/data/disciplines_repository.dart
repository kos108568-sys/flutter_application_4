import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'discipline_model.dart';

class DisciplinesRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<DisciplineModel>> getAll({
    String? search,
    String? groupCode,
    int? semester,
    String orderBy = 'name ASC',
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('(name LIKE ? OR teacher LIKE ?)');
      final q = '%${search.trim()}%';
      args..add(q)..add(q);
    }
    if (groupCode != null && groupCode.isNotEmpty) {
      where.add('group_code = ?');
      args.add(groupCode);
    }
    if (semester != null) {
      where.add('semester = ?');
      args.add(semester);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('SELECT * FROM disciplines $whereSql ORDER BY $orderBy', args);
    return rows.map((e) => DisciplineModel.fromMap(e)).toList();
  }

  Future<List<DisciplineModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM disciplines ORDER BY created_at DESC LIMIT ?', [limit]);
    return rows.map((e) => DisciplineModel.fromMap(e)).toList();
  }

  Future<int> insert(DisciplineModel m) async {
    final db = await _db;
    return await db.insert('disciplines', m.toMap()..remove('id'));
  }

  Future<int> update(DisciplineModel m) async {
    if (m.id == null) return 0;
    final db = await _db;
    return await db.update('disciplines', m.toMap()..remove('id'), where: 'id = ?', whereArgs: [m.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('disciplines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM disciplines')) ?? 0;
    if (count > 0) return;
    final samples = <DisciplineModel>[
      DisciplineModel(name: 'Математика', teacher: 'Селивёрстов К. О.', groupCode: 'ПО-42', semester: 1),
      DisciplineModel(name: 'Объектно-ориентированное программирование', teacher: 'Селивёрстов К. О.', groupCode: 'ПО-42', semester: 1),
      DisciplineModel(name: 'Математика', teacher: 'Селивёрстов К. О.', groupCode: 'ПО-41', semester: 2),
    ];
    for (final s in samples) {
      await insert(s);
    }
  }
}

