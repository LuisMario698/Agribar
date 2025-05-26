import 'package:flutter/material.dart';

/// Widget modular para filtrar por semana y cuadrilla.
class FilterBar extends StatelessWidget {
  final String weekLabel;
  final VoidCallback onWeekTap;
  final List<String> optionsCuadrilla;
  final String? selectedCuadrilla;
  final ValueChanged<String?> onCuadrillaChanged;

  const FilterBar({
    Key? key,
    required this.weekLabel,
    required this.onWeekTap,
    required this.optionsCuadrilla,
    required this.selectedCuadrilla,
    required this.onCuadrillaChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green[900])),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onWeekTap,
                    child: Text(weekLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Cuadrilla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green[900])),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: selectedCuadrilla,
                    isExpanded: true,
                    items: optionsCuadrilla
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: onCuadrillaChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
