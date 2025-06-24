import 'package:flutter/material.dart';
import '../widgets/export_button_group.dart';

/// Widget modular para la sección de exportación
/// Contiene los botones para exportar a PDF, Excel y Guardar
class NominaExportSection extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onGuardar;
  final bool canSave;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? cuadrillaSeleccionada;
  final List<Map<String, dynamic>> empleadosFiltrados;

  const NominaExportSection({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
    this.onGuardar,
    this.canSave = false,
    this.startDate,
    this.endDate,
    this.cuadrillaSeleccionada,
    this.empleadosFiltrados = const [],
  });
  
  String _getHelpMessage() {
    if (startDate == null || endDate == null) {
      return 'Selecciona una semana para continuar';
    }
    
    if (cuadrillaSeleccionada == null || 
        cuadrillaSeleccionada!['nombre'] == null || 
        cuadrillaSeleccionada!['nombre'] == '') {
      return 'Selecciona una cuadrilla para continuar';
    }
    
    if (empleadosFiltrados.isEmpty) {
      return 'La cuadrilla seleccionada no tiene empleados asignados. Usa "Armar cuadrilla" para agregar empleados.';
    }
    
    return 'Selecciona una semana y cuadrilla para habilitar el guardado';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Guardar con estilo destacado
              Container(
                margin: const EdgeInsets.only(right: 24),
                child: ElevatedButton.icon(
                  onPressed: canSave ? onGuardar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSave ? const Color(0xFF5BA829) : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canSave ? 4 : 1,
                    shadowColor: canSave ? const Color(0xFF5BA829).withOpacity(0.3) : Colors.transparent,
                  ),
                  icon: Icon(
                    Icons.save,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'GUARDAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Separador visual
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              
              Text(
                'EXPORTAR A',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              ExportButton(
                label: 'PDF',
                color: Colors.blue,
                onPressed: onExportPdf ?? () {
                  // TODO: Export to PDF
                },
              ),
              const SizedBox(width: 8),
              ExportButton(
                label: 'EXCEL',
                color: Colors.green,
                onPressed: onExportExcel ?? () {
                  // TODO: Export to Excel
                },
              ),
            ],
          ),
          
          // Texto de ayuda
          if (!canSave)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Selecciona una semana y cuadrilla para habilitar el guardado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
