# Модуль "Отделы" (Departments)

Этот модуль реализует полную двустороннюю синхронизацию таблицы `departments` между локальной базой SQLite и Supabase.

## Структура модуля

```
lib/features/departments/
├── data/
│   ├── department_model.dart              # Модель данных
│   ├── departments_repository.dart        # Локальный репозиторий (SQLite)
│   ├── departments_remote_repository.dart # Удаленный репозиторий (Supabase)
│   └── department_repository.dart         # Основной репозиторий с синхронизацией
└── presentation/
    ├── departments_screen.dart            # Экран управления отделами
    └── department_form_dialog.dart        # Диалог добавления/редактирования
```

## Возможности

### ✅ Локальная работа
- Создание, чтение, обновление и удаление отделов в SQLite
- Поиск отделов по названию
- Мягкое удаление (записи помечаются как удаленные)

### ✅ Синхронизация с Supabase
- Двусторонняя синхронизация данных
- Автоматическая отправка локальных изменений в Supabase
- Получение изменений из Supabase
- Обработка офлайн-режима

### ✅ Пользовательский интерфейс
- Список всех отделов
- Поиск по названию
- Добавление новых отделов
- Редактирование существующих отделов
- Удаление отделов
- Индикатор статуса синхронизации

## Настройка

### 1. Создание таблицы в Supabase

Выполните SQL-скрипт `scripts/create_departments_table.sql` в SQL Editor Supabase:

```sql
CREATE TABLE IF NOT EXISTS departments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Настройка RLS (Row Level Security)

В Supabase Dashboard включите RLS для таблицы `departments` и создайте политики доступа.

### 3. Обновление базы данных

Таблица `departments` автоматически создается в SQLite при обновлении версии базы данных до 5.

## Использование

### Основные методы репозитория

```dart
final repository = DepartmentRepository();

// Получение всех отделов
List<Department> departments = await repository.getAllDepartments();

// Добавление отдела (с автоматической синхронизацией)
int id = await repository.insertDepartment(
  Department(name: 'Кафедра информатики')
);

// Обновление отдела
await repository.updateDepartment(department);

// Удаление отдела
await repository.deleteDepartment(id);

// Ручная синхронизация
await repository.syncDepartments();
```

### Отображение экрана

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DepartmentsScreen(),
  ),
);
```

## Синхронизация

### Автоматическая синхронизация
- При запуске приложения выполняется полная синхронизация
- При добавлении/изменении/удалении данных происходит асинхронная синхронизация

### Ручная синхронизация
- Нажмите кнопку "Синхронизировать" в AppBar экрана отделов
- Или вызовите `repository.syncDepartments()`

### Обработка офлайн-режима
- Все операции сначала сохраняются локально
- При отсутствии сети данные помечаются как `pending`
- При восстановлении соединения выполняется синхронизация

## Статусы синхронизации

- `synced` - запись синхронизирована
- `pending` - ожидает синхронизации
- `error` - ошибка синхронизации

## Логирование

Все операции синхронизации логируются через `SyncLogger` для отладки.

## Тестирование

Для тестирования используйте метод `seedIfEmpty()` для создания тестовых данных:

```dart
await repository.seedIfEmpty();
```

## Безопасность

- Все операции с Supabase выполняются через анонимный ключ
- RLS политики контролируют доступ к данным
- Локальные данные шифруются SQLite

## Производительность

- Индексы в Supabase для быстрого поиска
- Пакетная обработка синхронизации
- Асинхронные операции не блокируют UI
