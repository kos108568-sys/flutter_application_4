import 'dart:io';
// Note: we intentionally don't import supabase_config here to avoid
// analyzer warnings and accidental use of service_role keys in a
// developer helper script.

/// Lightweight helper script.
///
/// The previous version attempted to include raw SQL and use RPC calls
/// which produced many analyzer errors and prevented the project from
/// running. To keep the repository healthy, this script now only
/// prints instructions and points to `scripts/migration.sql` which
/// should be applied manually in the Supabase SQL editor.
void main(List<String> args) {
  final sqlPath = 'scripts/migration.sql';

  print('Supabase migration helper');
  print('---------------------------');

  if (File(sqlPath).existsSync()) {
    print('Migration SQL is available at: $sqlPath');
    print('\nOpen your Supabase project -> SQL Editor and paste the file contents, then run.');
  } else {
    print('ERROR: migration.sql not found at: $sqlPath');
  }

  print('\nIf you want me to automate migrations further, I can prepare a safe RPC-based runner, but it\'s safer to run SQL in the dashboard.');
}