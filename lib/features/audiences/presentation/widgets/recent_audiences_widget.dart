import 'package:flutter/material.dart';
import '../../../teachers/data/teacher_model.dart';
import '../../data/audience_type_model.dart';
import '../../data/audiences_item_model.dart';
import '../../data/audiences_repository.dart';

class RecentAudiencesWidget extends StatefulWidget {
  final List<AudienceTypeModel> types;
  final List<TeacherModel> teachers;

  const RecentAudiencesWidget({super.key, required this.types, required this.teachers});

  @override
  State<RecentAudiencesWidget> createState() => _RecentAudiencesWidgetState();
}

class _RecentAudiencesWidgetState extends State<RecentAudiencesWidget> {
  final _repo = AudiencesRepository();
  List<AudiencesItemModel> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    await _loadRecent();
  }

  Future<void> _loadRecent() async {
    final items = await _repo.getRecent(limit: 5);
    if (!mounted) return;
    setState(() => _recentItems = items);
  }

  Future<void> _openAddAudienceModal() async {
    final result = await showDialog<AudiencesItemModel>(
      context: context,
      builder: (ctx) => _AddAudienceDialog(types: widget.types, teachers: widget.teachers),
    );
    if (result != null) {
      await _repo.insert(result);
      await _loadRecent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Недавние аудитории', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final item in _recentItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item.typeName ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddAudienceModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
          )
        ],
      ),
    );
  }
}

class _AddAudienceDialog extends StatefulWidget {
  final List<AudienceTypeModel> types;
  final List<TeacherModel> teachers;

  const _AddAudienceDialog({required this.types, required this.teachers});

  @override
  State<_AddAudienceDialog> createState() => _AddAudienceDialogState();
}

class _AddAudienceDialogState extends State<_AddAudienceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
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
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _typeId == null) return;
    final model = AudiencesItemModel(
      name: _nameCtrl.text.trim(),
      capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 0,
      typeId: _typeId!,
      headTeacherId: _teacherId,
      equipmentList: const [],
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  ...widget.teachers.where((t) => t.id != null).map(
                        (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                      ),
                ],
                onChanged: (value) => setState(() => _teacherId = value),
              ),
              TextFormField(
                controller: _capacityCtrl,
                decoration: const InputDecoration(labelText: 'Вместимость'),
                keyboardType: TextInputType.number,
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
    );
  }
}
