import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'app_data.db');

    return openDatabase(
      path,
      version: 16,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        await _ensureSchema(db);
      },
      onCreate: (db, version) async {
        await _ensureSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS disciplines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              teacher TEXT,
              group_code TEXT,
              semester INTEGER,
              created_at INTEGER
            );
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS groups (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              size INTEGER,
              curator TEXT,
              course INTEGER,
              specialty TEXT,
              discipline_ids TEXT
            );
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS teachers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              curator_group_id INTEGER
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS teacher_disciplines (
              teacher_id INTEGER NOT NULL,
              discipline_id INTEGER NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS teacher_audiences (
              teacher_id INTEGER NOT NULL,
              audience_id INTEGER NOT NULL
            );
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS departments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              remote_id TEXT,
              updated_at INTEGER,
              deleted INTEGER DEFAULT 0,
              sync_state TEXT DEFAULT 'synced'
            );
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audience_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              remote_id TEXT,
              updated_at INTEGER,
              deleted INTEGER DEFAULT 0,
              sync_state TEXT DEFAULT 'synced'
            );
          ''');
        }
        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS lesson_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT,
              remote_id TEXT,
              updated_at INTEGER,
              deleted INTEGER DEFAULT 0,
              sync_state TEXT DEFAULT 'synced'
            );
          ''');
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS lesson_rules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              lesson_type_id INTEGER NOT NULL,
              audience_type_id INTEGER NOT NULL,
              allowed INTEGER NOT NULL DEFAULT 1,
              FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id),
              FOREIGN KEY (audience_type_id) REFERENCES audience_types(id)
            );
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS equipments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT
            );
          ''');
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS buildings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              address TEXT,
              description TEXT
            );
          ''');
        }
        if (oldVersion < 11) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS time_slots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_number INTEGER NOT NULL,
              start_time TEXT NOT NULL,
              end_time TEXT NOT NULL,
              description TEXT
            );
          ''');
        }
        if (oldVersion < 12) {
          final rows = await db.rawQuery('PRAGMA table_info(teachers)');
          final existing = rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
          Future<void> add(String name, String ddl) async {
            if (!existing.contains(name.toLowerCase())) {
              await db.execute('ALTER TABLE teachers ADD COLUMN $name $ddl;');
            }
          }

          await add('department_id', 'INTEGER');
          await add('email', 'TEXT');
          await add('phone', 'TEXT');
          await add('notes', 'TEXT');
        }
        if (oldVersion < 13) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audience_equipments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              audience_id INTEGER NOT NULL,
              equipment_id INTEGER NOT NULL,
              FOREIGN KEY (audience_id) REFERENCES audiences(id),
              FOREIGN KEY (equipment_id) REFERENCES equipments(id),
              UNIQUE (audience_id, equipment_id)
            );
          ''');
        }
        if (oldVersion < 14) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS group_subject_teachers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              group_id INTEGER NOT NULL,
              teacher_id INTEGER NOT NULL,
              discipline_id INTEGER NOT NULL,
              total_hours INTEGER NOT NULL,
              start_date TEXT,
              end_date TEXT,
              notes TEXT,
              subgroup TEXT,
              FOREIGN KEY (group_id) REFERENCES groups(id),
              FOREIGN KEY (teacher_id) REFERENCES teachers(id),
              FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
              UNIQUE (group_id, teacher_id, discipline_id)
            );
          ''');
        }
        if (oldVersion < 15) {
          await _migrateAudiencesTable(db);
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audience_lesson_types (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              audience_id INTEGER NOT NULL,
              lesson_type_id INTEGER NOT NULL,
              FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE,
              FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id) ON DELETE CASCADE,
              UNIQUE (audience_id, lesson_type_id)
            );
          ''');
        }
        if (oldVersion < 16) {
          // Добавляем preferred_building_id, если его еще нет
          final rows = await db.rawQuery('PRAGMA table_info(teachers)');
          final existing = rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
          if (!existing.contains('preferred_building_id')) {
            await db.execute('ALTER TABLE teachers ADD COLUMN preferred_building_id INTEGER;');
          }
        }

        await _ensureSchema(db);
      },
    );
  }

  Future<void> _migrateAudiencesTable(Database db) async {
    final hasTable = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = "table" AND name = "audiences"',
    );
    if (hasTable.isEmpty) {
      return;
    }

    final info = await db.rawQuery('PRAGMA table_info(audiences)');
    final columnNames = info.map((row) => (row['name'] as String).toLowerCase()).toSet();
    final needsMigration = !columnNames.contains('type') ||
        !columnNames.contains('teacher_id') ||
        columnNames.contains('audience_type_id') ||
        columnNames.contains('responsible_teacher_id') ||
        columnNames.contains('boss') ||
        columnNames.contains('building');

    if (!needsMigration) {
      return;
    }

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        final typeLookup = <int, String>{};
        try {
          final typeRows = await txn.query('audience_types');
          for (final row in typeRows) {
            final id = row['id'] as int?;
            final name = row['name'] as String?;
            if (id != null && name != null) {
              typeLookup[id] = name;
            }
          }
        } catch (_) {
          // table might not exist yet
        }

        final oldRows = await txn.query('audiences');

        final tempName = 'audiences_old_backup';
        await txn.execute('ALTER TABLE audiences RENAME TO $tempName;');
        await txn.execute('''
          CREATE TABLE audiences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT,
            capacity INTEGER,
            building_id INTEGER,
            teacher_id INTEGER,
            notes TEXT,
            remote_id TEXT,
            updated_at INTEGER,
            deleted INTEGER DEFAULT 0,
            sync_state TEXT DEFAULT 'synced',
            FOREIGN KEY (building_id) REFERENCES buildings(id),
            FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL
          );
        ''');

        for (final row in oldRows) {
          final typeIdRaw = row.containsKey('audience_type_id') ? row['audience_type_id'] : null;
          final typeName = row.containsKey('type') && row['type'] is String
              ? row['type'] as String?
              : typeLookup[typeIdRaw is int ? typeIdRaw : (typeIdRaw is num ? typeIdRaw.toInt() : null)];

          final newRow = <String, Object?>{
            'id': row['id'],
            'name': row['name'],
            'type': typeName,
            'capacity': row['capacity'],
            'building_id': row['building_id'],
            'teacher_id': row.containsKey('teacher_id')
                ? row['teacher_id']
                : row.containsKey('responsible_teacher_id')
                    ? row['responsible_teacher_id']
                    : null,
            'notes': row['notes'],
            'remote_id': row['remote_id'],
            'updated_at': row['updated_at'],
            'deleted': row['deleted'] ?? 0,
            'sync_state': row['sync_state'] ?? 'synced',
          };

          await txn.insert('audiences', newRow, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await txn.execute('DROP TABLE IF EXISTS $tempName;');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateLessonsTable(Database db) async {
    final hasTable = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = "table" AND name = "lessons"',
    );
    if (hasTable.isEmpty) {
      return;
    }

    bool needsMigration = false;
    try {
      final fkList = await db.rawQuery('PRAGMA foreign_key_list(lessons)');
      needsMigration = fkList.any((row) {
        final table = row['table'] as String? ?? '';
        return table.toLowerCase() == 'audiences_old_backup';
      });
    } catch (_) {
      needsMigration = false;
    }
    if (!needsMigration) {
      return;
    }

    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE lessons RENAME TO lessons_old_backup;');
        await txn.execute('''
          CREATE TABLE lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            discipline_id INTEGER NOT NULL,
            type TEXT,
            teacher_id INTEGER NOT NULL,
            audience_id INTEGER NOT NULL,
            group_id INTEGER NOT NULL,
            pair_no INTEGER NOT NULL,
            day_of_week INTEGER NOT NULL,
            date TEXT NOT NULL,
            subgroup TEXT,
            remote_id TEXT,
            updated_at INTEGER,
            deleted INTEGER DEFAULT 0,
            sync_state TEXT DEFAULT 'synced',
            FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
            FOREIGN KEY (teacher_id) REFERENCES teachers(id),
            FOREIGN KEY (audience_id) REFERENCES audiences(id),
            FOREIGN KEY (group_id) REFERENCES groups(id)
          );
        ''');
        final oldInfo = await txn.rawQuery('PRAGMA table_info(lessons_old_backup)');
        final hasColumn = (String name) =>
            oldInfo.any((row) => (row['name'] as String).toLowerCase() == name.toLowerCase());
        final selectSql = '''
          SELECT
            id,
            discipline_id,
            type,
            teacher_id,
            audience_id,
            group_id,
            pair_no,
            day_of_week,
            date,
            ${hasColumn('subgroup') ? 'subgroup' : 'NULL'} AS subgroup,
            ${hasColumn('remote_id') ? 'remote_id' : 'NULL'} AS remote_id,
            ${hasColumn('updated_at') ? 'updated_at' : 'NULL'} AS updated_at,
            ${hasColumn('deleted') ? 'deleted' : '0'} AS deleted,
            ${hasColumn('sync_state') ? 'sync_state' : "'synced'"} AS sync_state
          FROM lessons_old_backup;
        ''';
        await txn.execute('''
          INSERT INTO lessons (
            id,
            discipline_id,
            type,
            teacher_id,
            audience_id,
            group_id,
            pair_no,
            day_of_week,
            date,
            subgroup,
            remote_id,
            updated_at,
            deleted,
            sync_state
          )
          $selectSql
        ''');
        await txn.execute('DROP TABLE IF EXISTS lessons_old_backup;');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _ensureSchema(Database db) async {
    await _migrateAudiencesTable(db);
    await _migrateLessonsTable(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audiences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        capacity INTEGER,
        building_id INTEGER,
        teacher_id INTEGER,
        notes TEXT,
        remote_id TEXT,
        updated_at INTEGER,
        deleted INTEGER DEFAULT 0,
        sync_state TEXT DEFAULT 'synced',
        FOREIGN KEY (building_id) REFERENCES buildings(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lessons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        discipline_id INTEGER NOT NULL,
        type TEXT,
        teacher_id INTEGER NOT NULL,
        audience_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        pair_no INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        date TEXT NOT NULL,
        subgroup TEXT,
        remote_id TEXT,
        updated_at INTEGER,
        deleted INTEGER DEFAULT 0,
        sync_state TEXT DEFAULT 'synced',
        FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (audience_id) REFERENCES audiences(id),
        FOREIGN KEY (group_id) REFERENCES groups(id)
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_lessons_date ON lessons(date);');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lessons_group_date ON lessons(group_id, date);',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_lessons_group_date_pair ON lessons(group_id, date, pair_no, subgroup);',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS disciplines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lesson_type_id INTEGER,
        semester TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        size INTEGER,
        curator TEXT,
        course INTEGER,
        specialty TEXT,
        discipline_ids TEXT,
        curator_teacher_id INTEGER,
        student_count INTEGER,
        department_id INTEGER,
        notes TEXT,
        FOREIGN KEY (curator_teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (department_id) REFERENCES departments(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        department_id INTEGER,
        email TEXT,
        phone TEXT,
        notes TEXT,
        preferred_building_id INTEGER,
        FOREIGN KEY (department_id) REFERENCES departments(id),
        FOREIGN KEY (preferred_building_id) REFERENCES buildings(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher_disciplines (
        teacher_id INTEGER NOT NULL,
        discipline_id INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher_audiences (
        teacher_id INTEGER NOT NULL,
        audience_id INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_disciplines (
        group_id INTEGER NOT NULL,
        discipline_id INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher_groups (
        teacher_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS departments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        remote_id TEXT,
        updated_at INTEGER,
        deleted INTEGER DEFAULT 0,
        sync_state TEXT DEFAULT 'synced'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audience_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        remote_id TEXT,
        updated_at INTEGER,
        deleted INTEGER DEFAULT 0,
        sync_state TEXT DEFAULT 'synced'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lesson_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        remote_id TEXT,
        updated_at INTEGER,
        deleted INTEGER DEFAULT 0,
        sync_state TEXT DEFAULT 'synced'
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lesson_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_type_id INTEGER NOT NULL,
        audience_type_id INTEGER NOT NULL,
        allowed INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id),
        FOREIGN KEY (audience_type_id) REFERENCES audience_types(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audience_equipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audience_id INTEGER NOT NULL,
        equipment_id INTEGER NOT NULL,
        FOREIGN KEY (audience_id) REFERENCES audiences(id),
        FOREIGN KEY (equipment_id) REFERENCES equipments(id),
        UNIQUE (audience_id, equipment_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audience_lesson_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audience_id INTEGER NOT NULL,
        lesson_type_id INTEGER NOT NULL,
        FOREIGN KEY (audience_id) REFERENCES audiences(id) ON DELETE CASCADE,
        FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id) ON DELETE CASCADE,
        UNIQUE (audience_id, lesson_type_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_subject_teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        discipline_id INTEGER NOT NULL,
        total_hours INTEGER NOT NULL,
        start_date TEXT,
        end_date TEXT,
        notes TEXT,
        subgroup TEXT,
        FOREIGN KEY (group_id) REFERENCES groups(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
        UNIQUE (group_id, teacher_id, discipline_id)
      );
    ''');

    await _ensureGroupColumns(db);
    await _ensureTeacherColumns(db);
    await _ensureDisciplineColumns(db);
    await _ensureAudienceColumns(db);
    await _ensureSyncColumns(db);
    await _ensureGSTColumns(db);
  }

  Future<void> _ensureSyncColumns(Database db) async {
    final tables = [
      'audiences',
      'groups',
      'teachers',
      'disciplines',
      'departments',
      'audience_types',
      'lesson_types',
      'lessons',
    ];

    for (final table in tables) {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();

      Future<void> add(String name, String ddl) async {
        if (!existing.contains(name.toLowerCase())) {
          await db.execute('ALTER TABLE $table ADD COLUMN $name $ddl;');
        }
      }

      await add('remote_id', 'TEXT');
      await add('updated_at', 'INTEGER');
      await add('deleted', 'INTEGER DEFAULT 0');
      await add('sync_state', "TEXT DEFAULT 'synced'");
    }
  }

  Future<void> _ensureAudienceColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(audiences)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();

    Future<void> addColumn(String name, String ddl) async {
      if (!existing.contains(name.toLowerCase())) {
        await db.execute('ALTER TABLE audiences ADD COLUMN $name $ddl;');
      }
    }

    await addColumn('type', 'TEXT');
    await addColumn('capacity', 'INTEGER');
    await addColumn('building_id', 'INTEGER');
    await addColumn('teacher_id', 'INTEGER');
    await addColumn('notes', 'TEXT');
  }

  Future<void> _ensureGroupColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(groups)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();

    Future<void> addColumn(String name, String ddl) async {
      if (!existing.contains(name.toLowerCase())) {
        await db.execute('ALTER TABLE groups ADD COLUMN $name $ddl;');
      }
    }

    await addColumn('size', 'INTEGER');
    await addColumn('discipline_ids', 'TEXT');
    await addColumn('curator', 'TEXT');
    await addColumn('course', 'INTEGER');
    await addColumn('specialty', 'TEXT');
    await addColumn('curator_teacher_id', 'INTEGER');
    await addColumn('student_count', 'INTEGER');
    await addColumn('department_id', 'INTEGER');
    await addColumn('notes', 'TEXT');
  }

  Future<void> _ensureTeacherColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(teachers)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();

    Future<void> add(String name, String ddl) async {
      if (!existing.contains(name.toLowerCase())) {
        await db.execute('ALTER TABLE teachers ADD COLUMN $name $ddl;');
      }
    }

    await add('department_id', 'INTEGER');
    await add('email', 'TEXT');
    await add('phone', 'TEXT');
    await add('notes', 'TEXT');
    await add('preferred_building_id', 'INTEGER');
  }

  Future<void> _ensureDisciplineColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(disciplines)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();

    Future<void> add(String name, String ddl) async {
      if (!existing.contains(name.toLowerCase())) {
        await db.execute('ALTER TABLE disciplines ADD COLUMN $name $ddl;');
      }
    }

    await add('lesson_type_id', 'INTEGER');
    await add('semester', 'TEXT');
  }

  Future<void> _ensureGSTColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(group_subject_teachers)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();
    if (!existing.contains('subgroup')) {
      await db.execute('ALTER TABLE group_subject_teachers ADD COLUMN subgroup TEXT;');
    }
  }
}
