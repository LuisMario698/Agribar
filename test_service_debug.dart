import 'package:agribar/services/reportes_gastos_service.dart';

void main() async {
  print('🔍 Probando el servicio de reportes de gastos...');
  
  final service = ReportesGastosService();
  
  try {
    print('📋 Obteniendo semanas disponibles...');
    final semanas = await service.obtenerSemanasDisponibles();
    print('✅ Semanas obtenidas: ${semanas.length}');
    for (final semana in semanas) {
      print('  - ${semana['nombre_completo']}');
    }
    
    print('\n🏞️ Obteniendo ranchos disponibles...');
    final ranchos = await service.obtenerRanchosDisponibles();
    print('✅ Ranchos obtenidos: ${ranchos.length}');
    for (final rancho in ranchos) {
      print('  - ${rancho['nombre']}');
    }
    
    print('\n⚒️ Obteniendo actividades disponibles...');
    final actividades = await service.obtenerActividadesDisponibles();
    print('✅ Actividades obtenidas: ${actividades.length}');
    for (final actividad in actividades) {
      print('  - ${actividad['nombre']}');
    }
    
    if (semanas.isNotEmpty) {
      print('\n📊 Probando reporte general para primera semana...');
      final reporte = await service.obtenerReporteGeneralPorSemana(semanas.first['id']);
      print('✅ Reporte obtenido: ${reporte.length} registros');
      for (final item in reporte) {
        print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('Stack trace:');
    print(e.toString());
  }
}
