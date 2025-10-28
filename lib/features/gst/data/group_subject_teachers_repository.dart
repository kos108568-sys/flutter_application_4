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
    final res = await _supabase.from(_table).insert(m.toMap()).select('id').maybeSingle();
    return res?['id'] as int?;
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
    try {
      final remoteId = await _insertRemote(m);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateGST(GroupSubjectTeacher m) async {
    // Сохранение локально
    final updated = await _updateLocal(m);
    // Отправка данных в Supabase
    try {
      await _updateRemote(m);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteGST(int id) async {
    // Сохранение локально
    final deleted = await _deleteLocal(id);
    // Отправка данных в Supabase
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncGST() async {
    try {
      final db = await _db;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка данных в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert(entry.value);
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(_table, entry.value, conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }
}


