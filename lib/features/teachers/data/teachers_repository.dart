import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import '../../groups/data/group_model.dart';
import '../../subjects/data/subject_model.dart';
import '../../audiences/data/audiences_item_model.dart';
import 'teacher_model.dart';

class TeachersRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(TeacherModel teacher) async {
    final db = await _db;
    final id = await db.insert('teachers', {'full_name': teacher.fullName});
    await _replaceSubjects(db, id, teacher.subjectIds);
    await _assignCuratedGroups(db, id, teacher.curatorGroupIds);
    await _assignAudiences(db, id, teacher.audienceIds);
    return id;
  }

  Future<int> update(TeacherModel teacher) async {
    if (teacher.id == null) return 0;
    final db = await _db;
    final result = await db.update(
      'teachers',
      {'full_name': teacher.fullName},
      where: 'id = ?',
      whereArgs: [teacher.id],
    );
    await _replaceSubjects(db, teacher.id!, teacher.subjectIds);
    await _assignCuratedGroups(db, teacher.id!, teacher.curatorGroupIds);
    await _assignAudiences(db, teacher.id!, teacher.audienceIds);
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    await db.delete('teacher_subjects', where: 'teacher_id = ?', whereArgs: [id]);
    await db.update('groups', {'curator_id': null}, where: 'curator_id = ?', whereArgs: [id]);
    await db.update('audiences', {'head_teacher_id': null}, where: 'head_teacher_id = ?', whereArgs: [id]);
    return db.delete('teachers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TeacherModel>> getAll({String? search, String orderBy = 'full_name ASC'}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('full_name LIKE ?');
      args.add('%${search.trim()}%');
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('SELECT * FROM teachers $whereSql ORDER BY $orderBy', args);
    return _rowsToTeachers(db, rows);
  }

  Future<List<TeacherModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM teachers ORDER BY id DESC LIMIT ?', [limit]);
    return _rowsToTeachers(db, rows);
  }

  Future<List<TeacherModel>> _rowsToTeachers(Database db, List<Map<String, Object?>> rows) async {
    final list = <TeacherModel>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final subjects = await db.rawQuery('SELECT subject_id FROM teacher_subjects WHERE teacher_id = ?', [id]);
      final groups = await db.rawQuery('SELECT id FROM groups WHERE curator_id = ?', [id]);
      final audiences = await db.rawQuery('SELECT id FROM audiences WHERE head_teacher_id = ?', [id]);
      list.add(TeacherModel(
        id: id,
        fullName: row['full_name'] as String,
        subjectIds: subjects.map((e) => (e['subject_id'] as int)).toList(),
        curatorGroupIds: groups.map((e) => (e['id'] as int)).toList(),
        audienceIds: audiences.map((e) => (e['id'] as int)).toList(),
      ));
    }
    return list;
  }

  Future<List<GroupModel>> groups() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT g.*, t.full_name AS curator_name
      FROM groups g
      LEFT JOIN teachers t ON t.id = g.curator_id
      ORDER BY g.name ASC
    ''');
    return rows.map((e) => GroupModel.fromMap(e)).toList();
  }

  Future<List<SubjectModel>> subjects() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM subjects ORDER BY name ASC');
    return rows.map(SubjectModel.fromMap).toList();
  }

  Future<List<AudiencesItemModel>> audiences() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT a.*, t.full_name AS head_teacher_name, at.type_name
      FROM audiences a
      LEFT JOIN teachers t ON t.id = a.head_teacher_id
      LEFT JOIN audience_types at ON at.id = a.type_id
      ORDER BY a.name ASC
    ''');
    return rows.map((e) => AudiencesItemModel.fromMap(e)).toList();
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teachers')) ?? 0;
    if (count > 0) return;
    await db.insert('teachers', {'full_name': 'Селивёрстов К. О.'});
    await db.insert('teachers', {'full_name': 'Иванова Е. А.'});
  }

  Future<void> _replaceSubjects(Database db, int teacherId, List<int> subjectIds) async {
    await db.delete('teacher_subjects', where: 'teacher_id = ?', whereArgs: [teacherId]);
    final ids = subjectIds.toSet().where((id) => id > 0);
    for (final subjectId in ids) {
      await db.insert('teacher_subjects', {'teacher_id': teacherId, 'subject_id': subjectId});
    }
  }

  Future<void> _assignCuratedGroups(Database db, int teacherId, List<int> groupIds) async {
    final ids = groupIds.toSet().where((id) => id > 0).toList();
    if (ids.isEmpty) {
      await db.update('groups', {'curator_id': null}, where: 'curator_id = ?', whereArgs: [teacherId]);
      return;
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'groups',
      {'curator_id': null},
      where: 'curator_id = ? AND id NOT IN ($placeholders)',
      whereArgs: [teacherId, ...ids],
    );
    for (final groupId in ids) {
      await db.update('groups', {'curator_id': teacherId}, where: 'id = ?', whereArgs: [groupId]);
    }
  }

  Future<void> _assignAudiences(Database db, int teacherId, List<int> audienceIds) async {
    final ids = audienceIds.toSet().where((id) => id > 0).toList();
    if (ids.isEmpty) {
      await db.update('audiences', {'head_teacher_id': null}, where: 'head_teacher_id = ?', whereArgs: [teacherId]);
      return;
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'audiences',
      {'head_teacher_id': null},
      where: 'head_teacher_id = ? AND id NOT IN ($placeholders)',
      whereArgs: [teacherId, ...ids],
    );
    for (final audienceId in ids) {
      await db.update('audiences', {'head_teacher_id': teacherId}, where: 'id = ?', whereArgs: [audienceId]);
    }
  }
}
