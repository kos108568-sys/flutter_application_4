import 'package:flutter/material.dart';
import '../../data/audiences_item_model.dart';

class AudienceCard extends StatelessWidget {
  final AudiencesItemModel audience;
  final VoidCallback? onTap;

  const AudienceCard({super.key, required this.audience, this.onTap});

  Color _getTypeColor(String? type) {
    switch ((type ?? '').toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getTypeColor(audience.typeName),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  audience.typeName ?? 'Тип не указан',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text("Вместимость: ${audience.capacity}", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            Text("Заведующий: ${audience.headTeacherName ?? '—'}", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            if (audience.building != null && audience.building!.isNotEmpty)
              Text("Корпус: ${audience.building}", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            if (audience.equipmentList.isNotEmpty)
              Text(
                "Оборудование: ${audience.equipmentList.join(', ')}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
