import 'lib/services/reportes_gastos_service.dart';

void main() async {
  print('🔍 PROBANDO REPORTES CON SOLO TABLA SEMANAL');
  print('=' * 50);
  
  final service = ReportesGastosService();
  
  try {
    // 1️⃣ Obtener semanas disponibles
    print('\n1️⃣ Obteniendo semanas disponibles...');
    final semanas = await service.obtenerSemanasDisponibles();
    
    print('📊 Semanas encontradas: ${semanas.length}');
    for (var semana in semanas) {
      print('   • Semana ${semana['id']}: ${semana['nombre']}');
    }
    
    if (semanas.isEmpty) {
      print('❌ No se encontraron semanas. Verificar que hay datos en nomina_empleados_semanal');
      return;
    }
    
    // 2️⃣ Probar semana específica (buscar semana 37)
    final semana37 = semanas.firstWhere(
      (s) => s['nombre'].toString().contains('37') || s['id'] == 37,
      orElse: () => semanas.first
    );
    
    print('\n2️⃣ Probando reporte para semana ${semana37['id']}...');
    final reporte = await service.obtenerReporteGeneralPorSemana(semana37['id']);
    
    print('📊 Actividades encontradas: ${reporte.length}');
    if (reporte.isNotEmpty) {
      print('✅ REPORTE EXITOSO:');
      for (var actividad in reporte.take(3)) {
        print('   • ${actividad['actividad_nombre']}: \$${actividad['total_pagado']} (${actividad['empleados_unicos']} empleados)');
      }
    } else {
      print('❌ No se generó reporte para esta semana');
    }
    
    // 3️⃣ Verificar otras semanas
    print('\n3️⃣ Verificando otras semanas disponibles...');
    for (var semana in semanas.take(3)) {
      final reporteTest = await service.obtenerReporteGeneralPorSemana(semana['id']);
      print('   • Semana ${semana['id']}: ${reporteTest.length} actividades');
    }
    
    print('\n✅ PRUEBA COMPLETADA - Los reportes ahora buscan solo en tabla semanal');
    
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  }
}
