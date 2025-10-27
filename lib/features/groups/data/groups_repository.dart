import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'group_model.dart';

class GroupsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(GroupModel g) async {
    final db = await _db;
    final id = await db.insert('groups', g.toMap()..remove('id'));
    await _replaceDisciplines(db, id, g.disciplineIds);
    return id;
  }

  Future<int> update(GroupModel g) async {
    if (g.id == null) return 0;
    final db = await _db;
    final res = await db.update('groups', g.toMap()..remove('id'), where: 'id = ?', whereArgs: [g.id]);
    await _replaceDisciplines(db, g.id!, g.disciplineIds);
    return res;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    await db.delete('group_disciplines', where: 'group_id = ?', whereArgs: [id]);
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
    final list = rows.map((e) => GroupModel.fromMap(e)).toList();
    return _hydrateDisciplines(db, list);
  }

  Future<List<GroupModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM groups ORDER BY id DESC LIMIT ?', [limit]);
    final list = rows.map((e) => GroupModel.fromMap(e)).toList();
    return _hydrateDisciplines(db, list);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM groups')) ?? 0;
    if (count > 0) return;
    final samples = [
      GroupModel(name: 'PO-42', size: 30, curator: 'I. I. Ivanov', course: 2, specialty: 'Programmnaya inzheneriya', disciplineIds: const []),
      GroupModel(name: 'PO-41', size: 28, curator: 'P. P. Petrov', course: 2, specialty: 'Programmnaya inzheneriya', disciplineIds: const []),
    ];
    for (final g in samples) {
      await insert(g);
    }
  }

  Future<void> _replaceDisciplines(Database db, int groupId, List<int> disciplineIds) async {
    await db.delete('group_disciplines', where: 'group_id = ?', whereArgs: [groupId]);
    for (final did in disciplineIds.toSet()) {
      await db.insert('group_disciplines', {'group_id': groupId, 'discipline_id': did});
    }
  }

  Future<List<GroupModel>> _hydrateDisciplines(Database db, List<GroupModel> groups) async {
    if (groups.isEmpty) return groups;
    final ids = groups.where((g) => g.id != null).map((g) => g.id!).toList();
    if (ids.isEmpty) return groups;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery('SELECT group_id, discipline_id FROM group_disciplines WHERE group_id IN ($placeholders)', ids);
    final map = <int, List<int>>{};
    for (final r in rows) {
      final gid = r['group_id'] as int;
      final did = r['discipline_id'] as int;
      map.putIfAbsent(gid, () => <int>[]).add(did);
    }
    return groups.map((g) => GroupModel(
          id: g.id,
          name: g.name,
          size: g.size,
          disciplineIds: map[g.id ?? -1] ?? const [],
          curator: g.curator,
          course: g.course,
          specialty: g.specialty,
        )).toList();
  }

  // --- Sync helpers ---
  Future<List<Map<String, Object?>>> getPendingMaps() async {
    final db = await _db;
    final rows = await db.rawQuery("SELECT * FROM groups WHERE sync_state != 'synced' OR (remote_id IS NULL AND deleted = 0)");
    return rows;
  }

  Future<Map<String, Object?>?> findByRemoteId(String remoteId) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM groups WHERE remote_id = ? LIMIT 1', [remoteId]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> setRemoteId(int localId, String remoteId) async {
    final db = await _db;
    await db.update('groups', {'remote_id': remoteId, 'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> markSyncedByLocalId(int localId) async {
    final db = await _db;
    await db.update('groups', {'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> applyRemoteToLocal(Map<String, dynamic> remote) async {
    final db = await _db;
    final existing = await db.rawQuery('SELECT id, updated_at FROM groups WHERE remote_id = ? LIMIT 1', [remote['id']]);
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'name': remote['name'],
      'size': remote['size'],
      'curator': remote['curator'],
      'course': remote['course'],
      'specialty': remote['specialty'],
      'discipline_ids': remote['discipline_ids'] is String ? remote['discipline_ids'] : (remote['discipline_ids'] == null ? null : remote['discipline_ids'].toString()),
      'remote_id': remote['id'],
      'updated_at': now,
      'sync_state': 'synced',
    };
    if (existing.isEmpty) {
      await db.insert('groups', row..remove('id'));
    } else {
      final localId = existing.first['id'] as int;
      await db.update('groups', row, where: 'id = ?', whereArgs: [localId]);
    }
  }
}

