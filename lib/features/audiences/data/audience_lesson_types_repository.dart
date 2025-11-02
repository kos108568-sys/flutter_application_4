import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/db_helper.dart';
import 'audience_lesson_type_model.dart';

class AudienceLessonTypesRepository {
  static const _table = 'audience_lesson_types';

  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;

  Future<List<AudienceLessonType>> getAll() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'audience_id ASC, lesson_type_id ASC');
    return rows.map((e) => AudienceLessonType.fromMap(e)).toList();
  }

  Future<List<AudienceLessonType>> getByAudience(int audienceId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'audience_id = ?',
      whereArgs: [audienceId],
      orderBy: 'lesson_type_id ASC',
    );
    return rows.map((e) => AudienceLessonType.fromMap(e)).toList();
  }

  Future<int> _insertLocal(AudienceLessonType value) async {
    final db = await _db;
    return db.insert(
      _table,
      value.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> _deleteLocal(int id) async {
    final db = await _db;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByAudience(int audienceId) async {
    final db = await _db;
    await db.delete(_table, where: 'audience_id = ?', whereArgs: [audienceId]);
  }

  Future<void> replaceLocal(int audienceId, List<int> lessonTypeIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(_table, where: 'audience_id = ?', whereArgs: [audienceId]);
      for (final typeId in lessonTypeIds) {
        await txn.insert(
          _table,
          {
            'audience_id': audienceId,
            'lesson_type_id': typeId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> replaceRemote(int audienceId, List<int> lessonTypeIds) async {
    await _supabase.from(_table).delete().eq('audience_id', audienceId);
    if (lessonTypeIds.isEmpty) return;
    final payload = lessonTypeIds
        .map((typeId) => {
              'audience_id': audienceId,
              'lesson_type_id': typeId,
            })
        .toList();
    await _supabase.from(_table).insert(payload);
  }

  Future<int?> _insertRemote(AudienceLessonType value) async {
    final payload = Map<String, Object?>.from(value.toMap())..remove('id');
    final response = await _supabase.from(_table).insert(payload).select('id').maybeSingle();
    return response?['id'] as int?;
  }

  Future<void> _deleteRemote(int id) async {
    await _supabase.from(_table).delete().eq('id', id);
  }

  Future<int> insert(AudienceLessonType value) async {
    final localId = await _insertLocal(value);
    try {
      final remoteId = await _insertRemote(value);
      if (remoteId != null && remoteId != localId) {
        final db = await _db;
        await db.update(_table, {'id': remoteId}, where: 'id = ?', whereArgs: [localId]);
        return remoteId;
      }
    } catch (_) {
      // offline mode
    }
    return localId;
  }

  Future<int> delete(int id) async {
    final deleted = await _deleteLocal(id);
    try {
      await _deleteRemote(id);
    } catch (_) {
      // offline mode
    }
    return deleted;
  }

  Future<void> syncAudienceLessonTypes() async {
    try {
      final db = await _db;
      final localRows = await db.query(_table);
      final remoteRows = await _supabase.from(_table).select();

      final localById = {for (final row in localRows) row['id'] as int: row};
      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final row in remoteList) row['id'] as int: row};

      for (final entry in localById.entries) {
        if (!remoteById.containsKey(entry.key)) {
          try {
            final payload = Map<String, Object?>.from(entry.value)..remove('id');
            await _supabase.from(_table).insert(payload);
          } catch (_) {}
        }
      }

      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            await db.insert(
              _table,
              entry.value,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      // offline mode
    }
  }
}
