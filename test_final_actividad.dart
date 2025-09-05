import 'lib/services/reportes_gastos_service.dart';

void main() async {
  final service = ReportesGastosService();
  
  try {
    print('=== Probando con actividad que tiene datos ===');
    
    // Probar con actividad ID 2 (JEFE DE LINEA) y semana 19
    final datos = await service.obtenerReportePorActividad(19, 2);
    
    print('Datos obtenidos: ${datos.length} registros');
    
    for (var dato in datos) {
      print('---');
      print('Clave Cuadrilla: ${dato['cuadrilla_clave']}');
      print('Nombre Cuadrilla: ${dato['cuadrilla_nombre']}');
      print('Empleados: ${dato['empleados_unicos']}');
      print('Total Pagado: \$${dato['total_pagado']}');
      print('Registros: ${dato['registros_totales']}');
      print('Ranchos trabajados: ${dato['ranchos_trabajados']}');
      print('Eficiencia: ${dato['eficiencia_porcentaje']}%');
    }
    
    if (datos.isNotEmpty) {
      print('\n✅ ¡El servicio funciona correctamente!');
      print('Ahora la interfaz debería mostrar:');
      print('  - Clave: ${datos.first['cuadrilla_clave']}');
      print('  - Cuadrilla: ${datos.first['cuadrilla_nombre']}');
      print('  - Empleados: ${datos.first['empleados_unicos']}');
      print('  - Total: \$${datos.first['total_pagado']}');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
