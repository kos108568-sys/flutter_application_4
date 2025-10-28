import 'package:flutter/material.dart';
import '../../equipments/data/equipment_repository.dart';
import '../../equipments/data/equipment_model.dart';

class EquipmentsScreen extends StatefulWidget {
  const EquipmentsScreen({super.key});
  @override
  State<EquipmentsScreen> createState() => _EquipmentsScreenState();
}

class _EquipmentsScreenState extends State<EquipmentsScreen> {
  final repo = EquipmentRepository();
  List<Equipment> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await repo.getAllEquipments();
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _openForm({Equipment? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Добавить оборудование' : 'Редактировать оборудование'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название')),
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
      if (item == null) {
        await repo.insertEquipment(Equipment(name: nameController.text.trim(), description: descController.text.trim().isEmpty ? null : descController.text.trim()));
      } else {
        await repo.updateEquipment(Equipment(id: item.id, name: nameController.text.trim(), description: descController.text.trim().isEmpty ? null : descController.text.trim()));
      }
      await _load();
    }
  }

  Future<void> _delete(int id) async {
    await repo.deleteEquipment(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оборудование')),
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
                  title: Text(e.name),
                  subtitle: e.description == null ? null : Text(e.description!),
                  onTap: () => _openForm(item: e),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(e.id!)),
                );
              },
            ),
    );
  }
}


