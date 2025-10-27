import 'package:flutter/material.dart';

class AudienceTypesWidget extends StatelessWidget {
  const AudienceTypesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'name': 'Компьютерная', 'color': Colors.purple},
      {'name': 'Лекционная', 'color': Colors.green},
      {'name': 'Лаборатория', 'color': Colors.red},
      {'name': 'Конференц-зал', 'color': Colors.orange},
      {'name': 'Актовый зал', 'color': Colors.pink},
    ];

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
            'Типы аудиторий',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // список типов
          ...types.map((type) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: type['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(type['name'] as String),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: обработка нажатия "Редактировать"
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Редактировать'),
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
