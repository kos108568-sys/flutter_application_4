import 'package:flutter/material.dart';
import '../../data/audience_model.dart';

class AudienceCard extends StatelessWidget {
  final Audience audience;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AudienceCard({super.key, required this.audience, this.onTap, this.onEdit, this.onDelete});

  Color _dotColor() => Colors.grey;

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
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    audience.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (audience.capacity != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _dotColor(), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('Capacity: ${audience.capacity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ]
              ],
            ),
            const SizedBox(height: 12),
            if (audience.notes != null && audience.notes!.isNotEmpty)
              Text(
                audience.notes!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
