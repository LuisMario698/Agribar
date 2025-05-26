import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? const Color(0xFF0B7A2F) : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 48,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0B7A2F) : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onFilterChanged;

  const FilterBar({
    Key? key,
    required this.filters,
    required this.selectedIndex,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: filters.asMap().entries.map((entry) {
        return FilterButton(
          label: entry.value,
          selected: selectedIndex == entry.key,
          onTap: () => onFilterChanged(entry.key),
        );
      }).toList(),
    );
  }
}
