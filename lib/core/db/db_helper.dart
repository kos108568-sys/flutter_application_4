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
      version: 4,
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
        await _ensureSchema(db);
      },
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audiences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        boss TEXT,
        building TEXT,
        equipment TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS disciplines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        teacher TEXT,
        group_code TEXT,
        semester INTEGER,
        hours INTEGER DEFAULT 0,
        created_at INTEGER
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
        discipline_ids TEXT
      );
    ''');
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

    await _ensureGroupColumns(db);
    await _ensureTeacherColumns(db);
    await _ensureDisciplineColumns(db);
    await _ensureAudienceColumns(db);
    await _ensureSyncColumns(db);
  }

  Future<void> _ensureSyncColumns(Database db) async {
    // Ensure common sync columns exist in tables we will sync
    final tables = ['audiences', 'groups', 'teachers', 'disciplines'];
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

    await addColumn('type', 'TEXT');
    await addColumn('capacity', 'INTEGER');
    await addColumn('boss', 'TEXT');
    await addColumn('building', 'TEXT');
    await addColumn('equipment', 'TEXT');
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
  }

  Future<void> _ensureTeacherColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(teachers)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();
    if (!existing.contains('curator_group_id')) {
      await db.execute('ALTER TABLE teachers ADD COLUMN curator_group_id INTEGER;');
    }
    if (!existing.contains('department')) {
      await db.execute('ALTER TABLE teachers ADD COLUMN department TEXT;');
    }
  }

  Future<void> _ensureDisciplineColumns(Database db) async {
    final rows = await db.rawQuery('PRAGMA table_info(disciplines)');
    final existing = rows.map((row) => (row['name'] as String).toLowerCase()).toSet();
    if (!existing.contains('hours')) {
      await db.execute('ALTER TABLE disciplines ADD COLUMN hours INTEGER DEFAULT 0;');
    }
  }
}
