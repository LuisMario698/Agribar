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
  final bool puedeCapturarDatos; // 🎯 Nueva propiedad para validación
  final bool isGuardando; // 🔄 Nueva propiedad para indicador de carga

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
    this.puedeCapturarDatos = false,
    this.isGuardando = false,
  });
  
  String _getHelpMessage() {
    if (startDate == null || endDate == null) {
      return '1️⃣ Selecciona una semana para continuar';
    }
    
    if (cuadrillaSeleccionada == null || 
        cuadrillaSeleccionada!['nombre'] == null || 
        cuadrillaSeleccionada!['nombre'] == '') {
      return '2️⃣ Selecciona o arma una cuadrilla para continuar';
    }
    
    if (empleadosFiltrados.isEmpty) {
      return '3️⃣ La cuadrilla no tiene empleados. Usa "Armar cuadrilla" para agregar empleados.';
    }
    
    if (!puedeCapturarDatos) {
      return '⚠️ Completa el flujo: semana → cuadrilla → captura';
    }
    
    // Verificar si hay datos capturados
    bool hayDatosCargados = empleadosFiltrados.any((emp) {
      for (int day = 0; day < 7; day++) {
        final dias = int.tryParse(emp['dia_${day}_s']?.toString() ?? '0') ?? 0;
        if (dias > 0) return true;
      }
      return false;
    });
    
    if (!hayDatosCargados) {
      return '💡 Captura días trabajados en la tabla para proceder';
    }
    
    return '✅ Todo listo para guardar datos de nómina';
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
                  onPressed: (canSave && !isGuardando) ? onGuardar : null,
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
                  icon: isGuardando 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.save,
                        size: 20,
                        color: Colors.white,
                      ),
                  label: Text(
                    isGuardando ? 'GUARDANDO...' : 'GUARDAR',
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
          
          // Texto de ayuda mejorado
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: canSave ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: canSave ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    canSave ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: canSave ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _getHelpMessage(),
                      style: TextStyle(
                        fontSize: 12,
                        color: canSave ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
