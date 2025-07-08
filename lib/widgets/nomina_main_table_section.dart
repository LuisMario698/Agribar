import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../widgets/editable_data_table.dart';
import '../widgets/fullscreen_table_dialog.dart';

/// Widget modular para la sección principal de la tabla
/// Incluye el header, controles y la tabla de nómina
class NominaMainTableSection extends StatelessWidget {
  final List<Map<String, dynamic>> empleadosFiltrados;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(int, String, dynamic) onTableChange;
  final VoidCallback onMostrarSemanasCerradas;
  final List<Map<String, dynamic>> empleadosNomina;
  
  // 🎯 Nuevas propiedades para el dropdown de cuadrillas
  final List<Map<String, dynamic>> cuadrillas;
  final Map<String, dynamic>? cuadrillaSeleccionada;
  final Function(Map<String, dynamic>?) onCuadrillaChanged;

  const NominaMainTableSection({
    super.key,
    required this.empleadosFiltrados,
    this.startDate,
    this.endDate,
    required this.onTableChange,
    required this.empleadosNomina, 
    required this.onMostrarSemanasCerradas,
    required this.cuadrillas,
    this.cuadrillaSeleccionada,
    required this.onCuadrillaChanged,
  });

  void _showFullscreenTable(BuildContext context) {
    final modalHorizontal = ScrollController();
    final modalVertical = ScrollController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return FullscreenTableDialog(
          empleados: empleadosFiltrados,
          semanaSeleccionada: startDate != null && endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : null,
          onChanged: onTableChange,
          onClose: () => Navigator.of(context).pop(),
          horizontalController: modalHorizontal,
          verticalController: modalVertical,
          cuadrillas: cuadrillas,
          cuadrillaSeleccionada: cuadrillaSeleccionada,
          onCuadrillaChanged: onCuadrillaChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 24,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nómina semanal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () => _showFullscreenTable(context),
                      tooltip: 'Ver en pantalla completa',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: onMostrarSemanasCerradas,
                      tooltip: 'Historial de semanas cerradas',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Tabla centrada y alineada arriba con scroll
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: EditableDataTableWidget(
                    empleados: empleadosFiltrados, // ✅ Usar empleadosFiltrados (misma fuente que tabla expandida)
                    semanaSeleccionada: startDate != null && endDate != null
                        ? DateTimeRange(start: startDate!, end: endDate!)
                        : null,
                    onChanged: onTableChange,
                    isExpanded: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
