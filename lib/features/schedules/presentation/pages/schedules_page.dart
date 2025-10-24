import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../../../core/widgets/schedule_card.dart';
import '../../data/schedule_model.dart';
import '../../../../core/constants/app_colors.dart';

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = [
      ScheduleModel(groupName: 'ПО-42', imageUrl: 'assets/schedule1.png'),
      ScheduleModel(groupName: 'ПО-41', imageUrl: ''),
      ScheduleModel(groupName: 'У-11', imageUrl: 'assets/schedule2.png'),
      ScheduleModel(groupName: 'ТМО-123', imageUrl: ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const SidebarMenu(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Недавние", style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    _buildGrid(schedules),
                    const SizedBox(height: 24),
                    const Text("Избранное", style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    _buildGrid(schedules),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ScheduleModel> items) {
    return Wrap(
      spacing: 40,
      runSpacing: 20,
      children: items.map((e) => ScheduleCard(schedule: e)).toList(),
    );
  }
}
