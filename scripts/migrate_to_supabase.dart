// Usage: dart run scripts/migrate_to_supabase.dart --db path_to_sqlite_db
// Requires env var SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final argDbIndex = args.indexOf('--db');
  String dbPath;
  if (argDbIndex != -1 && args.length > argDbIndex + 1) {
    dbPath = args[argDbIndex + 1];
  } else {
    // default path used by sqflite_common_ffi in this project
    dbPath = '${Directory.current.path}${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}sqflite_common_ffi${Platform.pathSeparator}databases${Platform.pathSeparator}app_data.db';
  }

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (supabaseUrl == null || serviceKey == null) {
    print('Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your environment.');
    exit(1);
  }

  if (!File(dbPath).existsSync()) {
    print('Local DB not found at $dbPath');
    exit(1);
  }

  final db = sqlite3.open(dbPath);
  try {
    final result = db.select('SELECT * FROM audiences');
    print('Found ${result.length} audiences, uploading...');
    for (final row in result) {
      final map = <String, dynamic>{};
      for (final e in row.entries) {
        map[e.key] = e.value;
      }
      final payload = {
        'name': map['name'],
        'type': map['type'],
        'capacity': map['capacity'],
        'boss': map['boss'],
        'building': map['building'],
        'equipment': map['equipment'] != null ? jsonDecode(map['equipment']) : null,
      };
      final res = await http.post(Uri.parse('$supabaseUrl/rest/v1/audiences'),
          headers: {
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
          },
          body: jsonEncode(payload));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final resp = jsonDecode(res.body);
        if (resp is List && resp.isNotEmpty) {
          final remote = resp.first;
          final remoteId = remote['id'];
          // update local row with remote_id
          final id = map['id'];
          db.execute('UPDATE audiences SET remote_id = ? WHERE id = ?', [remoteId, id]);
          print('Migrated local id $id -> remote $remoteId');
        }
      } else {
        print('Failed to insert: ${res.statusCode} ${res.body}');
      }
    }
    print('Migration finished');
  } finally {
    db.dispose();
  }
}
