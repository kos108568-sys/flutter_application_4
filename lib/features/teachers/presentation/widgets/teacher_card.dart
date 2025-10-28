import 'package:flutter/material.dart';
import '../../data/teacher_model.dart';

class TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final String? curatorGroupName;
  final VoidCallback? onTap;
  const TeacherCard({super.key, required this.teacher, this.curatorGroupName, this.onTap});

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
              teacher.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (curatorGroupName != null)
              Row(
                children: [
                  const Icon(Icons.group, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Куратор: ' + (curatorGroupName ?? '—'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            if (teacher.email != null && teacher.email!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(teacher.email!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            if (teacher.phone != null && teacher.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(teacher.phone!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

