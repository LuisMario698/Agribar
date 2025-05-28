/// Widget para el formulario principal de la pantalla de nómina
/// Incluye selección de cuadrilla y fechas (semana)

import 'package:flutter/material.dart';
import '../../../widgets/common/custom_input_field.dart';
import '../../../widgets/common/custom_dropdown_field.dart';
import '../../../widgets/common/custom_date_picker_field.dart';

class NominaForm extends StatelessWidget {
  final List<Map<String, String>> cuadrillas;
  final String? cuadrillaSeleccionada;
  final DateTimeRange? semanaSeleccionada;
  final Function(String?) onCuadrillaChanged;
  final Function(DateTimeRange?) onWeekSelected;

  const NominaForm({
    Key? key,
    required this.cuadrillas,
    required this.cuadrillaSeleccionada,
    required this.semanaSeleccionada,
    required this.onCuadrillaChanged,
    required this.onWeekSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Selector de cuadrilla
          Expanded(
            child: CustomDropdownField<String>(
              label: 'Cuadrilla',
              value: cuadrillaSeleccionada,
              items: cuadrillas.map((c) => c['nombre']!).toList(),
              itemLabel: (item) => item,
              onChanged: onCuadrillaChanged,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Selector del primer día de la semana
          Expanded(
            child: CustomDatePickerField(
              controller: TextEditingController(),
              label: 'Inicio de semana',
              selectedDate: semanaSeleccionada?.start,
              onDateSelected: (date) {
                if (date != null) {
                  final startDate = date;
                  final endDate = date.add(const Duration(days: 6));
                  onWeekSelected(DateTimeRange(start: startDate, end: endDate));
                } else {
                  onWeekSelected(null);
                }
              },
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
