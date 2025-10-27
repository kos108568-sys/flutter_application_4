import 'package:flutter/material.dart';
import 'features/schedules/presentation/pages/schedules_page.dart';
import 'core/sync/sync_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _sync = SyncService();

  @override
  void initState() {
    super.initState();
    _maybeInitSync();
  }

  Future<void> _maybeInitSync() async {
    // initialize sync only if Supabase was configured
    try {
      await _sync.init();
      // run a first sync in background
      Future.microtask(() => _sync.fullSync());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SchedulesPage(),
    );
  }
}
