import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Explorando información adicional disponible...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('\n📋 1. Explorando la estructura de la función gasto_por_actividad_semana...');
    
    // Vamos a hacer una consulta más detallada para ver qué información podemos obtener
    final result = await db.connection.query('''
      SELECT 
        act.nombre as actividad_nombre,
        SUM(a.pago) as total_pagado,
        COUNT(*) as registros,
        COUNT(DISTINCT n.id_empleado) as empleados_diferentes,
        COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_diferentes,
        AVG(a.pago) as promedio_pago,
        MIN(a.pago) as pago_minimo,
        MAX(a.pago) as pago_maximo,
        r.nombre as rancho_nombre,
        s.fecha_inicio,
        s.fecha_fin,
        act.clave as actividad_clave
      FROM semanas s
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
      LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
      WHERE n.id_semana = s.id_semana
        AND a.act_id IS NOT NULL 
        AND a.act_id <> 0
        AND s.id_semana = 17  -- Una semana específica para probar
      GROUP BY act.nombre, act.clave, r.nombre, s.fecha_inicio, s.fecha_fin
      ORDER BY total_pagado DESC
      LIMIT 5
    ''');
    
    print('✅ Información disponible por actividad:');
    for (final row in result) {
      print('📊 Actividad: ${row[0]}');
      print('  💰 Total pagado: \$${row[1]}');
      print('  📝 Registros: ${row[2]}');
      print('  👥 Empleados únicos: ${row[3]}');
      print('  🏗️ Cuadrillas únicas: ${row[4]}');
      print('  📈 Promedio por registro: \$${double.tryParse(row[5].toString())?.toStringAsFixed(2) ?? '0.00'}');
      print('  📉 Pago mínimo: \$${row[6]}');
      print('  📈 Pago máximo: \$${row[7]}');
      print('  🏞️ Rancho: ${row[8] ?? 'Sin rancho'}');
      print('  📅 Período: ${row[9]} - ${row[10]}');
      print('  🔑 Clave: ${row[11] ?? 'Sin clave'}');
      print('  ─────────────────────');
    }
    
    print('\n📋 2. Explorando datos de empleados por actividad...');
    
    final empleadosResult = await db.connection.query('''
      SELECT 
        act.nombre as actividad_nombre,
        COUNT(DISTINCT n.id_empleado) as total_empleados,
        AVG(CASE WHEN a.pago > 0 THEN a.pago END) as promedio_pago_activo,
        COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago,
        COUNT(CASE WHEN a.pago = 0 THEN 1 END) as registros_sin_pago
      FROM semanas s
      CROSS JOIN nomina_empleados_historial n
      CROSS JOIN LATERAL (
        VALUES 
          (n.act_1, COALESCE(n.dia_1,0)),
          (n.act_2, COALESCE(n.dia_2,0)),
          (n.act_3, COALESCE(n.dia_3,0)),
          (n.act_4, COALESCE(n.dia_4,0)),
          (n.act_5, COALESCE(n.dia_5,0)),
          (n.act_6, COALESCE(n.dia_6,0)),
          (n.act_7, COALESCE(n.dia_7,0))
      ) AS a(act_id, pago)
      LEFT JOIN actividades act ON act.id_actividad = a.act_id
      WHERE n.id_semana = s.id_semana
        AND a.act_id IS NOT NULL 
        AND a.act_id <> 0
        AND s.id_semana = 17
      GROUP BY act.nombre
      ORDER BY total_empleados DESC
      LIMIT 5
    ''');
    
    print('✅ Datos adicionales de empleados:');
    for (final row in empleadosResult) {
      print('👥 ${row[0]}: ${row[1]} empleados, Promedio activo: \$${double.tryParse(row[2].toString())?.toStringAsFixed(2) ?? '0.00'}, Con pago: ${row[3]}, Sin pago: ${row[4]}');
    }
    
    print('\n🎯 INFORMACIÓN ADICIONAL QUE SE PUEDE MOSTRAR:');
    print('  ✅ Número de empleados únicos por actividad');
    print('  ✅ Número de cuadrillas involucradas');
    print('  ✅ Promedio de pago por registro');
    print('  ✅ Pago mínimo y máximo');
    print('  ✅ Rancho donde se realizó la actividad');
    print('  ✅ Clave de la actividad');
    print('  ✅ Período de la semana');
    print('  ✅ Registros con pago vs sin pago');
    print('  ✅ Promedio de pago para registros activos');
    print('  ✅ Días de la semana trabajados');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await db.close();
  }
}
