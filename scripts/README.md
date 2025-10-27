Как правильно выполнить миграцию Supabase

Этот каталог содержит SQL-миграцию и лёгкий помощник. Чтобы корректно создать таблицы и политики в Supabase, выполните шаги ниже.

1) Откройте консоль Supabase
   - Перейдите в: https://app.supabase.com
   - Выберите ваш проект

2) Выполните SQL миграцию
   - В меню Database → SQL Editor создайте новый запрос
   - Откройте файл `scripts/migration.sql` в проекте
   - Скопируйте содержимое и вставьте в SQL Editor
   - Нажмите "Run"

3) Проверки и рекомендации
   - Убедитесь, что таблица `audiences` появилась в Database → Tables
   - Проверьте индексы и триггер `update_audiences_updated_at`
   - Политики в миграции дают доступ роли `authenticated`. Для тестирования локально вы можете временно добавить политики для роли `anon` (см. предупреждение ниже).

4) Быстрая тестовая политика (НЕ ДЛЯ ПРОДАКШЕНА)
   Выполните в SQL Editor, только если вы тестируете локально и понимаете риски:

```sql
CREATE POLICY IF NOT EXISTS "anon_select_audiences" ON audiences
  FOR SELECT TO anon
  USING (deleted_at IS NULL);

CREATE POLICY IF NOT EXISTS "anon_insert_audiences" ON audiences
  FOR INSERT TO anon
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "anon_update_audiences" ON audiences
  FOR UPDATE TO anon
  USING (true) WITH CHECK (true);
```

5) Локальный запуск приложения
```powershell
flutter clean
flutter pub get
flutter run
```

6) Тест синхронизации
   - Создайте новую аудиторию в приложении (это создаст запись в локальной SQLite с `sync_state = 'pending'`).
   - Вызовите синхронизацию: `await SyncService().fullSync();` (можно временно поставить вызов после инициализации Supabase в `main()` для теста).
   - После успешного пуша запись должна появиться в Supabase и локальная запись должна получить `remote_id`.

7) Безопасность
   - Никогда не храните `service_role` key в публичных репозиториях.
   - Миграции выполняйте в консоли Supabase или с помощью безопасного серверного процесса, который хранит `service_role` в защищённом месте.

Если хотите, могу:
- Подготовить безопасный runner миграций, который будет вызываться на CI или на сервере с защищённым ключом.
- Временно включить автоматический вызов `SyncService().fullSync()` при старте приложения для удобства тестирования (я добавлю это в `main.dart`, но помечу как тестовое).

Если нужно — выполню выбранный вариант и помогу с тестированием.