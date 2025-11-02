import 'package:flutter/material.dart';

import '../../../audience_types/data/audience_type_model.dart';
import '../../../buildings/data/building_model.dart';
import '../../../lesson_types/data/lesson_type_model.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../data/audience_model.dart';

class AudienceEditorDialog extends StatefulWidget {
  final Audience? initialAudience;
  final List<LessonType> lessonTypes;
  final List<Teacher> teachers;
  final List<Building> buildings;
  final List<AudienceType> audienceTypes;

  const AudienceEditorDialog({
    super.key,
    this.initialAudience,
    required this.lessonTypes,
    required this.teachers,
    required this.buildings,
    required this.audienceTypes,
  });

  @override
  State<AudienceEditorDialog> createState() => _AudienceEditorDialogState();
}

class _AudienceEditorDialogState extends State<AudienceEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _notesCtrl;

  int? _selectedTeacherId;
  int? _selectedBuildingId;
  String? _selectedAudienceType;
  late Set<int> _selectedLessonTypeIds;

  @override
  void initState() {
    super.initState();
    final audience = widget.initialAudience;
    _nameCtrl = TextEditingController(text: audience?.name ?? '');
    _capacityCtrl = TextEditingController(
      text: audience?.capacity != null ? '${audience!.capacity}' : '',
    );
    _notesCtrl = TextEditingController(text: audience?.notes ?? '');
    _selectedTeacherId = audience?.teacherId;
    _selectedBuildingId = audience?.buildingId;
    _selectedAudienceType = audience?.type;
    _selectedLessonTypeIds = audience != null
        ? audience.lessonTypeIds.toSet()
        : <int>{};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleLessonType(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedLessonTypeIds.add(id);
      } else {
        _selectedLessonTypeIds.remove(id);
      }
    });
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;

    final capacity = int.tryParse(_capacityCtrl.text.trim());
    final audience = Audience(
      id: widget.initialAudience?.id,
      name: _nameCtrl.text.trim(),
      type: _selectedAudienceType,
      capacity: capacity,
      buildingId: _selectedBuildingId,
      teacherId: _selectedTeacherId,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lessonTypeIds: _selectedLessonTypeIds.toList(),
    );

    Navigator.of(context).pop(audience);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialAudience == null ? 'Добавить аудиторию' : 'Редактировать аудиторию',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Название *',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
    DropdownButtonFormField<String?>(
      value: _selectedAudienceType,
      decoration: const InputDecoration(labelText: 'Тип аудитории'),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Не выбрано')),
        ...widget.audienceTypes
            .where((t) => t.name.isNotEmpty)
            .map(
              (t) => DropdownMenuItem<String?>(
                value: t.name,
                child: Text(t.name),
              ),
            ),
      ],
                  onChanged: (value) => setState(() => _selectedAudienceType = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Вместимость',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedBuildingId,
                  decoration: const InputDecoration(labelText: 'Корпус'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Не выбрано')),
                    ...widget.buildings.where((b) => b.id != null).map(
                          (b) => DropdownMenuItem<int?>(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() => _selectedBuildingId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _selectedTeacherId,
                  decoration: const InputDecoration(labelText: 'Ответственный преподаватель'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Не выбрано')),
                    ...widget.teachers.where((t) => t.id != null).map(
                          (t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(t.fullName),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() => _selectedTeacherId = value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Допустимые типы занятий',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                if (widget.lessonTypes.isEmpty)
                  const Text(
                    'Список типов занятий пуст. Добавьте их в разделе «Типы занятий».',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.lessonTypes
                        .where((lt) => lt.id != null)
                        .map(
                          (lessonType) => FilterChip(
                            label: Text(lessonType.name),
                            selected: _selectedLessonTypeIds.contains(lessonType.id),
                            onSelected: (selected) =>
                                _toggleLessonType(lessonType.id!, selected),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Заметки',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
