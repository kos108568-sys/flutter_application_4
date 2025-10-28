import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../data/teacher_model.dart';
import '../../data/teachers_repository.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_filter_bar.dart';
import '../widgets/recent_teachers_widget.dart';
import '../../../departments/data/department_repository.dart';
import '../../../departments/data/department_model.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../disciplines/data/discipline_model.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _repo = TeachersRepository();
  final _deptRepo = DepartmentRepository();
  final _discRepo = DisciplinesRepository();
  List<Teacher> all = [];
  List<Teacher> filtered = [];
  bool isGrid = true;
  Teacher? _selected;
  List<Department> _departments = [];
  List<Discipline> _disciplines = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    try {
      _departments = await _deptRepo.getAllDepartments(orderBy: 'name ASC');
    } catch (_) {}
    try {
      _disciplines = await _discRepo.getAllDisciplines(orderBy: 'name ASC');
    } catch (_) {}
    final items = await _repo.getAllTeachers(orderBy: 'full_name ASC');
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      if (_selected != null) {
        _selected = items.firstWhere((e) => e.id == _selected!.id, orElse: () => _selected!);
      }
    });
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all.where((e) => e.fullName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    });
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  Future<void> _openAddTeacher() async {
    final res = await showDialog<_TeacherResult>(
      context: context,
      builder: (ctx) => _TeacherDialog(departments: _departments, disciplines: _disciplines),
    );
    if (res != null) {
      final newId = await _repo.insertTeacherWithSync(res.teacher);
      await _repo.setTeacherDisciplines(newId, res.disciplineIds);
      await _init();
    }
  }

  Future<void> _openEditTeacher(Teacher t) async {
    final res = await showDialog<_TeacherResult>(
      context: context,
      builder: (ctx) => _TeacherDialog(existing: t, departments: _departments, disciplines: _disciplines),
    );
    if (res != null) {
      await _repo.updateTeacherWithSync(res.teacher);
      if (res.teacher.id != null) {
        await _repo.setTeacherDisciplines(res.teacher.id!, res.disciplineIds);
      }
      await _init();
    }
  }

  Future<void> _deleteTeacher(Teacher t) async {
    if (t.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Удалить преподавателя?'),
        content: Text('Вы уверены, что хотите удалить «${t.fullName}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteTeacherWithSync(t.id!);
      await _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Prepodavateli'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spisok prepodavatelei', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TeacherFilterBar(
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                          onViewChanged: _onViewChanged,
                          isGridView: isGrid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(onPressed: _openAddTeacher, icon: const Icon(Icons.add), label: const Text('Добавить')),
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
                              return GestureDetector(
                                onTap: () => setState(() => _selected = item),
                                child: TeacherCard(
                                  teacher: item,
                                  curatorGroupName: null,
                                  onTap: () => setState(() => _selected = item),
                                ),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return GestureDetector(
                                onTap: () => setState(() => _selected = item),
                                child: TeacherCard(
                                  teacher: item,
                                  curatorGroupName: null,
                                  onTap: () => setState(() => _selected = item),
                                ),
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
              child: SingleChildScrollView(
                child: _selected == null
                    ? const RecentTeachersWidget()
                    : _TeacherInfoPanel(
                        teacher: _selected!,
                        onEdit: () => _openEditTeacher(_selected!),
                        onDelete: () => _deleteTeacher(_selected!),
                        departmentName: _departments.firstWhere((d) => d.id == _selected!.departmentId, orElse: () => Department(name: '')).name,
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TeacherResult {
  final Teacher teacher;
  final List<int> disciplineIds;
  _TeacherResult(this.teacher, this.disciplineIds);
}

class _TeacherDialog extends StatefulWidget {
  final Teacher? existing;
  final List<Department> departments;
  final List<Discipline> disciplines;
  const _TeacherDialog({this.existing, required this.departments, required this.disciplines});

  @override
  State<_TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<_TeacherDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  int? _departmentId;
  final Set<int> _selectedDisciplineIds = {};

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.fullName;
      _email.text = e.email ?? '';
      _phone.text = e.phone ?? '';
      _notes.text = e.notes ?? '';
      _departmentId = e.departmentId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final base = Teacher(
      id: widget.existing?.id,
      fullName: _name.text.trim(),
      departmentId: _departmentId,
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.pop(context, _TeacherResult(base, _selectedDisciplineIds.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Добавить преподавателя' : 'Редактировать преподавателя', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'ФИО')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: _departmentId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Без отдела')),
                  ...widget.departments.where((d) => d.id != null).map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name))),
                ],
                decoration: const InputDecoration(labelText: 'Отдел'),
                onChanged: (v) => setState(() => _departmentId = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Телефон')),
              const SizedBox(height: 8),
              TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Заметки')),
              const SizedBox(height: 12),
              const Text('Дисциплины', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in widget.disciplines)
                    if (d.id != null)
                      FilterChip(
                        label: Text(d.name),
                        selected: _selectedDisciplineIds.contains(d.id),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedDisciplineIds.add(d.id!);
                            } else {
                              _selectedDisciplineIds.remove(d.id);
                            }
                          });
                        },
                      ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _submit, child: const Text('Сохранить')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherInfoPanel extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? departmentName;
  const _TeacherInfoPanel({required this.teacher, required this.onEdit, required this.onDelete, this.departmentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prepodavatel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(teacher.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (departmentName != null && departmentName!.isNotEmpty) Text('Отдел: $departmentName', style: const TextStyle(color: Colors.grey)),
          if (teacher.email != null && teacher.email!.isNotEmpty) Text('Email: ${teacher.email}', style: const TextStyle(color: Colors.grey)),
          if (teacher.phone != null && teacher.phone!.isNotEmpty) Text('Phone: ${teacher.phone}', style: const TextStyle(color: Colors.grey)),
          if (teacher.notes != null && teacher.notes!.isNotEmpty) Text('Notes: ${teacher.notes}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit), label: const Text('Редактировать')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline), label: const Text('Удалить')),
            ],
          )
        ],
      ),
    );
  }
}
