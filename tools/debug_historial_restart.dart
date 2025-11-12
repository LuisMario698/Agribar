import 'lib/services/database_service.dart';

void main() async {
  print('🔍 DEBUGGING ESPECÍFICO - HISTORIAL AFTER RESTART\n');

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // 1. Verificar semanas cerradas
    print('1. 📋 SEMANAS MARCADAS COMO CERRADAS:');
    final semanasCerradas = await db.connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        creado_en
      FROM semanas_nomina
      WHERE esta_cerrada = true
      ORDER BY fecha_inicio DESC;
    ''');
    
    if (semanasCerradas.isEmpty) {
      print('❌ No hay semanas marcadas como cerradas (esta_cerrada = true)');
      
      // Ver todas las semanas
      final todasSemanas = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
        FROM semanas_nomina
        ORDER BY fecha_inicio DESC;
      ''');
      
      print('\n📊 TODAS LAS SEMANAS EN BD:');
      for (var semana in todasSemanas) {
        print('   • ID: ${semana[0]}, Fechas: ${semana[1]} - ${semana[2]}, Cerrada: ${semana[3]}');
      }
    } else {
      for (var semana in semanasCerradas) {
        final semanaId = semana[0];
        print('   • ID: ${semana[0]}, Fechas: ${semana[1]} - ${semana[2]}, Cerrada: ${semana[3]}');
        
        // 2. Ver estructura de la tabla nomina_empleados_semanal
        print('   📊 Verificando datos para semana ID $semanaId:');
        
        final empleadosNomina = await db.connection.query('''
          SELECT 
            COUNT(*) as total_registros,
            SUM(CASE WHEN total_neto > 0 THEN 1 ELSE 0 END) as registros_con_total,
            SUM(total_neto) as suma_total_neto,
            SUM(total) as suma_total,
            COUNT(DISTINCT id_cuadrilla) as cuadrillas_distintas
          FROM nomina_empleados_semanal
          WHERE id_semana = @semanaId;
        ''', substitutionValues: {'semanaId': semanaId});
        
        if (empleadosNomina.isNotEmpty) {
          final stats = empleadosNomina.first;
          print('     - Total registros: ${stats[0]}');
          print('     - Registros con total > 0: ${stats[1]}');
          print('     - Suma total_neto: \$${stats[2] ?? 0}');
          print('     - Suma total: \$${stats[3] ?? 0}');
          print('     - Cuadrillas distintas: ${stats[4]}');
        }
        
        // 3. Ver detalles por cuadrilla
        final cuadrillasQuery = await db.connection.query('''
          SELECT 
            c.id_cuadrilla,
            c.nombre,
            COUNT(nes.id_empleado) as empleados_count,
            SUM(nes.total_neto) as total_cuadrilla,
            SUM(nes.total) as total_simple
          FROM cuadrillas c
          JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla
          WHERE nes.id_semana = @semanaId
          GROUP BY c.id_cuadrilla, c.nombre
          ORDER BY c.nombre;
        ''', substitutionValues: {'semanaId': semanaId});
        
        print('     🔍 Por cuadrilla:');
        for (var cuadrilla in cuadrillasQuery) {
          print('       - ${cuadrilla[1]}: ${cuadrilla[2]} empleados, Total neto: \$${cuadrilla[3] ?? 0}, Total simple: \$${cuadrilla[4] ?? 0}');
          
          // Ver algunos empleados específicos
          final empleadosDetalle = await db.connection.query('''
            SELECT 
              e.nombre,
              nes.dia_1, nes.dia_2, nes.dia_3, nes.dia_4, nes.dia_5, nes.dia_6, nes.dia_7,
              nes.total, nes.debe, nes.total_neto
            FROM nomina_empleados_semanal nes
            JOIN empleados e ON e.id_empleado = nes.id_empleado
            WHERE nes.id_semana = @semanaId AND nes.id_cuadrilla = @cuadrillaId
            LIMIT 3;
          ''', substitutionValues: {'semanaId': semanaId, 'cuadrillaId': cuadrilla[0]});
          
          for (var emp in empleadosDetalle) {
            print('         * ${emp[0]}: días=[${emp[1]},${emp[2]},${emp[3]},${emp[4]},${emp[5]},${emp[6]},${emp[7]}], total=${emp[8]}, debe=${emp[9]}, neto=${emp[10]}');
          }
        }
      }
    }
    
    // 4. Probar función obtenerSemanasCerradas directamente
    print('\n4. 🧪 PROBANDO obtenerSemanasCerradas():');
    final semanasCerradasFunc = await obtenerSemanasCerradas();
    
    print('   Resultado: ${semanasCerradasFunc.length} semanas');
    for (var i = 0; i < semanasCerradasFunc.length; i++) {
      final semana = semanasCerradasFunc[i];
      print('   • Semana $i: ID=${semana['id']}, Cuadrillas=${(semana['cuadrillas'] as List).length}, Total=\$${semana['totalSemana']}');
      
      final cuadrillas = semana['cuadrillas'] as List;
      for (var j = 0; j < cuadrillas.length; j++) {
        final cuadrilla = cuadrillas[j];
        print('     - ${cuadrilla['nombre']}: ${cuadrilla['empleados']?.length ?? 0} empleados, Total: \$${cuadrilla['total']}');
      }
    }
    
    await db.close();
    
  } catch (e) {
    print('❌ Error durante debugging: $e');
    print('Stack trace: ${StackTrace.current}');
    await db.close();
  }
}
