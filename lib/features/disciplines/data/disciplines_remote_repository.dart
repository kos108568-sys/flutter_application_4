import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/sync/sync_logger.dart';

class DisciplinesRemoteRepository {
  final client = Supabase.instance.client;
  final table = 'disciplines';

  Future<String?> insert(Map<String, dynamic> item) async {
    try {
      SyncLogger.log('Inserting discipline to Supabase: ${item['name']}');
      final payload = {
        'name': item['name'],
        'teacher': item['teacher'],
        'group_code': item['group_code'],
        'semester': item['semester'],
        'hours': item['hours'],
        'created_at': item['created_at'],
        'local_id': item['id'],
        'sync_status': 'synced',
      };
      final response = await client.from(table).insert(payload).select('id').single();
      final remoteId = response['id']?.toString();
      SyncLogger.log('Inserted discipline remote id: $remoteId');
      return remoteId;
    } catch (e, st) {
      SyncLogger.log('Error inserting discipline', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> update(String remoteId, Map<String, dynamic> changes) async {
    try {
      SyncLogger.log('Updating discipline $remoteId');
      final payload = {...changes, 'sync_status': 'synced'};
      await client.from(table).update(payload).eq('id', remoteId);
      return true;
    } catch (e, st) {
      SyncLogger.log('Error updating discipline', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> delete(String remoteId) async {
    try {
      SyncLogger.log('Marking discipline deleted $remoteId');
      await client.from(table).update({'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 'deleted'}).eq('id', remoteId);
      return true;
    } catch (e, st) {
      SyncLogger.log('Error deleting discipline', error: e, stackTrace: st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime since) async {
    try {
      final response = await client.from(table).select().filter('updated_at', 'gte', since.toIso8601String());
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      SyncLogger.log('Error fetching recent disciplines', error: e, stackTrace: st);
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamChanges() {
    return client.from(table).stream(primaryKey: ['id']).map((data) => List<Map<String, dynamic>>.from(data));
  }
}
