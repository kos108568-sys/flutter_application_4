import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../data/discipline_model.dart';
import '../../data/disciplines_repository.dart';
import '../widgets/discipline_card.dart';
import '../widgets/discipline_filter_bar.dart';
import '../widgets/recent_disciplines_widget.dart';
import '../../../lesson_types/data/lesson_types_repository.dart';
import '../../../lesson_types/data/lesson_type_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../../teachers/data/teacher_model.dart';

class DisciplinesPage extends StatefulWidget {
  const DisciplinesPage({super.key});

  @override
  State<DisciplinesPage> createState() => _DisciplinesPageState();
}

class _DisciplinesPageState extends State<DisciplinesPage> {
  final _repo = DisciplinesRepository();
  final _lessonTypesRepo = LessonTypesRepository();
  final _teachersRepo = TeachersRepository();
  List<Discipline> all = [];
  List<Discipline> filtered = [];
  bool isGrid = true;
  Map<int, List<String>> _groupsByDiscipline = {};
  List<LessonType> _lessonTypes = [];
  List<Teacher> _teachers = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Ne sozdaem predmety po umolchaniyu; tolko sinhronizacia\r\n    // Try to sync with Supabase so remote/local are consistent
    try { await _repo.syncDisciplines(); } catch (_) {}
    try { _lessonTypes = await _lessonTypesRepo.getAllLessonTypes(orderBy: 'name ASC'); } catch (_) {}
    try { _teachers = await _teachersRepo.getAllTeachers(orderBy: 'full_name ASC'); } catch (_) {}
    final items = await _repo.getAllDisciplines(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
    });
    await _refreshGroupNamesForFiltered();
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all.where((e) => e.name.toLowerCase().contains(q.toLowerCase())).toList();
    });
    _refreshGroupNamesForFiltered();
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'name':
        default:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }
    });
    _refreshGroupNamesForFiltered();
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  Future<void> _editDiscipline(Discipline d) async {
    final name = TextEditingController(text: d.name);
    final semester = TextEditingController(text: d.semester ?? '');
    int? lessonTypeId = d.lessonTypeId;
    final selectedTeacherIds = <int>{...await _repo.getTeacherIdsByDiscipline(d.id ?? -1)};

    final action = await showDialog<String>(
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
                DropdownButtonFormField<int?>(
                  value: lessonTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tip zanyatiya'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Ne vybran')),
                    ..._lessonTypes.where((lt) => lt.id != null).map((lt) => DropdownMenuItem<int?>(value: lt.id, child: Text(lt.name))),
                  ],
                  onChanged: (v) => lessonTypeId = v,
                ),
                const SizedBox(height: 8),
                TextField(controller: semester, decoration: const InputDecoration(labelText: 'Semestr'), keyboardType: TextInputType.text),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prepodavateli', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () async {
                        final set = await showDialog<Set<int>>(
                          context: ctx,
                          builder: (c) => _SelectItemsDialog(
                            title: 'Vybrat\' prepodavatelei',
                            hint: 'Poisk...',
                            items: [for (final t in _teachers) if (t.id != null) _SelectableItem(t.id!, t.fullName)],
                            initiallySelected: selectedTeacherIds,
                          ),
                        );
                        if (set != null) {
                          selectedTeacherIds
                            ..clear()
                            ..addAll(set);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Naznachit\''),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            title: const Text("Udalit' distsiplinu?"),
                            content: Text("Vy uvereny, chto hotite udalit' \"${d.name}\"?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Otmenit\'')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Udalit\'')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          Navigator.pop(ctx, 'delete');
                        }
                      },
                      child: const Text('Udalit\''),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, 'save'),
                      child: const Text('Sohranit\''),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
    if (action == 'delete') {
      if (d.id != null) {
        await _repo.deleteDiscipline(d.id!);
      }
      await _init();
      return;
    }
    if (action == 'save') {
      final updated = Discipline(
        id: d.id,
        name: name.text.trim(),
        lessonTypeId: lessonTypeId,
        semester: semester.text.trim().isEmpty ? null : semester.text.trim(),
      );
      await _repo.updateDiscipline(updated);
      if (updated.id != null) {
        await _repo.setDisciplineTeachers(updated.id!, selectedTeacherIds.toList());
      }
      await _init();
    }
  }

  Future<void> _addDiscipline() async {
    final name = TextEditingController();
    final semester = TextEditingController();
    int? lessonTypeId;
    final selectedTeacherIds = <int>{};

    final confirmed = await showDialog<bool>(
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
                const Text('Sozdanie distsipliny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nazvanie')),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: lessonTypeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tip zanyatiya'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Ne vybran')),
                    ..._lessonTypes.where((lt) => lt.id != null).map((lt) => DropdownMenuItem<int?>(value: lt.id, child: Text(lt.name))),
                  ],
                  onChanged: (v) => lessonTypeId = v,
                ),
                const SizedBox(height: 8),
                TextField(controller: semester, decoration: const InputDecoration(labelText: 'Semestr'), keyboardType: TextInputType.text),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prepodavateli', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () async {
                        final set = await showDialog<Set<int>>(
                          context: ctx,
                          builder: (c) => _SelectItemsDialog(
                            title: 'Vybrat\' prepodavatelei',
                            hint: 'Poisk...',
                            items: [for (final t in _teachers) if (t.id != null) _SelectableItem(t.id!, t.fullName)],
                            initiallySelected: selectedTeacherIds,
                          ),
                        );
                        if (set != null) {
                          selectedTeacherIds
                            ..clear()
                            ..addAll(set);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Naznachit\''),
                    ),
                  ],
                ),
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

    if (confirmed == true) {
      final toCreate = Discipline(
        name: name.text.trim(),
        lessonTypeId: lessonTypeId,
        semester: semester.text.trim().isEmpty ? null : semester.text.trim(),
      );
      final newId = await _repo.insertDiscipline(toCreate);
      await _repo.setDisciplineTeachers(newId, selectedTeacherIds.toList());
      await _init();
    }
  }

  Future<void> _refreshGroupNamesForFiltered() async {
    // Упрощено: связи групп убраны в текущей версии UI
    if (!mounted) return;
    setState(() => _groupsByDiscipline = {});
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
                  Row(
                    children: [
                      Expanded(
                        child: DisciplineFilterBar(
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                          onViewChanged: _onViewChanged,
                          isGridView: isGrid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addDiscipline,
                        icon: const Icon(Icons.add),
                        label: const Text('Dobavit\''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty ? const Center(child: Text('Net predmetov')) : isGrid
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

