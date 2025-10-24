import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../data/discipline_model.dart';
import '../../data/disciplines_repository.dart';
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
  }

  void _onFilterChanged(String q) {
    setState(() {
      filtered = all
          .where((e) => e.name.toLowerCase().contains(q.toLowerCase()) ||
              e.teacher.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
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
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  Future<void> _editDiscipline(DisciplineModel d) async {
    final name = TextEditingController(text: d.name);
    final teacher = TextEditingController(text: d.teacher);
    final group = TextEditingController(text: d.groupCode ?? '');
    final semester = TextEditingController(text: d.semester?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Редактирование дисциплины',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: teacher,
                decoration: const InputDecoration(labelText: 'Преподаватель'),
              ),
              TextField(
                controller: group,
                decoration: const InputDecoration(labelText: 'Группа (например, ПО-42)'),
              ),
              TextField(
                controller: semester,
                decoration: const InputDecoration(labelText: 'Семестр'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    d.name = name.text.trim();
                    d.teacher = teacher.text.trim();
                    final groupValue = group.text.trim();
                    d.groupCode = groupValue.isEmpty ? null : groupValue;
                    d.semester = int.tryParse(semester.text.trim());
                    Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить'),
                ),
              )
            ],
          ),
        ),
      ),
    );
    await _repo.update(d);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Дисциплины'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Список дисциплин',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                              return DisciplineCard(
                                discipline: item,
                                onTap: () => _editDiscipline(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return DisciplineCard(
                                discipline: item,
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

