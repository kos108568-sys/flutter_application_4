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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAll(orderBy: 'full_name ASC');
    final groups = await _repo.groups();
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      groupNameById = {for (final g in groups) if (g.id != null) g.id!: g.name};
    });
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all
          .where((e) => e.fullName.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    });
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

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
          title: const Text('Удалить преподавателя?'),
          content: Text('Вы уверены, что хотите удалить "${t.fullName}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
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
                    const Text('Редактирование преподавателя', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(labelText: 'ФИО'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: curatorId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Куратор группы'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('—')),
                        ...groups.map((g) => DropdownMenuItem<int?>(value: g.id, child: Text(g.name))),
                      ],
                      onChanged: (v) => setStateDialog(() => curatorId = v),
                    ),
                    const SizedBox(height: 12),
                    const Text('Дисциплины'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: discs.map((d) {
                        final selected = d.id != null && selectedDisc.contains(d.id);
                        return FilterChip(
                          label: Text(d.name),
                          selected: selected,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (d.id == null) return;
                              if (val) {
                                selectedDisc.add(d.id!);
                              } else {
                                selectedDisc.remove(d.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Аудитории'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: auds.map((a) {
                        final selected = a.id != null && selectedAud.contains(a.id);
                        return FilterChip(
                          label: Text(a.name),
                          selected: selected,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (a.id == null) return;
                              if (val) {
                                selectedAud.add(a.id!);
                              } else {
                                selectedAud.remove(a.id);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                          child: const Text('Удалить'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            t.fullName = fullName.text.trim();
                            t.curatorGroupId = curatorId;
                            t.disciplineIds = selectedDisc.toList();
                            t.audienceIds = selectedAud.toList();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Сохранить'),
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
          const SidebarMenu(selected: 'Профиль и доступ'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Список преподавателей', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                              return TeacherCard(
                                teacher: item,
                                curatorGroupName: groupName == null ? 'Куратор: —' : 'Куратор: $groupName',
                                onTap: () => _editTeacher(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final groupName = item.curatorGroupId != null ? groupNameById[item.curatorGroupId!] : null;
                              return TeacherCard(
                                teacher: item,
                                curatorGroupName: groupName == null ? 'Куратор: —' : 'Куратор: $groupName',
                                onTap: () => _editTeacher(item),
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
                    RecentTeachersWidget(),
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

