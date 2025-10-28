import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'lesson_rule_model.dart';

class LessonRulesRepository {
  final _table = 'lesson_rules';

  Database? _db;
  Future<Database> get _database async => _db ??= await DBHelper.instance.database;

  final _supabase = Supabase.instance.client;

  // Получение всех записей из SQLite
  Future<List<LessonRule>> getAllRules() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'id ASC');
    return rows.map((e) => LessonRule.fromMap(e)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(LessonRule r) async {
    final db = await _database;
    return await db.insert(_table, r.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(LessonRule r) async {
    final db = await _database;
    return await db.update(_table, r.toMap(), where: 'id = ?', whereArgs: [r.id!]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Отправка в Supabase
  Future<int?> _insertRemote(LessonRule r) async {
    final res = await _supabase.from(_table).insert(r.toSupabaseMap()).select('id').maybeSingle();
    return (res?['id'] as int?);
  }

  // Отправка в Supabase
  Future<bool> _updateRemote(LessonRule r) async {
    if (r.id == null) return false;
    await _supabase.from(_table).update(r.toSupabaseMap()).eq('id', r.id!);
    return true;
  }

  // Отправка в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertRule(LessonRule r) async {
    // Работа офлайн: сначала локально
    final localId = await _insertLocal(r);
    // Отправка в Supabase
    try {
      final remoteId = await _insertRemote(r);
      if (remoteId != null && remoteId != localId) {
        // выравнивание id: перезапишем локальную запись с новым id
        final db = await _database;
        await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateRule(LessonRule r) async {
    final updated = await _updateLocal(r);
    try {
      await _updateRemote(r);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteRule(int id) async {
    final deleted = await _deleteLocal(id);
    try {
      await _deleteRemote(id);
    } catch (_) {
      // Работа офлайн
    }
    return deleted;
  }

  // Синхронизация при запуске
  Future<void> syncRules() async {
    try {
      final db = await _database;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → отправить
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            await _supabase.from(_table).insert({
              'id': entry.value['id'],
              'lesson_type_id': entry.value['lesson_type_id'],
              'audience_type_id': entry.value['audience_type_id'],
              'allowed': (entry.value['allowed'] ?? 1) == 1,
            });
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(_table, {
              'id': entry.value['id'],
              'lesson_type_id': entry.value['lesson_type_id'],
              'audience_type_id': entry.value['audience_type_id'],
              'allowed': (entry.value['allowed'] == true) ? 1 : 0,
            });
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн: пропускаем до следующего раза
    }
  }
}


