import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync/sync_service.dart';
import 'supabase_config.dart';

Future<void> initializeApp() async {
  // Initialize Supabase if configured
  if (SUPABASE_URL.isNotEmpty && SUPABASE_ANNON_KEY.isNotEmpty) {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANNON_KEY,
    );

    // Initialize sync service
    final syncService = SyncService();
    await syncService.init();
    
    // Perform initial sync
    await syncService.fullSync();
  }
}