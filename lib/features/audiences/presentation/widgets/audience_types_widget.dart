import 'package:flutter/material.dart';
import '../../data/audience_type_model.dart';

class AudienceTypesWidget extends StatelessWidget {
  final List<AudienceTypeModel> types;

  const AudienceTypesWidget({super.key, required this.types});

  static const _palette = [
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Типы аудиторий',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (types.isEmpty)
            const Text('Нет данных', style: TextStyle(color: Colors.grey))
          else
            ...types.asMap().entries.map((entry) {
              final color = _palette[entry.key % _palette.length];
              final type = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.typeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (type.description?.isNotEmpty ?? false)
                            Text(type.description!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
