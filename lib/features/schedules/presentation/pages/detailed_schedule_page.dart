import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../data/lesson_model.dart';
import '../../data/lessons_repository.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../disciplines/data/discipline_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../audiences/data/audiences_repository.dart';
import '../../../audiences/data/audience_model.dart';
import '../../../groups/data/groups_repository.dart';
import '../../../groups/data/group_model.dart';
import '../../../gst/data/group_subject_teachers_repository.dart';
import '../../../gst/data/group_subject_teacher_model.dart';
import 'package:flutter/services.dart';

class DetailedSchedulePage extends StatefulWidget {
  const DetailedSchedulePage({Key? key}) : super(key: key);
  @override
  State<DetailedSchedulePage> createState() => _DetailedSchedulePageState();
}

class _DetailedSchedulePageState extends State<DetailedSchedulePage> {
  final lessonsRepo = LessonsRepository();
  final disciplinesRepo = DisciplinesRepository();
  final teachersRepo = TeachersRepository();
  final audiencesRepo = AudiencesRepository();
  final groupsRepo = GroupsRepository();
  final gstRepo = GroupSubjectTeachersRepository();

  final times = ['08:00 - 09:30', '09:40 - 11:10', '11:20 - 12:50', '13:10 - 14:40', '14:50 - 16:20'];
  final lessonTypes = ['Лекция', 'Практика', 'Лабораторная', 'Семинар'];
  final colors = [Colors.blue[100], Colors.yellow[100], Colors.green[100], Colors.pink[100], Colors.purple[100], Colors.orange[100], Colors.cyan[100]];

  DateTime currentWeekStart = DateTime.now();
  DateTime? selectedDate;
  int selectedGroupId = 0;
  bool isEditMode = false;

  List<LessonModel> lessons = [];
  List<String> daysOfWeek = [];
  List<Discipline> allDisciplines = [];
  List<Teacher> allTeachers = [];
  List<Audience> allAudiences = [];
  List<GroupModel> allGroups = [];
  List<GroupSubjectTeacher> assignments = [];
  
  // Search & drag
  String searchQuery = '';
  int? draggingCardIndex;

  ScrollController _horizontalController = ScrollController();
  ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _initializeData();
  }

  Future<void> _initializeData() async {
    await groupsRepo.seedIfEmpty();
    await disciplinesRepo.seedIfEmpty();
    await teachersRepo.seedIfEmpty();
    await audiencesRepo.seedIfEmpty();

    allGroups = await groupsRepo.getAllGroups(orderBy: 'name ASC');
    allDisciplines = await disciplinesRepo.getAllDisciplines(orderBy: 'name ASC');
    allTeachers = await teachersRepo.getAllTeachers(orderBy: 'full_name ASC');
    allAudiences = await audiencesRepo.getAllAudiences(orderBy: 'name ASC');

    if (allGroups.isNotEmpty) {
      selectedGroupId = allGroups.first.id ?? 0;
    }

    // Generate demo only on first run
    final existingLessons = await lessonsRepo.getAll();
    if (existingLessons.isEmpty) {
      await lessonsRepo.generateDemoData();
    }
    
    await _loadLessons();
  }

  Future<void> _loadLessons() async {
    lessons = await lessonsRepo.getAll(weekStart: currentWeekStart, groupId: selectedGroupId);
    _updateDaysOfWeek();
    setState(() {});
  }

  void _updateDaysOfWeek() {
    daysOfWeek = List.generate(6, (i) {
      final date = currentWeekStart.add(Duration(days: i));
      final monthNames = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
      return '${dayNames[i]} ${date.day} ${monthNames[date.month - 1]}';
    });
    selectedDate = currentWeekStart.add(Duration(days: DateTime.now().weekday - 1));
  }

  void _previousWeek() {
    setState(() => currentWeekStart = currentWeekStart.subtract(const Duration(days: 7)));
    _loadLessons();
  }

  void _nextWeek() {
    setState(() => currentWeekStart = currentWeekStart.add(const Duration(days: 7)));
    _loadLessons();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            const SidebarMenu(selected: 'Расписание'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildScheduleTable(),
                    ),
                  ],
                ),
                           ),
           ),
         ],
       ),
     ),
    
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateSchedule,
        icon: const Icon(Icons.auto_mode_rounded),
        label: const Text('Сгенерировать'),
      ));
   }

    Widget _buildTopBar() {
    return Row(
      children: [
        Builder(
          builder: (context) {
            final controller = TextEditingController();
            if (selectedGroupId != 0) {
              controller.text = allGroups.firstWhere((g) => g.id == selectedGroupId, orElse: () => GroupModel(name: '', disciplineIds: [])).name;
            }
            return SizedBox(
              width: 200,
              child: Autocomplete<int>(
                displayStringForOption: (value) => allGroups.firstWhere((g) => g.id == value).name,
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return allGroups.map((g) => g.id ?? 0);
                  }
                  return allGroups
                      .where((g) => g.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                      .map((g) => g.id ?? 0)
                      .toList();
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  focusNode.addListener(() {
                    if (focusNode.hasFocus) {
                      // Очищаем поле при фокусе
                      textEditingController.clear();
                    } else {
                      // Если не было выбора, восстанавливаем исходное значение
                      if (selectedGroupId != 0 && allGroups.firstWhere((g) => g.id == selectedGroupId, orElse: () => GroupModel(name: '', disciplineIds: [])).name != textEditingController.text) {
                        if (selectedGroupId != 0) {
                          textEditingController.text = allGroups.firstWhere((g) => g.id == selectedGroupId).name;
                        }
                      }
                    }
                  });
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Группа',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  );
                },
                onSelected: (value) {
                  setState(() {
                    selectedGroupId = value;
                    FocusScope.of(context).unfocus();
                  });
                  _loadLessons();
                },
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: _previousWeek),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: currentWeekStart, firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (date != null) {
              setState(() => currentWeekStart = date.subtract(Duration(days: date.weekday - 1)));
              _loadLessons();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('${currentWeekStart.day.toString().padLeft(2, '0')}.${currentWeekStart.month.toString().padLeft(2, '0')}.${currentWeekStart.year}',
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), onPressed: _nextWeek),
        const SizedBox(width: 12),
        IconButton(icon: const Icon(Icons.download), tooltip: 'Выгрузить в календарь', onPressed: () {}),
        const SizedBox(width: 12),
        Flexible(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isEditMode ? Colors.red[200] : Colors.amber[200]),
            onPressed: () => setState(() => isEditMode = !isEditMode),
            child: FittedBox(child: Text(isEditMode ? 'Выйти из редактирования' : 'Режим редактирования')),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTable() {
    if (daysOfWeek.isEmpty) return const Center(child: CircularProgressIndicator());
    return Expanded(
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(900, daysOfWeek.length * 220),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 52),
                  ...List.generate(daysOfWeek.length, (idx) {
                    final today = DateTime.now();
                    final cellDate = currentWeekStart.add(Duration(days: idx));
                    final isSelected = today.year == cellDate.year && today.month == cellDate.month && today.day == cellDate.day;
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isSelected ? Colors.blue[50] : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(daysOfWeek[idx],
                              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.blueAccent : Colors.black)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _verticalController,
                  itemCount: times.length,
                  itemBuilder: (context, pairIdx) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      alignment: Alignment.topCenter,
                      margin: const EdgeInsets.only(top: 22),
                      child: Column(
                        children: [
                          Text('${pairIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(times[pairIdx], style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                                         ...List.generate(daysOfWeek.length, (dayIdx) {
                       final lessonsForCell = lessons.where((l) => l.pairNo == pairIdx && l.dayOfWeek == dayIdx).toList();
                       return Expanded(
                         child: _buildLessonSlot(lessonsForCell, pairIdx, dayIdx),
                       );
                     })
                  ],
                ),
              );
                                           },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonSlot(List<LessonModel> lessonsForCell, int pairIdx, int dayIdx) {
    if (lessonsForCell.isEmpty) {
      return DragTarget<LessonModel>(
        onAccept: (draggedLesson) {
          _moveLesson(draggedLesson, pairIdx, dayIdx);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(5),
            constraints: const BoxConstraints(minHeight: 76),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? Colors.blue[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.blue : Colors.blueGrey.withOpacity(0.09),
                width: candidateData.isNotEmpty ? 3 : 1,
              ),
            ),
            child: _buildEmptyCell(pairIdx, dayIdx),
          );
        },
      );
    }

    final isEditModeDraggable = isEditMode && lessonsForCell.isNotEmpty;
    
    return DragTarget<LessonModel>(
      onWillAccept: (data) => false,
      builder: (context, candidateData, rejectedData) {
        final lesson = lessonsForCell.first;
        final cardColor = colors[lessonTypes.indexOf(lesson.type) % colors.length]!;
        
        if (!isEditModeDraggable) {
          return _buildLessonCardWithColor(lesson, pairIdx, dayIdx, cardColor);
        }

        return LongPressDraggable<LessonModel>(
          data: lesson,
          feedback: Container(
            width: 180,
            child: Container(
              margin: const EdgeInsets.all(5),
              constraints: const BoxConstraints(minHeight: 76),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.09)),
              ),
              child: _buildLessonCardContent(lesson),
            ),
          ),
          childWhenDragging: Container(
            margin: const EdgeInsets.all(5),
            constraints: const BoxConstraints(minHeight: 76),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.09)),
            ),
            child: const Center(child: Icon(Icons.remove, color: Colors.grey)),
          ),
          child: _buildLessonCardWithColor(lesson, pairIdx, dayIdx, cardColor),
        );
      },
    );
  }

  Future<void> _generateSchedule() async {
    if (selectedGroupId == 0) return;
    try { assignments = await gstRepo.getByGroup(selectedGroupId); } catch (_) { assignments = []; }
    if (assignments.isEmpty) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет назначений для группы')));
      return;
    }

    // Load all lessons for the current week (all groups) to check conflicts
    List<LessonModel> weekLessonsAll = await lessonsRepo.getAll(weekStart: currentWeekStart);

    bool teacherBusy(int d, int p, int tid) => weekLessonsAll.any((l) => l.dayOfWeek == d && l.pairNo == p && l.teacherId == tid);
    bool groupBusy(int d, int p, int gid) => weekLessonsAll.any((l) => l.dayOfWeek == d && l.pairNo == p && l.groupId == gid);
    bool audienceBusy(int d, int p, int aid) => weekLessonsAll.any((l) => l.dayOfWeek == d && l.pairNo == p && l.audienceId == aid);

    final pairsPerDay = times.length.clamp(4, 6);
    int rr = 0;

    for (int dayIdx = 0; dayIdx < 6; dayIdx++) {
      for (int pairIdx = 0; pairIdx < pairsPerDay; pairIdx++) {
        if (groupBusy(dayIdx, pairIdx, selectedGroupId)) continue;
        final date = currentWeekStart.add(Duration(days: dayIdx));
        bool placed = false;
        for (int k = 0; k < assignments.length; k++) {
          final a = assignments[(rr + k) % assignments.length];
          final aStart = a.startDate == null ? null : DateTime.tryParse(a.startDate!);
          final aEnd = a.endDate == null ? null : DateTime.tryParse(a.endDate!);
          if (aStart != null && date.isBefore(aStart)) continue;
          if (aEnd != null && date.isAfter(aEnd)) continue;
          if (teacherBusy(dayIdx, pairIdx, a.teacherId)) continue;

          int? freeAud;
          for (final aud in allAudiences) {
            final aid = aud.id;
            if (aid == null) continue;
            if (!audienceBusy(dayIdx, pairIdx, aid)) { freeAud = aid; break; }
          }
          if (freeAud == null) continue;

          final lesson = LessonModel(
            disciplineId: a.disciplineId,
            type: lessonTypes.first,
            teacherId: a.teacherId,
            audienceId: freeAud,
            groupId: selectedGroupId,
            pairNo: pairIdx,
            dayOfWeek: dayIdx,
            date: date,
            subgroup: '1 подгруппа',
          );
          try {
            await lessonsRepo.insertWithSync(lesson);
            weekLessonsAll.add(lesson);
            rr = (rr + k + 1) % assignments.length;
            placed = true;
            break;
          } catch (_) {}
        }
        if (!placed) {
          // no feasible option; leave empty
        }
      }
    }

    await _loadLessons();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Расписание сгенерировано')));
  }

  Widget _buildLessonCardWithColor(LessonModel lesson, int pairIdx, int dayIdx, Color cardColor) {
    return Container(
      margin: const EdgeInsets.all(5),
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.09)),
      ),
      child: _buildLessonCard(lesson, pairIdx, dayIdx),
    );
  }

  Widget _buildEmptyCell(int pairIdx, int dayIdx) {
    if (!isEditMode) return const Center(child: Icon(Icons.add, color: Colors.grey));
    return InkWell(
      onTap: () => _showAddEditDialog(pairIdx, dayIdx),
      child: const Center(child: Icon(Icons.add, color: Colors.grey)),
    );
  }

  Widget _buildLessonCardContent(LessonModel lesson) {
    final discipline = allDisciplines.firstWhere((d) => d.id == lesson.disciplineId, orElse: () => Discipline(name: 'Неизвестно'));
    final teacher = allTeachers.firstWhere((t) => t.id == lesson.teacherId, orElse: () => Teacher(fullName: 'Неизвестно'));
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(discipline.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(lesson.type, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(teacher.fullName, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

    Widget _buildLessonCard(LessonModel lesson, int pairIdx, int dayIdx) {
    final discipline = allDisciplines.firstWhere((d) => d.id == lesson.disciplineId, orElse: () => Discipline(name: 'Неизвестно'));
    final teacher = allTeachers.firstWhere((t) => t.id == lesson.teacherId, orElse: () => Teacher(fullName: 'Неизвестно'));
    final audience = allAudiences.firstWhere((a) => a.id == lesson.audienceId, orElse: () => Audience(name: 'Неизвестно'));

    return IgnorePointer(
      ignoring: !isEditMode,
      child: GestureDetector(
        onTap: () {
          if (isEditMode) {
            _showAddEditDialog(pairIdx, dayIdx, lesson);
          }
        },
        child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: Colors.primaries[lessonTypes.indexOf(lesson.type) % Colors.primaries.length], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(discipline.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  ],
                ),
                Text(lesson.type, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 1),
                Row(children: [const Icon(Icons.person, size: 15, color: Colors.black54), const SizedBox(width: 4), Expanded(child: Text(teacher.fullName, style: const TextStyle(fontSize: 11)))]),
                Row(children: [const Icon(Icons.meeting_room, size: 15, color: Colors.black54), const SizedBox(width: 4), Expanded(child: Text(audience.name, style: const TextStyle(fontSize: 11)))]),
                Row(children: [const Icon(Icons.group, size: 15, color: Colors.black54), const SizedBox(width: 4), Expanded(child: Text(lesson.subgroup, style: const TextStyle(fontSize: 11)))]),
              ],
            ),
          ),
          if (isEditMode)
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => _deleteLesson(lesson.id!),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Future<void> _moveLesson(LessonModel lesson, int newPairNo, int newDayOfWeek) async {
    final newDate = currentWeekStart.add(Duration(days: newDayOfWeek));
    final updated = LessonModel(
      id: lesson.id,
      disciplineId: lesson.disciplineId,
      type: lesson.type,
      teacherId: lesson.teacherId,
      audienceId: lesson.audienceId,
      groupId: lesson.groupId,
      pairNo: newPairNo,
      dayOfWeek: newDayOfWeek,
      date: newDate,
      subgroup: lesson.subgroup,
    );
    await lessonsRepo.update(updated);
    await _loadLessons();
  }

  void _deleteLesson(int id) async {
    await lessonsRepo.delete(id);
    await _loadLessons();
  }

  Future<void> _showAddEditDialog(int pairIdx, int dayIdx, [LessonModel? existingLesson]) async {
    int? disciplineId = existingLesson?.disciplineId;
    String lessonType = existingLesson?.type ?? lessonTypes.first;
    int? teacherId = existingLesson?.teacherId;
    int? audienceId = existingLesson?.audienceId;
    String subgroup = existingLesson?.subgroup ?? 'Вся группа';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Text('Пара ${pairIdx + 1}: ${times[pairIdx]}'),
            ],
          ),
                                                             content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Дисциплина *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final controller = TextEditingController();
                      if (disciplineId != null) {
                        controller.text = allDisciplines.firstWhere((d) => d.id == disciplineId).name;
                      }
                      return Autocomplete<int>(
                        displayStringForOption: (value) => allDisciplines.firstWhere((d) => d.id == value).name,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return allDisciplines.map((d) => d.id ?? 0);
                          }
                          return allDisciplines
                              .where((d) => d.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                              .map((d) => d.id ?? 0);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          focusNode.addListener(() {
                            if (focusNode.hasFocus) {
                              // Очищаем поле при фокусе
                              textEditingController.clear();
                            } else {
                              // Если не было выбора, восстанавливаем исходное значение
                              if (disciplineId == null || allDisciplines.firstWhere((d) => d.id == disciplineId, orElse: () => Discipline(name: '')).name != textEditingController.text) {
                                if (disciplineId != null) {
                                  textEditingController.text = allDisciplines.firstWhere((d) => d.id == disciplineId).name;
                                }
                              }
                            }
                          });
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Выберите дисциплину',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          );
                        },
                        onSelected: (value) {
                          setDialogState(() {
                            disciplineId = value;
                            FocusScope.of(context).unfocus();
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Тип *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: lessonType,
                    decoration: InputDecoration(
                      hintText: 'Выберите тип',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    isExpanded: true,
                    items: lessonTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => lessonType = v ?? lessonTypes.first),
                  ),
                  const SizedBox(height: 16),
                  Text('Преподаватель *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final controller = TextEditingController();
                      if (teacherId != null) {
                        controller.text = allTeachers.firstWhere((t) => t.id == teacherId).fullName;
                      }
                      return Autocomplete<int>(
                        displayStringForOption: (value) => allTeachers.firstWhere((t) => t.id == value).fullName,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return allTeachers.map((t) => t.id ?? 0);
                          }
                          return allTeachers
                              .where((t) => t.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                              .map((t) => t.id ?? 0);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          focusNode.addListener(() {
                            if (focusNode.hasFocus) {
                              // Очищаем поле при фокусе
                              textEditingController.clear();
                            } else {
                              // Если не было выбора, восстанавливаем исходное значение
                              if (teacherId == null || allTeachers.firstWhere((t) => t.id == teacherId, orElse: () => Teacher(fullName: '')).fullName != textEditingController.text) {
                                if (teacherId != null) {
                                  textEditingController.text = allTeachers.firstWhere((t) => t.id == teacherId).fullName;
                                }
                              }
                            }
                          });
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Выберите преподавателя',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          );
                        },
                                                 onSelected: (value) {
                           setDialogState(() {
                             teacherId = value;
                             FocusScope.of(context).unfocus();
                           });
                         },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Аудитория *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final controller = TextEditingController();
                      if (audienceId != null) {
                        controller.text = allAudiences.firstWhere((a) => a.id == audienceId).name;
                      }
                      return Autocomplete<int>(
                        displayStringForOption: (value) => allAudiences.firstWhere((a) => a.id == value).name,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return allAudiences.map((a) => a.id ?? 0);
                          }
                          return allAudiences
                              .where((a) => a.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                              .map((a) => a.id ?? 0);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          focusNode.addListener(() {
                            if (focusNode.hasFocus) {
                              // Очищаем поле при фокусе
                              textEditingController.clear();
                            } else {
                              // Если не было выбора, восстанавливаем исходное значение
                              if (audienceId == null || allAudiences.firstWhere((a) => a.id == audienceId, orElse: () => Audience(name: '')).name != textEditingController.text) {
                                if (audienceId != null) {
                                  textEditingController.text = allAudiences.firstWhere((a) => a.id == audienceId).name;
                                }
                              }
                            }
                          });
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Выберите аудиторию',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          );
                        },
                                                 onSelected: (value) {
                           setDialogState(() {
                             audienceId = value;
                             FocusScope.of(context).unfocus();
                           });
                         },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Группа/Подгруппа *', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: subgroup,
                    decoration: InputDecoration(
                      hintText: 'Выберите группу/подгруппу',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    isExpanded: true,
                    items: ['Вся группа', '1 подгруппа', '2 подгруппа'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => subgroup = v ?? 'Вся группа'),
                  ),
                 ],
               ),
             ),
           ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (disciplineId == null || teacherId == null || audienceId == null) return;
                final date = currentWeekStart.add(Duration(days: dayIdx));
                                 final lesson = LessonModel(
                   id: existingLesson?.id,
                   disciplineId: disciplineId!,
                   type: lessonType,
                   teacherId: teacherId!,
                   audienceId: audienceId!,
                   groupId: selectedGroupId,
                   pairNo: pairIdx,
                   dayOfWeek: dayIdx,
                   date: date,
                   subgroup: subgroup,
                 );
                if (existingLesson != null) {
                  await lessonsRepo.update(lesson);
                } else {
                  await lessonsRepo.insert(lesson);
                }
                await _loadLessons();
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
