import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/settings_item_model.dart';

class SettingsCard extends StatelessWidget {
  final SettingsItemModel item;
  final VoidCallback onTap;

  const SettingsCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      hoverColor: Colors.grey.withOpacity(0.1),
      child: Column(
        children: [
          Container(
            width: 310,
            height: 190,
            decoration: BoxDecoration(
              color: item.imageUrl.isEmpty ? AppColors.cardPlaceholder : null,
              borderRadius: BorderRadius.circular(16),
              image: item.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(item.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
