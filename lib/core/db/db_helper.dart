import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
    return await openDatabase(
      path,
      version: 14, // ����������� ������ ��� ���������� group_subject_teachers � ������ ���������
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
          // ��������� ������� departments
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
          // ��������� ������� audience_types
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
          // ��������� ������� lesson_types
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
          // ��������� ������� lesson_rules
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
          // ��������� ������� equipments
          await db.execute('''
            CREATE TABLE IF NOT EXISTS equipments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT
            );
          ''');
        }
        if (oldVersion < 10) {
          // ��������� ������� buildings
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
          // ��������� ������� time_slots
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
          // ��������� ��������� teachers: ��������� ����������� ����
          final rows = await db.rawQuery('PRAGMA table_info(teachers)');
          final existing = rows.map((r) => (r['name'] as String).toLowerCase()).toSet();
          Future<void> add(String name, String ddl) async {
            if (!existing.contains(name.toLowerCase())) {
              await db.execute('ALTER TABLE teachers ADD COLUMN ' + name + ' ' + ddl + ';');
            }
          }
          await add('department_id', 'INTEGER');
          await add('email', 'TEXT');
          await add('phone', 'TEXT');
          await add('notes', 'TEXT');
          // ����������: ���� curator_group_id � total_load ������ �� ������������
        }
        if (oldVersion < 13) {
          // ��������� ������� audience_equipments (M<->N ���������-������������)
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
          // ��������� ������� group_subject_teachers (����� ������-����������-�������������)
          await db.execute('''
            CREATE TABLE IF NOT EXISTS group_subject_teachers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              group_id INTEGER NOT NULL,
              teacher_id INTEGER NOT NULL,
              discipline_id INTEGER NOT NULL,
              total_hours INTEGER NOT NULL,
              start_date TEXT,
              end_date TEXT,
              notes TEXT,\r
              subgroup TEXT,\r
              FOREIGN KEY (group_id) REFERENCES groups(id),
              FOREIGN KEY (teacher_id) REFERENCES teachers(id),
              FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
              UNIQUE (group_id, teacher_id, discipline_id)
            );
          ''');
        }
        await _ensureSchema(db);
      },
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audiences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER,
        audience_type_id INTEGER,
        building_id INTEGER,
        responsible_teacher_id INTEGER,
        notes TEXT,\r
              subgroup TEXT,\r
              FOREIGN KEY (audience_type_id) REFERENCES audience_types(id),
        FOREIGN KEY (building_id) REFERENCES buildings(id),
        FOREIGN KEY (responsible_teacher_id) REFERENCES teachers(id)
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
        FOREIGN KEY (discipline_id) REFERENCES disciplines(id),
        FOREIGN KEY (teacher_id) REFERENCES teachers(id),
        FOREIGN KEY (audience_id) REFERENCES audiences(id),
        FOREIGN KEY (group_id) REFERENCES groups(id)
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lessons_date ON lessons(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_lessons_group_date ON lessons(group_id, date);');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS uq_lessons_group_date_pair ON lessons(group_id, date, pair_no, subgroup);');
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
        notes TEXT,\r
              subgroup TEXT,\r
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
        notes TEXT,\r
              subgroup TEXT,\r
              FOREIGN KEY (department_id) REFERENCES departments(id)
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

    // ��������� ������� departments
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

    // ��������� ������� audience_types
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

    // ��������� ������� lesson_types
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

    // ������� lesson_rules
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

    // ������� equipments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      );
    ''');

    // ������� buildings
    await db.execute('''
      CREATE TABLE IF NOT EXISTS buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        description TEXT
      );
    ''');

    // ������� time_slots
    await db.execute('''
      CREATE TABLE IF NOT EXISTS time_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        description TEXT
      );
    ''');

    // ������� audience_equipments (����� ��������� - ������������)
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

    // ������� group_subject_teachers (����� ������-����������-�������������)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_subject_teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        discipline_id INTEGER NOT NULL,
        total_hours INTEGER NOT NULL,
        start_date TEXT,
        end_date TEXT,
        notes TEXT,\r
              subgroup TEXT,\r
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
    // Ensure common sync columns exist in tables we will sync
    final tables = ['audiences', 'groups', 'teachers', 'disciplines', 'departments', 'audience_types', 'lesson_types', 'lessons']; // ��������� lesson_types
    for (final t in tables) {
      final rows = await db.rawQuery('PRAGMA table_info($t)');
      final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();
      Future<void> add(String name, String ddl) async {
        if (!existing.contains(name.toLowerCase())) {
          await db.execute('ALTER TABLE $t ADD COLUMN $name $ddl;');
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

    await addColumn('capacity', 'INTEGER');
    await addColumn('audience_type_id', 'INTEGER');
    await addColumn('building_id', 'INTEGER');
    await addColumn('responsible_teacher_id', 'INTEGER');
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
        await db.execute('ALTER TABLE teachers ADD COLUMN ' + name + ' ' + ddl + ';');
      }
    }
    await add('department_id', 'INTEGER');
    await add('email', 'TEXT');
    await add('phone', 'TEXT');
    await add('notes', 'TEXT');
  }

  Future<void> _ensureDisciplineColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(disciplines)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();
    Future<void> add(String name, String ddl) async {
      if (!existing.contains(name.toLowerCase())) {
        await db.execute('ALTER TABLE disciplines ADD COLUMN ' + name + ' ' + ddl + ';');
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
  }}
