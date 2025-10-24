import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'audiences_item_model.dart';

class AudiencesRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<AudiencesItemModel>> getAll({String? search, String? orderBy}) async {
    final db = await _db;
    String where = '';
    List<Object?> whereArgs = [];
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE name LIKE ? OR type LIKE ?';
      final q = '%${search.trim()}%';
      whereArgs = [q, q];
    }
    final order = orderBy ?? 'id DESC';
    final maps = await db.rawQuery('SELECT * FROM audiences $where ORDER BY $order', whereArgs);
    return maps.map((m) => AudiencesItemModel.fromMap(m)).toList();
  }

  Future<List<AudiencesItemModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT * FROM audiences ORDER BY id DESC LIMIT ?', [limit]);
    return maps.map((m) => AudiencesItemModel.fromMap(m)).toList();
  }

  Future<int> insert(AudiencesItemModel item) async {
    final db = await _db;
    return await db.insert('audiences', item.toMap()..remove('id'));
  }

  Future<int> update(AudiencesItemModel item) async {
    if (item.id == null) return 0;
    final db = await _db;
    return await db.update('audiences', item.toMap()..remove('id'), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('audiences', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audiences')) ?? 0;
    if (count > 0) return;
    final samples = [
      AudiencesItemModel(
        name: '8-232',
        type: 'Лекция',
        capacity: 40,
        boss: 'И. И. Иванов',
        building: 'Корпус А',
        equipment: ['Проектор', 'Доска'],
      ),
      AudiencesItemModel(
        name: 'Д-431',
        type: 'Семинар',
        capacity: 35,
        boss: 'П. П. Петров',
        building: 'Корпус Б',
        equipment: ['Доска', 'Маркеры'],
      ),
      AudiencesItemModel(
        name: '5-108',
        type: 'Лаборатория',
        capacity: 28,
        boss: 'С. С. Сидоров',
        building: 'Корпус А',
        equipment: ['ПК', 'Проектор'],
      ),
    ];
    for (final s in samples) {
      await insert(s);
    }
  }
}
