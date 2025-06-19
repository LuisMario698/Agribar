import 'package:agribar/services/database_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../widgets/custom_dropdown_menu.dart';

/// Widget modular para la selección y gestión de cuadrillas
/// Maneja la selección de cuadrilla y el botón para armar cuadrilla
class NominaCuadrillaSelectionCard extends StatefulWidget {
  final List<Map<String, dynamic>> optionsCuadrilla;
  final Map<String, dynamic> selectedCuadrilla;
  final List<Map<String, dynamic>> empleadosEnCuadrilla;
  final Function(Map<String, dynamic>?) onCuadrillaSelected;
  final Map<String, dynamic>? semanaSeleccionada;
  final VoidCallback onToggleArmarCuadrilla;

  const NominaCuadrillaSelectionCard({
    super.key,
    required this.optionsCuadrilla,
    required this.semanaSeleccionada,
    required this.selectedCuadrilla,
    required this.empleadosEnCuadrilla, 
    required this.onCuadrillaSelected,
    required this.onToggleArmarCuadrilla,
  });

  @override
  State<NominaCuadrillaSelectionCard> createState() => _NominaCuadrillaSelectionCardState();
}

class _NominaCuadrillaSelectionCardState extends State<NominaCuadrillaSelectionCard> {

   List<Map<String, dynamic>> empleadosNomina = [];

  Future<void> cargarNomina() async {
    if (widget.semanaSeleccionada != null && widget.selectedCuadrilla['id'] != null) {
  final data = await obtenerNominaEmpleadosDeCuadrilla(
    widget.semanaSeleccionada!['id'],
    widget.selectedCuadrilla['id'],
  );
  setState(() {
    empleadosNomina = data;
  });
}
  }
Future<List<Map<String, dynamic>>> obtenerNominaEmpleadosDeCuadrilla(int semanaId, int cuadrillaId) async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT 
      e.id_empleado,
      e.nombre,
      e.codigo,
      n.lunes,
      n.martes,
      n.miercoles,
      n.jueves,
      n.viernes,
      n.sabado,
      n.domingo,
      n.total,
      n.debe,
      n.subtotal,
      n.descuento_comedor
    FROM nomina_empleados_semanal n
    JOIN empleados e ON e.id_empleado = n.empleado_id
    WHERE n.semana_id = @semanaId AND n.cuadrilla_id = @cuadrillaId;
  ''', substitutionValues: {
    'semanaId': semanaId,
    'cuadrillaId': cuadrillaId,
  });

  await db.close();

  return result.map((row) => {
    'id': row[0],
    'nombre': row[1],
    'codigo': row[2],
    'lunes': row[3],
    'martes': row[4],
    'miercoles': row[5],
    'jueves': row[6],
    'viernes': row[7],
    'sabado': row[8],
    'domingo': row[9],
    'total': row[10],
    'debe': row[11],
    'subtotal': row[12],
    'comedor': row[13],
  }).toList();
}
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
                  onPressed: widget.onToggleArmarCuadrilla,
                  icon: const Icon(Icons.group_add),
                  label: Text(
                    widget.empleadosEnCuadrilla.isNotEmpty
                        ? 'Editar cuadrilla'
                        : 'Armar cuadrilla',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.selectedCuadrilla['nombre'] == ''
                        ? Colors.grey
                        : Colors.blue,
                    side: BorderSide(
                      color: widget.selectedCuadrilla['nombre'] == ''
                          ? Colors.grey
                          : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomDropdownMenu(
              options: widget.optionsCuadrilla,
              selectedOption: widget.selectedCuadrilla['nombre'] == '' ? null : widget.selectedCuadrilla,
              onOptionSelected: widget.onCuadrillaSelected,
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
