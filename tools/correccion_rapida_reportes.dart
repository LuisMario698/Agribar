import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔧 CORRECCIÓN RÁPIDA: Marcar semanas como cerradas');
  print('==================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Encontrar semanas que tienen datos en historial pero no están cerradas
    final semanasParaCorregir = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.cerrada,
        COUNT(n.id_empleado) as registros_historial
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = false OR s.esta_cerrada IS NULL
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada, s.cerrada
      ORDER BY s.id_semana
    ''');
    
    print('🔍 Semanas encontradas que necesitan corrección:');
    if (semanasParaCorregir.isEmpty) {
      print('  ✅ No hay semanas que necesiten corrección');
    } else {
      for (var sem in semanasParaCorregir) {
        print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]}');
        print('    Estado actual: esta_cerrada=${sem[3]}, cerrada=${sem[4]}');
        print('    Registros en historial: ${sem[5]}');
      }
      
      print('\n🔧 Aplicando correcciones...');
      
      int corregidas = 0;
      for (var sem in semanasParaCorregir) {
        var idSemana = sem[0];
        try {
          await db.connection.execute('''
            UPDATE semanas_nomina 
            SET esta_cerrada = true, 
                cerrada = true,
                fecha_autorizacion = CASE 
                  WHEN fecha_autorizacion IS NULL THEN CURRENT_TIMESTAMP 
                  ELSE fecha_autorizacion 
                END,
                autorizado_por = CASE 
                  WHEN autorizado_por IS NULL OR autorizado_por = '' THEN 'Sistema' 
                  ELSE autorizado_por 
                END
            WHERE id_semana = @idSemana
          ''', substitutionValues: {'idSemana': idSemana});
          
          print('  ✅ Semana $idSemana corregida');
          corregidas++;
          
        } catch (e) {
          print('  ❌ Error al corregir semana $idSemana: $e');
        }
      }
      
      print('\n📊 RESUMEN:');
      print('  • Semanas corregidas: $corregidas/${semanasParaCorregir.length}');
    }

    // 2. Verificar que ahora aparezcan en reportes
    print('\n🔍 Verificando que ahora aparezcan en reportes...');
    
    final semanasEnReportes = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.autorizado_por
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.id_semana DESC
    ''');
    
    print('✅ Semanas que ahora aparecerán en reportes (${semanasEnReportes.length}):');
    for (var sem in semanasEnReportes) {
      print('  • Semana ${sem[0]}: ${sem[1]} a ${sem[2]} | Auth: ${sem[3]}');
    }

    // 3. Probar una consulta de reporte para verificar que funcione
    if (semanasEnReportes.isNotEmpty) {
      var semanaTest = semanasEnReportes.first[0];
      print('\n🧪 Probando reporte con semana $semanaTest...');
      
      try {
        final testReporte = await db.connection.query('''
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
          LIMIT 5
        ''', substitutionValues: {'semanaId': semanaTest});
        
        if (testReporte.isEmpty) {
          print('  ⚠️  Aún no hay datos en el reporte (problema en los datos)');
        } else {
          print('  ✅ Reporte funciona correctamente:');
          for (var rep in testReporte) {
            print('    • ${rep[0]}: ${rep[1]} registros, \$${rep[2]} total');
          }
        }
      } catch (e) {
        print('  ❌ Error al probar reporte: $e');
      }
    }

    await db.close();
    
    print('\n🎯 PRÓXIMOS PASOS:');
    print('1. Recarga la aplicación de reportes');
    print('2. Las semanas corregidas deberían aparecer en el dropdown');
    print('3. Si aún hay problemas, revisa que las actividades existan en la tabla actividades');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
