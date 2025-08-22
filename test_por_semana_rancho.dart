import 'package:agribar/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 Test específico por semana y rancho...');
  
  final service = ReportesGastosService();
  
  try {
    // Test semana 19 (más reciente) con San Valentín
    print('📊 1. Semana 19 - Reporte general:');
    final reporte19 = await service.obtenerReporteGeneralPorSemana(19);
    for (final item in reporte19) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n🏞️ 2. Semana 19 - San Valentín (ID: 2):');
    final reporteRancho19 = await service.obtenerReportePorRancho(19, 2);
    for (final item in reporteRancho19) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n📊 3. Semana 18 - Reporte general:');
    final reporte18 = await service.obtenerReporteGeneralPorSemana(18);
    for (final item in reporte18) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n🏞️ 4. Semana 18 - San Francisco (ID: 1):');
    final reporteRancho18 = await service.obtenerReportePorRancho(18, 1);
    for (final item in reporteRancho18) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
    print('\n🏞️ 5. Semana 18 - Santa Amalia (ID: 3):');
    final reporteRancho18_3 = await service.obtenerReportePorRancho(18, 3);
    for (final item in reporteRancho18_3) {
      print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
