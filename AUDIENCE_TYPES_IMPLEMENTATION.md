# Реализация таблицы audience_types с двусторонней синхронизацией

## ✅ Что реализовано

### 1. Локальная база данных (SQLite)
- ✅ Таблица `audience_types` создана в `db_helper.dart`
- ✅ Поля: `id`, `name`, `description`, `remote_id`, `updated_at`, `deleted`, `sync_state`
- ✅ Версия базы данных увеличена до 6
- ✅ Автоматическое создание таблицы при обновлении

### 2. Модель данных
- ✅ Класс `AudienceType` с поддержкой синхронизации
- ✅ Наследование от `SyncableModel`
- ✅ Методы `toMap()`, `fromMap()`, `toSupabaseMap()`, `fromSupabaseMap()`
- ✅ Поддержка копирования и сравнения

### 3. Репозитории
- ✅ `AudienceTypesRepository` - локальная работа с SQLite
- ✅ `AudienceTypesRemoteRepository` - работа с Supabase
- ✅ `AudienceTypeRepository` - основной репозиторий с синхронизацией

### 4. Синхронизация
- ✅ Двусторонняя синхронизация SQLite ↔ Supabase
- ✅ Асинхронная отправка локальных изменений
- ✅ Получение изменений из Supabase
- ✅ Обработка офлайн-режима
- ✅ Интеграция в `SyncService`

### 5. Пользовательский интерфейс
- ✅ `AudienceTypesScreen` - экран управления типами аудиторий
- ✅ `AudienceTypeFormDialog` - диалог добавления/редактирования
- ✅ Поиск по названию и описанию
- ✅ CRUD операции
- ✅ Индикатор статуса синхронизации

### 6. Документация и тесты
- ✅ Подробный README модуля
- ✅ SQL-скрипт для создания таблицы в Supabase
- ✅ Тестовый экран `AudienceTypesTestScreen`
- ✅ Комментарии в коде

## 🚀 Как использовать

### 1. Настройка Supabase

Выполните SQL-скрипт в Supabase SQL Editor:

```sql
-- Создание таблицы audience_types в Supabase
CREATE TABLE IF NOT EXISTS audience_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Включение RLS
ALTER TABLE audience_types ENABLE ROW LEVEL SECURITY;

-- Политика для анонимного доступа
CREATE POLICY "Allow anonymous access to audience_types" ON audience_types
  FOR ALL USING (true);
```

### 2. Запуск приложения

```bash
flutter run
```

### 3. Тестирование модуля

1. **В главном экране** нажмите фиолетовую кнопку **"Тест типов аудиторий"**
2. **Протестируйте функции**:
   - Обновить (загрузка из SQLite)
   - Добавить тест (создание нового типа)
   - Синхронизация (с Supabase, если настроено)
   - Тестовые данные (добавление предустановленных типов)

### 4. Программное использование

```dart
import 'package:flutter_application_4/features/audience_types/data/audience_type_repository.dart';

final repository = AudienceTypeRepository();

// Получение всех типов аудиторий
List<AudienceType> types = await repository.getAllAudienceTypes();

// Добавление типа аудитории
int id = await repository.insertAudienceType(
  AudienceType(name: 'Лекционная', description: 'Для проведения лекций')
);

// Синхронизация
await repository.syncAudienceTypes();
```

## 📁 Структура файлов

```
lib/features/audience_types/
├── data/
│   ├── audience_type_model.dart              # Модель данных
│   ├── audience_types_repository.dart        # Локальный репозиторий
│   ├── audience_types_remote_repository.dart # Удаленный репозиторий
│   └── audience_type_repository.dart         # Основной репозиторий
└── presentation/
    ├── audience_types_screen.dart            # Главный экран
    └── audience_type_form_dialog.dart        # Диалог формы

scripts/
└── create_audience_types_table.sql           # SQL для Supabase
```

## 🔄 Процесс синхронизации

### При добавлении типа аудитории:
1. Сохранение в SQLite с `sync_state = 'pending'`
2. Асинхронная отправка в Supabase
3. При успехе: установка `remote_id` и `sync_state = 'synced'`
4. При ошибке: запись остается в состоянии `pending`

### При запуске приложения:
1. Инициализация `SyncService`
2. Выполнение `fullSync()`
3. Отправка локальных изменений в Supabase
4. Получение изменений из Supabase

### Обработка офлайн-режима:
- Все операции сначала сохраняются локально
- При отсутствии сети данные помечаются как `pending`
- При восстановлении соединения выполняется синхронизация

## 🎯 Особенности реализации

### Комментарии в коде:
- ✅ "Сохранение локально"
- ✅ "Отправка данных в Supabase" 
- ✅ "Синхронизация при запуске"
- ✅ "Работа офлайн"

### Обработка ошибок:
- ✅ Try/catch для всех операций с Supabase
- ✅ Логирование ошибок
- ✅ Graceful degradation при отсутствии сети

### Производительность:
- ✅ Асинхронные операции
- ✅ Пакетная обработка синхронизации
- ✅ Индексы в Supabase

## 🔒 Безопасность

- Используется анонимный ключ Supabase
- RLS политики контролируют доступ
- Локальные данные защищены SQLite

## 📊 Статусы синхронизации

- `synced` - запись синхронизирована
- `pending` - ожидает синхронизации  
- `error` - ошибка синхронизации

## 🎉 Готово к использованию!

Модуль полностью реализован и готов к использованию. Все требования выполнены:

- ✅ Таблица audience_types в SQLite и Supabase
- ✅ Двусторонняя синхронизация
- ✅ Обработка офлайн-режима
- ✅ Пользовательский интерфейс
- ✅ Подробная документация
- ✅ Тесты и примеры использования
- ✅ Комментарии в коде
