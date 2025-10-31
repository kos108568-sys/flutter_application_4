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

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _groupsRepo = GroupsRepository();
  final _discRepo = DisciplinesRepository();
  final _teachersRepo = TeachersRepository();
  final _gstRepo = GroupSubjectTeachersRepository();

  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  List<Discipline> _allDisc = [];
  List<Teacher> _teachers = [];
  final Set<int> _selectedDiscIds = {};
  int? _selectedCuratorId;
  final List<GroupSubjectTeacher> _assignments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Ensure teachers/disciplines are synced so IDs align with remote (FK safety)
    try { await _teachersRepo.syncTeachers(); } catch (_) {}
    try { await _discRepo.syncDisciplines(); } catch (_) {}
    final discs = await _discRepo.getAllDisciplines(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAllTeachers(orderBy: 'full_name ASC');
    if (!mounted) return;
    setState(() {
      _allDisc = discs;
      _teachers = teachers.where((t) => t.id != null).toList();
    });
  }

  Future<void> _save() async {
    final model = GroupModel(
      name: _nameCtrl.text.trim(),
      size: int.tryParse(_sizeCtrl.text.trim()),
      curator: null,
      course: int.tryParse(_courseCtrl.text.trim()),
      specialty: _specialtyCtrl.text.trim().isEmpty ? null : _specialtyCtrl.text.trim(),
      disciplineIds: _selectedDiscIds.toList(),
      curatorTeacherId: _selectedCuratorId,
      studentCount: int.tryParse(_sizeCtrl.text.trim()),
    );
    final groupId = await _groupsRepo.insertGroup(model);
    // Insert GST rows after group exists remotely; make best-effort and continue
    // Batch insert assignments for this group
    final batchItems = _assignments
        .map((a) => GroupSubjectTeacher(
              groupId: groupId,
              teacherId: a.teacherId,
              disciplineId: a.disciplineId,
              totalHours: a.totalHours,
              startDate: a.startDate,
              endDate: a.endDate,
              notes: a.notes,
            ))
        .toList();
    await _gstRepo.insertManyForGroup(groupId, batchItems);
    try { await _gstRepo.syncGST(); } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Группа сохранена')));
    _nameCtrl.clear();
    _sizeCtrl.clear();
    _courseCtrl.clear();
    _specialtyCtrl.clear();
    setState(() {
      _selectedDiscIds.clear();
      _selectedCuratorId = null;
      _assignments.clear();
    });
  }

  Future<void> _openAddAssignmentDialog() async {
    final res = await showDialog<GroupSubjectTeacher>(
      context: context,
      builder: (ctx) => _AssignmentDialog(
        disciplines: _allDisc.where((d) => d.id != null).toList(),
        teachers: _teachers.where((t) => t.id != null).toList(),
        gstRepo: _gstRepo,
        teachersRepo: _teachersRepo,
      ),
    );
    if (res != null) {
      setState(() => _assignments.add(res));
    }
  }

  // curator name helper no longer used

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _courseCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Группы'),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 820),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Добавление группы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Название группы'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _specialtyCtrl,
                            decoration: const InputDecoration(labelText: 'Специальность'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _selectedCuratorId,
                            decoration: const InputDecoration(labelText: 'Куратор (преподаватель)'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                              ..._teachers.map(
                                (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                              ),
                            ],
                            onChanged: (value) => setState(() => _selectedCuratorId = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _sizeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Количество студентов'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _courseCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Курс'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Предметы', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allDisc.map((d) {
                        final selected = d.id != null && _selectedDiscIds.contains(d.id);
                        return FilterChip(
                          label: Text(d.name),
                          selected: selected,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (val) {
                            setState(() {
                              if (d.id == null) return;
                              if (val) {
                                _selectedDiscIds.add(d.id!);
                              } else {
                                _selectedDiscIds.remove(d.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Назначения предметов (преподаватель, часы, даты)', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextButton.icon(onPressed: _openAddAssignmentDialog, icon: const Icon(Icons.add), label: const Text('Добавить')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._assignments.map((a) {
                      final discName = _allDisc.firstWhere((d) => d.id == a.disciplineId, orElse: () => Discipline(name: 'Неизвестно')).name;
                      final teacherName = _teachers.firstWhere((t) => t.id == a.teacherId, orElse: () => Teacher(fullName: 'Неизвестно')).fullName;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('$discName — $teacherName, ${a.totalHours} ч.  ${a.startDate ?? ''} — ${a.endDate ?? ''}')),
                            IconButton(
                              tooltip: 'Удалить',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(() => _assignments.remove(a)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _save,
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
        ],
      ),
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  final List<Discipline> disciplines;
  final List<Teacher> teachers;
  final GroupSubjectTeachersRepository gstRepo;
  final TeachersRepository teachersRepo;

  const _AssignmentDialog({required this.disciplines, required this.teachers, required this.gstRepo, required this.teachersRepo});

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  int? _disciplineId;
  int? _teacherId;
  final _hoursCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  List<Teacher> _filteredTeachers = [];
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    _filteredTeachers = widget.teachers;
    _hoursCtrl.text = '2';
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

    Future<void> _onDisciplineChanged(int? id) async {
    setState(() {
      _disciplineId = id;
      _teacherId = null;
      _filteredTeachers = widget.teachers;
    });
    if (id != null) {
      final byDisc = await widget.teachersRepo.getTeachersByDiscipline(id);
      setState(() {
        final ids = byDisc.map((t) => t.id).whereType<int>().toSet();
        _filteredTeachers = widget.teachers.where((t) => t.id != null && ids.contains(t.id)).toList();
      });
    }
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final v = await showDatePicker(context: context, initialDate: _start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (v != null) setState(() => _start = v);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final v = await showDatePicker(context: context, initialDate: _end ?? _start ?? now, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (v != null) setState(() => _end = v);
  }

  void _submit() {
    setState(() => _triedSubmit = true);
    final hours = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
    if (_disciplineId == null || _teacherId == null || hours <= 0) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните дисциплину, преподавателя и корректные часы')));
      } catch (_) {}
      return;
    }
    final fmt = (DateTime? d) => d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    Navigator.pop(context, GroupSubjectTeacher(
      groupId: 0, // будет заменено вызывающей стороной после insert группы
      teacherId: _teacherId!,
      disciplineId: _disciplineId!,
      totalHours: hours,
      startDate: fmt(_start),
      endDate: fmt(_end),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавить назначение предмета', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Дисциплина',
                errorText: _triedSubmit && _disciplineId == null ? 'Выберите дисциплину' : null,
              ),
              isExpanded: true,
              value: _disciplineId,
              items: [
                for (final d in widget.disciplines)
                  if (d.id != null) DropdownMenuItem<int>(value: d.id, child: Text(d.name)),
              ],
              onChanged: _onDisciplineChanged,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Дисциплина',
                errorText: _triedSubmit && _disciplineId == null ? 'Выберите дисциплину' : null,
              ),
              isExpanded: true,
              value: _teacherId,
              items: [
                for (final t in _filteredTeachers)
                  if (t.id != null) DropdownMenuItem<int>(value: t.id, child: Text(t.fullName)),
              ],
              onChanged: (v) => setState(() => _teacherId = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hoursCtrl,
              decoration: InputDecoration(
                labelText: 'Часы',
                errorText: _triedSubmit && (int.tryParse(_hoursCtrl.text.trim()) ?? 0) <= 0 ? 'Укажите положительное число часов' : null,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _pickStart, child: Text(_start == null ? 'Дата начала' : '${_start!.day.toString().padLeft(2, '0')}.${_start!.month.toString().padLeft(2, '0')}.${_start!.year}'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: _pickEnd, child: Text(_end == null ? 'Дата окончания' : '${_end!.day.toString().padLeft(2, '0')}.${_end!.month.toString().padLeft(2, '0')}.${_end!.year}'))),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _submit, child: const Text('Добавить')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




