import 'package:flutter/material.dart';
import 'package:flutter_application_4/features/schedules/data/schedule_model.dart';
import '../../core/constants/app_colors.dart';


class ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 160,
          decoration: BoxDecoration(
            color: schedule.imageUrl.isEmpty ? AppColors.cardPlaceholder : null,
            borderRadius: BorderRadius.circular(12),
            image: schedule.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(schedule.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(schedule.groupName, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
