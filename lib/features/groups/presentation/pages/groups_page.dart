import 'package:flutter/material.dart';

import '../../../../core/widgets/sidebar_menu.dart';
import '../../../disciplines/data/discipline_model.dart';
import '../../../disciplines/data/disciplines_repository.dart';
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
  final _discRepo = DisciplinesRepository();
  final _teachersRepo = TeachersRepository();

  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  List<DisciplineModel> _allDisc = [];
  List<TeacherModel> _teachers = [];
  final Set<int> _selectedDiscIds = {};
  int? _selectedCuratorId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final discs = await _discRepo.getAll(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAll(orderBy: 'full_name ASC');
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
      curator: _curatorNameById(_selectedCuratorId),
      course: int.tryParse(_courseCtrl.text.trim()),
      specialty: _specialtyCtrl.text.trim().isEmpty ? null : _specialtyCtrl.text.trim(),
      disciplineIds: _selectedDiscIds.toList(),
    );
    await _groupsRepo.insert(model);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Группа сохранена')));
    _nameCtrl.clear();
    _sizeCtrl.clear();
    _courseCtrl.clear();
    _specialtyCtrl.clear();
    setState(() {
      _selectedDiscIds.clear();
      _selectedCuratorId = null;
    });
  }

  String? _curatorNameById(int? id) {
    if (id == null) return null;
    try {
      return _teachers.firstWhere((t) => t.id == id).fullName;
    } catch (_) {
      return null;
    }
  }

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
