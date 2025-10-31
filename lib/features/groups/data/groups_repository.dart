import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'group_model.dart';

class GroupsRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  Map<String, dynamic> _toRemoteMap(GroupModel g) {
    return {
      if (g.id != null) 'id': g.id,
      'name': g.name,
      'curator_teacher_id': g.curatorTeacherId,
      'student_count': g.studentCount,
      'course': g.course,
      'department_id': g.departmentId,
      'notes': g.notes,
    };
  }

  // Сохранение локально
  Future<int> _insertLocal(GroupModel g) async {
    final db = await _db;
    final id = await db.insert('groups', g.toMap());
    await _replaceDisciplines(db, id, g.disciplineIds);
    return id;
  }

  // Сохранение локально
  Future<int> _updateLocal(GroupModel g) async {
    if (g.id == null) return 0;
    final db = await _db;
    final res = await db.update('groups', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
    await _replaceDisciplines(db, g.id!, g.disciplineIds);
    return res;
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    await db.delete('group_disciplines', where: 'group_id = ?', whereArgs: [id]);
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GroupModel>> getAllGroups({String? search, String orderBy = 'name ASC'}) async {
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
      GroupModel(name: 'PO-42', size: 30, curator: 'I. I. Ivanov', course: 2, specialty: 'Programmnaya inzheneriya', disciplineIds: const [], studentCount: 30),
      GroupModel(name: 'PO-41', size: 28, curator: 'P. P. Petrov', course: 2, specialty: 'Programmnaya inzheneriya', disciplineIds: const [], studentCount: 28),
    ];
    for (final g in samples) {
      await _insertLocal(g);
    }
  }

  // Отправка в Supabase
  Future<int?> _insertRemote(GroupModel g) async {
    final res = await _supabase.from('groups').insert(_toRemoteMap(g)).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка в Supabase
  Future<bool> _updateRemote(GroupModel g) async {
    if (g.id == null) return false;
    await _supabase.from('groups').update(_toRemoteMap(g)).eq('id', g.id!);
    return true;
  }

  // Отправка в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from('groups').delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertGroup(GroupModel g) async {
    // Сохранение локально
    final localId = await _insertLocal(g);
    // Отправка в Supabase
    try {
      final remoteId = await _insertRemote(g);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update('groups', {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateGroup(GroupModel g) async {
    // Сохранение локально
    final updated = await _updateLocal(g);
    // Отправка в Supabase
    try {
      await _updateRemote(g);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteGroup(int id) async {
    // Сохранение локально
    final deleted = await _deleteLocal(id);
    // Отправка в Supabase
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncGroups() async {
    try {
      final db = await _db;
      final localRows = await db.query('groups');
      final remoteRows = await _supabase.from('groups').select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            final localMap = entry.value as Map<String, Object?>;
            final localModel = GroupModel.fromMap(localMap);
            await _supabase.from('groups').insert(_toRemoteMap(localModel));
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            final remote = entry.value as Map<String, Object?>;
            final mapped = GroupModel.fromMap({
              'id': remote['id'],
              'name': remote['name'] ?? '',
              'size': null,
              'discipline_ids': '[]',
              'curator': null,
              'course': remote['course'],
              'specialty': null,
              'curator_teacher_id': remote['curator_teacher_id'],
              'student_count': remote['student_count'],
              'department_id': remote['department_id'],
              'notes': remote['notes'],
            });
            await db.insert('groups', mapped.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
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
}

