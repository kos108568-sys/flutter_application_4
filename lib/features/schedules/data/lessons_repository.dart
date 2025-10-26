import 'package:sqflite/sqflite.dart';
import '../../../core/db/db_helper.dart';
import 'lesson_model.dart';

class LessonsRepository {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<int> insert(LessonModel lesson) async {
    final db = await _db;
    return await db.insert('lessons', lesson.toMap()..remove('id'));
  }

  Future<int> update(LessonModel lesson) async {
    if (lesson.id == null) return 0;
    final db = await _db;
    return await db.update('lessons', lesson.toMap()..remove('id'), where: 'id = ?', whereArgs: [lesson.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LessonModel>> getAll({DateTime? weekStart, int? groupId}) async {
    final db = await _db;
    String where = '';
    List<Object?> args = [];
    if (weekStart != null) {
      where = 'WHERE date >= ? AND date < ?';
      final weekEnd = weekStart.add(const Duration(days: 7));
      args = [weekStart.toIso8601String(), weekEnd.toIso8601String()];
    }
    if (groupId != null) {
      where += where.isEmpty ? 'WHERE group_id = ?' : ' AND group_id = ?';
      args.add(groupId);
    }
    final rows = await db.rawQuery('SELECT * FROM lessons $where ORDER BY date, pair_no', args);
    return rows.map((e) => LessonModel.fromMap(e)).toList();
  }

  Future<void> generateDemoData() async {
    final db = await _db;
    await db.delete('lessons');

    final disciplines = await db.rawQuery('SELECT id, name, teacher FROM disciplines');
    final teachers = await db.rawQuery('SELECT id, full_name FROM teachers');
    final audiences = await db.rawQuery('SELECT id, name FROM audiences');
    final groups = await db.rawQuery('SELECT id, name FROM groups');

    if (disciplines.isEmpty || teachers.isEmpty || audiences.isEmpty || groups.isEmpty) {
      return;
    }

    final lessonTypes = ['Лекция', 'Практика', 'Лабораторная', 'Семинар'];
    final typesForColor = lessonTypes;
    final subgroups = ['1 подгруппа', '2 подгруппа'];

    final baseDate = DateTime.now();
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));

    for (int week = 0; week < 2; week++) {
      final weekStart = monday.add(Duration(days: week * 7));
      for (int day = 0; day < 6; day++) {
        final date = weekStart.add(Duration(days: day));
        for (int pair = 0; pair < 5; pair++) {
          if ((day + pair) % 3 != 0) {
            final lesson = LessonModel(
              disciplineId: (disciplines[day % disciplines.length]['id'] as int),
              type: lessonTypes[pair % lessonTypes.length],
              teacherId: (teachers[day % teachers.length]['id'] as int),
              audienceId: (audiences[day % audiences.length]['id'] as int),
              groupId: (groups[0]['id'] as int),
              pairNo: pair,
              dayOfWeek: day,
              date: date,
              subgroup: subgroups[pair % subgroups.length],
            );
            await insert(lesson);
          }
        }
      }
    }
  }
}
