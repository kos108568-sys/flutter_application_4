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

  // --- Relations: teachers <-> disciplines ---
  Future<List<Map<String, Object?>>> teachersLite() async {
    final db = await _db;
    return await db.rawQuery('SELECT id, full_name FROM teachers ORDER BY full_name ASC');
  }

  Future<Set<int>> teacherIdsFor(int disciplineId) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT teacher_id FROM teacher_disciplines WHERE discipline_id = ?', [disciplineId]);
    return rows.map((e) => (e['teacher_id'] as int)).toSet();
  }

  Future<void> setTeachersFor(int disciplineId, List<int> teacherIds) async {
    final db = await _db;
    await db.delete('teacher_disciplines', where: 'discipline_id = ?', whereArgs: [disciplineId]);
    for (final tid in teacherIds.toSet()) {
      await db.insert('teacher_disciplines', {'teacher_id': tid, 'discipline_id': disciplineId});
    }
  }

  // groups <-> disciplines join helpers (for UI cards)
  Future<Map<int, List<String>>> groupNamesByDiscipline(List<int> disciplineIds) async {
    if (disciplineIds.isEmpty) return {};
    final db = await _db;
    final placeholders = List.filled(disciplineIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT gd.discipline_id AS did, g.name AS gname FROM group_disciplines gd INNER JOIN groups g ON g.id = gd.group_id WHERE gd.discipline_id IN ($placeholders)',
      disciplineIds,
    );
    final map = <int, List<String>>{};
    for (final r in rows) {
      final did = r['did'] as int;
      final name = (r['gname'] as String?) ?? '';
      if (name.isEmpty) continue;
      map.putIfAbsent(did, () => <String>[]).add(name);
    }
    return map;
  }

  // --- Relations: groups <-> disciplines (M<->N) ---
  Future<Set<int>> groupIdsFor(int disciplineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT group_id FROM group_disciplines WHERE discipline_id = ?',
      [disciplineId],
    );
    return rows.map((e) => (e['group_id'] as int)).toSet();
  }

  Future<void> setGroupsFor(int disciplineId, List<int> groupIds) async {
    final db = await _db;
    await db.delete('group_disciplines', where: 'discipline_id = ?', whereArgs: [disciplineId]);
    for (final gid in groupIds.toSet()) {
      await db.insert('group_disciplines', {
        'group_id': gid,
        'discipline_id': disciplineId,
      });
    }
  }

  // For groups UI: fetch discipline names for given group ids
  Future<Map<int, List<String>>> disciplineNamesByGroup(List<int> groupIds) async {
    if (groupIds.isEmpty) return {};
    final db = await _db;
    final placeholders = List.filled(groupIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT gd.group_id AS gid, d.name AS dname FROM group_disciplines gd INNER JOIN disciplines d ON d.id = gd.discipline_id WHERE gd.group_id IN ($placeholders)',
      groupIds,
    );
    final map = <int, List<String>>{};
    for (final r in rows) {
      final gid = r['gid'] as int;
      final name = (r['dname'] as String?) ?? '';
      if (name.isEmpty) continue;
      map.putIfAbsent(gid, () => <String>[]).add(name);
    }
    return map;
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM disciplines')) ?? 0;
    if (count > 0) return;
    final samples = <DisciplineModel>[
      DisciplineModel(name: 'Primer A', teacher: 'Prepod 1', groupCode: 'PO-42', semester: 1, hours: 40),
      DisciplineModel(name: 'Primer B', teacher: 'Prepod 1', groupCode: 'PO-42', semester: 1, hours: 72),
      DisciplineModel(name: 'Primer C', teacher: 'Prepod 1', groupCode: 'PO-41', semester: 2, hours: 36),
    ];
    for (final s in samples) {
      await insert(s);
    }
  }
}


