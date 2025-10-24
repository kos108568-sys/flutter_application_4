import 'package:flutter/material.dart';

class AudienceTypesWidget extends StatelessWidget {
  const AudienceTypesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final types = ['Лекционная', 'Компьютерная', 'Лаборатория', 'Спортивная', 'Актовый зал'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Типы аудиторий',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            for (final type in types)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(type),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
