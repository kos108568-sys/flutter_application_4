class LessonModel {
  int? id;
  final int disciplineId;
  final String type; // 'Лекция', 'Практика', 'Лабораторная', 'Семинар'
  final int teacherId;
  final int audienceId;
  final int groupId;
  final int pairNo; // 0-4 (1-5 пара)
  final int dayOfWeek; // 0-5 (Пн-Сб)
  final DateTime date;
  final String subgroup; // '1 подгруппа', '2 подгруппа' и т.д.

  LessonModel({
    this.id,
    required this.disciplineId,
    required this.type,
    required this.teacherId,
    required this.audienceId,
    required this.groupId,
    required this.pairNo,
    required this.dayOfWeek,
    required this.date,
    this.subgroup = '1 подгруппа',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'discipline_id': disciplineId,
        'type': type,
        'teacher_id': teacherId,
        'audience_id': audienceId,
        'group_id': groupId,
        'pair_no': pairNo,
        'day_of_week': dayOfWeek,
        'date': date.toIso8601String(),
        'subgroup': subgroup,
      };

  factory LessonModel.fromMap(Map<String, dynamic> map) => LessonModel(
        id: map['id'] as int?,
        disciplineId: map['discipline_id'] as int,
        type: map['type'] as String,
        teacherId: map['teacher_id'] as int,
        audienceId: map['audience_id'] as int,
        groupId: map['group_id'] as int,
        pairNo: map['pair_no'] as int,
        dayOfWeek: map['day_of_week'] as int,
        date: DateTime.parse(map['date'] as String),
        subgroup: map['subgroup'] as String? ?? '1 подгруппа',
      );
}
