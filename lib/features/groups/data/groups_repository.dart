import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'group_model.dart';

class GroupsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(GroupModel g) async {
    final db = await _db;
    return db.insert('groups', g.toMap()..remove('id'));
  }

  Future<int> update(GroupModel g) async {
    if (g.id == null) return 0;
    final db = await _db;
    return db.update('groups', g.toMap()..remove('id'), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GroupModel>> getAll({String? search, String orderBy = 'name ASC'}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE name LIKE ? OR curator LIKE ? OR specialty LIKE ?';
      final q = '%${search.trim()}%';
      args = [q, q, q];
    }
    final rows = await db.rawQuery('SELECT * FROM groups $where ORDER BY $orderBy', args);
    return rows.map((e) => GroupModel.fromMap(e)).toList();
  }

  Future<List<GroupModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM groups ORDER BY id DESC LIMIT ?', [limit]);
    return rows.map((e) => GroupModel.fromMap(e)).toList();
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM groups')) ?? 0;
    if (count > 0) return;
    final samples = [
      GroupModel(name: 'ПО-42', size: 30, curator: 'И. И. Иванов', course: 2, specialty: 'Программная инженерия', disciplineIds: []),
      GroupModel(name: 'ПО-41', size: 28, curator: 'П. П. Петров', course: 2, specialty: 'Программная инженерия', disciplineIds: []),
    ];
    for (final g in samples) {
      await insert(g);
    }
  }
}
