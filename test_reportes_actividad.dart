import 'package:agribar/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 Test específico de reportes por actividad...');
  
  final service = ReportesGastosService();
  
  try {
    print('📊 1. Probando reporte por actividad DESTAJO (ID: 1)...');
    final reporteDestajo = await service.obtenerReportePorActividad(17, 1);
    print('✅ Resultados: ${reporteDestajo.length}');
    for (final item in reporteDestajo) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n📊 2. Probando reporte por actividad JEFE DE LINEA (ID: 2)...');
    final reporteJefe = await service.obtenerReportePorActividad(17, 2);
    print('✅ Resultados: ${reporteJefe.length}');
    for (final item in reporteJefe) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n📊 3. Probando reporte por actividad JEFE DE EMPAQUE (ID: 3)...');
    final reporteEmpaque = await service.obtenerReportePorActividad(17, 3);
    print('✅ Resultados: ${reporteEmpaque.length}');
    for (final item in reporteEmpaque) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
