import 'package:flutter/material.dart';
import '../../time_slots/data/time_slot_repository.dart';
import '../../time_slots/data/time_slot_model.dart';

class TimeSlotsScreen extends StatefulWidget {
  const TimeSlotsScreen({super.key});
  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  final repo = TimeSlotRepository();
  List<TimeSlot> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await repo.getAllTimeSlots();
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _openForm({TimeSlot? item}) async {
    final orderController = TextEditingController(text: item?.orderNumber.toString() ?? '');
    final startController = TextEditingController(text: item?.startTime ?? '');
    final endController = TextEditingController(text: item?.endTime ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Добавить слот' : 'Редактировать слот'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: orderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '№ пары')),
            TextField(controller: startController, decoration: const InputDecoration(labelText: 'Начало (HH:MM)')),
            TextField(controller: endController, decoration: const InputDecoration(labelText: 'Конец (HH:MM)')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Описание')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
        ],
      ),
    );
    if (result == true) {
      final order = int.tryParse(orderController.text.trim());
      if (order == null) return;
      final slot = TimeSlot(
        id: item?.id,
        orderNumber: order,
        startTime: startController.text.trim(),
        endTime: endController.text.trim(),
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
      );
      if (item == null) {
        await repo.insertTimeSlot(slot);
      } else {
        await repo.updateTimeSlot(slot);
      }
      await _load();
    }
  }

  Future<void> _delete(int id) async {
    await repo.deleteTimeSlot(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Временные слоты')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final e = items[i];
                return ListTile(
                  title: Text('${e.orderNumber}. ${e.startTime} - ${e.endTime}'),
                  subtitle: e.description == null ? null : Text(e.description!),
                  onTap: () => _openForm(item: e),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(e.id!)),
                );
              },
            ),
    );
  }
}


