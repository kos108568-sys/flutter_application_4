import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../data/discipline_model.dart';
import '../../data/disciplines_repository.dart';
import '../../../groups/data/groups_repository.dart';
import '../widgets/discipline_card.dart';
import '../widgets/discipline_filter_bar.dart';
import '../widgets/recent_disciplines_widget.dart';

class DisciplinesPage extends StatefulWidget {
  const DisciplinesPage({super.key});

  @override
  State<DisciplinesPage> createState() => _DisciplinesPageState();
}

class _DisciplinesPageState extends State<DisciplinesPage> {
  final _repo = DisciplinesRepository();
  List<DisciplineModel> all = [];
  List<DisciplineModel> filtered = [];
  bool isGrid = true;
  Map<int, List<String>> _groupsByDiscipline = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAll(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
    });
    await _refreshGroupNamesForFiltered();
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all
          .where((e) => e.name.toLowerCase().contains(q.toLowerCase()) ||
              e.teacher.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
    _refreshGroupNamesForFiltered();
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'teacher':
          filtered.sort((a, b) => a.teacher.compareTo(b.teacher));
          break;
        case 'name':
        default:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }
    });
    _refreshGroupNamesForFiltered();
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  Future<void> _editDiscipline(DisciplineModel d) async {
    final name = TextEditingController(text: d.name);
    final hours = TextEditingController(text: d.hours.toString());
    final semester = TextEditingController(text: d.semester?.toString() ?? '');
    final groups = await GroupsRepository().getAll(orderBy: 'name ASC');
    final teachersLite = await _repo.teachersLite();
    final selectedTeachers = d.id == null ? <int>{} : await _repo.teacherIdsFor(d.id!);
    final selectedGroups = d.id == null ? <int>{} : await _repo.groupIdsFor(d.id!);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Redaktirovanie distsipliny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nazvanie')),
                const SizedBox(height: 8),
                TextField(controller: hours, decoration: const InputDecoration(labelText: 'Chasy'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<Set<int>>(
                        context: context,
                        builder: (_) => _SelectItemsDialog(
                          title: 'Vybor grupp',
                          hint: 'Poisk grupp...',
                          items: [for (final g in groups.where((g) => g.id != null)) _SelectableItem(g.id!, g.name)],
                          initiallySelected: selectedGroups,
                        ),
                      );
                      if (result != null) {
                        selectedGroups
                          ..clear()
                          ..addAll(result);
                      }
                    },
                    child: const Text("Vybrat' gruppy"),
                  ),
                  const SizedBox(width: 12),
                  Text('Vybrano grupp: ' + selectedGroups.length.toString()),
                ]),
                const SizedBox(height: 8),
                TextField(controller: semester, decoration: const InputDecoration(labelText: 'Semestr (1/2)'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<Set<int>>(
                        context: context,
                        builder: (_) => _SelectItemsDialog(
                          title: 'Vybor prepodavatelei',
                          hint: 'Poisk prepodavatelei...',
                          items: [for (final t in teachersLite) _SelectableItem(t['id'] as int, t['full_name'] as String)],
                          initiallySelected: selectedTeachers,
                        ),
                      );
                      if (result != null) {
                        selectedTeachers
                          ..clear()
                          ..addAll(result);
                      }
                    },
                    child: const Text("Vybrat' prepodavatelei"),
                  ),
                  const SizedBox(width: 12),
                  Text('Vybrano: ' + selectedTeachers.length.toString()),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sohranit\''),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
    d.name = name.text.trim();
    d.hours = int.tryParse(hours.text.trim()) ?? d.hours;
    // M<->N svyaz: ne ispol'zuem groupCode dlya sohraneniya
    d.groupCode = null;
    d.semester = int.tryParse(semester.text.trim());
    await _repo.update(d);
    if (d.id != null) {
      await _repo.setTeachersFor(d.id!, selectedTeachers.toList());
      await _repo.setGroupsFor(d.id!, selectedGroups.toList());
    }
    await _init();
  }

  Future<void> _refreshGroupNamesForFiltered() async {
    final ids = filtered.where((e) => e.id != null).map((e) => e.id!).toList();
    final map = await _repo.groupNamesByDiscipline(ids);
    if (!mounted) return;
    setState(() => _groupsByDiscipline = map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Distsipliny'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spisok distsiplin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DisciplineFilterBar(
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
                              final gl = (item.id != null) ? (_groupsByDiscipline[item.id!] ?? const <String>[]) : const <String>[];
                              final line = gl.isEmpty ? '' : gl.join(', ');
                              return DisciplineCard(
                                discipline: item,
                                groupsLine: line,
                                onTap: () => _editDiscipline(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final gl = (item.id != null) ? (_groupsByDiscipline[item.id!] ?? const <String>[]) : const <String>[];
                              final line = gl.isEmpty ? '' : gl.join(', ');
                              return DisciplineCard(
                                discipline: item,
                                groupsLine: line,
                                onTap: () => _editDiscipline(item),
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
                    RecentDisciplinesWidget(),
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
    final list = widget.items.where((it) => it.name.toLowerCase().contains(_q.toLowerCase())).toList();
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
