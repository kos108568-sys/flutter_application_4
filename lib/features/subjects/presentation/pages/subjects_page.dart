import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../data/subject_model.dart';
import '../../data/subjects_repository.dart';
import '../widgets/recent_subjects_widget.dart';
import '../widgets/subject_card.dart';
import '../widgets/subject_filter_bar.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final _repo = SubjectsRepository();
  List<SubjectModel> all = [];
  List<SubjectModel> filtered = [];
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
          .where((e) =>
              e.name.toLowerCase().contains(q.toLowerCase()) ||
              e.semester.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void _onSortChanged(String by) {
    setState(() {
      switch (by) {
        case 'hours':
          filtered.sort((a, b) => a.hours.compareTo(b.hours));
          break;
        case 'name':
        default:
          filtered.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _onViewChanged(bool grid) => setState(() => isGrid = grid);

  Future<void> _editSubject(SubjectModel subject) async {
    final name = TextEditingController(text: subject.name);
    final hours = TextEditingController(text: subject.hours.toString());
    String semester = subject.semester;

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
              const Text('Редактирование предмета', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: hours,
                decoration: const InputDecoration(labelText: 'Часы'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: semester,
                decoration: const InputDecoration(labelText: 'Семестр'),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1 семестр')),
                  DropdownMenuItem(value: '2', child: Text('2 семестр')),
                  DropdownMenuItem(value: 'year', child: Text('Учебный год')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    semester = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    subject.name = name.text.trim();
                    subject.hours = int.tryParse(hours.text.trim()) ?? subject.hours;
                    subject.semester = semester;
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
    await _repo.update(subject);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Предметы'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Управление предметами', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SubjectFilterBar(
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
                              return SubjectCard(
                                subject: item,
                                onTap: () => _editSubject(item),
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return SubjectCard(
                                subject: item,
                                onTap: () => _editSubject(item),
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
                    RecentSubjectsWidget(),
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
