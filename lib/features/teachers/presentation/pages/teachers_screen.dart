import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../data/teacher_model.dart';
import '../../data/teachers_repository.dart';
import '../../../groups/data/group_model.dart';
import '../../../disciplines/data/discipline_model.dart';
import '../../../audiences/data/audiences_item_model.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_filter_bar.dart';
import '../widgets/recent_teachers_widget.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _repo = TeachersRepository();
  List<TeacherModel> all = [];
  List<TeacherModel> filtered = [];
  bool isGrid = true;
  Map<int, String> groupNameById = {};
  List<GroupModel> _groups = [];
  List<DisciplineModel> _subjects = [];
  TeacherModel? _selected;
  String _detailTab = 'groups'; // 'groups' | 'subjects'

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAll(orderBy: 'full_name ASC');
    final groups = await _repo.groups();
    final subjects = await _repo.disciplines();
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      _groups = groups;
      _subjects = subjects;
      groupNameById = {for (final g in groups) if (g.id != null) g.id!: g.name};
      if (_selected != null) {
        // refresh selected from new list
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

  Future<void> _editLinks(TeacherModel t) async {
    // select groups taught
    final groupsResult = await showDialog<Set<int>>(
      context: context,
      builder: (c) => _SelectItemsDialog(
        title: "Vybor grupp",
        hint: "Poisk grupp...",
        items: [for (final g in _groups) if (g.id != null) _SelectableItem(g.id!, g.name)],
        initiallySelected: t.taughtGroupIds.toSet(),
      ),
    );
    if (groupsResult != null) {
      t.taughtGroupIds = groupsResult.toList();
    }
    // select subjects
    final subjectsResult = await showDialog<Set<int>>(
      context: context,
      builder: (c) => _SelectItemsDialog(
        title: "Vybor predmetov",
        hint: "Poisk predmetov...",
        items: [for (final s in _subjects) if (s.id != null) _SelectableItem(s.id!, s.name)],
        initiallySelected: t.disciplineIds.toSet(),
      ),
    );
    if (subjectsResult != null) {
      t.disciplineIds = subjectsResult.toList();
    }
    await _repo.update(t);
    await _init();
  }

  Future<void> _editTeacher(TeacherModel t) async {
    final fullName = TextEditingController(text: t.fullName);
    final List<GroupModel> groups = await _repo.groups();
    final List<DisciplineModel> discs = await _repo.disciplines();
    final List<AudiencesItemModel> auds = await _repo.audiences();

    int? curatorId = t.curatorGroupId;
    final selectedDisc = {...t.disciplineIds};
    final selectedAud = {...t.audienceIds};

    final confirmDelete = () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Udalit' prepodavatelia?"),
          content: Text("Vy uvereny, chto hotite udalit' \"${t.fullName}\"?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Otmena')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Udalit'")),
          ],
        ),
      );
      return ok ?? false;
    };

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
                    const Text('Redaktirovanie prepodavatelia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(labelText: 'FIO'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: curatorId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kuriruemaya gruppa'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Ne naznachena')),
                        ...groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))),
                      ],
                      onChanged: (v) => setStateDialog(() => curatorId = v),
                    ),
                    const SizedBox(height: 12),
                    const Text('Predmety'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<Set<int>>(
                              context: context,
                              builder: (c) => _SelectItemsDialog(
                                title: 'Vybor predmetov',
                                hint: 'Poisk predmetov...',
                                items: [for (final d in discs) if (d.id != null) _SelectableItem(d.id!, d.name)],
                                initiallySelected: selectedDisc,
                              ),
                            );
                            if (result != null) setStateDialog(() { selectedDisc..clear()..addAll(result); });
                          },
                          child: const Text("Vybrat' predmety"),
                        ),
                        const SizedBox(width: 12),
                        Text('Vybrano: ' + selectedDisc.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Auditorii (zaveduyushchiy)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<Set<int>>(
                              context: context,
                              builder: (c) => _SelectItemsDialog(
                                title: 'Vybor auditorii',
                                hint: 'Poisk auditorii...',
                                items: [for (final a in auds) if (a.id != null) _SelectableItem(a.id!, a.name)],
                                initiallySelected: selectedAud,
                              ),
                            );
                            if (result != null) setStateDialog(() { selectedAud..clear()..addAll(result); });
                          },
                          child: const Text("Vybrat' auditorii"),
                        ),
                        const SizedBox(width: 12),
                        Text('Vybrano: ' + selectedAud.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () async {
                            if (await confirmDelete()) {
                              Navigator.pop(ctx);
                              if (t.id != null) await _repo.delete(t.id!);
                              await _init();
                            }
                          },
                          child: const Text("Udalit'"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            t.fullName = fullName.text.trim();
                            t.curatorGroupId = curatorId;
                            t.disciplineIds = selectedDisc.toList();
                            t.audienceIds = selectedAud.toList();
                            Navigator.pop(ctx);
                          },
                          child: const Text("Sohranit'"),
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
    await _repo.update(t);
    await _init();
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
                  TeacherFilterBar(
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
                              final groupName = item.curatorGroupId != null ? groupNameById[item.curatorGroupId!] : null;
                              return GestureDetector(
                                onTap: () => setState(() => _selected = item),
                                child: TeacherCard(
                                  teacher: item,
                                  curatorGroupName: groupName == null ? 'Kurator: —' : 'Kurator: $groupName',
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
                              final groupName = item.curatorGroupId != null ? groupNameById[item.curatorGroupId!] : null;
                              return GestureDetector(
                                onTap: () => setState(() => _selected = item),
                                child: TeacherCard(
                                  teacher: item,
                                  curatorGroupName: groupName == null ? 'Kurator: —' : 'Kurator: $groupName',
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
                    : _TeacherDetailPanel(
                        teacher: _selected!,
                        groups: _groups,
                        subjects: _subjects,
                        onEdit: () => _editLinks(_selected!),
                        tab: _detailTab,
                        onTabChanged: (v) => setState(() => _detailTab = v),
                      ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TeacherDetailPanel extends StatelessWidget {
  final TeacherModel teacher;
  final List<GroupModel> groups;
  final List<DisciplineModel> subjects;
  final VoidCallback onEdit;
  final String tab; // 'groups' | 'subjects'
  final ValueChanged<String> onTabChanged;

  const _TeacherDetailPanel({
    required this.teacher,
    required this.groups,
    required this.subjects,
    required this.onEdit,
    required this.tab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final groupById = {for (final g in groups) if (g.id != null) g.id!: g};
    final subjectById = {for (final s in subjects) if (s.id != null) s.id!: s};
    final taughtGroups = teacher.taughtGroupIds.map((id) => groupById[id]).whereType<GroupModel>().toList();
    final taughtSubjects = teacher.disciplineIds.map((id) => subjectById[id]).whereType<DisciplineModel>().toList();

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
          Text('Otdelenie: ' + (teacher.department ?? '-'), style: const TextStyle(color: Colors.grey)),
          Text('Kuratorstvo: ' + (groupById[teacher.curatorGroupId]?.name ?? '-'), style: const TextStyle(color: Colors.grey)),
          Text('Nagruzka: ' + teacher.workloadHours.toString() + ' ch.', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ToggleButtons(
              isSelected: [tab == 'groups', tab == 'subjects'],
              onPressed: (i) => onTabChanged(i == 0 ? 'groups' : 'subjects'),
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Gruppy')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('Distsipliny')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onEdit, child: const Text('Redaktirovat\''))),
          const SizedBox(height: 8),
          if (tab == 'groups')
            ...taughtGroups.map((g) => _tile(icon: Icons.group, title: g.name, subtitle: (g.specialty ?? '') + (g.course != null ? ' • Kurs ' + g.course.toString() : '')))
          else
            ...taughtSubjects.map((s) => _tile(icon: Icons.menu_book, title: s.name, subtitle: (s.hours).toString() + ' ch.')),
        ],
      ),
    );
  }

  Widget _tile({required IconData icon, required String title, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE9EDF3)))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (subtitle != null && subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
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
