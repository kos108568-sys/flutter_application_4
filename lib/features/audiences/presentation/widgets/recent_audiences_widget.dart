import 'package:flutter/material.dart';

import '../../../audience_types/data/audience_type_model.dart';
import '../../data/audience_model.dart';
import '../../data/audiences_repository.dart';

class RecentAudiencesWidget extends StatefulWidget {
  const RecentAudiencesWidget({super.key});

  @override
  State<RecentAudiencesWidget> createState() => _RecentAudiencesWidgetState();
}

class _RecentAudiencesWidgetState extends State<RecentAudiencesWidget> {
  final _audiencesRepo = AudiencesRepository();

  List<Audience> _recentItems = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final items = await _audiencesRepo.getRecent(limit: 5);
      if (!mounted) return;
      setState(() => _recentItems = items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Недавние аудитории',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_recentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Список пуст.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._recentItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MiniAudienceCard(
                  item: item,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAudienceCard extends StatelessWidget {
  final Audience item;

  const _MiniAudienceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if ((item.type ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.type!,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ),
                if (item.capacity != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Вместимость: ${item.capacity}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
