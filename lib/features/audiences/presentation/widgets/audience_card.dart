import 'package:flutter/material.dart';
import '../../data/audiences_item_model.dart';

class AudienceCard extends StatelessWidget {
  final AudiencesItemModel audience;
  final VoidCallback? onTap; // новый параметр

  const AudienceCard({super.key, required this.audience, this.onTap});

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'компьютерная':
        return Colors.blueAccent;
      case 'лекционная':
        return Colors.orangeAccent;
      case 'лабораторная':
        return Colors.green;
      case 'семинарская':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // добавляем обработку нажатия
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              audience.name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getTypeColor(audience.type),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(audience.type,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text("Вместимость: ${audience.capacity}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            Text("Ответственный: ${audience.boss}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
