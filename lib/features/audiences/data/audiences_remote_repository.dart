import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/sync/sync_logger.dart';

class AudiencesRemoteRepository {
  final client = Supabase.instance.client;
  final table = 'audiences';

  Future<String?> insert(Map<String, dynamic> item) async {
    try {
      SyncLogger.log('Inserting audience to Supabase: ${item['name']}');
      final payload = {
        'name': item['name'],
        'type': item['type'],
        'capacity': item['capacity'],
        'boss': item['boss'],
        'building': item['building'],
        'equipment': item['equipment'],
        'local_id': item['id'],
        'sync_status': 'synced',
      };
      SyncLogger.log('Payload: $payload');
      
      final response = await client
          .from(table)
          .insert(payload)
          .select('id')
          .single();
      
      final remoteId = response['id']?.toString();
      SyncLogger.log('Successfully inserted audience, remote ID: $remoteId');
      return remoteId;
    } catch (e, st) {
      SyncLogger.log('Error inserting audience', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> update(String remoteId, Map<String, dynamic> changes) async {
    try {
      SyncLogger.log('Updating audience in Supabase (ID: $remoteId)');
      final payload = {
        ...changes,
        'sync_status': 'synced',
        'version': changes['version'] ?? 1,
      };
      SyncLogger.log('Update payload: $payload');
      
      await client.from(table).update(payload).eq('id', remoteId);
      SyncLogger.log('Successfully updated audience');
      return true;
    } catch (e, st) {
      SyncLogger.log('Error updating audience', error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> delete(String remoteId) async {
    try {
      await client.from(table).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'sync_status': 'deleted'
      }).eq('id', remoteId);
      return true;
    } catch (e) {
      print('Error deleting audience: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAll({bool includeDeleted = false}) async {
    try {
      var query = client.from(table).select();
      if (!includeDeleted) {
        query = query.filter('deleted_at', 'is', null);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching audiences: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSince(DateTime since) async {
    try {
      final response = await client
          .from(table)
          .select()
          .filter('updated_at', 'gte', since.toIso8601String());
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching recent audiences: $e');
      return [];
    }
  }

  // Stream для реального времени
  Stream<List<Map<String, dynamic>>> streamChanges() {
    return client
        .from(table)
        .stream(primaryKey: ['id'])
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
