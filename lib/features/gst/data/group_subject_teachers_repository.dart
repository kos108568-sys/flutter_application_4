import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'group_subject_teacher_model.dart';
import '../../teachers/data/teacher_model.dart';

class GroupSubjectTeachersRepository {
  final _table = 'group_subject_teachers';
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  // Получить все
  Future<List<GroupSubjectTeacher>> getAllGST() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map((e) => GroupSubjectTeacher.fromMap(e)).toList();
  }

  // Получить по группе
  Future<List<GroupSubjectTeacher>> getByGroup(int groupId) async {
    final db = await _db;
    final rows = await db.query(_table, where: 'group_id = ?', whereArgs: [groupId]);
    return rows.map((e) => GroupSubjectTeacher.fromMap(e)).toList();
  }

  // Получить по преподавателю
  Future<List<GroupSubjectTeacher>> getByTeacher(int teacherId) async {
    final db = await _db;
    final rows = await db.query(_table, where: 'teacher_id = ?', whereArgs: [teacherId]);
    return rows.map((e) => GroupSubjectTeacher.fromMap(e)).toList();
  }

  // Получить список преподавателей, ведущих указанный предмет (по локальной базе)
  Future<List<Teacher>> teachersByDiscipline(int disciplineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT DISTINCT t.* FROM teachers t '
      'JOIN group_subject_teachers gst ON gst.teacher_id = t.id '
      'WHERE gst.discipline_id = ? ORDER BY t.full_name ASC',
      [disciplineId],
    );
    return rows.map((e) => Teacher.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(GroupSubjectTeacher m) async {
    final db = await _db;
    return await db.insert(_table, m.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Сохранение локально
  Future<int> _updateLocal(GroupSubjectTeacher m) async {
    if (m.id == null) return 0;
    final db = await _db;
    return await db.update(_table, m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(GroupSubjectTeacher m) async {
    try {
      final payload = Map<String, dynamic>.from(m.toMap())..remove('id');
      final res = await _supabase.from(_table).insert(payload).select('id').maybeSingle();
      return res?['id'] as int?;
    } catch (e) {
      return null;
    }
  }

  // Отправка данных в Supabase
  Future<bool> _updateRemote(GroupSubjectTeacher m) async {
    if (m.id == null) return false;
    await _supabase.from(_table).update(m.toMap()).eq('id', m.id!);
    return true;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertGST(GroupSubjectTeacher m) async {
    // Сохранение локально
    final localId = await _insertLocal(m);
    // Отправка данных в Supabase
    final remoteId = await _insertRemote(m);
    if (remoteId != null && remoteId != localId) {
      final db = await _db;
      await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
      return remoteId;
    }
    return localId;
  }

  // Batch insert GST rows for a group: insert local, then remote, then map remote IDs back
  Future<void> insertManyForGroup(int groupId, List<GroupSubjectTeacher> items) async {
    if (items.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final m in items) {
      final row = m.toMap();
      row.remove('id');
      batch.insert(_table, row, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);

    try {
      final payload = items
          .map((m) => (Map<String, dynamic>.from(m.toMap())..remove('id')))
          .toList();
      final inserted = await _supabase
          .from(_table)
          .insert(payload)
          .select('id, group_id, teacher_id, discipline_id, subgroup');
      final list = (inserted as List).cast<Map<String, dynamic>>();
      for (final r in list) {
        final rid = r['id'] as int?;
        if (rid == null) continue;
        // Update local PK to remote id by natural key (group, teacher, discipline)
        await db.update(
          _table,
          {'id': rid},
          where: 'group_id = ? AND teacher_id = ? AND discipline_id = ? AND ifnull(subgroup, "all") = ifnull(?, "all")',
          whereArgs: [r['group_id'], r['teacher_id'], r['discipline_id'], r['subgroup']],
        );
      }
    } catch (_) {
      // best-effort; syncGST will reconcile later
    }
  }
  // Sync local <-> remote GST rows (best-effort)
  Future<void> syncGST() async {
    try {
      final db = await _db;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) (r['id'] as int?): r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) (r['id'] as int?): r};

      // Push: local rows missing in remote
      for (final entry in localById.entries) {
        final id = entry.key;
        if (id == null || remoteById.containsKey(id)) continue;
        try {
          final payload = Map<String, dynamic>.from(entry.value)..remove('id');
          await _supabase.from(_table).insert(payload);
        } catch (_) {}
      }

      // Pull: remote rows missing locally
      for (final entry in remoteById.entries) {
        final id = entry.key;
        if (id == null || localById.containsKey(id)) continue;
        try {
          await db.insert(_table, entry.value, conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (_) {}
      }
    } catch (_) {
      // ignore sync errors
    }
  }

  // Replace all assignments for a group (delete then insert). Best-effort sync to Supabase.
  Future<void> replaceForGroup(int groupId, List<GroupSubjectTeacher> items) async {
    final db = await _db;
    await db.delete(_table, where: 'group_id = ?', whereArgs: [groupId]);
    try {
      await _supabase.from(_table).delete().eq('group_id', groupId);
    } catch (_) {}
    // ensure groupId set on each item
    final normalized = items
        .map((m) => GroupSubjectTeacher(
              id: m.id,
              groupId: groupId,
              teacherId: m.teacherId,
              disciplineId: m.disciplineId,
              totalHours: m.totalHours,
              startDate: m.startDate,
              endDate: m.endDate,
              notes: m.notes,
              subgroup: m.subgroup ?? 'all',
            ))
        .toList();
    await insertManyForGroup(groupId, normalized);
  }
}

