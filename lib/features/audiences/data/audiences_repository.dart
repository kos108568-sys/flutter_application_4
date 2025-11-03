import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/db_helper.dart';
import 'audience_lesson_types_repository.dart';
import 'audience_model.dart';

class AudiencesRepository {
  Future<Database> get _db async => DBHelper.instance.database;
  final _supabase = Supabase.instance.client;
  final AudienceLessonTypesRepository _lessonTypesRepo = AudienceLessonTypesRepository();

  Future<List<Audience>> getAllAudiences({String? search, String? orderBy}) async {
    final db = await _db;
    final buffer = StringBuffer('SELECT * FROM audiences');
    final whereArgs = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      buffer.write(' WHERE name LIKE ?');
      whereArgs.add('%${search.trim()}%');
    }
    final order = orderBy ?? 'id DESC';
    buffer.write(' ORDER BY $order');

    final rows = await db.rawQuery(buffer.toString(), whereArgs);
    final lessonMap = await _loadLessonTypesForRows(db, rows);

    return rows
        .map(
          (row) => Audience.fromMap(
            row,
            lessonTypeIds: lessonMap[(row['id'] as num?)?.toInt()] ?? const [],
          ),
        )
        .toList();
  }

  Future<List<Audience>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM audiences ORDER BY id DESC LIMIT ?',
      [limit],
    );
    final lessonMap = await _loadLessonTypesForRows(db, rows);
    return rows
        .map(
          (row) => Audience.fromMap(
            row,
            lessonTypeIds: lessonMap[(row['id'] as num?)?.toInt()] ?? const [],
          ),
        )
        .toList();
  }

  Future<Map<int, List<int>>> _loadLessonTypesForRows(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final audienceIds = rows
        .map((row) => (row['id'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    if (audienceIds.isEmpty) {
      return {};
    }

    final placeholders = List.filled(audienceIds.length, '?').join(',');
    final joinRows = await db.rawQuery(
      'SELECT audience_id, lesson_type_id FROM audience_lesson_types WHERE audience_id IN ($placeholders)',
      audienceIds,
    );

    final map = <int, List<int>>{};
    for (final row in joinRows) {
      final audienceId = (row['audience_id'] as num).toInt();
      final lessonTypeId = (row['lesson_type_id'] as num).toInt();
      map.putIfAbsent(audienceId, () => []).add(lessonTypeId);
    }
    return map;
  }

  Future<int> insertAudience(Audience audience) async {
    final db = await _db;
    final map = Map<String, Object?>.from(audience.toMap())..remove('id');
    final localId = await db.insert('audiences', map);

    await _lessonTypesRepo.replaceLocal(localId, audience.lessonTypeIds);

    try {
      final remoteId = await _insertRemote(
        audience.copyWith(id: localId),
        lessonTypeIds: audience.lessonTypeIds,
      );
      if (remoteId != null && remoteId != localId) {
        await db.transaction((txn) async {
          await txn.update(
            'audiences',
            {
              'id': remoteId,
              'remote_id': remoteId,
            },
            where: 'id = ?',
            whereArgs: [localId],
          );
          await txn.update(
            'audience_lesson_types',
            {'audience_id': remoteId},
            where: 'audience_id = ?',
            whereArgs: [localId],
          );
        });
        return remoteId;
      } else if (remoteId != null) {
        await db.update(
          'audiences',
          {'remote_id': remoteId},
          where: 'id = ?',
          whereArgs: [localId],
        );
      }
    } catch (_) {
      // offline mode
    }

    return localId;
  }

  Future<int> updateAudience(Audience audience) async {
    if (audience.id == null) return 0;
    final db = await _db;
    final updated = await db.update(
      'audiences',
      audience.toMap(),
      where: 'id = ?',
      whereArgs: [audience.id],
    );

    await _lessonTypesRepo.replaceLocal(audience.id!, audience.lessonTypeIds);

    try {
      await _updateRemote(audience);
    } catch (_) {
      // offline mode
    }

    return updated;
  }

  Future<int> deleteAudience(int id) async {
    final db = await _db;
    await _lessonTypesRepo.deleteByAudience(id);
    final deleted = await db.delete('audiences', where: 'id = ?', whereArgs: [id]);

    try {
      await _deleteRemote(id);
    } catch (_) {
      // offline mode
    }

    return deleted;
  }

  Future<int?> _insertRemote(
    Audience audience, {
    required List<int> lessonTypeIds,
  }) async {
    final payload = Map<String, Object?>.from(audience.toMap())..remove('id');
    final res = await _supabase.from('audiences').insert(payload).select('id').maybeSingle();
    final remoteId = res?['id'] as int?;
    if (remoteId != null) {
      try {
        await _lessonTypesRepo.replaceRemote(remoteId, lessonTypeIds);
      } catch (_) {}
    }
    return remoteId;
  }

  Future<void> _updateRemote(Audience audience) async {
    if (audience.id == null) return;
    await _supabase.from('audiences').update(audience.toMap()).eq('id', audience.id!);
    try {
      await _lessonTypesRepo.replaceRemote(audience.id!, audience.lessonTypeIds);
    } catch (_) {}
  }

  Future<void> _deleteRemote(int id) async {
    await _supabase.from('audiences').delete().eq('id', id);
  }

  static Future<void>? _syncInProgress;

  Future<void> syncAudiences() {
    final inFlight = _syncInProgress;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> future;
    future = _syncAudiencesInternal().whenComplete(() {
      if (identical(_syncInProgress, future)) {
        _syncInProgress = null;
      }
    });
    _syncInProgress = future;
    return future;
  }

  Future<void> _syncAudiencesInternal() async {
    try {
      final db = await _db;
      final localRows = await db.query('audiences');
      final remoteRows = await _supabase.from('audiences').select();

      final localById = <int, Map<String, Object?>>{};
      for (final row in localRows) {
        final id = row['id'] as int?;
        if (id != null) {
          localById[id] = row;
        }
      }

      final remoteList = (remoteRows as List).cast<Map<String, dynamic>>();
      final remoteById = {for (final row in remoteList) row['id'] as int: row};

      for (final entry in localById.entries) {
        final local = entry.value;
        final localId = entry.key;
        final mappedRemoteId = (local['remote_id'] as num?)?.toInt();

        // If we already know the remote id and it exists remotely, just reconcile ids locally and skip insert
        if (mappedRemoteId != null && remoteById.containsKey(mappedRemoteId)) {
          if (mappedRemoteId != localId) {
            try {
              await db.transaction((txn) async {
                await txn.delete(
                  'audience_lesson_types',
                  where: 'audience_id = ?',
                  whereArgs: [mappedRemoteId],
                );
                await txn.delete(
                  'audiences',
                  where: 'id = ?',
                  whereArgs: [mappedRemoteId],
                );
                await txn.update(
                  'audiences',
                  {
                    'id': mappedRemoteId,
                    'remote_id': mappedRemoteId,
                  },
                  where: 'id = ?',
                  whereArgs: [localId],
                );
                await txn.update(
                  'audience_lesson_types',
                  {'audience_id': mappedRemoteId},
                  where: 'audience_id = ?',
                  whereArgs: [localId],
                );
              });
            } catch (_) {}
          }
          continue;
        }

        // If neither local id nor mapped remote id exist remotely, create remote and reconcile
        if (!remoteById.containsKey(localId)) {
          try {
            final payload = {
              'name': local['name'],
              'type': local['type'],
              'capacity': local['capacity'],
              'building_id': local['building_id'],
              'teacher_id': local['teacher_id'],
              'notes': local['notes'],
            };
            final res = await _supabase
                .from('audiences')
                .insert(payload)
                .select('id')
                .maybeSingle();
            final remoteId = res?['id'] as int?;
            if (remoteId != null && remoteId != localId) {
              await db.transaction((txn) async {
                await txn.delete(
                  'audience_lesson_types',
                  where: 'audience_id = ?',
                  whereArgs: [remoteId],
                );
                await txn.delete(
                  'audiences',
                  where: 'id = ?',
                  whereArgs: [remoteId],
                );
                await txn.update(
                  'audiences',
                  {
                    'id': remoteId,
                    'remote_id': remoteId,
                  },
                  where: 'id = ?',
                  whereArgs: [localId],
                );
                await txn.update(
                  'audience_lesson_types',
                  {'audience_id': remoteId},
                  where: 'audience_id = ?',
                  whereArgs: [localId],
                );
              });

              // Also mirror lesson types to remote for this audience to avoid empty types on duplicates
              try {
                final pairs = await _lessonTypesRepo.getByAudience(remoteId);
                final typeIds = pairs.map((e) => e.lessonTypeId).toList();
                await _lessonTypesRepo.replaceRemote(remoteId, typeIds);
              } catch (_) {}

            } else if (remoteId != null) {
              await db.update(
                'audiences',
                {'remote_id': remoteId},
                where: 'id = ?',
                whereArgs: [localId],
              );

              // Ensure lesson types are synced remotely when ids match
              try {
                final pairs = await _lessonTypesRepo.getByAudience(localId);
                final typeIds = pairs.map((e) => e.lessonTypeId).toList();
                await _lessonTypesRepo.replaceRemote(remoteId, typeIds);
              } catch (_) {}
            }
          } catch (_) {}
        }
      }

      for (final entry in remoteById.entries) {
        if (!localById.containsKey(entry.key)) {
          try {
            final remote = entry.value;
            final mapped = Audience.fromMap(
              {
                'id': remote['id'],
                'name': remote['name'] ?? '',
                'type': remote['type'],
                'capacity': remote['capacity'],
                'building_id': remote['building_id'],
                'teacher_id': remote['teacher_id'],
                'notes': remote['notes'],
              },
            );
            await db.insert(
              'audiences',
              {
                ...mapped.toMap(),
                'remote_id': remote['id'],
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          } catch (_) {}
        } else {
          try {
            await db.update(
              'audiences',
              {'remote_id': entry.key},
              where: 'id = ? AND (remote_id IS NULL OR remote_id != ?)',
              whereArgs: [entry.key, entry.key],
            );
          } catch (_) {}
        }
      }

      await _lessonTypesRepo.syncAudienceLessonTypes();
    } catch (_) {
      // offline mode
    }
  }

  Future<void> seedIfEmpty() async {
    // no default seed for audiences; method retained for API compatibility
  }
}
