import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'subject_model.dart';

class SubjectsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<List<SubjectModel>> getAll({
    String? search,
    String? semester,
    String orderBy = 'name ASC',
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (semester != null && semester.trim().isNotEmpty) {
      where.add('semester = ?');
      args.add(semester.trim());
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('SELECT * FROM subjects $whereSql ORDER BY $orderBy', args);
    return rows.map(SubjectModel.fromMap).toList();
  }

  Future<List<SubjectModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT * FROM subjects ORDER BY COALESCE(created_at, 0) DESC LIMIT ?',
      [limit],
    );
    return rows.map(SubjectModel.fromMap).toList();
  }

  Future<int> insert(SubjectModel subject) async {
    final db = await _db;
    return db.insert('subjects', subject.toMap()..remove('id'));
  }

  Future<int> update(SubjectModel subject) async {
    if (subject.id == null) return 0;
    final db = await _db;
    return db.update(
      'subjects',
      subject.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM subjects')) ?? 0;
    if (count > 0) return;
    final samples = <SubjectModel>[
      SubjectModel(name: 'Алгебра и геометрия', hours: 72, semester: '1'),
      SubjectModel(name: 'Объектно-ориентированное программирование', hours: 108, semester: '2'),
      SubjectModel(name: 'Проектная деятельность', hours: 54, semester: 'year'),
    ];
    for (final subject in samples) {
      await insert(subject);
    }
  }
}
