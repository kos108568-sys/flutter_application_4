import 'package:flutter/material.dart';
import '../../data/group_model.dart';
import '../../data/groups_repository.dart';

class RecentGroupsWidget extends StatefulWidget {
  const RecentGroupsWidget({super.key});

  @override
  State<RecentGroupsWidget> createState() => _RecentGroupsWidgetState();
}

class _RecentGroupsWidgetState extends State<RecentGroupsWidget> {
  final _repo = GroupsRepository();
  List<GroupModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _repo.seedIfEmpty();
    final items = await _repo.getRecent(limit: 5);
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _openAddModal() async {
    final result = await showDialog<GroupModel>(
      context: context,
      builder: (ctx) => const _AddGroupDialog(),
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
          const Text('Новые группы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final g in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.group, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Куратор: ${g.curator ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
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

class _AddGroupDialog extends StatefulWidget {
  const _AddGroupDialog();
  @override
  State<_AddGroupDialog> createState() => _AddGroupDialogState();
}

class _AddGroupDialogState extends State<_AddGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _curator = TextEditingController();
  final _course = TextEditingController();
  final _specialty = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _curator.dispose();
    _course.dispose();
    _specialty.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final model = GroupModel(
      name: _name.text.trim(),
      size: int.tryParse(_size.text.trim()),
      curator: _curator.text.trim().isEmpty ? null : _curator.text.trim(),
      course: int.tryParse(_course.text.trim()),
      specialty: _specialty.text.trim().isEmpty ? null : _specialty.text.trim(),
      disciplineIds: const [],
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
              const Text('Новая группа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Укажите название' : null,
              ),
              TextFormField(
                controller: _specialty,
                decoration: const InputDecoration(labelText: 'Специальность'),
              ),
              TextFormField(
                controller: _curator,
                decoration: const InputDecoration(labelText: 'Куратор'),
              ),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _size,
                    decoration: const InputDecoration(labelText: 'Количество'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _course,
                    decoration: const InputDecoration(labelText: 'Курс'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
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

