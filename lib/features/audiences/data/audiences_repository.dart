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
    final map = item.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.insert('audiences', map);
  }

  Future<int> update(AudiencesItemModel item) async {
    if (item.id == null) return 0;
    final db = await _db;
    final map = item.toMap()..remove('id');
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    map['sync_state'] = 'pending';
    return await db.update('audiences', map, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    // Soft delete to allow sync
    await db.update('audiences', {'deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch, 'sync_state': 'pending'}, where: 'id = ?', whereArgs: [id]);
    return 1;
  }

  // --- Sync helpers ---
  Future<List<Map<String, Object?>>> getPendingMaps() async {
    final db = await _db;
    final rows = await db.rawQuery("SELECT * FROM audiences WHERE sync_state != 'synced' OR (remote_id IS NULL AND deleted = 0)");
    return rows;
  }

  Future<Map<String, Object?>?> findByRemoteId(String remoteId) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM audiences WHERE remote_id = ? LIMIT 1', [remoteId]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> setRemoteId(int localId, String remoteId) async {
    final db = await _db;
    await db.update('audiences', {'remote_id': remoteId, 'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> markSyncedByLocalId(int localId) async {
    final db = await _db;
    await db.update('audiences', {'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> applyRemoteToLocal(Map<String, dynamic> remote) async {
    final db = await _db;
    // Try find by remote_id
    final existing = await db.rawQuery('SELECT id, updated_at FROM audiences WHERE remote_id = ? LIMIT 1', [remote['id']]);
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'name': remote['name'],
      'type': remote['type'],
      'capacity': remote['capacity'],
      'boss': remote['boss'],
      'building': remote['building'],
      'equipment': remote['equipment'] is String ? remote['equipment'] : null,
      'remote_id': remote['id'],
      'updated_at': now,
      'sync_state': 'synced',
    };
    if (existing.isEmpty) {
      await db.insert('audiences', row..remove('id'));
    } else {
      final localId = existing.first['id'] as int;
      await db.update('audiences', row, where: 'id = ?', whereArgs: [localId]);
    }
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
