import 'package:flutter/material.dart';
import 'package:flutter_application_4/features/audiences/data/audiences_item_model.dart';

class AudienceCard extends StatelessWidget {
  final AudiencesItemModel audience;

  const AudienceCard({super.key, required this.audience});

  // Цвет точки в зависимости от типа аудитории
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'компьютерная':
        return Colors.blueAccent;
      case 'лекционная':
        return Colors.orangeAccent;
      case 'лабораторная':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Функция для открытия модального окна редактирования
  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: audience.name);
    final typeController = TextEditingController(text: audience.type);
    final capacityController = TextEditingController(text: audience.capacity.toString());
    final bossController = TextEditingController(text: audience.boss);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать аудиторию'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Тип'),
                ),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Вместимость'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: bossController,
                  decoration: const InputDecoration(labelText: 'Ответственный'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                // Здесь можно сохранить изменения, например, обновить модель
                audience.name = nameController.text;
                audience.type = typeController.text;
                audience.capacity = int.tryParse(capacityController.text) ?? audience.capacity;
                audience.boss = bossController.text;

                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audience.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getTypeColor(audience.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      audience.type,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Вместимость: ${audience.capacity}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  'Ответственный: ${audience.boss}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            // Иконка редактирования справа посредине
            Positioned(
              right: 0,
              top: 24,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () => _showEditDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
