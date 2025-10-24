import 'package:flutter/material.dart';
import 'package:flutter_application_4/features/audiences/data/audiences_item_model.dart';
import 'package:flutter_application_4/features/audiences/presentation/widgets/audience_types_widget.dart';
import '../widgets/audience_card.dart';
import '../widgets/recent_audiences_widget.dart';
import '../../../../core/widgets/sidebar_menu.dart';

class AudiencesScreen extends StatelessWidget {
  const AudiencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      AudiencesItemModel(
        name: 'Аудитория 101',
        type: 'Лекционная',
        capacity: 35,
        boss: 'Иванов И.И.',
      ),
      AudiencesItemModel(
        name: 'Аудитория 203',
        type: 'Компьютерная',
        capacity: 20,
        boss: 'Петров П.П.',
      ),
      AudiencesItemModel(
        name: 'Аудитория 310',
        type: 'Лабораторная',
        capacity: 15,
        boss: 'Сидоров С.С.',
      ),
      AudiencesItemModel(
        name: 'Аудитория 412',
        type: 'Лекционная',
        capacity: 40,
        boss: 'Алексеев А.А.',
      ),
    ];

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая панель
          SidebarMenu(selected: 'Аудитории'),

          // Основной контент
          Expanded(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Аудитории",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // GridView с 2 колонками
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 колонки
              mainAxisSpacing: 16, // вертикальный отступ между карточками
              crossAxisSpacing: 16, // горизонтальный отступ
              childAspectRatio: 3 / 2.5, // ширина/высота карточки
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return AudienceCard(audience: items[index]);
            },
          ),
        ),
      ],
    ),
  ),
),

          // Отступ между контентом и правой панелью
          const SizedBox(width: 10),

          // Правая панель с ограниченной высотой
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 250,
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 24, right: 24),
              child: ListView(
                children: const [
                  AudienceTypesWidget(),
                  SizedBox(height: 24),
                  RecentAudiencesWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
