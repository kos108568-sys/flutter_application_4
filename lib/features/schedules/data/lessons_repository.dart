import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'lesson_model.dart';

class LessonsRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  SupabaseClient? get _supabaseOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<int> insert(LessonModel lesson) async {
    final db = await _db;
    return await db.insert('lessons', lesson.toMap()..remove('id'));
  }

  Future<int> update(LessonModel lesson) async {
    if (lesson.id == null) return 0;
    final db = await _db;
    return await db.update('lessons', lesson.toMap()..remove('id'), where: 'id = ?', whereArgs: [lesson.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LessonModel>> getAll({DateTime? weekStart, int? groupId}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];
    if (weekStart != null) {
      where = 'WHERE date >= ? AND date < ?';
      final weekEnd = weekStart.add(const Duration(days: 7));
      args = [weekStart.toIso8601String(), weekEnd.toIso8601String()];
    }
    if (groupId != null) {
      where += where.isEmpty ? 'WHERE group_id = ?' : ' AND group_id = ?';
      args.add(groupId);
    }
    final rows = await db.rawQuery('SELECT * FROM lessons $where ORDER BY date, pair_no', args);
    return rows.map((e) => LessonModel.fromMap(e)).toList();
  }

  Future<void> generateDemoData() async {
    final db = await _db;
    await db.delete('lessons');

    final disciplines = await db.rawQuery('SELECT id, name, teacher FROM disciplines');
    final teachers = await db.rawQuery('SELECT id, full_name FROM teachers');
    final audiences = await db.rawQuery('SELECT id, name FROM audiences');
    final groups = await db.rawQuery('SELECT id, name FROM groups');

    if (disciplines.isEmpty || teachers.isEmpty || audiences.isEmpty || groups.isEmpty) {
      return;
    }

    final lessonTypes = ['Лекция', 'Практика', 'Лабораторная', 'Семинар'];
    final typesForColor = lessonTypes;
    final subgroups = ['1 подгруппа', '2 подгруппа'];

    final baseDate = DateTime.now();
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));

    for (int week = 0; week < 2; week++) {
      final weekStart = monday.add(Duration(days: week * 7));
      for (int day = 0; day < 6; day++) {
        final date = weekStart.add(Duration(days: day));
        for (int pair = 0; pair < 5; pair++) {
          if ((day + pair) % 3 != 0) {
            final lesson = LessonModel(
              disciplineId: (disciplines[day % disciplines.length]['id'] as int),
              type: lessonTypes[pair % lessonTypes.length],
              teacherId: (teachers[day % teachers.length]['id'] as int),
              audienceId: (audiences[day % audiences.length]['id'] as int),
              groupId: (groups[0]['id'] as int),
              pairNo: pair,
              dayOfWeek: day,
              date: date,
              subgroup: subgroups[pair % subgroups.length],
            );
            await insert(lesson);
          }
        }
      }
    }
  }

  // Remote helpers (best-effort)
  Future<int?> _insertRemote(LessonModel m) async {
    final sb = _supabaseOrNull;
    if (sb == null) return null;
    final payload = Map<String, dynamic>.from(m.toMap())..remove('id');
    // Supabase column types: date is timestamptz, accept ISO string
    final res = await sb.from('lessons').insert(payload).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  Future<bool> _updateRemote(LessonModel m) async {
    if (m.id == null) return false;
    final sb = _supabaseOrNull;
    if (sb == null) return false;
    final payload = Map<String, dynamic>.from(m.toMap())..remove('id');
    await sb.from('lessons').update(payload).eq('id', m.id!);
    return true;
  }

  Future<bool> _deleteRemote(int id) async {
    final sb = _supabaseOrNull;
    if (sb == null) return false;
    await sb.from('lessons').delete().eq('id', id);
    return true;
  }

  // With-sync variants
  Future<int> insertWithSync(LessonModel m) async {
    final id = await insert(m);
    try {
      final remoteId = await _insertRemote(m);
      if (remoteId != null && remoteId != id) {
        final db = await _db;
        await db.update('lessons', {'id': remoteId}, where: 'id = ?', whereArgs: [id]);
        return remoteId;
      }
    } catch (_) {}
    return id;
  }

  Future<int> updateWithSync(LessonModel m) async {
    final res = await update(m);
    try { await _updateRemote(m); } catch (_) {}
    return res;
  }

  Future<int> deleteWithSync(int id) async {
    final res = await delete(id);
    try { await _deleteRemote(id); } catch (_) {}
    return res;
  }

  // Simple two-way sync (by id)
  Future<void> syncLessons() async {
    final sb = _supabaseOrNull;
    if (sb == null) return;
    try {
      final db = await _db;
      final localRows = await db.query('lessons');
      final remoteRows = await sb.from('lessons').select();

      final localById = {for (final r in localRows) (r['id'] as int?): r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) (r['id'] as int?): r};

      // Push locals missing remotely
      for (final entry in localById.entries) {
        final id = entry.key;
        if (id == null || remoteById.containsKey(id)) continue;
        try {
          final payload = Map<String, dynamic>.from(entry.value)..remove('id');
          await sb.from('lessons').insert(payload);
        } catch (_) {}
      }

      // Pull remotes missing locally
      for (final entry in remoteById.entries) {
        final id = entry.key;
        if (id == null || localById.containsKey(id)) continue;
        try {
          await db.insert('lessons', entry.value, conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
