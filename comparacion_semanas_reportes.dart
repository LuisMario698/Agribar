import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔍 ANÁLISIS COMPARATIVO: Semanas que funcionan vs las que no');
  print('===========================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Obtener todas las semanas que aparecen en reportes (las que funcionan)
    print('\n1️⃣ SEMANAS QUE FUNCIONAN (aparecen en reportes)...');
    
    final semanasQueFuncionan = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.autorizado_por
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.id_semana DESC
    ''');
    
    print('✅ Semanas que aparecen en reportes (${semanasQueFuncionan.length}):');
    for (var sem in semanasQueFuncionan) {
      print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]} | Auth: ${sem[4]}');
    }

    // 2. Obtener semanas que tienen datos en historial pero NO aparecen en reportes
    print('\n2️⃣ SEMANAS QUE NO FUNCIONAN (tienen datos pero no aparecen)...');
    
    final semanasQueNoFuncionan = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.cerrada,
        s.autorizado_por,
        COUNT(n.id_empleado) as registros_historial
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = false OR s.esta_cerrada IS NULL
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada, s.cerrada, s.autorizado_por
      ORDER BY s.id_semana DESC
    ''');
    
    print('❌ Semanas con datos en historial pero NO aparecen en reportes (${semanasQueNoFuncionan.length}):');
    for (var sem in semanasQueNoFuncionan) {
      print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]}');
      print('    esta_cerrada: ${sem[3]} | cerrada: ${sem[4]} | Auth: ${sem[5]} | Registros: ${sem[6]}');
    }

    // 3. Análisis detallado: ¿Qué diferencias hay en los datos?
    print('\n3️⃣ ANÁLISIS COMPARATIVO DETALLADO...');
    
    if (semanasQueFuncionan.isNotEmpty && semanasQueNoFuncionan.isNotEmpty) {
      var semanaQueFunciona = semanasQueFuncionan.first[0];
      var semanaQueNoFunciona = semanasQueNoFuncionan.first[0];
      
      print('\n🔍 COMPARANDO:');
      print('  ✅ Semana que funciona: $semanaQueFunciona');
      print('  ❌ Semana que no funciona: $semanaQueNoFunciona');
      
      // Comparar datos de historial
      final datosQueFunciona = await db.connection.query('''
        SELECT 
          COUNT(*) as total_registros,
          COUNT(CASE WHEN act_1 IS NOT NULL AND act_1 <> 0 THEN 1 END) as con_act1,
          COUNT(CASE WHEN act_7 IS NOT NULL AND act_7 <> 0 THEN 1 END) as con_act7,
          COUNT(CASE WHEN dia_1 IS NOT NULL AND dia_1 > 0 THEN 1 END) as con_horas1,
          COUNT(CASE WHEN dia_7 IS NOT NULL AND dia_7 > 0 THEN 1 END) as con_horas7,
          AVG(CASE WHEN dia_1 IS NOT NULL THEN dia_1 ELSE 0 END) as promedio_horas1,
          AVG(CASE WHEN dia_7 IS NOT NULL THEN dia_7 ELSE 0 END) as promedio_horas7
        FROM nomina_empleados_historial 
        WHERE id_semana = @semana
      ''', substitutionValues: {'semana': semanaQueFunciona});
      
      final datosQueNoFunciona = await db.connection.query('''
        SELECT 
          COUNT(*) as total_registros,
          COUNT(CASE WHEN act_1 IS NOT NULL AND act_1 <> 0 THEN 1 END) as con_act1,
          COUNT(CASE WHEN act_7 IS NOT NULL AND act_7 <> 0 THEN 1 END) as con_act7,
          COUNT(CASE WHEN dia_1 IS NOT NULL AND dia_1 > 0 THEN 1 END) as con_horas1,
          COUNT(CASE WHEN dia_7 IS NOT NULL AND dia_7 > 0 THEN 1 END) as con_horas7,
          AVG(CASE WHEN dia_1 IS NOT NULL THEN dia_1 ELSE 0 END) as promedio_horas1,
          AVG(CASE WHEN dia_7 IS NOT NULL THEN dia_7 ELSE 0 END) as promedio_horas7
        FROM nomina_empleados_historial 
        WHERE id_semana = @semana
      ''', substitutionValues: {'semana': semanaQueNoFunciona});
      
      print('\n📊 COMPARACIÓN DE DATOS:');
      if (datosQueFunciona.isNotEmpty && datosQueNoFunciona.isNotEmpty) {
        var funciona = datosQueFunciona.first;
        var noFunciona = datosQueNoFunciona.first;
        
        print('                                   FUNCIONA    NO FUNCIONA');
        print('  Total registros:                ${funciona[0].toString().padLeft(8)}    ${noFunciona[0].toString().padLeft(11)}');
        print('  Con actividad día 1:            ${funciona[1].toString().padLeft(8)}    ${noFunciona[1].toString().padLeft(11)}');
        print('  Con actividad día 7:            ${funciona[2].toString().padLeft(8)}    ${noFunciona[2].toString().padLeft(11)}');
        print('  Con horas día 1:                ${funciona[3].toString().padLeft(8)}    ${noFunciona[3].toString().padLeft(11)}');
        print('  Con horas día 7:                ${funciona[4].toString().padLeft(8)}    ${noFunciona[4].toString().padLeft(11)}');
        print('  Promedio horas día 1:           ${funciona[5].toString().padLeft(8)}    ${noFunciona[5].toString().padLeft(11)}');
        print('  Promedio horas día 7:           ${funciona[6].toString().padLeft(8)}    ${noFunciona[6].toString().padLeft(11)}');
      }

      // Mostrar registros específicos de cada semana
      print('\n🔍 EJEMPLOS DE REGISTROS:');
      
      print('\n✅ Semana que funciona ($semanaQueFunciona) - Primeros 3 registros:');
      final ejemplosFuncionan = await db.connection.query('''
        SELECT id_empleado, act_1, dia_1, act_7, dia_7, campo_1, campo_7
        FROM nomina_empleados_historial 
        WHERE id_semana = @semana 
        LIMIT 3
      ''', substitutionValues: {'semana': semanaQueFunciona});
      
      for (var ej in ejemplosFuncionan) {
        print('  Empleado ${ej[0]}: act_1=${ej[1]} dia_1=${ej[2]} | act_7=${ej[3]} dia_7=${ej[4]} | campo_1=${ej[5]} campo_7=${ej[6]}');
      }
      
      print('\n❌ Semana que NO funciona ($semanaQueNoFunciona) - Primeros 3 registros:');
      final ejemplosNoFuncionan = await db.connection.query('''
        SELECT id_empleado, act_1, dia_1, act_7, dia_7, campo_1, campo_7
        FROM nomina_empleados_historial 
        WHERE id_semana = @semana 
        LIMIT 3
      ''', substitutionValues: {'semana': semanaQueNoFunciona});
      
      for (var ej in ejemplosNoFuncionan) {
        print('  Empleado ${ej[0]}: act_1=${ej[1]} dia_1=${ej[2]} | act_7=${ej[3]} dia_7=${ej[4]} | campo_1=${ej[5]} campo_7=${ej[6]}');
      }
    }

    // 4. Probar la consulta completa del reporte en ambas semanas
    print('\n4️⃣ PROBANDO CONSULTA DE REPORTE EN AMBAS SEMANAS...');
    
    if (semanasQueFuncionan.isNotEmpty && semanasQueNoFuncionan.isNotEmpty) {
      var semanaFunciona = semanasQueFuncionan.first[0];
      var semanaNoFunciona = semanasQueNoFuncionan.first[0];
      
      // Consulta del reporte para la semana que funciona
      print('\n✅ Resultado reporte semana que FUNCIONA ($semanaFunciona):');
      try {
        final reporteFunciona = await db.connection.query('''
          SELECT 
            act.nombre as actividad_nombre,
            COUNT(*) as registros_totales,
            SUM(a.pago) as total_pagado
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
          GROUP BY act.nombre
          ORDER BY total_pagado DESC
        ''', substitutionValues: {'semanaId': semanaFunciona});
        
        for (var rep in reporteFunciona.take(5)) {
          print('  • ${rep[0]}: ${rep[1]} registros, \$${rep[2]} total');
        }
      } catch (e) {
        print('  ❌ Error: $e');
      }
      
      // Consulta del reporte para la semana que NO funciona
      print('\n❌ Resultado reporte semana que NO FUNCIONA ($semanaNoFunciona):');
      try {
        final reporteNoFunciona = await db.connection.query('''
          SELECT 
            act.nombre as actividad_nombre,
            COUNT(*) as registros_totales,
            SUM(a.pago) as total_pagado
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
          GROUP BY act.nombre
          ORDER BY total_pagado DESC
        ''', substitutionValues: {'semanaId': semanaNoFunciona});
        
        if (reporteNoFunciona.isEmpty) {
          print('  ⚠️  REPORTE VACÍO - Esta es la razón por la que no aparece');
          
          // Análisis paso a paso de por qué está vacío
          print('\n🔍 ANÁLISIS PASO A PASO de por qué está vacío:');
          
          // Verificar cada condición del WHERE
          final verificaciones = await db.connection.query('''
            SELECT 
              'Total registros en historial' as condicion,
              COUNT(*) as cantidad
            FROM nomina_empleados_historial n, semanas_nomina sn
            WHERE n.id_semana = sn.id_semana AND sn.id_semana = @semanaId
            
            UNION ALL
            
            SELECT 
              'Con actividades no nulas' as condicion,
              COUNT(*) as cantidad
            FROM nomina_empleados_historial n, semanas_nomina sn
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
            WHERE n.id_semana = sn.id_semana 
              AND a.act_id IS NOT NULL
              AND sn.id_semana = @semanaId
            
            UNION ALL
            
            SELECT 
              'Con actividades <> 0' as condicion,
              COUNT(*) as cantidad
            FROM nomina_empleados_historial n, semanas_nomina sn
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
            WHERE n.id_semana = sn.id_semana 
              AND a.act_id IS NOT NULL 
              AND a.act_id <> 0
              AND sn.id_semana = @semanaId
          ''', substitutionValues: {'semanaId': semanaNoFunciona});
          
          for (var verif in verificaciones) {
            print('    ${verif[0]}: ${verif[1]}');
          }
          
        } else {
          for (var rep in reporteNoFunciona.take(5)) {
            print('  • ${rep[0]}: ${rep[1]} registros, \$${rep[2]} total');
          }
        }
      } catch (e) {
        print('  ❌ Error: $e');
      }
    }

    // 5. Generar script de corrección
    print('\n5️⃣ SCRIPT DE CORRECCIÓN...');
    
    if (semanasQueNoFuncionan.isNotEmpty) {
      print('\n🔧 Para que estas semanas aparezcan en reportes, ejecuta:');
      for (var sem in semanasQueNoFuncionan) {
        print('UPDATE semanas_nomina SET esta_cerrada = true WHERE id_semana = ${sem[0]};');
      }
    }

    await db.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
