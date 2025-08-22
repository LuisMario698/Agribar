import 'package:agribar/services/reportes_gastos_service.dart';

void main() async {
  print('🧪 Test completo del sistema de reportes...');
  
  final service = ReportesGastosService();
  
  try {
    // Test 1: Cargar datos iniciales secuencialmente
    print('\n📋 1. Cargando semanas...');
    final semanas = await service.obtenerSemanasDisponibles();
    print('✅ Semanas: ${semanas.length}');
    for (final semana in semanas) {
      print('  - ${semana['nombre']} (ID: ${semana['id']})');
    }
    
    print('\n🏞️ 2. Cargando ranchos...');
    final ranchos = await service.obtenerRanchosDisponibles();
    print('✅ Ranchos: ${ranchos.length}');
    for (final rancho in ranchos) {
      print('  - ${rancho['nombre']} (ID: ${rancho['id']})');
    }
    
    print('\n⚒️ 3. Cargando actividades...');
    final actividades = await service.obtenerActividadesDisponibles();
    print('✅ Actividades: ${actividades.length}');
    for (final actividad in actividades) {
      print('  - ${actividad['nombre']} (ID: ${actividad['id']})');
    }
    
    if (semanas.isNotEmpty) {
      final semanaId = semanas.first['id'] as int;
      
      print('\n📊 4. Probando reporte general...');
      final reporteGeneral = await service.obtenerReporteGeneralPorSemana(semanaId);
      print('✅ Reporte general: ${reporteGeneral.length} registros');
      for (final item in reporteGeneral) {
        print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
      }
      
      if (ranchos.isNotEmpty) {
        final ranchoId = ranchos.first['id'] as int;
        print('\n🏞️ 5. Probando reporte por rancho...');
        final reporteRancho = await service.obtenerReportePorRancho(semanaId, ranchoId);
        print('✅ Reporte por rancho: ${reporteRancho.length} registros');
        for (final item in reporteRancho) {
          print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
        }
      }
      
      if (actividades.isNotEmpty) {
        final actividadId = actividades.first['id'] as int;
        print('\n⚒️ 6. Probando reporte por actividad...');
        final reporteActividad = await service.obtenerReportePorActividad(semanaId, actividadId);
        print('✅ Reporte por actividad: ${reporteActividad.length} registros');
        for (final item in reporteActividad) {
          print('  - ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
        }
      }
    }
    
    print('\n🎉 ¡Todos los tests pasaron exitosamente!');
    
  } catch (e, stackTrace) {
    print('❌ Error en el test: $e');
    print('Stack trace: $stackTrace');
  }
}
