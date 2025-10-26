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
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audiences (
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
          CREATE TABLE disciplines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            teacher TEXT,
            group_code TEXT,
            semester INTEGER,
            created_at INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE groups (
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
          CREATE TABLE teachers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            curator_group_id INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE teacher_disciplines (
            teacher_id INTEGER NOT NULL,
            discipline_id INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE teacher_audiences (
            teacher_id INTEGER NOT NULL,
            audience_id INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            discipline_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            teacher_id INTEGER NOT NULL,
            audience_id INTEGER NOT NULL,
            group_id INTEGER NOT NULL,
            pair_no INTEGER NOT NULL,
            day_of_week INTEGER NOT NULL,
            date TEXT NOT NULL,
            subgroup TEXT
          );
        ''');
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
            CREATE TABLE IF NOT EXISTS lessons (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              discipline_id INTEGER NOT NULL,
              type TEXT NOT NULL,
              teacher_id INTEGER NOT NULL,
              audience_id INTEGER NOT NULL,
              group_id INTEGER NOT NULL,
              pair_no INTEGER NOT NULL,
              day_of_week INTEGER NOT NULL,
              date TEXT NOT NULL,
              subgroup TEXT
            );
          ''');
        }
      },
    );
  }
}
