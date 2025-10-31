// Supabase configuration.
// Values are injected at build time via --dart-define to avoid committing secrets.
// Example:
//   flutter run \
//     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY

const String SUPABASE_URL = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://npnfifitzkzifgoepeje.supabase.co',
);
const String SUPABASE_ANON_KEY = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  // Public anon key for client usage only. Safe to embed in app binaries.
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wbmZpZml0emt6aWZnb2VwZWplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NTM0MzYsImV4cCI6MjA3NzEyOTQzNn0.rLT5Mrqx6LQ7P_eNDPRy9oZEb-FtFUNNlJakvyLAfFc',
);

// For admin scripts (in scripts/), use environment variables at runtime:
//   SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
