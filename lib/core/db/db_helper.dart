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
    return openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await _dropLegacyTables(db);
          await _createSchema(db);
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE audience_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL,
        description TEXT,
        equipment TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hours INTEGER NOT NULL DEFAULT 0,
        semester TEXT NOT NULL,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        curator_id INTEGER,
        student_count INTEGER,
        course INTEGER,
        speciality TEXT,
        department TEXT,
        FOREIGN KEY (curator_id) REFERENCES teachers (id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE audiences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        head_teacher_id INTEGER,
        building TEXT,
        equipment_list TEXT,
        FOREIGN KEY (type_id) REFERENCES audience_types (id) ON DELETE RESTRICT,
        FOREIGN KEY (head_teacher_id) REFERENCES teachers (id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE teacher_subjects (
        teacher_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        PRIMARY KEY (teacher_id, subject_id),
        FOREIGN KEY (teacher_id) REFERENCES teachers (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE group_subjects (
        group_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        PRIMARY KEY (group_id, subject_id),
        FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _dropLegacyTables(Database db) async {
    const tables = [
      'teacher_audiences',
      'teacher_disciplines',
      'group_subjects',
      'teacher_subjects',
      'audiences',
      'audience_types',
      'groups',
      'subjects',
      'disciplines',
      'teachers',
    ];
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table;');
    }
  }
}
