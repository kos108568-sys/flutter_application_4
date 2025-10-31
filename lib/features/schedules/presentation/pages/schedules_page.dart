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
      ScheduleModel(groupName: 'ИТ-42', imageUrl: ''),
      ScheduleModel(groupName: 'ИТ-41', imageUrl: ''),
      ScheduleModel(groupName: 'Э-11', imageUrl: ''),
      ScheduleModel(groupName: 'ИТ-123', imageUrl: ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const SidebarMenu(selected: 'Расписания'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Расписания', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    _buildGrid(schedules),
                    const SizedBox(height: 24),
                    const Text('Недавние', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),
                    _buildGrid(schedules),
                    const SizedBox(height: 24),
                    // Навигация для тестовых разделов и справочников
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test-departments');
                          },
                          icon: const Icon(Icons.business),
                          label: const Text('Кафедры'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test-audience-types');
                          },
                          icon: const Icon(Icons.meeting_room),
                          label: const Text('Типы аудиторий'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test-lesson-types');
                          },
                          icon: const Icon(Icons.school),
                          label: const Text('Типы занятий'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/equipments');
                          },
                          icon: const Icon(Icons.devices_other),
                          label: const Text('Оборудование'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/buildings');
                          },
                          icon: const Icon(Icons.location_city),
                          label: const Text('Корпуса'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/time-slots');
                          },
                          icon: const Icon(Icons.access_time),
                          label: const Text('Временные слоты'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
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

