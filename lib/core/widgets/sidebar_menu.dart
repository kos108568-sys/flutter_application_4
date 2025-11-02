import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/custom_button.dart';
import 'package:flutter_application_4/features/schedules/presentation/pages/detailed_schedule_page.dart';
import '../../features/schedules/presentation/pages/schedules_page.dart';
import '../../features/disciplines/presentation/pages/disciplines_page.dart';
import '../../features/groups/presentation/pages/groups_screen.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

import '../../features/departments/presentation/departments_screen.dart';
import '../constants/app_colors.dart';

class SidebarMenu extends StatelessWidget {
  final String? selected;

  const SidebarMenu({super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.sidebar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
            const SizedBox(height: 8),
            const Text('Иванов И. И.', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('Администратор', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            const Divider(),
            _navItem(context, Icons.home, 'Расписания', const SchedulesPage()),
            _navItem(context, Icons.menu_book, 'Дисциплины', const DisciplinesPage()),
            _navItem(context, Icons.group, 'Группы', const GroupsScreen()),
            _navItem(context, Icons.business, 'Кафедры', const DepartmentsScreen()),
            _navItem(context, Icons.schedule, 'Детальное расписание', const DetailedSchedulePage()),
            _navItem(context, Icons.calendar_today, 'Календарь', null),
            _navItem(context, Icons.settings, 'Настройки', const SettingsPage()),
            const Spacer(),
            CustomButton(text: 'Выйти', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, Widget? page) {
    final isActive = selected == label;

    return InkWell(
      onTap: page == null
          ? null
          : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.accent : Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accent : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

