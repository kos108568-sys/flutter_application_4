import 'package:flutter/material.dart';
import '../../data/audience_model.dart';
import '../../data/audiences_repository.dart';

class RecentAudiencesWidget extends StatefulWidget {
  const RecentAudiencesWidget({super.key});

  @override
  State<RecentAudiencesWidget> createState() => _RecentAudiencesWidgetState();
}

class _RecentAudiencesWidgetState extends State<RecentAudiencesWidget> {
  final _repo = AudiencesRepository();
  List<Audience> _recentItems = [];

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
    final result = await showModalBottomSheet<Audience>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddAudienceBottomSheet(),
    );

    if (result != null) {
      await _repo.insertAudience(result);
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
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Недавние аудитории',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          for (final item in _recentItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MiniAudienceCard(item: item),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openAddAudienceModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAudienceCard extends StatelessWidget {
  final Audience item;
  const _MiniAudienceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                if (item.capacity != null)
                  Text('Вместимость: ${item.capacity}',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(item.notes!,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}

class _AddAudienceBottomSheet extends StatefulWidget {
  const _AddAudienceBottomSheet();

  @override
  State<_AddAudienceBottomSheet> createState() => _AddAudienceBottomSheetState();
}

class _AddAudienceBottomSheetState extends State<_AddAudienceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final capacity = int.tryParse(_capacityCtrl.text.trim());

    final item = Audience(
      name: _nameCtrl.text.trim(),
      capacity: capacity,
      audienceTypeId: null,
      buildingId: null,
      responsibleTeacherId: null,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    Navigator.of(context).pop(item);
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
                const Text(
                  'Новая аудитория',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Название'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите название'
                      : null,
                ),
                TextFormField(
                  controller: _capacityCtrl,
                  decoration: const InputDecoration(labelText: 'Вместимость'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Заметки'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

