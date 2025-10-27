# Модуль "Типы аудиторий" (Audience Types)

Этот модуль реализует полную двустороннюю синхронизацию таблицы `audience_types` между локальной базой SQLite и Supabase.

## Структура модуля

```
lib/features/audience_types/
├── data/
│   ├── audience_type_model.dart              # Модель данных
│   ├── audience_types_repository.dart        # Локальный репозиторий (SQLite)
│   ├── audience_types_remote_repository.dart # Удаленный репозиторий (Supabase)
│   └── audience_type_repository.dart         # Основной репозиторий с синхронизацией
└── presentation/
    ├── audience_types_screen.dart            # Экран управления типами аудиторий
    └── audience_type_form_dialog.dart        # Диалог добавления/редактирования
```

## Возможности

### ✅ Локальная работа
- Создание, чтение, обновление и удаление типов аудиторий в SQLite
- Поиск по названию и описанию
- Мягкое удаление (записи помечаются как удаленные)

### ✅ Синхронизация с Supabase
- Двусторонняя синхронизация данных
- Автоматическая отправка локальных изменений в Supabase
- Получение изменений из Supabase
- Обработка офлайн-режима

### ✅ Пользовательский интерфейс
- Список всех типов аудиторий
- Поиск по названию и описанию
- Добавление новых типов аудиторий
- Редактирование существующих типов аудиторий
- Удаление типов аудиторий
- Индикатор статуса синхронизации

## Настройка

### 1. Создание таблицы в Supabase

Выполните SQL-скрипт `scripts/create_audience_types_table.sql` в SQL Editor Supabase:

```sql
CREATE TABLE IF NOT EXISTS audience_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Настройка RLS (Row Level Security)

В Supabase Dashboard включите RLS для таблицы `audience_types` и создайте политики доступа.

### 3. Обновление базы данных

Таблица `audience_types` автоматически создается в SQLite при обновлении версии базы данных до 6.

## Использование

### Основные методы репозитория

```dart
final repository = AudienceTypeRepository();

// Получение всех типов аудиторий
List<AudienceType> types = await repository.getAllAudienceTypes();

// Добавление типа аудитории (с автоматической синхронизацией)
int id = await repository.insertAudienceType(
  AudienceType(name: 'Лекционная', description: 'Для проведения лекций')
);

// Обновление типа аудитории
await repository.updateAudienceType(audienceType);

// Удаление типа аудитории
await repository.deleteAudienceType(id);

// Ручная синхронизация
await repository.syncAudienceTypes();
```

### Отображение экрана

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AudienceTypesScreen(),
  ),
);
```

## Синхронизация

### Автоматическая синхронизация
- При запуске приложения выполняется полная синхронизация
- При добавлении/изменении/удалении данных происходит асинхронная синхронизация

### Ручная синхронизация
- Нажмите кнопку "Синхронизировать" в AppBar экрана типов аудиторий
- Или вызовите `repository.syncAudienceTypes()`

### Обработка офлайн-режима
- Все операции сначала сохраняются локально
- При отсутствии сети данные помечаются как `pending`
- При восстановлении соединения выполняется синхронизация

## Статусы синхронизации

- `synced` - запись синхронизирована
- `pending` - ожидает синхронизации
- `error` - ошибка синхронизации

## Логирование

Все операции синхронизации логируются через `print` для отладки.

## Тестирование

Для тестирования используйте метод `seedIfEmpty()` для создания тестовых данных:

```dart
await repository.seedIfEmpty();
```

Или используйте тестовый экран:
- В главном экране нажмите "Тест типов аудиторий"
- Протестируйте все функции модуля

## Безопасность

- Все операции с Supabase выполняются через анонимный ключ
- RLS политики контролируют доступ к данным
- Локальные данные шифруются SQLite

## Производительность

- Индексы в Supabase для быстрого поиска
- Пакетная обработка синхронизации
- Асинхронные операции не блокируют UI

## Комментарии в коде

Код содержит подробные комментарии:
- `// Сохранение локально`
- `// Отправка данных в Supabase`
- `// Синхронизация при запуске`
- `// Работа офлайн`
