import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'discipline_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisciplinesRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  Future<List<Discipline>> getAllDisciplines({
    String? search,
    String? orderBy = 'name ASC',
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('(name LIKE ?)');
      final q = '%${search.trim()}%';
      args.add(q);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('SELECT * FROM disciplines $whereSql ORDER BY $orderBy', args);
    return rows.map((e) => Discipline.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(Discipline m) async {
    final db = await _db;
    return await db.insert('disciplines', m.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(Discipline m) async {
    if (m.id == null) return 0;
    final db = await _db;
    return await db.update('disciplines', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    return await db.delete('disciplines', where: 'id = ?', whereArgs: [id]);
  }

  // Отправка в Supabase
  Future<int?> _insertRemote(Discipline m) async {
    final res = await _supabase.from('disciplines').insert(m.toMap()).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка в Supabase
  Future<bool> _updateRemote(Discipline m) async {
    if (m.id == null) return false;
    await _supabase.from('disciplines').update(m.toMap()).eq('id', m.id!);
    return true;
  }

  // Отправка в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from('disciplines').delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertDiscipline(Discipline d) async {
    // Сохранение локально
    final localId = await _insertLocal(d);
    // Отправка в Supabase
    try {
      final remoteId = await _insertRemote(d);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update('disciplines', {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateDiscipline(Discipline d) async {
    // Сохранение локально
    final updated = await _updateLocal(d);
    // Отправка в Supabase
    try {
      await _updateRemote(d);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteDiscipline(int id) async {
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
  Future<void> syncDisciplines() async {
    try {
      final db = await _db;
      final localRows = await db.query('disciplines');
      final remoteRows = await _supabase.from('disciplines').select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from('disciplines').insert(entry.value);
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert('disciplines', entry.value);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM disciplines')) ?? 0;
    if (count > 0) return;
    final samples = <Discipline>[
      Discipline(name: 'Математика', lessonTypeId: null, semester: '1'),
      Discipline(name: 'Информатика', lessonTypeId: null, semester: '1'),
      Discipline(name: 'Физика', lessonTypeId: null, semester: '2'),
    ];
    for (final s in samples) {
      await _insertLocal(s);
    }
  }

  // Возвращает карту: groupId -> список названий дисциплин для группы
  Future<Map<int, List<String>>> disciplineNamesByGroup(List<int> groupIds) async {
    if (groupIds.isEmpty) return <int, List<String>>{};
    final db = await _db;
    final placeholders = List.filled(groupIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT gd.group_id AS gid, d.name AS dname '
      'FROM group_disciplines gd '
      'JOIN disciplines d ON d.id = gd.discipline_id '
      'WHERE gd.group_id IN ($placeholders) '
      'ORDER BY d.name ASC',
      groupIds,
    );
    final result = <int, List<String>>{};
    for (final r in rows) {
      final gid = r['gid'] as int;
      final name = r['dname'] as String;
      result.putIfAbsent(gid, () => <String>[]).add(name);
    }
    return result;
  }

  // === Teacher links (many-to-many via teacher_disciplines) ===
  Future<List<int>> getTeacherIdsByDiscipline(int disciplineId) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT teacher_id FROM teacher_disciplines WHERE discipline_id = ?', [disciplineId]);
    return rows.map((e) => (e['teacher_id'] as int)).toList();
  }

  Future<void> setDisciplineTeachers(int disciplineId, List<int> teacherIds) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('teacher_disciplines', where: 'discipline_id = ?', whereArgs: [disciplineId]);
    for (final tid in teacherIds.toSet()) {
      batch.insert('teacher_disciplines', {'teacher_id': tid, 'discipline_id': disciplineId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    try {
      await _supabase.from('teacher_disciplines').delete().eq('discipline_id', disciplineId);
      if (teacherIds.isNotEmpty) {
        final payload = teacherIds.toSet().map((t) => {'teacher_id': t, 'discipline_id': disciplineId}).toList();
        await _supabase.from('teacher_disciplines').insert(payload);
      }
    } catch (_) {}
  }
}


