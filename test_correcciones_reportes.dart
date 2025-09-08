import 'lib/services/database_service.dart';
import 'lib/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 PROBANDO CORRECCIONES DE REPORTES');
  print('=====================================');
  
  try {
    final reportesService = ReportesGastosService();
    
    // 1. Probar obtenerSemanasDisponibles() corregido
    print('\n1️⃣ PROBANDO obtenerSemanasDisponibles() CORREGIDO...');
    
    final semanasDisponibles = await reportesService.obtenerSemanasDisponibles();
    
    print('✅ Semanas disponibles encontradas: ${semanasDisponibles.length}');
    for (var semana in semanasDisponibles) {
      print('  • ID: ${semana['id']}, Nombre: ${semana['nombre']}, Autorizado: ${semana['autorizado_por']}');
    }
    
    // 2. Si encontramos semanas, probar generar reporte
    if (semanasDisponibles.isNotEmpty) {
      var semanaTest = semanasDisponibles.first['id'] as int;
      print('\n2️⃣ PROBANDO REPORTE PARA SEMANA $semanaTest...');
      
      final reporte = await reportesService.obtenerReporteGeneralPorSemana(semanaTest);
      
      print('✅ Resultados del reporte: ${reporte.length}');
      for (var resultado in reporte.take(5)) {
        print('  • ${resultado['actividad_nombre']}: \$${resultado['total_pagado']} (${resultado['empleados_unicos']} empleados)');
      }
      
      if (reporte.isEmpty) {
        print('⚠️ El reporte está vacío. Investigando...');
        
        // Verificar datos directamente
        final db = DatabaseService();
        await db.connect();
        
        final verificarDatos = await db.connection.query('''
          SELECT 
            (SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @semanaId) as datos_semanal,
            (SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @semanaId) as datos_historial
        ''', substitutionValues: {'semanaId': semanaTest});
        
        print('  📊 Datos - Semanal: ${verificarDatos.first[0]}, Historial: ${verificarDatos.first[1]}');
        
        await db.close();
      }
    } else {
      print('❌ No se encontraron semanas disponibles para reportes');
      
      // Investigar por qué
      final db = DatabaseService();
      await db.connect();
      
      final todasSemanas = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada 
        FROM semanas_nomina 
        ORDER BY id_semana DESC;
      ''');
      
      print('\n🔍 DIAGNÓSTICO - Todas las semanas en BD:');
      for (var sem in todasSemanas) {
        final cerrada = sem[3] ? 'CERRADA' : 'ABIERTA';
        print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]} - $cerrada');
      }
      
      await db.close();
    }
    
    print('\n✅ PRUEBA COMPLETADA');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
