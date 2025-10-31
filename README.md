# flutter_application_4

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Project Overview

- Domain: schedules and academic entities (departments, audiences, lesson types, rules, equipment, buildings, time slots, teachers, disciplines, groups).
- Local storage: SQLite with per-table sync metadata (`remote_id`, `updated_at`, `deleted`, `sync_state`).
- Remote backend: Supabase. Sync orchestrated in `lib/core/sync/sync_service.dart`.

## Configuration (Supabase)

This app reads Supabase settings from build-time defines. Do not hardcode secrets.

Run with your project values:

```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Admin/migration scripts in `scripts/` expect environment variables at runtime:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` (keep it out of client code and VCS)

Example (PowerShell):

```
$env:SUPABASE_URL = "https://YOUR-PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY = "YOUR_SERVICE_ROLE_KEY"
dart run scripts/migrate_to_supabase.dart
```

## Notes

- Some text resources were previously garbled due to encoding. Prefer UTF-8 without BOM and avoid non-ASCII in logs where possible.
- Feature structure lives under `lib/features/<domain>/{data,presentation}`; shared code under `lib/core/`.
