import 'package:flutter/material.dart';
import '../../data/discipline_model.dart';
import '../../data/disciplines_repository.dart';

class RecentDisciplinesWidget extends StatefulWidget {
  const RecentDisciplinesWidget({super.key});

  @override
  State<RecentDisciplinesWidget> createState() => _RecentDisciplinesWidgetState();
}

class _RecentDisciplinesWidgetState extends State<RecentDisciplinesWidget> {
  final _repo = DisciplinesRepository();
  List<Discipline> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _load();
  }

  Future<void> _load() async {
    final items = await _repo.getAllDisciplines(orderBy: 'name ASC');
    if (!mounted) return;
    setState(() {
      _items = items.take(5).toList();
    });
  }

  Future<void> _openAddModal() async {
    final result = await showDialog<Discipline>(
      context: context,
      builder: (ctx) => const _AddDisciplineDialog(),
    );
    if (result != null) {
      await _repo.insertDiscipline(result);
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
          const Text('Недавние дисциплины', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final d in _items)
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
                        Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (d.semester != null && d.semester!.isNotEmpty)
                          Text('Семестр: ${d.semester}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
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

class _AddDisciplineDialog extends StatefulWidget {
  const _AddDisciplineDialog();
  @override
  State<_AddDisciplineDialog> createState() => _AddDisciplineDialogState();
}

class _AddDisciplineDialogState extends State<_AddDisciplineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _semester = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _semester.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final model = Discipline(
      name: _name.text.trim(),
      lessonTypeId: null,
      semester: _semester.text.trim().isEmpty ? null : _semester.text.trim(),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новая дисциплина', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Название'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Название обязательно' : null,
                ),
                TextFormField(controller: _semester, decoration: const InputDecoration(labelText: 'Семестр'), keyboardType: TextInputType.text),
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

