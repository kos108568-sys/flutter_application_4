import 'package:flutter/material.dart';

import '../../../../core/widgets/sidebar_menu.dart';
import '../../../buildings/data/building_repository.dart';
import '../../../lesson_types/data/lesson_type_repository.dart';
import '../../../teachers/data/teachers_repository.dart';
import '../../../audience_types/data/audience_type_model.dart';
import '../../../audience_types/data/audience_type_repository.dart';
import '../../data/audience_model.dart';
import '../../data/audiences_repository.dart';
import '../widgets/audience_editor_dialog.dart';
import '../widgets/audience_card.dart';
import '../widgets/audience_filter_bar.dart';
import '../widgets/audience_types_widget.dart';
import '../widgets/recent_audiences_widget.dart';
import '../../../lesson_types/data/lesson_type_model.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../../buildings/data/building_model.dart';

class AudiencesScreen extends StatefulWidget {
  const AudiencesScreen({super.key});

  @override
  State<AudiencesScreen> createState() => _AudiencesScreenState();
}

class _AudiencesScreenState extends State<AudiencesScreen> {
  final _audiencesRepo = AudiencesRepository();
  final _buildingRepo = BuildingRepository();
  final _teachersRepo = TeachersRepository();
  final _lessonTypesRepo = LessonTypeRepository();
  final _audienceTypeRepo = AudienceTypeRepository();

  List<Audience> _allAudiences = [];
  List<Audience> _filteredAudiences = [];
  List<Building> _buildings = [];
  List<Teacher> _teachers = [];
  List<LessonType> _lessonTypes = [];
  List<AudienceType> _audienceTypes = [];

  late Map<int, String> _buildingNameById = {};
  late Map<int, Teacher> _teacherById = {};
  late Map<int, String> _lessonTypeNameById = {};

  bool _isGridView = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _audiencesRepo.syncAudiences();
    } catch (_) {}
    try {
      await _teachersRepo.syncTeachers();
    } catch (_) {}
    try {
      await _lessonTypesRepo.syncLessonTypes();
    } catch (_) {}
    try {
      await _buildingRepo.syncBuildings();
    } catch (_) {}
    try {
      await _audienceTypeRepo.syncAudienceTypes();
    } catch (_) {}

    List<Audience> audiences = [];
    List<Building> buildings = [];
    List<Teacher> teachers = [];
    List<LessonType> lessonTypes = [];
    List<AudienceType> audienceTypes = [];

    try {
      audiences = await _audiencesRepo.getAllAudiences(orderBy: 'name ASC');
    } catch (_) {}

    try {
      buildings = await _buildingRepo.getAllBuildings();
    } catch (_) {}

    try {
      teachers = await _teachersRepo.getAllTeachers(orderBy: 'full_name ASC');
    } catch (_) {}

    try {
      lessonTypes = await _lessonTypesRepo.getAllLessonTypes(orderBy: 'name ASC');
    } catch (_) {}

    try {
      audienceTypes = await _audienceTypeRepo.getAllAudienceTypes(orderBy: 'name ASC');
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _allAudiences = audiences;
      _filteredAudiences = List.from(audiences);
      _buildings = buildings;
      _teachers = teachers;
      _lessonTypes = lessonTypes;
      _audienceTypes = audienceTypes;

      _buildingNameById = {
        for (final building in buildings.where((b) => b.id != null)) building.id!: building.name,
      };
      _teacherById = {
        for (final teacher in teachers.where((t) => t.id != null)) teacher.id!: teacher,
      };
      _lessonTypeNameById = {
        for (final lessonType in lessonTypes.where((t) => t.id != null)) lessonType.id!: lessonType.name,
      };
      _isLoading = false;
    });
  }

  void _onFilterChanged(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredAudiences = _allAudiences.where((audience) {
        final teacherName = audience.teacherId != null ? _teacherById[audience.teacherId!]?.fullName ?? '' : '';
        final buildingName = audience.buildingId != null ? _buildingNameById[audience.buildingId!] ?? '' : '';
        final lessonNames = audience.lessonTypeIds
            .map((id) => _lessonTypeNameById[id] ?? '')
            .where((name) => name.isNotEmpty)
            .join(' ');

        return audience.name.toLowerCase().contains(lower) ||
            (audience.type ?? '').toLowerCase().contains(lower) ||
            teacherName.toLowerCase().contains(lower) ||
            buildingName.toLowerCase().contains(lower) ||
            lessonNames.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'capacity':
          _filteredAudiences.sort(
            (a, b) => (a.capacity ?? 0).compareTo(b.capacity ?? 0),
          );
          break;
        case 'type':
          _filteredAudiences.sort(
            (a, b) => (a.type ?? '').compareTo(b.type ?? ''),
          );
          break;
        case 'name':
        default:
          _filteredAudiences.sort(
            (a, b) => a.name.compareTo(b.name),
          );
          break;
      }
    });
  }

  void _onViewChanged(bool isGrid) {
    setState(() => _isGridView = isGrid);
  }

  Future<void> _showCreateAudienceDialog() async {
    final result = await showDialog<Audience>(
      context: context,
      builder: (context) => AudienceEditorDialog(
        lessonTypes: _lessonTypes,
        teachers: _teachers,
        buildings: _buildings,
        audienceTypes: _audienceTypes,
      ),
    );

    if (result != null) {
      await _audiencesRepo.insertAudience(result);
      await _loadData();
    }
  }

  Future<void> _showEditAudienceDialog(Audience audience) async {
    final result = await showDialog<Audience>(
      context: context,
      builder: (context) => AudienceEditorDialog(
        initialAudience: audience,
        lessonTypes: _lessonTypes,
        teachers: _teachers,
        buildings: _buildings,
        audienceTypes: _audienceTypes,
      ),
    );

    if (result != null) {
      await _audiencesRepo.updateAudience(result);
      await _loadData();
    }
  }

  Future<void> _deleteAudience(Audience audience) async {
    if (audience.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить аудиторию?'),
        content: Text('Вы уверены, что хотите удалить «${audience.name}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audiencesRepo.deleteAudience(audience.id!);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
                  const Text(
                    'Аудитории',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  AudienceFilterBar(
                    onFilterChanged: _onFilterChanged,
                    onSortChanged: _onSortChanged,
                    onViewChanged: _onViewChanged,
                    isGridView: _isGridView,
                    onAddPressed: _showCreateAudienceDialog,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredAudiences.isEmpty
                            ? const Center(child: Text('Аудитории не найдены'))
                            : _isGridView
                                ? GridView.builder(
                                    padding: EdgeInsets.zero,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.7,
                                    ),
                                    itemCount: _filteredAudiences.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredAudiences[index];
                                      final lessonNames = item.lessonTypeIds
                                          .map((id) => _lessonTypeNameById[id])
                                          .whereType<String>()
                                          .toList();
                                      final teacherName = item.teacherId != null
                                          ? _teacherById[item.teacherId!]?.fullName
                                          : null;

                                      return AudienceCard(
                                        audience: item,
                                        teacherName: teacherName,
                                        lessonTypeNames: lessonNames,
                                        onTap: () => _showEditAudienceDialog(item),
                                        onDelete: () => _deleteAudience(item),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: _filteredAudiences.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredAudiences[index];
                                      final lessonNames = item.lessonTypeIds
                                          .map((id) => _lessonTypeNameById[id])
                                          .whereType<String>()
                                          .toList();
                                      final teacherName = item.teacherId != null
                                          ? _teacherById[item.teacherId!]?.fullName
                                          : null;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: AudienceCard(
                                          audience: item,
                                          teacherName: teacherName,
                                          lessonTypeNames: lessonNames,
                                          onTap: () => _showEditAudienceDialog(item),
                                          onDelete: () => _deleteAudience(item),
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
