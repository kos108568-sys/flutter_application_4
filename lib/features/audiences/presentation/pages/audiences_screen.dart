import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../data/audience_model.dart';
import '../../data/audiences_repository.dart';
import '../widgets/audience_card.dart';
import '../widgets/audience_filter_bar.dart';
import '../widgets/audience_types_widget.dart';
import '../widgets/recent_audiences_widget.dart';

class AudiencesScreen extends StatefulWidget {
  const AudiencesScreen({super.key});

  @override
  State<AudiencesScreen> createState() => _AudiencesPageState();
}

class _AudiencesPageState extends State<AudiencesScreen> {
  final _repo = AudiencesRepository();
  List<Audience> allItems = [];
  List<Audience> filteredItems = [];
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAllAudiences(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      allItems = items;
      filteredItems = List.from(items);
    });
  }

  void _onFilterChanged(String query) {
    setState(() {
      filteredItems = allItems.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'name':
          filteredItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'capacity':
          filteredItems.sort((a, b) => (a.capacity ?? 0).compareTo(b.capacity ?? 0));
          break;
      }
    });
  }

  void _onViewChanged(bool grid) {
    setState(() => isGridView = grid);
  }

  Future<void> _showEditAudienceDialog(Audience audience) async {
    final nameController = TextEditingController(text: audience.name);
    final capacityController = TextEditingController(text: (audience.capacity ?? '').toString());
    final notesController = TextEditingController(text: audience.notes ?? '');

    // types selection UI removed for now; will be added later if needed

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(20),
          child: StatefulBuilder(builder: (context, setStateDialog) {
            return Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Редактирование аудитории',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Аудитория',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Вместимость',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Заметки',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              final updated = Audience(
                                id: audience.id,
                                name: nameController.text.trim(),
                                capacity: int.tryParse(capacityController.text.trim()),
                                audienceTypeId: audience.audienceTypeId,
                                buildingId: audience.buildingId,
                                responsibleTeacherId: audience.responsibleTeacherId,
                                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              );
                              _repo.updateAudience(updated);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Сохранить'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
    await _repo.updateAudience(audience);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SidebarMenu(selected: 'Аудитории'),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Поиск аудиторий', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  AudienceFilterBar(
                    onFilterChanged: _onFilterChanged,
                    onSortChanged: _onSortChanged,
                    onViewChanged: _onViewChanged,
                    isGridView: isGridView,
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: isGridView
                        ? GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.7,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return AudienceCard(
                                audience: item,
                                onTap: () => _showEditAudienceDialog(item),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: AudienceCard(
                                  audience: item,
                                  onTap: () => _showEditAudienceDialog(item),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: 320,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: const SingleChildScrollView(
              child: Column(
                children: [
                  AudienceTypesWidget(),
                  SizedBox(height: 24),
                  RecentAudiencesWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
