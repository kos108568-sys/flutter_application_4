import 'package:flutter/material.dart';

class GroupFilterBar extends StatelessWidget {
  final void Function(String query) onFilterChanged;
  final void Function(String sortBy) onSortChanged;
  final void Function(bool grid) onViewChanged;
  final bool isGridView;

  const GroupFilterBar({
    super.key,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onViewChanged,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onFilterChanged,
            decoration: InputDecoration(
              hintText: 'Поиск по названию, куратору, специальности',
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
          value: 'name',
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Сортировка: Название')),
            DropdownMenuItem(value: 'size', child: Text('Сортировка: Размер')),
            DropdownMenuItem(value: 'course', child: Text('Сортировка: Курс')),
          ],
          onChanged: (v) => onSortChanged(v ?? 'name'),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Сетка',
          onPressed: () => onViewChanged(true),
          icon: Icon(Icons.grid_view, color: isGridView ? Colors.blueAccent : Colors.black54),
        ),
        IconButton(
          tooltip: 'Список',
          onPressed: () => onViewChanged(false),
          icon: Icon(Icons.list, color: !isGridView ? Colors.blueAccent : Colors.black54),
        ),
      ],
    );
  }
}

