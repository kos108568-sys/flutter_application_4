import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import '../../groups/data/group_model.dart';
import '../../disciplines/data/discipline_model.dart';
import '../../audiences/data/audiences_item_model.dart';
import 'teacher_model.dart';

class TeachersRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(TeacherModel t) async {
    final db = await _db;
    final id = await db.insert('teachers', {
      'full_name': t.fullName,
      'curator_group_id': t.curatorGroupId
    });
    await _replaceLinks(db, id, t.disciplineIds, t.audienceIds);
    return id;
  }

  Future<int> update(TeacherModel t) async {
    if (t.id == null) return 0;
    final db = await _db;
    final res = await db.update('teachers', {
      'full_name': t.fullName,
      'curator_group_id': t.curatorGroupId
    }, where: 'id = ?', whereArgs: [t.id]);
    await _replaceLinks(db, t.id!, t.disciplineIds, t.audienceIds);
    return res;
  }

  Future<void> _replaceLinks(Database db, int teacherId, List<int> discIds, List<int> audIds) async {
    await db.delete('teacher_disciplines', where: 'teacher_id = ?', whereArgs: [teacherId]);
    await db.delete('teacher_audiences', where: 'teacher_id = ?', whereArgs: [teacherId]);
    for (final d in discIds) {
      await db.insert('teacher_disciplines', {'teacher_id': teacherId, 'discipline_id': d});
    }
    for (final a in audIds) {
      await db.insert('teacher_audiences', {'teacher_id': teacherId, 'audience_id': a});
    }
  }

  Future<int> delete(int id) async {
    final db = await _db;
    await db.delete('teacher_disciplines', where: 'teacher_id = ?', whereArgs: [id]);
    await db.delete('teacher_audiences', where: 'teacher_id = ?', whereArgs: [id]);
    return db.delete('teachers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TeacherModel>> getAll({String? search, String orderBy = 'full_name ASC'}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];
    if (search != null && search.trim().isNotEmpty) {
      where = 'WHERE full_name LIKE ?';
      args = ['%${search.trim()}%'];
    }
    final rows = await db.rawQuery('SELECT * FROM teachers $where ORDER BY $orderBy', args);
    final List<TeacherModel> list = [];
    for (final r in rows) {
      final id = (r['id'] as int);
      final discRows = await db.rawQuery('SELECT discipline_id FROM teacher_disciplines WHERE teacher_id = ?', [id]);
      final audRows = await db.rawQuery('SELECT audience_id FROM teacher_audiences WHERE teacher_id = ?', [id]);
      list.add(TeacherModel(
        id: id,
        fullName: (r['full_name'] as String),
        curatorGroupId: r['curator_group_id'] as int?,
        disciplineIds: discRows.map((e) => (e['discipline_id'] as int)).toList(),
        audienceIds: audRows.map((e) => (e['audience_id'] as int)).toList(),
      ));
    }
    return list;
  }

  Future<List<TeacherModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM teachers ORDER BY id DESC LIMIT ?', [limit]);
    return rows.map((r) => TeacherModel(
      id: r['id'] as int?,
      fullName: r['full_name'] as String,
      curatorGroupId: r['curator_group_id'] as int?,
      disciplineIds: const [],
      audienceIds: const [],
    )).toList();
  }

  // Helpers to populate selections
  Future<List<GroupModel>> groups() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM groups ORDER BY name ASC');
    return rows.map((e) => GroupModel.fromMap(e)).toList();
  }

  Future<List<DisciplineModel>> disciplines() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM disciplines ORDER BY name ASC');
    return rows.map((e) => DisciplineModel.fromMap(e)).toList();
  }

  Future<List<AudiencesItemModel>> audiences() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT * FROM audiences ORDER BY name ASC');
    return rows.map((e) => AudiencesItemModel.fromMap(e)).toList();
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teachers')) ?? 0;
    if (count > 0) return;
    await db.insert('teachers', {'full_name': 'Селивёрстов К. О.', 'curator_group_id': null});
  }
}

