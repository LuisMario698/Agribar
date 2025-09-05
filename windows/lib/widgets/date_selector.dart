import 'package:flutter/material.dart';

/// Selector de fecha personalizado con formato dd/mm/yyyy.
///
/// Este widget implementa un selector de fecha con las siguientes características:
/// - Diseño minimalista con fondo semi-transparente
/// - Bordes redondeados
/// - Formato de fecha en español (dd/mm/yyyy)
/// - Placeholder cuando no hay fecha seleccionada
/// - Comportamiento táctil con efecto de tinta
///
/// Se utiliza principalmente en pantallas que requieren filtrado por fechas,
/// como la pantalla de reportes y consultas históricas.
class DateSelector extends StatelessWidget {
  /// Fecha seleccionada actualmente. Null si no hay fecha seleccionada.
  final DateTime? date;
  /// Función que se ejecuta al tocar el selector para elegir una fecha
  final VoidCallback onTap;

  const DateSelector({
    Key? key,
    required this.date,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(118, 206, 206, 206),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                date != null
                  ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                  : 'dd/mm/yyyy',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(bool) onDateSelect;

  const DateRangeSelector({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.onDateSelect,
  }) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DateSelector(
          date: startDate,
          onTap: () => onDateSelect(true),
        ),
        const Text(
          '  →  ',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        DateSelector(
          date: endDate,
          onTap: () => onDateSelect(false),
        ),
      ],
    );
  }
}
