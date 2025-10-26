import 'package:flutter/material.dart';
import '../../data/subject_model.dart';
import '../../data/subjects_repository.dart';

class RecentSubjectsWidget extends StatefulWidget {
  const RecentSubjectsWidget({super.key});

  @override
  State<RecentSubjectsWidget> createState() => _RecentSubjectsWidgetState();
}

class _RecentSubjectsWidgetState extends State<RecentSubjectsWidget> {
  final _repo = SubjectsRepository();
  List<SubjectModel> _items = [];

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
    final result = await showDialog<SubjectModel>(
      context: context,
      builder: (ctx) => const _AddSubjectDialog(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Последние предметы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final subject in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Семестр: ${subject.semester}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
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

class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _hours = TextEditingController();
  String _semester = '1';

  @override
  void dispose() {
    _name.dispose();
    _hours.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final model = SubjectModel(
      name: _name.text.trim(),
      hours: int.tryParse(_hours.text.trim()) ?? 0,
      semester: _semester,
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
              const Text('Новый предмет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Название обязательно' : null,
              ),
              TextFormField(
                controller: _hours,
                decoration: const InputDecoration(labelText: 'Количество часов'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _semester,
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1 семестр')),
                  DropdownMenuItem(value: '2', child: Text('2 семестр')),
                  DropdownMenuItem(value: 'year', child: Text('Учебный год')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _semester = value);
                },
                decoration: const InputDecoration(labelText: 'Семестр'),
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
