import 'package:flutter/material.dart';

typedef OnFilterChanged = void Function(String query);
typedef OnSortChanged = void Function(String sortBy);
typedef OnViewChanged = void Function(bool isGridView);

class AudienceFilterBar extends StatefulWidget {
  final OnFilterChanged onFilterChanged;
  final OnSortChanged onSortChanged;
  final OnViewChanged onViewChanged;
  final bool isGridView;

  const AudienceFilterBar({
    super.key,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onViewChanged,
    required this.isGridView,
  });

  @override
  State<AudienceFilterBar> createState() => _AudienceFilterBarState();
}

class _AudienceFilterBarState extends State<AudienceFilterBar> {
  final TextEditingController _controller = TextEditingController();
  String _selectedSort = 'name';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // === Поле поиска ===
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onFilterChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск аудитории...',
                border: InputBorder.none,
                hintStyle:
                    TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // === Выпадающее меню сортировки ===
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.sort_rounded),
              items: const [
                DropdownMenuItem(
                  value: 'name',
                  child: Text('По названию'),
                ),
                DropdownMenuItem(
                  value: 'type',
                  child: Text('По типу'),
                ),
                DropdownMenuItem(
                  value: 'capacity',
                  child: Text('По вместимости'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSort = value);
                  widget.onSortChanged(value);
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // === Кнопки вида (сетка/список) ===
          IconButton(
            icon: Icon(Icons.grid_view_rounded,
                color: widget.isGridView ? Colors.blue : Colors.grey),
            onPressed: () => widget.onViewChanged(true),
          ),
          IconButton(
            icon: Icon(Icons.view_list_rounded,
                color: !widget.isGridView ? Colors.blue : Colors.grey),
            onPressed: () => widget.onViewChanged(false),
          ),
        ],
      ),
    );
  }
}
