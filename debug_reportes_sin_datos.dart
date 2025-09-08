import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔍 DEBUGGING REPORTES - ¿Por qué no aparecen datos?');
  print('====================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Verificar qué semanas tenemos disponibles
    print('\n1️⃣ SEMANAS DISPONIBLES EN LA BD...');
    
    final semanasNomina = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, autorizado_por, cerrada
      FROM semanas_nomina 
      ORDER BY id_semana DESC 
      LIMIT 10;
    ''');
    
    print('📋 Semanas en tabla semanas_nomina:');
    for (var sem in semanasNomina) {
      print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]} | Auth: ${sem[3]} | Cerrada: ${sem[4]}');
    }

    // 2. Verificar datos en nomina_empleados_historial
    print('\n2️⃣ DATOS EN HISTORIAL POR SEMANA...');
    
    final datosHistorial = await db.connection.query('''
      SELECT id_semana, COUNT(*) as registros,
             COUNT(CASE WHEN act_1 IS NOT NULL AND act_1 <> 0 THEN 1 END) as con_actividades,
             COUNT(CASE WHEN dia_1 IS NOT NULL AND dia_1 > 0 THEN 1 END) as con_horas
      FROM nomina_empleados_historial 
      GROUP BY id_semana 
      ORDER BY id_semana DESC;
    ''');
    
    print('📊 Registros en nomina_empleados_historial:');
    for (var hist in datosHistorial) {
      print('  • Semana ${hist[0]}: ${hist[1]} registros | Act: ${hist[2]} | Horas: ${hist[3]}');
    }

    // 3. Probar la consulta del reporte para una semana específica
    if (semanasNomina.isNotEmpty) {
      var semanaTest = semanasNomina.first[0];
      print('\n3️⃣ PROBANDO CONSULTA DE REPORTE PARA SEMANA $semanaTest...');
      
      // Consulta simplificada para debuggear
      final consultaDebug = await db.connection.query('''
        SELECT 
          n.id_empleado,
          n.id_semana,
          n.act_1, n.dia_1, n.campo_1,
          n.act_2, n.dia_2, n.campo_2,
          act1.nombre as act1_nombre,
          act2.nombre as act2_nombre
        FROM nomina_empleados_historial n
        LEFT JOIN actividades act1 ON act1.id_actividad = n.act_1
        LEFT JOIN actividades act2 ON act2.id_actividad = n.act_2
        WHERE n.id_semana = @semanaId
        LIMIT 5;
      ''', substitutionValues: {'semanaId': semanaTest});
      
      print('🔍 Datos detallados para semana $semanaTest:');
      for (var row in consultaDebug) {
        print('  Empleado ${row[0]}: act_1=${row[2]}(${row[8]}) dia_1=${row[3]}, act_2=${row[5]}(${row[9]}) dia_2=${row[6]}');
      }

      // 4. Probar la consulta exacta del reporte
      print('\n4️⃣ PROBANDO CONSULTA EXACTA DEL REPORTE...');
      
      try {
        final reporteTest = await db.connection.query('''
          SELECT 
            act.nombre as actividad_nombre,
            act.clave as actividad_clave,
            SUM(a.pago) as total_pagado,
            COUNT(*) as registros_totales
          FROM semanas_nomina sn
          CROSS JOIN nomina_empleados_historial n
          CROSS JOIN LATERAL (
            VALUES 
              (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
              (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
              (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
              (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
              (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
              (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
              (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
          ) AS a(act_id, pago, rancho_id)
          LEFT JOIN actividades act ON act.id_actividad = a.act_id
          WHERE n.id_semana = sn.id_semana
            AND a.act_id IS NOT NULL 
            AND a.act_id <> 0
            AND sn.id_semana = @semanaId
          GROUP BY act.nombre, act.clave
          ORDER BY total_pagado DESC
        ''', substitutionValues: {'semanaId': semanaTest});
        
        print('📊 Resultado del reporte (primeros 10):');
        for (var rep in reporteTest.take(10)) {
          print('  • ${rep[0]} (${rep[1]}): \$${rep[2]} | ${rep[3]} registros');
        }
        
        if (reporteTest.isEmpty) {
          print('❌ ¡EL REPORTE ESTÁ VACÍO! Vamos a analizar por qué...');
          
          // Análisis paso a paso
          print('\n🔍 ANÁLISIS PASO A PASO:');
          
          // Paso 1: ¿Existe la semana en semanas_nomina?
          final existeSemana = await db.connection.query('''
            SELECT COUNT(*) FROM semanas_nomina WHERE id_semana = @semanaId
          ''', substitutionValues: {'semanaId': semanaTest});
          print('1. ¿Existe semana $semanaTest en semanas_nomina? ${existeSemana.first[0]}');
          
          // Paso 2: ¿Hay registros en historial para esa semana?
          final existeHistorial = await db.connection.query('''
            SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @semanaId
          ''', substitutionValues: {'semanaId': semanaTest});
          print('2. ¿Registros en historial para semana $semanaTest? ${existeHistorial.first[0]}');
          
          // Paso 3: ¿Hay actividades válidas?
          final actividadesValidas = await db.connection.query('''
            SELECT COUNT(*) FROM nomina_empleados_historial 
            WHERE id_semana = @semanaId 
            AND (act_1 IS NOT NULL AND act_1 <> 0 
                 OR act_2 IS NOT NULL AND act_2 <> 0 
                 OR act_3 IS NOT NULL AND act_3 <> 0
                 OR act_4 IS NOT NULL AND act_4 <> 0
                 OR act_5 IS NOT NULL AND act_5 <> 0
                 OR act_6 IS NOT NULL AND act_6 <> 0
                 OR act_7 IS NOT NULL AND act_7 <> 0)
          ''', substitutionValues: {'semanaId': semanaTest});
          print('3. ¿Registros con actividades válidas? ${actividadesValidas.first[0]}');
          
          // Paso 4: ¿Las actividades existen en la tabla actividades?
          final actividadesExisten = await db.connection.query('''
            SELECT DISTINCT n.act_1, act.nombre
            FROM nomina_empleados_historial n
            LEFT JOIN actividades act ON act.id_actividad = n.act_1
            WHERE n.id_semana = @semanaId AND n.act_1 IS NOT NULL AND n.act_1 <> 0
            LIMIT 5
          ''', substitutionValues: {'semanaId': semanaTest});
          print('4. ¿Las actividades existen en tabla actividades?');
          for (var act in actividadesExisten) {
            print('   act_id=${act[0]} → nombre="${act[1]}"');
          }
        }
        
      } catch (e) {
        print('❌ Error en consulta del reporte: $e');
      }
    }

    // 5. Verificar qué actividades tenemos en la BD
    print('\n5️⃣ ACTIVIDADES DISPONIBLES...');
    
    final actividades = await db.connection.query('''
      SELECT id_actividad, nombre, clave 
      FROM actividades 
      ORDER BY id_actividad 
      LIMIT 10;
    ''');
    
    print('📋 Actividades en la BD:');
    for (var act in actividades) {
      print('  • ID ${act[0]}: ${act[1]} (${act[2]})');
    }

    // 6. Verificar la última semana específica
    if (semanasNomina.isNotEmpty) {
      var ultimaSemana = semanasNomina.first[0];
      print('\n6️⃣ ANÁLISIS DETALLADO DE SEMANA $ultimaSemana...');
      
      final analisisDetallado = await db.connection.query('''
        SELECT 
          'Total empleados' as tipo, COUNT(DISTINCT id_empleado) as cantidad
        FROM nomina_empleados_historial WHERE id_semana = @semanaId
        UNION ALL
        SELECT 
          'Con act_1 válida' as tipo, COUNT(*) as cantidad
        FROM nomina_empleados_historial WHERE id_semana = @semanaId AND act_1 IS NOT NULL AND act_1 <> 0
        UNION ALL
        SELECT 
          'Con act_7 válida' as tipo, COUNT(*) as cantidad
        FROM nomina_empleados_historial WHERE id_semana = @semanaId AND act_7 IS NOT NULL AND act_7 <> 0
        UNION ALL
        SELECT 
          'Con horas > 0' as tipo, COUNT(*) as cantidad
        FROM nomina_empleados_historial WHERE id_semana = @semanaId 
        AND (dia_1 > 0 OR dia_2 > 0 OR dia_3 > 0 OR dia_4 > 0 OR dia_5 > 0 OR dia_6 > 0 OR dia_7 > 0)
      ''', substitutionValues: {'semanaId': ultimaSemana});
      
      for (var analisis in analisisDetallado) {
        print('  ${analisis[0]}: ${analisis[1]}');
      }
    }

    await db.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
