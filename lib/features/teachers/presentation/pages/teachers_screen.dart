import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../../audiences/data/audiences_item_model.dart';
import '../../../groups/data/group_model.dart';
import '../../../groups/data/groups_repository.dart';
import '../../../subjects/data/subject_model.dart';
import '../../../subjects/data/subjects_repository.dart';
import '../../data/teacher_model.dart';
import '../../data/teachers_repository.dart';
import '../widgets/recent_teachers_widget.dart';
import '../widgets/teacher_card.dart';
import '../widgets/teacher_filter_bar.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _repo = TeachersRepository();
  final _groupsRepo = GroupsRepository();
  final _subjectsRepo = SubjectsRepository();

  List<TeacherModel> all = [];
  List<TeacherModel> filtered = [];
  List<GroupModel> _groups = [];
  List<SubjectModel> _subjects = [];
  List<AudiencesItemModel> _audiences = [];
  bool isGrid = true;
  Map<int, String> groupNameById = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final teachers = await _repo.getAll(orderBy: 'full_name ASC');
    final groups = await _groupsRepo.getAll(orderBy: 'g.name ASC');
    final subjects = await _subjectsRepo.getAll(orderBy: 'name ASC');
    final audiences = await _repo.audiences();
    if (!mounted) return;
    setState(() {
      all = teachers;
      filtered = List.of(teachers);
      _groups = groups;
      _subjects = subjects;
      _audiences = audiences;
      groupNameById = {for (final g in groups) if (g.id != null) g.id!: g.name};
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

  Future<void> _editTeacher(TeacherModel teacher) async {
    final fullName = TextEditingController(text: teacher.fullName);
    final selectedSubjects = {...teacher.subjectIds};
    final selectedAudiences = {...teacher.audienceIds};
    final selectedGroups = {...teacher.curatorGroupIds};

    Future<bool> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить преподавателя?'),
          content: Text('Вы уверены, что хотите удалить "${teacher.fullName}"?'),
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
                    const Text('Редактирование преподавателя', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(labelText: 'ФИО'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Курируемые группы'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _groups.map((group) {
                        final selected = group.id != null && selectedGroups.contains(group.id);
                        return FilterChip(
                          label: Text(group.name),
                          selected: selected,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (group.id == null) return;
                              if (val) {
                                selectedGroups.add(group.id!);
                              } else {
                                selectedGroups.remove(group.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    const Text('Аудитории (заведующий)'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _audiences.map((audience) {
                        final selected = audience.id != null && selectedAudiences.contains(audience.id);
                        return FilterChip(
                          label: Text(audience.name),
                          selected: selected,
                          onSelected: (val) {
                            setStateDialog(() {
                              if (audience.id == null) return;
                              if (val) {
                                selectedAudiences.add(audience.id!);
                              } else {
                                selectedAudiences.remove(audience.id);
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
                              if (teacher.id != null) await _repo.delete(teacher.id!);
                              await _init();
                            }
                          },
                          child: const Text('Удалить'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            teacher.fullName = fullName.text.trim();
                            teacher.curatorGroupIds = selectedGroups.toList();
                            teacher.subjectIds = selectedSubjects.toList();
                            teacher.audienceIds = selectedAudiences.toList();
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
    await _repo.update(teacher);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Преподаватели'),
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
                              final curatedNames = item.curatorGroupIds.map((id) => groupNameById[id]).whereType<String>().toList();
                              final curatorInfo = curatedNames.isEmpty ? 'Куратор: —' : 'Куратор: ${curatedNames.join(', ')}';
                              return TeacherCard(
                                teacher: item,
                                curatorInfo: curatorInfo,
                                subjectCount: item.subjectIds.length,
                                audienceCount: item.audienceIds.length,
                                onTap: () => _editTeacher(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final curatedNames = item.curatorGroupIds.map((id) => groupNameById[id]).whereType<String>().toList();
                              final curatorInfo = curatedNames.isEmpty ? 'Куратор: —' : 'Куратор: ${curatedNames.join(', ')}';
                              return TeacherCard(
                                teacher: item,
                                curatorInfo: curatorInfo,
                                subjectCount: item.subjectIds.length,
                                audienceCount: item.audienceIds.length,
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
