import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../../subjects/data/subject_model.dart';
import '../../../subjects/data/subjects_repository.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../data/group_model.dart';
import '../../data/groups_repository.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _groupsRepo = GroupsRepository();
  final _subjectsRepo = SubjectsRepository();
  final _teachersRepo = TeachersRepository();

  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();

  List<SubjectModel> _subjects = [];
  List<TeacherModel> _teachers = [];
  final Set<int> _selectedSubjectIds = {};
  int? _curatorId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _subjectsRepo.getAll(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAll(orderBy: 'full_name ASC');
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _teachers = teachers;
    });
  }

  Future<void> _save() async {
    final model = GroupModel(
      name: _nameCtrl.text.trim(),
      studentCount: int.tryParse(_sizeCtrl.text.trim()),
      course: int.tryParse(_courseCtrl.text.trim()),
      speciality: _specialtyCtrl.text.trim().isEmpty ? null : _specialtyCtrl.text.trim(),
      department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
      curatorId: _curatorId,
      subjectIds: _selectedSubjectIds.toList(),
    );
    await _groupsRepo.insert(model);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Группа сохранена')));
    _nameCtrl.clear();
    _sizeCtrl.clear();
    _courseCtrl.clear();
    _specialtyCtrl.clear();
    _departmentCtrl.clear();
    setState(() {
      _selectedSubjectIds.clear();
      _curatorId = null;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _courseCtrl.dispose();
    _specialtyCtrl.dispose();
    _departmentCtrl.dispose();
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                            value: _curatorId,
                            decoration: const InputDecoration(labelText: 'Куратор (преподаватель)'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                              ..._teachers
                                  .where((t) => t.id != null)
                                  .map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)))
                            ],
                            onChanged: (value) => setState(() => _curatorId = value),
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
                        Expanded(
                          child: TextField(
                            controller: _departmentCtrl,
                            decoration: const InputDecoration(labelText: 'Кафедра'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Предметы', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects.map((subject) {
                        final selected = subject.id != null && _selectedSubjectIds.contains(subject.id);
                        return FilterChip(
                          label: Text(subject.name),
                          selected: selected,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (val) {
                            setState(() {
                              if (subject.id == null) return;
                              if (val) {
                                _selectedSubjectIds.add(subject.id!);
                              } else {
                                _selectedSubjectIds.remove(subject.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
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
        ],
      ),
    );
  }
}
