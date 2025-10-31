import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/db/db_helper.dart';
import 'audience_model.dart';

class AudiencesRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  Future<List<Audience>> getAllAudiences({String? search, String? orderBy}) async {
    final db = await _db;
    String where = '';
    List<Object?> whereArgs = [];
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE name LIKE ?';
      final q = '%${search.trim()}%';
      whereArgs = [q];
    }
    final order = orderBy ?? 'id DESC';
    final maps = await db.rawQuery('SELECT * FROM audiences $where ORDER BY $order', whereArgs);
    return maps.map((m) => Audience.fromMap(m)).toList();
  }

  Future<List<Audience>> getRecent({int limit = 5}) async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT * FROM audiences ORDER BY id DESC LIMIT ?', [limit]);
    return maps.map((m) => Audience.fromMap(m)).toList();
  }

  // Сохранение локально
  Future<int> _insertLocal(Audience a) async {
    final db = await _db;
    return await db.insert('audiences', a.toMap());
  }

  // Сохранение локально
  Future<int> _updateLocal(Audience a) async {
    if (a.id == null) return 0;
    final db = await _db;
    return await db.update('audiences', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  // Сохранение локально
  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    return await db.delete('audiences', where: 'id = ?', whereArgs: [id]);
  }

  // Отправка данных в Supabase
  Future<int?> _insertRemote(Audience a) async {
    final payload = Map<String, dynamic>.from(a.toMap())..remove('id');
    final res = await _supabase.from('audiences').insert(payload).select('id').maybeSingle();
    return res?['id'] as int?;
  }

  // Отправка данных в Supabase
  Future<bool> _updateRemote(Audience a) async {
    if (a.id == null) return false;
    await _supabase.from('audiences').update(a.toMap()).eq('id', a.id!);
    return true;
  }

  // Отправка данных в Supabase
  Future<bool> _deleteRemote(int id) async {
    await _supabase.from('audiences').delete().eq('id', id);
    return true;
  }

  // Публичные методы
  Future<int> insertAudience(Audience a) async {
    // Сохранение локально
    final localId = await _insertLocal(a);
    // Отправка данных в Supabase
    try {
      final remoteId = await _insertRemote(a);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update('audiences', {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // Работа офлайн
    }
    return localId;
  }

  Future<int> updateAudience(Audience a) async {
    // Сохранение локально
    final updated = await _updateLocal(a);
    // Отправка данных в Supabase
    try {
      await _updateRemote(a);
    } catch (_) {
      // Работа офлайн
    }
    return updated;
  }

  Future<int> deleteAudience(int id) async {
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
  Future<void> syncAudiences() async {
    try {
      final db = await _db;
      final localRows = await db.query('audiences');
      final remoteRows = await _supabase.from('audiences').select();

      final localById = {for (final r in localRows) r['id'] as int: r};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final r in remoteList) r['id'] as int: r};

      // Локальные, которых нет в Supabase → Отправка данных в Supabase
      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            final local = entry.value as Map<String, Object?>;
            final payload = {
              'name': local['name'],
              'capacity': local['capacity'],
              'audience_type_id': local['audience_type_id'],
              'building_id': local['building_id'],
              'responsible_teacher_id': local['responsible_teacher_id'],
              'notes': local['notes'],
            };
            await _supabase.from('audiences').insert(payload);
          } catch (_) {}
        }
      }

      // Удаленные, которых нет локально → Добавить локально
      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            final r = entry.value as Map<String, Object?>;
            final mapped = Audience.fromMap({
              'id': r['id'],
              'name': r['name'] ?? '',
              'capacity': r['capacity'],
              'audience_type_id': r['audience_type_id'],
              'building_id': r['building_id'],
              'responsible_teacher_id': r['responsible_teacher_id'],
              'notes': r['notes'],
            });
            await db.insert('audiences', mapped.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Работа офлайн
    }
  }

  Future<void> seedIfEmpty() async {    // No-op: do not preseed; let UI show empty state.\n  }
  }
}

