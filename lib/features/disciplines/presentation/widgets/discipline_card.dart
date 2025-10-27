import 'package:flutter/material.dart';
import '../../data/discipline_model.dart';

class DisciplineCard extends StatelessWidget {
  final DisciplineModel discipline;
  final String? groupsLine;
  final VoidCallback? onTap;
  const DisciplineCard({super.key, required this.discipline, this.groupsLine, this.onTap});

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
            Text(
              discipline.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (groupsLine != null && groupsLine!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.group, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      groupsLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${discipline.hours} ch.', style: const TextStyle(color: Colors.grey)),
            ])
          ],
        ),
      ),
    );
  }
}
