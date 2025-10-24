import 'package:flutter/material.dart';
import 'package:flutter_application_4/core/widgets/custom_button.dart';

class RecentAudiencesWidget extends StatelessWidget {
  const RecentAudiencesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = ['Ауд. 203', 'Ауд. 312', 'Ауд. 108'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Последние добавленные',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Используем Column вместо ListView
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recent
                  .map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(r),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 12),
           CustomButton(text: "Добавить", onPressed: () {},),
          ],
        ),
      ),
    );
  }
}
