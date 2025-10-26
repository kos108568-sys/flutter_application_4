import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../../subjects/data/subject_model.dart';
import '../../../subjects/data/subjects_repository.dart';
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
  final _groupsRepo = GroupsRepository();
  final _teachersRepo = TeachersRepository();
  final _subjectsRepo = SubjectsRepository();

  List<GroupModel> all = [];
  List<GroupModel> filtered = [];
  List<TeacherModel> _teachers = [];
  List<SubjectModel> _subjects = [];
  bool isGrid = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _groupsRepo.seedIfEmpty();
    final items = await _groupsRepo.getAll(orderBy: 'g.name ASC');
    final teachers = await _teachersRepo.getAll(orderBy: 'full_name ASC');
    final subjects = await _subjectsRepo.getAll(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      all = items;
      filtered = List.of(items);
      _teachers = teachers;
      _subjects = subjects;
    });
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all
          .where(
            (e) =>
                e.name.toLowerCase().contains(q.toLowerCase()) ||
                (e.curatorName ?? '').toLowerCase().contains(q.toLowerCase()) ||
                (e.speciality ?? '').toLowerCase().contains(q.toLowerCase()) ||
                (e.department ?? '').toLowerCase().contains(q.toLowerCase()),
          )
          .toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'size':
          filtered.sort((a, b) => (a.studentCount ?? 0).compareTo(b.studentCount ?? 0));
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

  Future<void> _editGroup(GroupModel group) async {
    final name = TextEditingController(text: group.name);
    final studentCount = TextEditingController(text: (group.studentCount ?? '').toString());
    final course = TextEditingController(text: (group.course ?? '').toString());
    final speciality = TextEditingController(text: group.speciality ?? '');
    final department = TextEditingController(text: group.department ?? '');
    int? curatorId = group.curatorId;
    final selectedSubjects = {...group.subjectIds};

    Future<bool> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить группу?'),
          content: Text('Вы уверены, что хотите удалить "${group.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
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
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Редактирование группы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Название'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: speciality, decoration: const InputDecoration(labelText: 'Специальность'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: curatorId,
                            decoration: const InputDecoration(labelText: 'Куратор'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                              ..._teachers
                                  .where((t) => t.id != null)
                                  .map(
                                    (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                                  ),
                            ],
                            onChanged: (val) => setStateDialog(() => curatorId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: studentCount,
                            decoration: const InputDecoration(labelText: 'Кол-во студентов'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: course,
                            decoration: const InputDecoration(labelText: 'Курс'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: department,
                            decoration: const InputDecoration(labelText: 'Кафедра'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Предметы'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _subjects.map((subject) {
                        final selected = subject.id != null && selectedSubjects.contains(subject.id);
                        return FilterChip(
                          label: Text(subject.name),
                          selected: selected,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (subject.id == null) return;
                              if (val) {
                                selectedSubjects.add(subject.id!);
                              } else {
                                selectedSubjects.remove(subject.id);
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
                              if (group.id != null) await _groupsRepo.delete(group.id!);
                              await _init();
                            }
                          },
                          child: const Text('Удалить'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            group.name = name.text.trim();
                            group.speciality = speciality.text.trim().isEmpty ? null : speciality.text.trim();
                            group.department = department.text.trim().isEmpty ? null : department.text.trim();
                            group.curatorId = curatorId;
                            group.studentCount = int.tryParse(studentCount.text.trim());
                            group.course = int.tryParse(course.text.trim());
                            group.subjectIds = selectedSubjects.toList();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Сохранить'),
                        ),
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
    await _groupsRepo.update(group);
    await _init();
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Список групп', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                              return GroupCard(
                                group: item,
                                onTap: () => _editGroup(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return GroupCard(
                                group: item,
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
