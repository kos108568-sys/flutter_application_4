import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import '../../groups/data/group_model.dart';
import 'teacher_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeachersRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  SupabaseClient? get _supabaseOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Сохранение локально
  Future<int> insertTeacher(Teacher t) async {
    final db = await _db;
    final id = await db.insert('teachers', t.toMap());
    return id;
  }

  // Сохранение локально
  Future<int> updateTeacher(Teacher t) async {
    if (t.id == null) return 0;
    final db = await _db;
    final res = await db.update('teachers', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    return res;
  }

  // Сохранение локально
  Future<int> deleteTeacher(int id) async {
    final db = await _db;
    return db.delete('teachers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Teacher>> getAllTeachers({String? search, String orderBy = 'full_name ASC'}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE full_name LIKE ?';
      args = ['%${search.trim()}%'];
    }
    final rows = await db.rawQuery('SELECT * FROM teachers $where ORDER BY $orderBy', args);
    return rows.map((r) => Teacher.fromMap(r)).toList();
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teachers')) ?? 0;
    if (count > 0) return;
    await db.insert('teachers', {'full_name': 'Primer Prepodavatel'});
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(Teacher t) async {
    final sb = _supabaseOrNull;
    if (sb == null) return null;
    final res = await sb.from('teachers').insert(t.toSupabaseMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка данных в Supabase
  Future<bool> _updateRemote(Teacher t) async {
    if (t.id == null) return false;
    final sb = _supabaseOrNull;
    if (sb == null) return false;
    await sb.from('teachers').update(t.toSupabaseMap()).eq('id', t.id!);
    return true;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    final sb = _supabaseOrNull;
    if (sb == null) return false;
    await sb.from('teachers').delete().eq('id', id);
    return true;
  }

  // Публичные методы с синхронизацией
  Future<int> insertTeacherWithSync(Teacher t) async {
    // Сохранение локально
    final localId = await insertTeacher(t);
    // Отправка данных в Supabase
    try {
      final remoteId = await _insertRemote(t);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update('teachers', {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateTeacherWithSync(Teacher t) async {
    // Сохранение локально
    final updated = await updateTeacher(t);
    // Отправка данных в Supabase
    try {
      await _updateRemote(t);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteTeacherWithSync(int id) async {
    // Сохранение локально
    final deleted = await deleteTeacher(id);
    // Отправка данных в Supabase
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncTeachers() async {
    try {
      final db = await _db;
      final localRows = await db.query('teachers');
      final sb = _supabaseOrNull;
      if (sb == null) return; // нет удалённого клиента — офлайн
      final remoteRows = await sb.from('teachers').select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка данных в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            final created = await sb.from('teachers').insert(entry.value).select('id').maybeSingle();
            final newId = created?['id'] as int?;
            if (newId != null && newId != entry.key) {
              await db.update('teachers', {'id': newId}, where: 'id = ?', whereArgs: [entry.key]);
            }
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавление локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert('teachers', entry.value, conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }

  // Helpers to populate selections
  Future<List<GroupModel>> groups() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM groups ORDER BY name ASC');
    return rows.map((e) => GroupModel.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> disciplines() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM disciplines ORDER BY name ASC');
    return rows;
  }

  // Teacher-Discipline linking helpers
  Future<List<int>> getTeacherDisciplineIds(int teacherId) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT discipline_id FROM teacher_disciplines WHERE teacher_id = ?', [teacherId]);
    return rows.map((e) => (e['discipline_id'] as int)).toList();
  }

  Future<void> setTeacherDisciplines(int teacherId, List<int> disciplineIds) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('teacher_disciplines', where: 'teacher_id = ?', whereArgs: [teacherId]);
    for (final did in disciplineIds.toSet()) {
      batch.insert('teacher_disciplines', {'teacher_id': teacherId, 'discipline_id': did}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    // Push to Supabase (best-effort)
    final sb = _supabaseOrNull;
    if (sb != null) {
      try {
        await sb.from('teacher_disciplines').delete().eq('teacher_id', teacherId);
        if (disciplineIds.isNotEmpty) {
          final payload = disciplineIds.toSet().map((d) => {'teacher_id': teacherId, 'discipline_id': d}).toList();
          await sb.from('teacher_disciplines').insert(payload);
        }
      } catch (_) {}
    }
  }
}



