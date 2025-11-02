import 'package:flutter/material.dart';

import '../../data/audience_model.dart';

class AudienceCard extends StatelessWidget {
  final Audience audience;
  final String? teacherName;
  final List<String> lessonTypeNames;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AudienceCard({
    super.key,
    required this.audience,
    this.teacherName,
    this.lessonTypeNames = const [],
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Редактировать',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                  ),
              ],
            ),
            if ((audience.type ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                audience.type!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (audience.capacity != null)
                  _InfoRow(
                    icon: Icons.people_alt_outlined,
                    label: 'Вместимость',
                    value: '${audience.capacity}',
                  ),
                if (teacherName != null && teacherName!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Ответственный',
                    value: teacherName!,
                  ),
                if (audience.buildingId != null)
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Корпус',
                    value: '#${audience.buildingId}',
                  ),
              ],
            ),
            if (lessonTypeNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lessonTypeNames
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor: Colors.blueGrey[50],
                      ),
                    )
                    .toList(),
              ),
            ],
            if (audience.notes != null && audience.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                audience.notes!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey[400]),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: textTheme.bodySmall?.copyWith(
            color: Colors.blueGrey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
        ),
      ],
    );
  }
}
