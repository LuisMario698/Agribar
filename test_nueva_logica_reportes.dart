import 'lib/services/reportes_gastos_service.dart';
import 'lib/services/database_service.dart';

void main() async {
  print('🔄 PROBANDO NUEVA LÓGICA DE REPORTES');
  print('=' * 50);
  
  try {
    // 1️⃣ Probar obtener semanas disponibles
    print('\n1️⃣ Obteniendo semanas disponibles con nueva lógica...');
    final service = ReportesGastosService();
    final semanas = await service.obtenerSemanasDisponibles();
    
    print('📊 Total semanas encontradas: ${semanas.length}');
    
    if (semanas.isEmpty) {
      print('❌ No se encontraron semanas disponibles');
      return;
    }
    
    // Mostrar todas las semanas encontradas
    for (var semana in semanas) {
      print('   • Semana ${semana['id']}: ${semana['nombre']}');
    }
    
    // 2️⃣ Buscar específicamente la semana 37
    final semana37 = semanas.where((s) => s['id'] == 37).toList();
    if (semana37.isNotEmpty) {
      print('\n✅ ¡SEMANA 37 ENCONTRADA!');
      print('   • ${semana37.first['nombre']}');
      print('   • Cerrada: ${semana37.first['cerrada']}');
      
      // Probar generar reporte para semana 37
      print('\n2️⃣ Generando reporte para semana 37...');
      final reporte = await service.obtenerReporteGeneralPorSemana(37);
      
      print('📊 Actividades encontradas en semana 37: ${reporte.length}');
      if (reporte.isNotEmpty) {
        print('✅ REPORTE EXITOSO PARA SEMANA 37:');
        for (var actividad in reporte.take(5)) {
          print('   • ${actividad['actividad_nombre']}: \$${actividad['total_pagado']} (${actividad['empleados_unicos']} empleados)');
        }
      }
    } else {
      print('\n⚠️ Semana 37 no encontrada en las disponibles');
      
      // Verificar dónde están los datos de la semana 37
      print('\n🔍 Verificando datos de semana 37 directamente en BD...');
      final db = DatabaseService();
      await db.connect();
      
      final verificacion = await db.connection.query('''
        SELECT 
          (SELECT COUNT(*) FROM semanas_nomina WHERE id_semana = 37 AND esta_cerrada = true) as semana_cerrada,
          (SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = 37) as datos_semanal,
          (SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = 37) as datos_historial
      ''');
      
      final semanaCerrada = verificacion.first[0] as int;
      final datosSemanal = verificacion.first[1] as int;
      final datosHistorial = verificacion.first[2] as int;
      
      print('   • Semana 37 cerrada: ${semanaCerrada > 0}');
      print('   • Datos en tabla semanal: $datosSemanal');
      print('   • Datos en tabla historial: $datosHistorial');
      
      await db.close();
    }
    
    // 3️⃣ Probar otras semanas
    print('\n3️⃣ Probando reportes para otras semanas...');
    for (var semana in semanas.take(3)) {
      final reporteTest = await service.obtenerReporteGeneralPorSemana(semana['id']);
      print('   • Semana ${semana['id']}: ${reporteTest.length} actividades encontradas');
    }
    
    print('\n✅ PRUEBA COMPLETADA');
    
  } catch (e, stackTrace) {
    print('❌ Error durante la prueba: $e');
    print('Stack trace: $stackTrace');
  }
}
