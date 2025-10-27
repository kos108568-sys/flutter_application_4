import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/sync/sync_logger.dart';

class TeachersRemoteRepository {
  final client = Supabase.instance.client;
  final table = 'teachers';

  Future<String?> insert(Map<String, dynamic> item) async {
    try {
      SyncLogger.log('Inserting teacher to Supabase: ${item['full_name']}');
      final payload = {
        'full_name': item['full_name'],
        'curator_group_id': item['curator_group_id'],
        'department': item['department'],
        'local_id': item['id'],
        'sync_status': 'synced',
      };
      final response = await client.from(table).insert(payload).select('id').single();
      final remoteId = response['id']?.toString();
      SyncLogger.log('Inserted teacher remote id: $remoteId');
      return remoteId;
    } catch (e, st) {
      SyncLogger.log('Error inserting teacher', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> update(String remoteId, Map<String, dynamic> changes) async {
    try {
      SyncLogger.log('Updating teacher $remoteId');
      final payload = {...changes, 'sync_status': 'synced'};
      await client.from(table).update(payload).eq('id', remoteId);
      return true;
    } catch (e, st) {
      SyncLogger.log('Error updating teacher', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> delete(String remoteId) async {
    try {
      SyncLogger.log('Marking teacher deleted $remoteId');
      await client.from(table).update({'deleted_at': DateTime.now().toIso8601String(), 'sync_status': 'deleted'}).eq('id', remoteId);
      return true;
    } catch (e, st) {
      SyncLogger.log('Error deleting teacher', error: e, stackTrace: st);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime since) async {
    try {
      final response = await client.from(table).select().filter('updated_at', 'gte', since.toIso8601String());
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      SyncLogger.log('Error fetching recent teachers', error: e, stackTrace: st);
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamChanges() {
    return client.from(table).stream(primaryKey: ['id']).map((data) => List<Map<String, dynamic>>.from(data));
  }
}
