import 'package:flutter/material.dart';
import '../../../groups/data/groups_repository.dart';
import '../../data/discipline_model.dart';
import '../../data/disciplines_repository.dart';

class RecentDisciplinesWidget extends StatefulWidget {
  const RecentDisciplinesWidget({super.key});

  @override
  State<RecentDisciplinesWidget> createState() => _RecentDisciplinesWidgetState();
}

class _RecentDisciplinesWidgetState extends State<RecentDisciplinesWidget> {
  final _repo = DisciplinesRepository();
  List<DisciplineModel> _items = [];
  Map<int, String> _groupsLine = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    await _load();
  }

  Future<void> _load() async {
    final items = await _repo.getRecent(limit: 5);
    final ids = items.where((e) => e.id != null).map((e) => e.id!).toList();
    final map = await _repo.groupNamesByDiscipline(ids);
    final line = <int, String>{
      for (final id in map.keys) id: (map[id] ?? const <String>[]).join(', '),
    };
    if (!mounted) return;
    setState(() {
      _items = items;
      _groupsLine = line;
    });
  }

  Future<void> _openAddModal() async {
    final result = await showDialog<_NewDisciplineData>(
      context: context,
      builder: (ctx) => const _AddDisciplineDialog(),
    );
    if (result != null) {
      final id = await _repo.insert(result.model);
      if (id > 0) {
        await _repo.setTeachersFor(id, result.teacherIds);
        await _repo.setGroupsFor(id, result.groupIds);
      }
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
          const Text('Nedavnie distsipliny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final d in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(((_groupsLine[d.id ?? -1] ?? '').isEmpty ? '-' : _groupsLine[d.id ?? -1]!) + ' • ' + (d.hours).toString() + ' ch.', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
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

class _NewDisciplineData {
  final DisciplineModel model;
  final List<int> teacherIds;
  final List<int> groupIds;
  _NewDisciplineData(this.model, this.teacherIds, this.groupIds);
}

class _AddDisciplineDialog extends StatefulWidget {
  const _AddDisciplineDialog();
  @override
  State<_AddDisciplineDialog> createState() => _AddDisciplineDialogState();
}

class _AddDisciplineDialogState extends State<_AddDisciplineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _hours = TextEditingController();
  final _semester = TextEditingController();
  Set<int> _selectedGroupIds = {};
  Set<int> _selectedTeachers = {};
  List<Map<String, Object?>> _teachers = [];
  List<_SelectableItem> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadRefs();
  }

  Future<void> _loadRefs() async {
    final repo = DisciplinesRepository();
    final t = await repo.teachersLite();
    final groups = await GroupsRepository().getAll(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      _teachers = t;
      _groups = [
        for (final g in groups)
          if (g.id != null) _SelectableItem(g.id!, g.name)
      ];
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _hours.dispose();
    _semester.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final model = DisciplineModel(
      name: _name.text.trim(),
      teacher: '',
      groupCode: null,
      semester: int.tryParse(_semester.text.trim()),
      hours: int.tryParse(_hours.text.trim()) ?? 0,
    );
    Navigator.of(context).pop(_NewDisciplineData(
      model,
      _selectedTeachers.toList(),
      _selectedGroupIds.toList(),
    ));
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
                const Text('Novaya distsiplina', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nazvanie'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nazvanie obyazatelno' : null,
                ),
                Row(children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<Set<int>>(
                        context: context,
                        builder: (_) => _SelectItemsDialog(
                          title: 'Vybor grupp',
                          hint: 'Poisk grupp...',
                          items: _groups,
                          initiallySelected: _selectedGroupIds,
                        ),
                      );
                      if (result != null) setState(() { _selectedGroupIds = result; });
                    },
                    child: const Text("Vybrat' gruppy"),
                  ),
                  const SizedBox(width: 12),
                  Text('Vybrano grupp: ' + _selectedGroupIds.length.toString()),
                ]),
                TextFormField(controller: _hours, decoration: const InputDecoration(labelText: 'Chasy'), keyboardType: TextInputType.number),
                TextFormField(controller: _semester, decoration: const InputDecoration(labelText: 'Semestr (1/2)'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await showDialog<Set<int>>(
                        context: context,
                        builder: (_) => _SelectItemsDialog(
                          title: 'Vybor prepodavatelei',
                          hint: 'Poisk prepodavatelei...',
                          items: [for (final t in _teachers) _SelectableItem(t['id'] as int, t['full_name'] as String)],
                          initiallySelected: _selectedTeachers,
                        ),
                      );
                      if (result != null) setState(() { _selectedTeachers = result; });
                    },
                    child: const Text("Vybrat' prepodavatelei"),
                  ),
                  const SizedBox(width: 12),
                  Text('Vybrano: ' + _selectedTeachers.length.toString()),
                ]),
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
