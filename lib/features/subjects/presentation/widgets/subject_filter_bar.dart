import 'package:flutter/material.dart';

class SubjectFilterBar extends StatefulWidget {
  final void Function(String query) onFilterChanged;
  final void Function(String sortBy) onSortChanged;
  final void Function(bool grid) onViewChanged;
  final bool isGridView;

  const SubjectFilterBar({
    super.key,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onViewChanged,
    required this.isGridView,
  });

  @override
  State<SubjectFilterBar> createState() => _SubjectFilterBarState();
}

class _SubjectFilterBarState extends State<SubjectFilterBar> {
  String _selectedSort = 'name';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: widget.onFilterChanged,
            decoration: InputDecoration(
              hintText: 'Поиск предметов...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _selectedSort,
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Сортировать по названию')),
            DropdownMenuItem(value: 'hours', child: Text('Сортировать по часам')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSort = value);
              widget.onSortChanged(value);
            }
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Плитка',
          onPressed: () => widget.onViewChanged(true),
          icon: Icon(Icons.grid_view, color: widget.isGridView ? Colors.blueAccent : Colors.black54),
        ),
        IconButton(
          tooltip: 'Список',
          onPressed: () => widget.onViewChanged(false),
          icon: Icon(Icons.list, color: !widget.isGridView ? Colors.blueAccent : Colors.black54),
        ),
      ],
    );
  }
}
