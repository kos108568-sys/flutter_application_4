import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/audiences/data/audiences_repository.dart';
import '../../features/audiences/data/audiences_remote_repository.dart';
import '../../features/departments/data/department_repository.dart';
import '../../features/audience_types/data/audience_type_repository.dart';
import '../../features/lesson_types/data/lesson_type_repository.dart';
import 'sync_logger.dart';

class SyncService {
  final _localAudRepo = AudiencesRepository();
  final _remoteAudRepo = AudiencesRemoteRepository();
  final _departmentRepo = DepartmentRepository();
  final _audienceTypeRepo = AudienceTypeRepository();
  final _lessonTypeRepo = LessonTypeRepository();
  final supabase = Supabase.instance.client;

  DateTime _lastPulled = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final since = prefs.getInt('lastPulledAt') ?? 0;
    _lastPulled = DateTime.fromMillisecondsSinceEpoch(since);
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
    try {
      // push local first, then pull remote
      await pushPendingAudiences();
      await pullAudiencesSince();
      
      // Синхронизация отделов (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _departmentRepo.syncDepartments();
        } catch (e) {
          print('Ошибка при синхронизации отделов: $e');
        }
      });
      
      // Синхронизация типов аудиторий (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _audienceTypeRepo.syncAudienceTypes();
        } catch (e) {
          print('Ошибка при синхронизации типов аудиторий: $e');
        }
      });
      
      // Синхронизация типов занятий (асинхронно, чтобы не блокировать)
      Future.microtask(() async {
        try {
          await _lessonTypeRepo.syncLessonTypes();
        } catch (e) {
          print('Ошибка при синхронизации типов занятий: $e');
        }
      });
    } catch (e) {
      print('Ошибка при полной синхронизации: $e');
    }
  }
}
