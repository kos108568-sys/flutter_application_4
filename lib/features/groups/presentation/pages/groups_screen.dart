import 'package:flutter/material.dart';

import '../../../../core/widgets/sidebar_menu.dart';
import '../../../disciplines/data/discipline_model.dart';
import '../../../disciplines/data/disciplines_repository.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../data/group_model.dart';
import '../../data/groups_repository.dart';
import '../widgets/group_card.dart';
import '../widgets/group_filter_bar.dart';
import '../widgets/recent_groups_widget.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _repo = GroupsRepository();
  final _teachersRepo = TeachersRepository();
  final _discRepo = DisciplinesRepository();

  List<GroupModel> all = [];
  List<GroupModel> filtered = [];
  List<TeacherModel> _teachers = [];
  List<DisciplineModel> _disciplines = [];
  Map<int, String> _teacherNames = {};
  Map<int, List<String>> _discNamesByGroup = {};
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAll(orderBy: 'name ASC');
    final teachers = await _teachersRepo.getAll(orderBy: 'full_name ASC');
    final discs = await _discRepo.getAll(orderBy: 'name ASC');
    final gidList = items.where((g) => g.id != null).map((g) => g.id!).toList();
    final discNamesMap = await _discRepo.disciplineNamesByGroup(gidList);
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      _teachers = teachers.where((t) => t.id != null).toList();
      _disciplines = discs;
      _teacherNames = {for (final t in _teachers) t.id!: t.fullName};
      _discNamesByGroup = discNamesMap;
    });
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
    int? curatorId = _teacherIdByName(g.curator);
    final selectedDisc = {...g.disciplineIds};

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
              return Column(
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
                  const Text('Subjects'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final result = await showDialog<Set<int>>(
                            context: context,
                            builder: (c) => _SelectItemsDialog(
                              title: 'Select subjects',
                              hint: 'Search subjects...',
                              items: [for (final d in _disciplines) if (d.id != null) _SelectableItem(d.id!, d.name)],
                              initiallySelected: selectedDisc,
                            ),
                          );
                          if (result != null) {
                            setStateDialog(() {
                              selectedDisc
                                ..clear()
                                ..addAll(result);
                            });
                          }
                        },
                        child: const Text('Select subjects'),
                      ),
                      const SizedBox(width: 12),
                      Text('Selected: ' + selectedDisc.length.toString()),
                    ],
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          if (await confirmDelete()) {
                            Navigator.pop(ctx);
                            if (g.id != null) await _repo.delete(g.id!);
                            await _init();
                          }
                        },
                        child: const Text('Delete'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          g.name = name.text.trim();
                          g.curator = curatorId == null ? null : _teacherNames[curatorId];
                          g.size = int.tryParse(size.text.trim());
                          g.course = int.tryParse(course.text.trim());
                          g.specialty = specialty.text.trim().isEmpty ? null : specialty.text.trim();
                          g.disciplineIds = selectedDisc.toList();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      )
                    ],
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
    await _repo.update(g);
    await _init();
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
                  GroupFilterBar(
                    onFilterChanged: _onFilterChanged,
                    onSortChanged: _onSortChanged,
                    onViewChanged: _onViewChanged,
                    isGridView: isGrid,
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
