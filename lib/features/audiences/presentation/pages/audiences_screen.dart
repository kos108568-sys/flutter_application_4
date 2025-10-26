import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/sidebar_menu.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../data/audience_type_model.dart';
import '../../data/audiences_item_model.dart';
import '../../data/audiences_repository.dart';
import '../widgets/audience_card.dart';
import '../widgets/audience_filter_bar.dart';
import '../widgets/audience_types_widget.dart';
import '../widgets/recent_audiences_widget.dart';

class AudiencesScreen extends StatefulWidget {
  const AudiencesScreen({super.key});

  @override
  State<AudiencesScreen> createState() => _AudiencesScreenState();
}

class _AudiencesScreenState extends State<AudiencesScreen> {
  final _repo = AudiencesRepository();
  final _teachersRepo = TeachersRepository();

  List<AudiencesItemModel> allItems = [];
  List<AudiencesItemModel> filteredItems = [];
  List<AudienceTypeModel> types = [];
  List<TeacherModel> teachers = [];
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getAll(orderBy: 'a.name ASC');
    final typeList = await _repo.types();
    final teacherList = await _teachersRepo.getAll(orderBy: 'full_name ASC');
    if (!mounted) return;
    setState(() {
      allItems = items;
      filteredItems = List.from(items);
      types = typeList;
      teachers = teacherList;
    });
  }

  void _onFilterChanged(String query) {
    setState(() {
      filteredItems = allItems
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              (item.typeName ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'name':
          filteredItems.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'type':
          filteredItems.sort((a, b) => (a.typeName ?? '').compareTo(b.typeName ?? ''));
          break;
        case 'capacity':
          filteredItems.sort((a, b) => a.capacity.compareTo(b.capacity));
          break;
      }
    });
  }

  void _onViewChanged(bool grid) => setState(() => isGridView = grid);

  Future<void> _showEditAudienceDialog(AudiencesItemModel audience) async {
    final nameController = TextEditingController(text: audience.name);
    final buildingController = TextEditingController(text: audience.building ?? '');
    final capacityController = TextEditingController(text: audience.capacity.toString());
    final equipmentController = TextEditingController(text: audience.equipmentList.join(', '));

    int typeId = audience.typeId;
    int? teacherId = audience.headTeacherId;

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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Редактирование аудитории', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: typeId,
                      decoration: const InputDecoration(labelText: 'Тип аудитории'),
                      items: types
                          .map((t) => DropdownMenuItem<int>(value: t.id, child: Text(t.typeName)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => typeId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: teacherId,
                      decoration: const InputDecoration(labelText: 'Заведующий'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                        ...teachers
                            .where((t) => t.id != null)
                            .map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)))
                      ],
                      onChanged: (value) => setStateDialog(() => teacherId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: buildingController,
                      decoration: const InputDecoration(labelText: 'Корпус/здание'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacityController,
                      decoration: const InputDecoration(labelText: 'Вместимость'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: equipmentController,
                      decoration: const InputDecoration(labelText: 'Оборудование (через запятую)'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            audience.name = nameController.text.trim();
                            audience.building = buildingController.text.trim().isEmpty ? null : buildingController.text.trim();
                            audience.capacity = int.tryParse(capacityController.text.trim()) ?? audience.capacity;
                            audience.typeId = typeId;
                            audience.headTeacherId = teacherId;
                            audience.equipmentList = equipmentController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            Navigator.pop(context);
                          },
                          child: const Text('Сохранить'),
                        ),
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
    await _repo.update(audience);
    await _init();
  }

  Future<void> _openAddAudienceModal() async {
    final result = await showModalBottomSheet<AudiencesItemModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddAudienceBottomSheet(types: types, teachers: teachers),
    );
    if (result != null) {
      await _repo.insert(result);
      await _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAudienceModal,
        child: const Icon(Icons.add),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SidebarMenu(selected: 'Аудитории'),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Залы и аудитории', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AudienceTypesWidget(types: types),
                  const SizedBox(height: 24),
                  RecentAudiencesWidget(types: types, teachers: teachers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAudienceBottomSheet extends StatefulWidget {
  final List<AudienceTypeModel> types;
  final List<TeacherModel> teachers;

  const _AddAudienceBottomSheet({required this.types, required this.teachers});

  @override
  State<_AddAudienceBottomSheet> createState() => _AddAudienceBottomSheetState();
}

class _AddAudienceBottomSheetState extends State<_AddAudienceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _equipmentCtrl = TextEditingController();
  int? _typeId;
  int? _teacherId;

  @override
  void initState() {
    super.initState();
    if (widget.types.isNotEmpty) {
      _typeId = widget.types.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _buildingCtrl.dispose();
    _equipmentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _typeId == null) return;
    final equipment = _equipmentCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final model = AudiencesItemModel(
      name: _nameCtrl.text.trim(),
      capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 0,
      typeId: _typeId!,
      headTeacherId: _teacherId,
      building: _buildingCtrl.text.trim().isEmpty ? null : _buildingCtrl.text.trim(),
      equipmentList: equipment,
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новая аудитория', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Название обязательно' : null,
                ),
                DropdownButtonFormField<int>(
                  value: _typeId,
                  decoration: const InputDecoration(labelText: 'Тип'),
                  items: widget.types
                      .map((t) => DropdownMenuItem<int>(value: t.id, child: Text(t.typeName)))
                      .toList(),
                  onChanged: (value) => setState(() => _typeId = value),
                ),
                DropdownButtonFormField<int?>(
                  value: _teacherId,
                  decoration: const InputDecoration(labelText: 'Заведующий'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Не назначен')),
                    ...widget.teachers
                        .where((t) => t.id != null)
                        .map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)))
                  ],
                  onChanged: (value) => setState(() => _teacherId = value),
                ),
                TextFormField(
                  controller: _capacityCtrl,
                  decoration: const InputDecoration(labelText: 'Вместимость'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _buildingCtrl,
                  decoration: const InputDecoration(labelText: 'Корпус'),
                ),
                TextFormField(
                  controller: _equipmentCtrl,
                  decoration: const InputDecoration(labelText: 'Оборудование'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _submit, child: const Text('Сохранить')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
