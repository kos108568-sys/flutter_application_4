import 'package:flutter/material.dart';
import '../../buildings/data/building_repository.dart';
import '../../buildings/data/building_model.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});
  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  final repo = BuildingRepository();
  List<Building> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await repo.getAllBuildings();
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _openForm({Building? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final addressController = TextEditingController(text: item?.address ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'Добавить корпус' : 'Редактировать корпус'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Адрес')),
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
      final addr = addressController.text.trim().isEmpty ? null : addressController.text.trim();
      final desc = descController.text.trim().isEmpty ? null : descController.text.trim();
      if (item == null) {
        await repo.insertBuilding(Building(name: nameController.text.trim(), address: addr, description: desc));
      } else {
        await repo.updateBuilding(Building(id: item.id, name: nameController.text.trim(), address: addr, description: desc));
      }
      await _load();
    }
  }

  Future<void> _delete(int id) async {
    await repo.deleteBuilding(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Корпусы')),
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
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (e.address != null && e.address!.isNotEmpty) Text(e.address!),
                    if (e.description != null && e.description!.isNotEmpty) Text(e.description!),
                  ]),
                  onTap: () => _openForm(item: e),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(e.id!)),
                );
              },
            ),
    );
  }
}


