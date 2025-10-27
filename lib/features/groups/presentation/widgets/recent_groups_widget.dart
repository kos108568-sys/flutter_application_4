import 'package:flutter/material.dart';

import '../../../disciplines/data/discipline_model.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../data/group_model.dart';
import '../../data/groups_repository.dart';

class RecentGroupsWidget extends StatefulWidget {
  const RecentGroupsWidget({super.key});

  @override
  State<RecentGroupsWidget> createState() => _RecentGroupsWidgetState();
}

class _RecentGroupsWidgetState extends State<RecentGroupsWidget> {
  final _groupsRepo = GroupsRepository();
  final _teachersRepo = TeachersRepository();
  final _discRepo = DisciplinesRepository();

  List<GroupModel> _items = [];
  List<TeacherModel> _teachers = [];
  List<DisciplineModel> _disciplines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _groupsRepo.seedIfEmpty();
    final items = await _groupsRepo.getRecent(limit: 5);
    final teachers = await _teachersRepo.getAll(orderBy: 'full_name ASC');
    final discs = await _discRepo.getAll(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      _items = items;
      _teachers = teachers;
      _disciplines = discs;
    });
  }

  Future<void> _openAddModal() async {
    final result = await showDialog<GroupModel>(
      context: context,
      builder: (ctx) => _AddGroupDialog(
        teachers: _teachers,
        disciplines: _disciplines,
      ),
    );
    if (result != null) {
      await _groupsRepo.insert(result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nedavnie gruppy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final g in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.group, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Kurator: ${g.curator ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dobavit\''),
            ),
          )
        ],
      ),
    );
  }
}

class _AddGroupDialog extends StatefulWidget {
  final List<TeacherModel> teachers;
  final List<DisciplineModel> disciplines;

  const _AddGroupDialog({
    required this.teachers,
    required this.disciplines,
  });

  @override
  State<_AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<_AddGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _course = TextEditingController();
  final _specialty = TextEditingController();
  int? _selectedCuratorId;
  final Set<int> _selectedDisciplineIds = {};

  List<TeacherModel> get _teachersWithId => widget.teachers.where((t) => t.id != null).toList();
  List<DisciplineModel> get _disciplinesWithId => widget.disciplines.where((d) => d.id != null).toList();

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _course.dispose();
    _specialty.dispose();
    super.dispose();
  }

  Future<void> _openSelectSubjects() async {
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _SelectSubjectsDialog(
        disciplines: _disciplinesWithId,
        initiallySelected: _selectedDisciplineIds,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedDisciplineIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final curatorName = _selectedCuratorId == null
        ? null
        : _teachersWithId.firstWhere((t) => t.id == _selectedCuratorId!).fullName;
    final model = GroupModel(
      name: _name.text.trim(),
      size: int.tryParse(_size.text.trim()),
      curator: curatorName,
      course: int.tryParse(_course.text.trim()),
      specialty: _specialty.text.trim().isEmpty ? null : _specialty.text.trim(),
      disciplineIds: _selectedDisciplineIds.toList(),
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Novaya gruppa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nazvanie'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nazvanie obyazatelno' : null,
                ),
                TextFormField(
                  controller: _specialty,
                  decoration: const InputDecoration(labelText: 'Specialnost'),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedCuratorId,
                  decoration: const InputDecoration(labelText: 'Kurator (prepodavatel)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Ne naznachen')),
                    ..._teachersWithId.map(
                      (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedCuratorId = value),
                ),
                const SizedBox(height: 12),
                const Text('Predmety', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _openSelectSubjects,
                      child: const Text("Vybrat' predmety"),
                    ),
                    const SizedBox(width: 12),
                    Text('Vybrano: ' + _selectedDisciplineIds.length.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _size,
                        decoration: const InputDecoration(labelText: 'Kolichestvo studentov'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _course,
                        decoration: const InputDecoration(labelText: 'Kurs'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _submit, child: const Text('Sohranit\'')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectSubjectsDialog extends StatefulWidget {
  final List<DisciplineModel> disciplines;
  final Set<int> initiallySelected;
  const _SelectSubjectsDialog({required this.disciplines, required this.initiallySelected});

  @override
  State<_SelectSubjectsDialog> createState() => _SelectSubjectsDialogState();
}

class _SelectSubjectsDialogState extends State<_SelectSubjectsDialog> {
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
    final items = widget.disciplines
        .where((d) => d.id != null && d.name.toLowerCase().contains(_q.toLowerCase()))
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
              const Text('Vybor predmetov', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Poisk predmetov...'),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final d = items[i];
                    final sel = _selected.contains(d.id);
                    return CheckboxListTile(
                      value: sel,
                      title: Text(d.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (d.id == null) return;
                          if (val == true) {
                            _selected.add(d.id!);
                          } else {
                            _selected.remove(d.id);
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
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otmena')),
                  const SizedBox(width: 12),
                  ElevatedButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Gotovo')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

