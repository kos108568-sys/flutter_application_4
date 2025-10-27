import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/audiences/data/audiences_repository.dart';
import '../../features/audiences/data/audiences_remote_repository.dart';
import '../../features/groups/data/groups_remote_repository.dart';
import '../../features/teachers/data/teachers_remote_repository.dart';
import '../../features/disciplines/data/disciplines_remote_repository.dart';
import '../../features/groups/data/groups_repository.dart';
import '../../features/teachers/data/teachers_repository.dart';
import '../../features/disciplines/data/disciplines_repository.dart';
import '../db/db_helper.dart';
import 'sync_logger.dart';

class SyncService {
  // Singleton instance to avoid multiple initializations
  SyncService._();
  static final SyncService instance = SyncService._();

  final _localAudRepo = AudiencesRepository();
  final _remoteAudRepo = AudiencesRemoteRepository();
  final _remoteGroups = GroupsRemoteRepository();
  final _remoteTeachers = TeachersRemoteRepository();
  final _remoteDisciplines = DisciplinesRemoteRepository();
  final supabase = Supabase.instance.client;

  DateTime _lastPulled = DateTime.fromMillisecondsSinceEpoch(0);
  bool _initialized = false;
  Timer? _syncTimer;

  /// Initialize sync service. Safe to call multiple times — actual init runs once.
  Future<void> init() async {
    if (_initialized) {
      SyncLogger.log('SyncService already initialized');
      return;
    }
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt('lastPulledAt') ?? 0;
    _lastPulled = DateTime.fromMillisecondsSinceEpoch(since);

    // Run an initial full sync
    try {
      await fullSync();
    } catch (e, st) {
      SyncLogger.log('Initial fullSync failed', error: e, stackTrace: st);
    }

    // Start periodic sync (every 5 minutes)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        await fullSync();
      } catch (e, st) {
        SyncLogger.log('Periodic fullSync failed', error: e, stackTrace: st);
      }
    });

    SyncLogger.log('SyncService initialized');
  }

  Future<void> _saveLastPulled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPulledAt', DateTime.now().millisecondsSinceEpoch);
    _lastPulled = DateTime.now();
  }

  Future<void> pushPendingAudiences() async {
    SyncLogger.log('Starting push of pending audiences');
    final pending = await _localAudRepo.getPendingMaps();
    SyncLogger.log('Found ${pending.length} pending audience(s)');
    
    for (final row in pending) {
      try {
        final localId = row['id'] as int;
        final remoteId = row['remote_id'] as String?;
        final deleted = (row['deleted'] as int?) ?? 0;
        final payload = {
          'name': row['name'],
          'type': row['type'],
          'capacity': row['capacity'],
          'boss': row['boss'],
          'building': row['building'],
          'equipment': row['equipment'],
        };
        
        SyncLogger.log('Processing audience: ${row['name']} (local_id: $localId, remote_id: $remoteId)');
        if (remoteId == null) {
          if (deleted == 1) {
            SyncLogger.log('Skipping deleted local record with no remote ID');
            await _localAudRepo.markSyncedByLocalId(localId);
            continue;
          }
          SyncLogger.log('Inserting new record to Supabase');
          final rid = await _remoteAudRepo.insert(payload);
          if (rid != null) {
            SyncLogger.log('Successfully inserted to Supabase, got remote ID: $rid');
            await _localAudRepo.setRemoteId(localId, rid);
          } else {
            SyncLogger.log('Failed to get remote ID after insert');
          }
        } else {
          if (deleted == 1) {
            SyncLogger.log('Deleting record from Supabase: $remoteId');
            await supabase.from('audiences').delete().eq('id', remoteId);
            await _localAudRepo.markSyncedByLocalId(localId);
          } else {
            SyncLogger.log('Updating record in Supabase: $remoteId');
            await _remoteAudRepo.update(remoteId, payload);
            await _localAudRepo.markSyncedByLocalId(localId);
          }
        }
      } catch (e, st) {
        SyncLogger.log('Error processing audience sync', error: e, stackTrace: st);
        // keep record pending for retry
      }
    }
  }

  Future<void> pullAudiencesSince() async {
    final rows = await _remoteAudRepo.fetchSince(_lastPulled);
    for (final r in rows) {
      try {
        await _localAudRepo.applyRemoteToLocal(r);
      } catch (e) {
        // log
      }
    }
    await _saveLastPulled();
  }

  Future<void> fullSync() async {
    // push local first, then pull remote for all synced tables
    await pushPendingAudiences();
    await pushPendingGroups();
    await pushPendingTeachers();
    await pushPendingDisciplines();

    await pullAudiencesSince();
    await pullGroupsSince();
    await pullTeachersSince();
    await pullDisciplinesSince();
  }

  Future<void> pushPendingGroups() async {
    SyncLogger.log('Starting push of pending groups');
    final groupsRepo = GroupsRepository();
    final remote = _remoteGroups;
    final pending = await groupsRepo.getPendingMaps();
    SyncLogger.log('Found ${pending.length} pending group(s)');
    for (final row in pending) {
      try {
        final localId = row['id'] as int;
        final remoteId = row['remote_id'] as String?;
        final deleted = (row['deleted'] as int?) ?? 0;
        final payload = Map<String, dynamic>.from(row);
        if (remoteId == null) {
          if (deleted == 1) {
            await groupsRepo.markSyncedByLocalId(localId);
            continue;
          }
          final rid = await remote.insert(payload);
          if (rid != null) await groupsRepo.setRemoteId(localId, rid);
        } else {
          if (deleted == 1) {
            await remote.delete(remoteId);
            await groupsRepo.markSyncedByLocalId(localId);
          } else {
            await remote.update(remoteId, payload);
            await groupsRepo.markSyncedByLocalId(localId);
          }
        }
      } catch (e, st) {
        SyncLogger.log('Error pushing group', error: e, stackTrace: st);
      }
    }
  }

  Future<void> pushPendingTeachers() async {
    SyncLogger.log('Starting push of pending teachers');
    final repo = TeachersRepository();
    final remote = _remoteTeachers;
    final pending = await repo.getPendingMaps();
    SyncLogger.log('Found ${pending.length} pending teacher(s)');
    for (final row in pending) {
      try {
        final localId = row['id'] as int;
        final remoteId = row['remote_id'] as String?;
        final deleted = (row['deleted'] as int?) ?? 0;
        final payload = Map<String, dynamic>.from(row);
        if (remoteId == null) {
          if (deleted == 1) {
            await repo.markSyncedByLocalId(localId);
            continue;
          }
          final rid = await remote.insert(payload);
          if (rid != null) await repo.setRemoteId(localId, rid);
        } else {
          if (deleted == 1) {
            await remote.delete(remoteId);
            await repo.markSyncedByLocalId(localId);
          } else {
            await remote.update(remoteId, payload);
            await repo.markSyncedByLocalId(localId);
          }
        }
      } catch (e, st) {
        SyncLogger.log('Error pushing teacher', error: e, stackTrace: st);
      }
    }
  }

  Future<void> pushPendingDisciplines() async {
    SyncLogger.log('Starting push of pending disciplines');
    final repo = DisciplinesRepository();
    final remote = _remoteDisciplines;
    final pending = await repo.getPendingMaps();
    SyncLogger.log('Found ${pending.length} pending discipline(s)');
    for (final row in pending) {
      try {
        final localId = row['id'] as int;
        final remoteId = row['remote_id'] as String?;
        final deleted = (row['deleted'] as int?) ?? 0;
        final payload = Map<String, dynamic>.from(row);
        if (remoteId == null) {
          if (deleted == 1) {
            await repo.markSyncedByLocalId(localId);
            continue;
          }
          final rid = await remote.insert(payload);
          if (rid != null) await repo.setRemoteId(localId, rid);
        } else {
          if (deleted == 1) {
            await remote.delete(remoteId);
            await repo.markSyncedByLocalId(localId);
          } else {
            await remote.update(remoteId, payload);
            await repo.markSyncedByLocalId(localId);
          }
        }
      } catch (e, st) {
        SyncLogger.log('Error pushing discipline', error: e, stackTrace: st);
      }
    }
  }

  Future<void> pullGroupsSince() async {
    final rows = await _remoteGroups.fetchSince(_lastPulled);
    final local = GroupsRepository();
    for (final r in rows) {
      try {
        await local.applyRemoteToLocal(r);
      } catch (e, st) {
        SyncLogger.log('Error applying group remote row', error: e, stackTrace: st);
      }
    }
    await _saveLastPulled();
  }

  Future<void> pullTeachersSince() async {
    final rows = await _remoteTeachers.fetchSince(_lastPulled);
    final local = TeachersRepository();
    for (final r in rows) {
      try {
        await local.applyRemoteToLocal(r);
      } catch (e, st) {
        SyncLogger.log('Error applying teacher remote row', error: e, stackTrace: st);
      }
    }
    await _saveLastPulled();
  }

  Future<void> pullDisciplinesSince() async {
    final rows = await _remoteDisciplines.fetchSince(_lastPulled);
    final local = DisciplinesRepository();
    for (final r in rows) {
      try {
        await local.applyRemoteToLocal(r);
      } catch (e, st) {
        SyncLogger.log('Error applying discipline remote row', error: e, stackTrace: st);
      }
    }
    await _saveLastPulled();
  }

  // Generic helpers for local DB operations for tables without specialized repository methods
  Future<List<Map<String, Object?>>> _getPendingMapsFor(String table) async {
    final db = await DBHelper.instance.database;
    final rows = await db.rawQuery("SELECT * FROM $table WHERE sync_state != 'synced' OR (remote_id IS NULL AND deleted = 0)");
    return rows;
  }

  Future<void> _setRemoteIdLocal(String table, int localId, String remoteId) async {
    final db = await DBHelper.instance.database;
    await db.update(table, {'remote_id': remoteId, 'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  Future<void> _markSyncedLocal(String table, int localId) async {
    final db = await DBHelper.instance.database;
    await db.update(table, {'sync_state': 'synced'}, where: 'id = ?', whereArgs: [localId]);
  }

  // Generic push for tables: insertFn should accept Map and return remoteId, updateFn/deleteFn return bool
  Future<void> pushPendingForTable(
    String table,
    Future<String?> Function(Map<String, dynamic>) insertFn,
    Future<bool> Function(String, Map<String, dynamic>) updateFn,
    Future<bool> Function(String) deleteFn,
  ) async {
    SyncLogger.log('Starting push of pending $table');
    final pending = await _getPendingMapsFor(table);
    SyncLogger.log('Found ${pending.length} pending $table record(s)');
    for (final row in pending) {
      try {
        final localId = row['id'] as int;
        final remoteId = row['remote_id'] as String?;
        final deleted = (row['deleted'] as int?) ?? 0;

        // Build a payload using raw row data; remote repo will pick required fields
        final payload = Map<String, dynamic>.from(row);

        if (remoteId == null) {
          if (deleted == 1) {
            SyncLogger.log('Skipping deleted local $table record with no remote ID (local $localId)');
            await _markSyncedLocal(table, localId);
            continue;
          }
          SyncLogger.log('Inserting new $table record to Supabase (local $localId)');
          final rid = await insertFn(payload);
          if (rid != null) {
            await _setRemoteIdLocal(table, localId, rid);
            SyncLogger.log('Set remote id $rid for local $table $localId');
          } else {
            SyncLogger.log('Failed to get remote id after insert for local $table $localId');
          }
        } else {
          if (deleted == 1) {
            SyncLogger.log('Deleting $table record from Supabase: $remoteId');
            await deleteFn(remoteId);
            await _markSyncedLocal(table, localId);
          } else {
            SyncLogger.log('Updating $table record in Supabase: $remoteId');
            await updateFn(remoteId, payload);
            await _markSyncedLocal(table, localId);
          }
        }
      } catch (e, st) {
        SyncLogger.log('Error pushing $table record', error: e, stackTrace: st);
      }
    }
  }

}
