import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'group_model.dart';

class GroupsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(GroupModel group) async {
    final db = await _db;
    final id = await db.insert('groups', group.toMap()..remove('id'));
    await _replaceSubjects(db, id, group.subjectIds);
    return id;
  }

  Future<int> update(GroupModel group) async {
    if (group.id == null) return 0;
    final db = await _db;
    final result = await db.update(
      'groups',
      group.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [group.id],
    );
    await _replaceSubjects(db, group.id!, group.subjectIds);
    return result;
  }

  Future<int> delete(int id) async {
    final db = await _db;
    await db.delete('group_subjects', where: 'group_id = ?', whereArgs: [id]);
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GroupModel>> getAll({String? search, String orderBy = 'g.name ASC'}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('(g.name LIKE ? OR IFNULL(g.speciality, "") LIKE ? OR IFNULL(g.department, "") LIKE ? OR IFNULL(t.full_name, "") LIKE ?)');
      final query = '%${search.trim()}%';
      args..add(query)..add(query)..add(query)..add(query);
    }
    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT g.*, t.full_name AS curator_name
      FROM groups g
      LEFT JOIN teachers t ON t.id = g.curator_id
      $whereSql
      ORDER BY $orderBy
    ''', args);
    return _hydrateGroups(db, rows);
  }

  Future<List<GroupModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT g.*, t.full_name AS curator_name
      FROM groups g
      LEFT JOIN teachers t ON t.id = g.curator_id
      ORDER BY g.id DESC
      LIMIT ?
    ''', [limit]);
    return _hydrateGroups(db, rows);
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM groups')) ?? 0;
    if (count > 0) return;
    final samples = [
      GroupModel(name: 'ПО-42', studentCount: 30, course: 2, speciality: 'Программная инженерия', department: 'ИТ', subjectIds: const []),
      GroupModel(name: 'ПО-41', studentCount: 28, course: 2, speciality: 'Программная инженерия', department: 'ИТ', subjectIds: const []),
    ];
    for (final group in samples) {
      await insert(group);
    }
  }

  Future<void> _replaceSubjects(Database db, int groupId, List<int> subjectIds) async {
    await db.delete('group_subjects', where: 'group_id = ?', whereArgs: [groupId]);
    final ids = subjectIds.toSet().where((id) => id > 0);
    for (final subjectId in ids) {
      await db.insert('group_subjects', {'group_id': groupId, 'subject_id': subjectId});
    }
  }

  Future<List<GroupModel>> _hydrateGroups(Database db, List<Map<String, Object?>> rows) async {
    final groupIds = rows.map((row) => row['id']).whereType<int>().toList();
    final subjectsMap = await _subjectsByGroup(db, groupIds);
    return rows
        .map((row) => GroupModel.fromMap(
              row,
              subjectIds: subjectsMap[row['id']] ?? const <int>[],
            ))
        .toList();
  }

  Future<Map<int, List<int>>> _subjectsByGroup(Database db, List<int> groupIds) async {
    if (groupIds.isEmpty) return {};
    final placeholders = List.filled(groupIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT group_id, subject_id FROM group_subjects WHERE group_id IN ($placeholders)',
      groupIds,
    );
    final map = <int, List<int>>{};
    for (final row in rows) {
      final groupId = row['group_id'] as int;
      final subjectId = row['subject_id'] as int;
      map.putIfAbsent(groupId, () => <int>[]).add(subjectId);
    }
    return map;
  }
}
