import 'lib/services/reportes_gastos_service.dart';

void main() async {
  final service = ReportesGastosService();
  
  try {
    print('Probando obtener reporte por actividad...');
    
    // Usar valores de ejemplo - ajusta según tus datos
    final int semanaId = 1; // Cambiar por una semana válida
    final int actividadId = 1; // Cambiar por una actividad válida
    
    final datos = await service.obtenerReportePorActividad(semanaId, actividadId);
    
    print('Datos obtenidos: ${datos.length} registros');
    
    for (var dato in datos) {
      print('---');
      print('Clave Cuadrilla: ${dato['cuadrilla_clave']}');
      print('Nombre Cuadrilla: ${dato['cuadrilla_nombre']}');
      print('Empleados: ${dato['empleados_unicos']}');
      print('Total Pagado: ${dato['total_pagado']}');
      print('Ranchos trabajados: ${dato['ranchos_trabajados']}');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
