import 'package:flutter/material.dart';
import 'package:flutter_application_4/features/audiences/presentation/pages/audiences_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sidebar_menu.dart';
import '../../data/settings_item_model.dart';
import '../widgets/settings_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      SettingsItemModel(title: "Аудитории", imageUrl: "assets/images/settings/image4.png"),
      SettingsItemModel(title: "Дисциплины", imageUrl: "assets/images/settings/image5.png"),
      SettingsItemModel(title: "Преподаватели", imageUrl: "assets/images/settings/image6.png"),
      SettingsItemModel(title: "Отделения", imageUrl: ""),
      SettingsItemModel(title: "Группы", imageUrl: ""),
      SettingsItemModel(title: "Учебный план", imageUrl: ""),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SidebarMenu(selected: "Настройки"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Настройки", style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 40,
                      runSpacing: 30,
                      children: items.map((item) {
                        return SettingsCard(
                          item: item,
                          onTap: () {
                             if (item.title == "Аудитории") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AudiencesScreen(),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
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
}
