import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../widgets/custom_dropdown_menu.dart';

/// Widget modular para la selección y gestión de cuadrillas
/// Maneja la selección de cuadrilla y el botón para armar cuadrilla
class NominaCuadrillaSelectionCard extends StatelessWidget {
  final List<Map<String, dynamic>> optionsCuadrilla;
  final Map<String, dynamic> selectedCuadrilla;
  final List<Map<String, dynamic>> empleadosEnCuadrilla;
  final Function(Map<String, dynamic>?) onCuadrillaSelected;
  final VoidCallback onToggleArmarCuadrilla;

  const NominaCuadrillaSelectionCard({
    super.key,
    required this.optionsCuadrilla,
    required this.selectedCuadrilla,
    required this.empleadosEnCuadrilla,
    required this.onCuadrillaSelected,
    required this.onToggleArmarCuadrilla,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.tableHeader,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 20,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cuadrilla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: onToggleArmarCuadrilla,
                  icon: const Icon(Icons.group_add),
                  label: Text(
                    empleadosEnCuadrilla.isNotEmpty
                        ? 'Editar cuadrilla'
                        : 'Armar cuadrilla',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selectedCuadrilla['nombre'] == ''
                        ? Colors.grey
                        : Colors.blue,
                    side: BorderSide(
                      color: selectedCuadrilla['nombre'] == ''
                          ? Colors.grey
                          : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomDropdownMenu(
              options: optionsCuadrilla,
              selectedOption: selectedCuadrilla['nombre'] == '' ? null : selectedCuadrilla,
              onOptionSelected: onCuadrillaSelected,
              displayKey: 'nombre',
              valueKey: 'nombre',
              hint: 'Seleccionar cuadrilla',
              icon: Icon(
                Icons.groups,
                color: AppColors.greenDark,
              ),
              allowDeselect: true,
              searchHint: 'Buscar cuadrilla...',
            ),
          ],
        ),
      ),
    );
  }
}
