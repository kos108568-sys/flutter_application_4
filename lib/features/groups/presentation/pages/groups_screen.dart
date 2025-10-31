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
  final _repo = GroupsRepository();
  final _teachersRepo = TeachersRepository();
  final _discRepo = DisciplinesRepository();
  final _gstRepo = GroupSubjectTeachersRepository();

  List<GroupModel> all = [];
  List<GroupModel> filtered = [];
  List<Teacher> _teachers = [];
  List<Discipline> _disciplines = [];
  // removed unused _teacherNames map
  Map<int, List<String>> _discNamesByGroup = {};
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    try { await _repo.syncGroups(); } catch (_) {}
    final items = await _repo.getAllGroups(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAllTeachers(orderBy: 'full_name ASC');
    final discs = await _discRepo.getAllDisciplines(orderBy: 'name ASC');
    final gidList = items.where((g) => g.id != null).map((g) => g.id!).toList();
    final discNamesMap = await _discRepo.disciplineNamesByGroup(gidList);
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      _teachers = teachers.where((t) => t.id != null).toList();
      _disciplines = discs;
      _discNamesByGroup = discNamesMap;
    });
  }

  Future<void> _openCreateGroup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsPage()));
    await _init();
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all
          .where((e) =>
              e.name.toLowerCase().contains(q.toLowerCase()) ||
              (e.curator ?? '').toLowerCase().contains(q.toLowerCase()) ||
              (e.specialty ?? '').toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'size':
          filtered.sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
          break;
        case 'course':
          filtered.sort((a, b) => (a.course ?? 0).compareTo(b.course ?? 0));
          break;
        case 'name':
        default:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  int? _teacherIdByName(String? name) {
    if (name == null) return null;
    try {
      return _teachers.firstWhere((t) => t.fullName == name).id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _editGroup(GroupModel g) async {
    final name = TextEditingController(text: g.name);
    final size = TextEditingController(text: (g.size ?? '').toString());
    final course = TextEditingController(text: (g.course ?? '').toString());
    final specialty = TextEditingController(text: g.specialty ?? '');
    int? curatorId = g.curatorTeacherId ?? _teacherIdByName(g.curator);
    final selectedDisc = {...g.disciplineIds};
    final assignments = <GroupSubjectTeacher>[];
    if (g.id != null) {
      try {
        final current = await _gstRepo.getByGroup(g.id!);
        assignments.addAll(current);
      } catch (_) {}
    }

    Future<bool> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete group?'),
          content: Text('Are you sure you want to delete "${g.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
          ],
        ),
      );
      return ok ?? false;
    }

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('Edit group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: specialty, decoration: const InputDecoration(labelText: 'Specialty'))),
                  ]),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: curatorId,
                        decoration: const InputDecoration(labelText: 'Curator (teacher)'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Not assigned')),
                          ..._teachers.map(
                            (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                          ),
                        ],
                        onChanged: (val) => setStateDialog(() => curatorId = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: size,
                        decoration: const InputDecoration(labelText: 'Student count'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: course,
                        decoration: const InputDecoration(labelText: 'Course'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ]),
                  const SizedBox(height: 16),
                  // Assignments section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assignments (teacher, subject, hours, dates)'),
                      TextButton.icon(
                        onPressed: () async {
                          final newItem = await _showAddAssignmentDialogForEdit(g.id);
                          if (newItem != null) {
                            setStateDialog(() => assignments.add(newItem));
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...assignments.asMap().entries.map((e) {
                    final a = e.value;
                    final idx = e.key;
                    final discName = _disciplines.firstWhere(
                      (d) => d.id == a.disciplineId,
                      orElse: () => Discipline(name: 'Unknown'),
                    ).name;
                    final teacherName = _teachers.firstWhere(
                      (t) => t.id == a.teacherId,
                      orElse: () => Teacher(fullName: 'Unknown'),
                    ).fullName;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text('$discName - $teacherName, ${a.totalHours}h ${a.startDate ?? ''} ${a.endDate ?? ''}')),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              final updated = await _showEditAssignmentDialogForEdit(g.id, a);
                              if (updated != null) {
                                setStateDialog(() => assignments[idx] = updated);
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setStateDialog(() => assignments.remove(a)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          if (await confirmDelete()) {
                            Navigator.pop(ctx);
                            if (g.id != null) await _repo.deleteGroup(g.id!);
                            await _init();
                          }
                        },
                        child: const Text('Delete'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          g.name = name.text.trim();
                          g.curatorTeacherId = curatorId;
                          g.studentCount = int.tryParse(size.text.trim());
                          g.course = int.tryParse(course.text.trim());
                          g.specialty = specialty.text.trim().isEmpty ? null : specialty.text.trim();
                          g.disciplineIds = assignments.map((a) => a.disciplineId).whereType<int>().toSet().toList();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      )
                    ],
                  )
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
    await _repo.updateGroup(g);
    if (g.id != null) {
      try {
        await _gstRepo.replaceForGroup(g.id!, assignments);
      } catch (_) {}
    }
    await _init();
  }

  Future<GroupSubjectTeacher?> _showAddAssignmentDialogForEdit(int? groupId) async {
    if (groupId == null) return null;
    int? disciplineId;
    int? teacherId;
    final hoursCtrl = TextEditingController(text: '2');
    DateTime? start;
    DateTime? end;
    List<Teacher> filteredTeachers = _teachers;

    Future<void> onDisciplineChanged(int? id) async {
      disciplineId = id;
      teacherId = null;
      filteredTeachers = _teachers;
      if (id != null) {
        try {
          final byDisc = await _teachersRepo.getTeachersByDiscipline(id);
          final ids = byDisc.map((t) => t.id).whereType<int>().toSet();
          filteredTeachers = _teachers.where((t) => t.id != null && ids.contains(t.id)).toList();
        } catch (_) {}
      }
    }

    return showDialog<GroupSubjectTeacher>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Discipline'),
                    isExpanded: true,
                    value: disciplineId,
                    items: [
                      for (final d in _disciplines)
                        if (d.id != null) DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
                    ],
                    onChanged: (v) async {
                      await onDisciplineChanged(v);
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    isExpanded: true,
                    value: teacherId,
                    items: [
                      for (final t in filteredTeachers)
                        if (t.id != null) DropdownMenuItem<int>(value: t.id, child: Text(t.fullName)),
                    ],
                    onChanged: (v) => setStateDialog(() => teacherId = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hoursCtrl,
                    decoration: const InputDecoration(labelText: 'Hours'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final v = await showDatePicker(context: context, initialDate: start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (v != null) setStateDialog(() => start = v);
                        },
                        child: Text(start == null ? 'Start date' : '${start!.day.toString().padLeft(2, '0')}.${start!.month.toString().padLeft(2, '0')}.${start!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final v = await showDatePicker(context: context, initialDate: end ?? start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (v != null) setStateDialog(() => end = v);
                        },
                        child: Text(end == null ? 'End date' : '${end!.day.toString().padLeft(2, '0')}.${end!.month.toString().padLeft(2, '0')}.${end!.year}'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final hours = int.tryParse(hoursCtrl.text.trim()) ?? 0;
                          if (disciplineId == null || teacherId == null || hours <= 0) return;
                          String? fmt(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          Navigator.pop(
                            ctx,
                            GroupSubjectTeacher(
                              groupId: groupId,
                              teacherId: teacherId!,
                              disciplineId: disciplineId!,
                              totalHours: hours,
                              startDate: fmt(start),
                              endDate: fmt(end),
                            ),
                          );
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<GroupSubjectTeacher?> _showEditAssignmentDialogForEdit(int? groupId, GroupSubjectTeacher current) async {
    if (groupId == null) return null;
    int? disciplineId = current.disciplineId;
    int? teacherId = current.teacherId;
    final hoursCtrl = TextEditingController(text: current.totalHours.toString());
    DateTime? start = current.startDate == null ? null : DateTime.tryParse(current.startDate!);
    DateTime? end = current.endDate == null ? null : DateTime.tryParse(current.endDate!);
    List<Teacher> filteredTeachers = _teachers;

    Future<void> refreshTeachers() async {
      if (disciplineId != null) {
        try {
          final byDisc = await _teachersRepo.getTeachersByDiscipline(disciplineId!);
          final ids = byDisc.map((t) => t.id).whereType<int>().toSet();
          filteredTeachers = _teachers.where((t) => t.id != null && ids.contains(t.id)).toList();
        } catch (_) {}
      } else {
        filteredTeachers = _teachers;
      }
    }
    await refreshTeachers();

    return showDialog<GroupSubjectTeacher>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          Future<void> onDisciplineChanged(int? v) async {
            disciplineId = v;
            teacherId = null;
            await refreshTeachers();
            setStateDialog(() {});
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Discipline'),
                    isExpanded: true,
                    value: disciplineId,
                    items: [
                      for (final d in _disciplines)
                        if (d.id != null) DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
                    ],
                    onChanged: onDisciplineChanged,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    isExpanded: true,
                    value: teacherId,
                    items: [
                      for (final t in filteredTeachers)
                        if (t.id != null) DropdownMenuItem<int>(value: t.id, child: Text(t.fullName)),
                    ],
                    onChanged: (v) => setStateDialog(() => teacherId = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hoursCtrl,
                    decoration: const InputDecoration(labelText: 'Hours'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final v = await showDatePicker(context: context, initialDate: start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (v != null) setStateDialog(() => start = v);
                        },
                        child: Text(start == null ? 'Start date' : '${start!.day.toString().padLeft(2, '0')}.${start!.month.toString().padLeft(2, '0')}.${start!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final v = await showDatePicker(context: context, initialDate: end ?? start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (v != null) setStateDialog(() => end = v);
                        },
                        child: Text(end == null ? 'End date' : '${end!.day.toString().padLeft(2, '0')}.${end!.month.toString().padLeft(2, '0')}.${end!.year}'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final hours = int.tryParse(hoursCtrl.text.trim()) ?? 0;
                          if (disciplineId == null || teacherId == null || hours <= 0) return;
                          String? fmt(DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          Navigator.pop(
                            ctx,
                            GroupSubjectTeacher(
                              groupId: groupId,
                              teacherId: teacherId!,
                              disciplineId: disciplineId!,
                              totalHours: hours,
                              startDate: fmt(start),
                              endDate: fmt(end),
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
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
                  const Text('Groups list', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GroupFilterBar(
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                          onViewChanged: _onViewChanged,
                          isGridView: isGrid,
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
                    child: isGrid
                        ? GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final names = (item.id != null) ? (_discNamesByGroup[item.id!] ?? const <String>[]) : const <String>[];
                              final line = names.isEmpty ? null : names.join(', ');
                              return GroupCard(
                                group: item,
                                disciplinesLine: line,
                                onTap: () => _editGroup(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final names = (item.id != null) ? (_discNamesByGroup[item.id!] ?? const <String>[]) : const <String>[];
                              final line = names.isEmpty ? null : names.join(', ');
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
                child: Column(
                  children: [
                    RecentGroupsWidget(),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SelectableItem {
  final int id;
  final String name;
  _SelectableItem(this.id, this.name);
}

class _SelectItemsDialog extends StatefulWidget {
  final String title;
  final String hint;
  final List<_SelectableItem> items;
  final Set<int> initiallySelected;

  const _SelectItemsDialog({
    required this.title,
    required this.hint,
    required this.items,
    required this.initiallySelected,
  });

  @override
  State<_SelectItemsDialog> createState() => _SelectItemsDialogState();
}

class _SelectItemsDialogState extends State<_SelectItemsDialog> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.items
        .where((it) => it.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: widget.hint),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final it = list[i];
                    final sel = _selected.contains(it.id);
                    return CheckboxListTile(
                      value: sel,
                      title: Text(it.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selected.add(it.id);
                          } else {
                            _selected.remove(it.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Done')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

