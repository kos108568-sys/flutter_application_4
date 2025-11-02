import 'package:flutter/material.dart';

import '../../../../core/widgets/sidebar_menu.dart';
import '../../../disciplines/data/discipline_model.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../data/group_model.dart';
import '../../data/groups_repository.dart';
import '../../../gst/data/group_subject_teacher_model.dart';
import '../../../gst/data/group_subject_teachers_repository.dart';
import '../widgets/group_card.dart';
import '../widgets/group_filter_bar.dart';
import '../widgets/recent_groups_widget.dart';
import 'groups_page.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupsRepo = GroupsRepository();
  final _teachersRepo = TeachersRepository();
  final _discRepo = DisciplinesRepository();
  final _gstRepo = GroupSubjectTeachersRepository();

  List<GroupModel> _all = [];
  List<GroupModel> _filtered = [];
  List<Teacher> _teachers = [];
  List<Discipline> _disciplines = [];
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try { await _groupsRepo.syncGroups(); } catch (_) {}
    try { await _teachersRepo.syncTeachers(); } catch (_) {}
    try { await _discRepo.syncDisciplines(); } catch (_) {}
    final groups = await _groupsRepo.getAllGroups(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAllTeachers(orderBy: 'full_name ASC');
    final discs = await _discRepo.getAllDisciplines(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      _all = groups;
      _filtered = List.of(groups);
      _teachers = teachers.where((t) => t.id != null).toList();
      _disciplines = discs;
    });
  }

  Future<void> _openCreateGroup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsPage()));
    await _init();
  }

  void _onFilterChanged(String q) {
    setState(() {
      final query = q.toLowerCase();
      _filtered = _all.where((g) {
        final curator = (g.curator ?? '').toLowerCase();
        final spec = (g.specialty ?? '').toLowerCase();
        return g.name.toLowerCase().contains(query) || curator.contains(query) || spec.contains(query);
      }).toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'size':
          _filtered.sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
          break;
        case 'course':
          _filtered.sort((a, b) => (a.course ?? 0).compareTo(b.course ?? 0));
          break;
        case 'name':
        default:
          _filtered.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _onViewChanged(bool grid) => setState(() => _isGrid = grid);

  String? _disciplinesLineFor(GroupModel g) {
    if (g.disciplineIds.isEmpty) return null;
    final names = <String>[];
    for (final id in g.disciplineIds) {
      final d = _disciplines.firstWhere(
        (e) => e.id == id,
        orElse: () => Discipline(name: ''),
      );
      if (d.name.isNotEmpty) names.add(d.name);
    }
    return names.isEmpty ? null : names.join(', ');
  }

  Future<void> _editGroup(GroupModel g) async {
    final nameCtrl = TextEditingController(text: g.name);
    final sizeCtrl = TextEditingController(text: (g.size ?? '').toString());
    final courseCtrl = TextEditingController(text: (g.course ?? '').toString());
    final specialtyCtrl = TextEditingController(text: g.specialty ?? '');
    int? curatorId = g.curatorTeacherId;

    final assignments = <GroupSubjectTeacher>[];
    if (g.id != null) {
      try { assignments.addAll(await _gstRepo.getByGroup(g.id!)); } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setDialog) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Редактировать группу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: specialtyCtrl, decoration: const InputDecoration(labelText: 'Специальность'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>
                        (initialValue: curatorId,
                        decoration: const InputDecoration(labelText: 'Куратор (преподаватель)') ,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                          ..._teachers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName))).toList(),
                        ],
                        onChanged: (v) => setDialog(() => curatorId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: sizeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Количество студентов'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: courseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Курс'))),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Назначения (предмет, преподаватель, часы, период, подгруппа)'),
                      TextButton.icon(
                        onPressed: () async {
                          if (g.id == null) return;
                          final item = await _showAssignmentDialog(g.id!, null);
                          if (item != null) setDialog(() => assignments.add(item));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...assignments.asMap().entries.map((e) {
                    final a = e.value; final idx = e.key;
                    final discName = _disciplines.firstWhere((d) => d.id == a.disciplineId, orElse: () => Discipline(name: 'Неизвестно')).name;
                    final teacherName = _teachers.firstWhere((t) => t.id == a.teacherId, orElse: () => Teacher(fullName: 'Неизвестно')).fullName;
                    final sg = (a.subgroup == '1') ? '1 подгруппа' : (a.subgroup == '2') ? '2 подгруппа' : 'Вся группа';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(children: [
                        Expanded(child: Text('$discName — $teacherName, ${a.totalHours} ч, ${a.startDate ?? ''} – ${a.endDate ?? ''}, $sg')),
                        IconButton(
                          tooltip: 'Изменить',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            if (g.id == null) return;
                            final updated = await _showAssignmentDialog(g.id!, a);
                            if (updated != null) setDialog(() => assignments[idx] = updated);
                          },
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setDialog(() => assignments.removeAt(idx)),
                        ),
                      ]),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          g.name = nameCtrl.text.trim();
                          g.curatorTeacherId = curatorId;
                          g.studentCount = int.tryParse(sizeCtrl.text.trim());
                          g.course = int.tryParse(courseCtrl.text.trim());
                          g.specialty = specialtyCtrl.text.trim().isEmpty ? null : specialtyCtrl.text.trim();
                          g.disciplineIds = assignments.map((a) => a.disciplineId).whereType<int>().toSet().toList();
                          Navigator.pop(ctx);
                          await _groupsRepo.updateGroup(g);
                          if (g.id != null) { try { await _gstRepo.replaceForGroup(g.id!, assignments); } catch (_) {} }
                          await _init();
                        },
                        child: const Text('Сохранить'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<GroupSubjectTeacher?> _showAssignmentDialog(int groupId, GroupSubjectTeacher? current) async {
    int? disciplineId = current?.disciplineId;
    int? teacherId = current?.teacherId;
    final hoursCtrl = TextEditingController(text: (current?.totalHours ?? 2).toString());
    DateTime? start = current?.startDate == null ? null : DateTime.tryParse(current!.startDate!);
    DateTime? end = current?.endDate == null ? null : DateTime.tryParse(current!.endDate!);
    String subgroup = current?.subgroup ?? 'all';
    List<Teacher> filteredTeachers = _teachers;

    Future<void> _refreshTeachers() async {
      if (disciplineId != null) {
        try {
          final byDisc = await _teachersRepo.getTeachersByDiscipline(disciplineId!);
          final ids = byDisc.map((t) => t.id).whereType<int>().toSet();
          filteredTeachers = _teachers.where((t) => t.id != null && ids.contains(t.id)).toList();
        } catch (_) { filteredTeachers = _teachers; }
      } else {
        filteredTeachers = _teachers;
      }
    }
    await _refreshTeachers();

    return showDialog<GroupSubjectTeacher>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current == null ? 'Добавить назначение' : 'Изменить назначение', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Дисциплина'),
                  isExpanded: true,
                  value: disciplineId,
                  items: [ for (final d in _disciplines) if (d.id != null) DropdownMenuItem<int>(value: d.id, child: Text(d.name)) ],
                  onChanged: (v) async { disciplineId = v; teacherId = null; await _refreshTeachers(); setDialog((){}); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Преподаватель'),
                  isExpanded: true,
                  value: teacherId,
                  items: [ for (final t in filteredTeachers) if (t.id != null) DropdownMenuItem<int>(value: t.id, child: Text(t.fullName)) ],
                  onChanged: (v) => setDialog(() => teacherId = v),
                ),
                const SizedBox(height: 8),
                TextField(controller: hoursCtrl, decoration: const InputDecoration(labelText: 'Часы'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Подгруппа'),
                  value: subgroup,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Вся группа')),
                    DropdownMenuItem(value: '1', child: Text('1 подгруппа')),
                    DropdownMenuItem(value: '2', child: Text('2 подгруппа')),
                  ],
                  onChanged: (v) => setDialog(() => subgroup = v ?? 'all'),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final v = await showDatePicker(context: context, initialDate: start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                        if (v != null) setDialog(() => start = v);
                      },
                      child: Text(start == null ? 'Дата начала' : '${start!.day.toString().padLeft(2, '0')}.${start!.month.toString().padLeft(2, '0')}.${start!.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final v = await showDatePicker(context: context, initialDate: end ?? start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                        if (v != null) setDialog(() => end = v);
                      },
                      child: Text(end == null ? 'Дата окончания' : '${end!.day.toString().padLeft(2, '0')}.${end!.month.toString().padLeft(2, '0')}.${end!.year}'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final hours = int.tryParse(hoursCtrl.text.trim()) ?? 0;
                        if (disciplineId == null || teacherId == null || hours <= 0) return;
                        String? fmt(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                        Navigator.pop(
                          ctx,
                          GroupSubjectTeacher(
                            id: current?.id,
                            groupId: groupId,
                            teacherId: teacherId!,
                            disciplineId: disciplineId!,
                            totalHours: hours,
                            startDate: fmt(start),
                            endDate: fmt(end),
                            subgroup: subgroup,
                          ),
                        );
                      },
                      child: Text(current == null ? 'Добавить' : 'Сохранить'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Groups'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Список групп', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GroupFilterBar(
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                          onViewChanged: _onViewChanged,
                          isGridView: _isGrid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _openCreateGroup,
                        icon: const Icon(Icons.add),
                        label: const Text('Создать группу'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isGrid
                        ? GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final item = _filtered[i];
                              final line = _disciplinesLineFor(item);
                              return GroupCard(
                                group: item,
                                disciplinesLine: line,
                                onTap: () => _editGroup(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = _filtered[i];
                              final line = _disciplinesLineFor(item);
                              return GroupCard(
                                group: item,
                                disciplinesLine: line,
                                onTap: () => _editGroup(item),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const SingleChildScrollView(
                child: Column(children: [RecentGroupsWidget()]),
              ),
            ),
          )
        ],
      ),
    );
  }
}

