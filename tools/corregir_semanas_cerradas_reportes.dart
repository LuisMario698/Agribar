import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔧 CORRIGIENDO SEMANAS QUE DEBERÍAN ESTAR CERRADAS');
  print('==================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Encontrar semanas que tienen datos pero no están marcadas como cerradas
    print('\n1️⃣ BUSCANDO SEMANAS CON DATOS PERO NO CERRADAS...');
    
    final semanasConDatos = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.autorizado_por,
        (SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = s.id_semana) as datos_semanal,
        (SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = s.id_semana) as datos_historial
      FROM semanas_nomina s
      ORDER BY s.id_semana DESC;
    ''');
    
    print('📋 ANÁLISIS DE TODAS LAS SEMANAS:');
    List<int> semanasParaCerrar = [];
    
    for (var semana in semanasConDatos) {
      var idSemana = semana[0] as int;
      var fechaInicio = semana[1];
      var fechaFin = semana[2]; 
      var estaCerrada = semana[3] as bool;
      var autorizado = semana[4];
      var datosSemanal = semana[5] as int;
      var datosHistorial = semana[6] as int;
      
      String estado = estaCerrada ? '✅ CERRADA' : '❌ ABIERTA';
      print('  • Semana $idSemana ($fechaInicio - $fechaFin): $estado');
      print('    Datos - Semanal: $datosSemanal, Historial: $datosHistorial, Auth: $autorizado');
      
      // Si tiene datos pero no está cerrada, agregarla a la lista
      if (!estaCerrada && (datosSemanal > 0 || datosHistorial > 0)) {
        print('    🔧 NECESITA SER CERRADA');
        semanasParaCerrar.add(idSemana);
      }
    }
    
    // 2. Cerrar automáticamente las semanas que lo necesitan
    if (semanasParaCerrar.isNotEmpty) {
      print('\n2️⃣ CERRANDO ${semanasParaCerrar.length} SEMANAS...');
      
      for (var semanaId in semanasParaCerrar) {
        try {
          await db.connection.execute('''
            UPDATE semanas_nomina 
            SET esta_cerrada = true,
                autorizado_por = 'Sistema Auto-Cerrado',
                fecha_autorizacion = CURRENT_TIMESTAMP
            WHERE id_semana = @semanaId
          ''', substitutionValues: {'semanaId': semanaId});
          
          print('  ✅ Semana $semanaId cerrada automáticamente');
        } catch (e) {
          print('  ❌ Error al cerrar semana $semanaId: $e');
        }
      }
      
      print('\n✅ PROCESO DE AUTO-CERRADO COMPLETADO');
    } else {
      print('\n✅ No hay semanas que necesiten ser cerradas');
    }
    
    // 3. Verificar resultado final
    print('\n3️⃣ VERIFICACIÓN FINAL...');
    
    final semanasParaReportes = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin
      FROM semanas_nomina s
      WHERE s.esta_cerrada = true
        AND ((SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = s.id_semana) > 0
             OR (SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = s.id_semana) > 0)
      ORDER BY s.fecha_inicio DESC
    ''');
    
    print('📊 SEMANAS AHORA DISPONIBLES PARA REPORTES: ${semanasParaReportes.length}');
    for (var semana in semanasParaReportes) {
      print('  • Semana ${semana[0]}: ${semana[1]} - ${semana[2]}');
    }
    
    await db.close();
    print('\n🎯 CORRECCIÓN COMPLETADA - Prueba los reportes ahora!');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
