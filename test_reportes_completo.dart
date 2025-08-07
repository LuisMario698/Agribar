import 'package:agribar/services/reportes_service.dart';

/// Test completo del servicio de reportes con datos expandidos
void main() async {
  print('🔍 === TEST COMPLETO DE REPORTES SERVICE ===\n');

  final reportesService = ReportesService();

  try {
    // 1. Test de ranchos reales
    print('1️⃣ Probando obtener ranchos REALES...');
    final ranchos = await reportesService.obtenerRanchos();
    print('✅ Ranchos obtenidos: $ranchos');
    print('📊 Total ranchos: ${ranchos.length}\n');

    // 2. Test de actividades reales  
    print('2️⃣ Probando obtener actividades...');
    final actividades = await reportesService.obtenerActividades();
    print('✅ Actividades obtenidas: ${actividades.take(5).toList()}...'); 
    print('📊 Total actividades: ${actividades.length}\n');

    // 3. Test del reporte general EXPANDIDO
    print('3️⃣ Probando reporte general EXPANDIDO...');
    final reporteGeneral = await reportesService.obtenerReporteGeneral();
    print('✅ Reporte general obtenido:');
    for (var reporte in reporteGeneral) {
      print('   🏡 Rancho: ${reporte['rancho']}');
      print('   🔧 Actividad: ${reporte['actividad']}');
      print('   📅 Días trabajados: ${reporte['dias_trabajados']}');
      print('   👷 Empleados: ${reporte['empleados_involucrados']}');
      print('   💰 Gasto total: \$${reporte['gasto_total']}');
      print('   📊 Promedio: \$${reporte['promedio']}\n');
    }
    print('📈 Total registros en reporte general: ${reporteGeneral.length}\n');

    // 4. Test del resumen general
    print('4️⃣ Probando resumen general...');
    final resumen = await reportesService.obtenerResumenGeneral();
    print('✅ Resumen general:');
    print('   👷 Total empleados: ${resumen['total_empleados']}');
    print('   🏡 Ranchos activos: ${resumen['ranchos_activos']}');
    print('   📅 Días trabajados: ${resumen['dias_trabajados']}');
    print('   💰 Monto total: \$${resumen['monto_total']}');
    print('   🔧 Actividades realizadas: ${resumen['actividades_realizadas']}\n');

    // 5. Test filtrado por rancho específico
    if (ranchos.length > 1 && ranchos[1] != 'Todos') {
      String ranchoEspecifico = ranchos[1]; // Primer rancho real
      print('5️⃣ Probando filtro por rancho específico: $ranchoEspecifico...');
      final reporteFiltrado = await reportesService.obtenerReporteGeneral(rancho: ranchoEspecifico);
      print('✅ Reporte filtrado:');
      for (var reporte in reporteFiltrado) {
        print('   🏡 ${reporte['rancho']} - ${reporte['actividad']} - \$${reporte['gasto_total']}');
      }
      print('📊 Total registros filtrados: ${reporteFiltrado.length}\n');
    }

    print('🎉 === TODOS LOS TESTS COMPLETADOS EXITOSAMENTE ===');

  } catch (e, stackTrace) {
    print('❌ ERROR EN TEST: $e');
    print('🔍 Stack trace: $stackTrace');
  }
}
