import 'dart:developer' as developer;

class SyncLogger {
  static void log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'SyncService',
      error: error,
      stackTrace: stackTrace,
    );
    print('[SyncService] $message');
    if (error != null) {
      print('[SyncService] Error: $error');
      if (stackTrace != null) {
        print('[SyncService] StackTrace: $stackTrace');
      }
    }
  }
}