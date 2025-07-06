import 'package:flutter/material.dart';

/// Widget modular para filtrar por semana y cuadrilla.
class FilterBar extends StatelessWidget {
  final String weekLabel;
  final VoidCallback onWeekTap;
  final List<String> optionsCuadrilla;
  final String? selectedCuadrilla;
  final ValueChanged<String?> onCuadrillaChanged;
  final bool showCloseWeekButton;
  final VoidCallback? onCloseWeek;

  const FilterBar({
    Key? key,
    required this.weekLabel,
    required this.onWeekTap,
    required this.optionsCuadrilla,
    required this.selectedCuadrilla,
    required this.onCuadrillaChanged,
    this.showCloseWeekButton = false,
    this.onCloseWeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 380, // Reducido de 480
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Semana',
                    style: TextStyle(
                      fontSize: 18, // Aumentado de 16
                      fontWeight: FontWeight.w500,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 16), // Aumentado de 12
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onWeekTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22), // Aumentado padding
                          ),
                          child: Text(weekLabel, style: const TextStyle(fontSize: 15)), // Añadido tamaño de texto
                        ),
                      ),
                      if (showCloseWeekButton) ...[
                        const SizedBox(width: 12), // Aumentado de 8
                        SizedBox(
                          height: 48, // Aumentado de 42
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.lock, color: Colors.white, size: 22), // Aumentado de 20
                            label: const Text('Cerrar', style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B7A2F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Aumentado padding
                            ),
                            onPressed: onCloseWeek,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20), // Aumentado de 16
        SizedBox(
          width: 380, // Aumentado de 300
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28), // Aumentado padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cuadrilla',
                    style: TextStyle(
                      fontSize: 18, // Aumentado de 16
                      fontWeight: FontWeight.w500,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 16), // Aumentado de 12
                  SizedBox(
                    height: 48, // Aumentado de 42
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Aumentado de 12
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(6), // Aumentado de 4
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCuadrilla,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          style: const TextStyle(fontSize: 15, color: Colors.black87), // Añadido estilo
                          items: optionsCuadrilla
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: onCuadrillaChanged,
                        ),
                      ),
                    ),
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
