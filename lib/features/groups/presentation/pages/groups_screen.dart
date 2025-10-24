import 'package:flutter/material.dart';
import '../../../../core/widgets/sidebar_menu.dart';
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
  List<GroupModel> all = [];
  List<GroupModel> filtered = [];
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

  Future<void> _editGroup(GroupModel g) async {
    final name = TextEditingController(text: g.name);
    final curator = TextEditingController(text: g.curator ?? '');
    final size = TextEditingController(text: (g.size ?? '').toString());
    final course = TextEditingController(text: (g.course ?? '').toString());
    final specialty = TextEditingController(text: g.specialty ?? '');

    final confirmDelete = () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить группу?'),
          content: Text('Вы уверены, что хотите удалить группу "${g.name}"?'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Редактирование группы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Название'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: specialty, decoration: const InputDecoration(labelText: 'Специальность'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: curator, decoration: const InputDecoration(labelText: 'Куратор'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: size, decoration: const InputDecoration(labelText: 'Количество'), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: course, decoration: const InputDecoration(labelText: 'Курс'), keyboardType: TextInputType.number)),
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
                    child: const Text('Удалить'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      g.name = name.text.trim();
                      g.curator = curator.text.trim().isEmpty ? null : curator.text.trim();
                      g.size = int.tryParse(size.text.trim());
                      g.course = int.tryParse(course.text.trim());
                      g.specialty = specialty.text.trim().isEmpty ? null : specialty.text.trim();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Сохранить'),
                  )
                ],
              )
            ],
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

