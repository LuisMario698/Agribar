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
  final bool puedeArmarCuadrilla; // 🎯 Nueva propiedad para validación
  final bool bloqueadoPorFaltaSemana; // 🎯 Nueva propiedad para mostrar estado

  const NominaCuadrillaSelectionCard({
    super.key,
    required this.optionsCuadrilla,
    required this.semanaSeleccionada,
    required this.selectedCuadrilla,
    required this.empleadosEnCuadrilla, 
    required this.onCuadrillaSelected,
    required this.onToggleArmarCuadrilla,
    this.puedeArmarCuadrilla = false,
    this.bloqueadoPorFaltaSemana = true,
  });

  @override
  State<NominaCuadrillaSelectionCard> createState() => _NominaCuadrillaSelectionCardState();
}

class _NominaCuadrillaSelectionCardState extends State<NominaCuadrillaSelectionCard> {

   List<Map<String, dynamic>> empleadosNomina = [];



  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Verificar qué opciones de cuadrilla recibe
    print('🔍 [CUADRILLA_WIDGET] Opciones recibidas: ${widget.optionsCuadrilla.length}');
    if (widget.optionsCuadrilla.isNotEmpty) {
      print('🔍 [CUADRILLA_WIDGET] Primera opción: ${widget.optionsCuadrilla[0]}');
    }
    print('🔍 [CUADRILLA_WIDGET] Bloqueado por falta semana: ${widget.bloqueadoPorFaltaSemana}');
    
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
            // 🎯 Mostrar indicador de estado arriba si está bloqueado
            if (widget.bloqueadoPorFaltaSemana) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.orange.shade600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Requiere semana activa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 20,
                      color: widget.bloqueadoPorFaltaSemana 
                          ? Colors.grey 
                          : AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cuadrilla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.bloqueadoPorFaltaSemana 
                            ? Colors.grey 
                            : AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: widget.puedeArmarCuadrilla ? widget.onToggleArmarCuadrilla : null,
                  icon: Icon(
                    Icons.group_add,
                    color: widget.puedeArmarCuadrilla 
                        ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                        : Colors.grey,
                  ),
                  label: Text(
                    widget.empleadosEnCuadrilla.isNotEmpty
                        ? 'Editar cuadrilla'
                        : 'Armar cuadrilla',
                    style: TextStyle(
                      color: widget.puedeArmarCuadrilla 
                          ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.puedeArmarCuadrilla
                          ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                    backgroundColor: widget.puedeArmarCuadrilla
                        ? (widget.empleadosEnCuadrilla.isNotEmpty 
                            ? Colors.blue.shade50 
                            : Colors.green.shade50)
                        : Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.bloqueadoPorFaltaSemana ? 8 : 12),
            
            // 🎯 Indicador informativo sobre múltiples cuadrillas
            if (!widget.bloqueadoPorFaltaSemana) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.blue.shade600,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Los empleados ahora pueden estar en múltiples cuadrillas en la misma semana',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            CustomDropdownMenu(
              options: widget.bloqueadoPorFaltaSemana ? [] : widget.optionsCuadrilla,
              selectedOption: widget.selectedCuadrilla['nombre'] == '' ? null : widget.selectedCuadrilla,
              onOptionSelected: widget.bloqueadoPorFaltaSemana 
                  ? (Map<String, dynamic>? option) {} // Función vacía cuando está bloqueado
                  : widget.onCuadrillaSelected,
              displayKey: 'nombre',
              valueKey: 'nombre',
              hint: widget.bloqueadoPorFaltaSemana 
                  ? 'Seleccionar una semana primero' 
                  : (widget.optionsCuadrilla.isEmpty 
                      ? 'No hay cuadrillas - Armar cuadrilla primero'
                      : 'Seleccionar cuadrilla'),
              icon: Icon(
                Icons.groups,
                color: widget.bloqueadoPorFaltaSemana 
                    ? Colors.grey 
                    : AppColors.greenDark,
              ),
              allowDeselect: !widget.bloqueadoPorFaltaSemana,
              searchHint: 'Buscar cuadrilla...',
            ),
          ],
        ),
      ),
    );
  }
}
