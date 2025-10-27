import 'package:flutter/material.dart';
import '../../data/teacher_model.dart';
import '../../data/teachers_repository.dart';

class RecentTeachersWidget extends StatefulWidget {
  const RecentTeachersWidget({super.key});

  @override
  State<RecentTeachersWidget> createState() => _RecentTeachersWidgetState();
}

class _RecentTeachersWidgetState extends State<RecentTeachersWidget> {
  final _repo = TeachersRepository();
  List<TeacherModel> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.seedIfEmpty();
    await _load();
  }

  Future<void> _load() async {
    final items = await _repo.getRecent(limit: 5);
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _openAddModal() async {
    final result = await showDialog<TeacherModel>(
      context: context,
      builder: (ctx) => const _AddTeacherDialog(),
    );
    if (result != null) {
      await _repo.insert(result);
      await _load();
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
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Новые преподаватели', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final t in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
          )
        ],
      ),
    );
  }
}

class _AddTeacherDialog extends StatefulWidget {
  const _AddTeacherDialog();
  @override
  State<_AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<_AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final model = TeacherModel(fullName: _fullName.text.trim(), curatorGroupId: null, disciplineIds: const [], audienceIds: const []);
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
              const Text('Новый преподаватель', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'ФИО'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Укажите ФИО' : null,
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

