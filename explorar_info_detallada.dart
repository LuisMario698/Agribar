import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Explorando información detallada disponible...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('\n📋 Consultando información detallada de la semana 18...');
    
    final result = await db.connection.query('''
      SELECT 
        act.nombre as actividad_nombre,
        act.clave as actividad_clave,
        SUM(a.pago) as total_pagado,
        COUNT(*) as registros_totales,
        COUNT(DISTINCT n.id_empleado) as empleados_unicos,
        COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_unicas,
        AVG(a.pago) as promedio_pago,
        MIN(a.pago) as pago_minimo,
        MAX(a.pago) as pago_maximo,
        r.nombre as rancho_nombre,
        sn.fecha_inicio,
        sn.fecha_fin,
        sn.autorizado_por,
        COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago,
        COUNT(CASE WHEN a.pago = 0 THEN 1 END) as registros_sin_pago,
        STRING_AGG(DISTINCT c.nombre, ', ') as cuadrillas_nombres
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
      LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
      LEFT JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
      WHERE n.id_semana = sn.id_semana
        AND a.act_id IS NOT NULL 
        AND a.act_id <> 0
        AND sn.id_semana = 18
      GROUP BY act.nombre, act.clave, r.nombre, sn.fecha_inicio, sn.fecha_fin, sn.autorizado_por
      ORDER BY total_pagado DESC
      LIMIT 10
    ''');
    
    print('✅ Información completa disponible:');
    print('═══════════════════════════════════════════════════════════════');
    
    for (final row in result) {
      print('📊 ACTIVIDAD: ${row[0]} (${row[1] ?? 'Sin clave'})');
      print('  💰 Total pagado: \$${row[2]}');
      print('  📝 Registros totales: ${row[3]}');
      print('  👥 Empleados únicos: ${row[4]}');
      print('  🏗️ Cuadrillas únicas: ${row[5]}');
      print('  📈 Promedio por registro: \$${double.tryParse(row[6].toString())?.toStringAsFixed(2) ?? '0.00'}');
      print('  📉 Rango de pagos: \$${row[7]} - \$${row[8]}');
      print('  🏞️ Rancho: ${row[9] ?? 'Múltiples/Sin asignar'}');
      print('  📅 Período: ${row[10]} - ${row[11]}');
      print('  👤 Autorizado por: ${row[12] ?? 'Sin autorización'}');
      print('  ✅ Con pago: ${row[13]} | ❌ Sin pago: ${row[14]}');
      print('  🏗️ Cuadrillas: ${row[15] ?? 'Sin cuadrillas'}');
      print('  ─────────────────────────────────────────────────────────────');
    }
    
    print('\n🎯 COLUMNAS ADICIONALES RECOMENDADAS PARA LA TABLA:');
    print('═══════════════════════════════════════════════════════════════');
    print('  ✅ Clave de Actividad - Para identificación rápida');
    print('  ✅ Empleados Únicos - Cuántas personas trabajaron');
    print('  ✅ Cuadrillas Únicas - Cuántas cuadrillas participaron');
    print('  ✅ Promedio por Registro - Pago promedio por entrada');
    print('  ✅ Rango de Pagos - Mínimo y máximo pagado');
    print('  ✅ Rancho - Dónde se realizó la actividad');
    print('  ✅ Eficiencia - Registros con pago vs sin pago');
    print('  ✅ Período - Fechas de la semana');
    print('  ✅ Nombres de Cuadrillas - Qué cuadrillas participaron');
    print('  ✅ Estado de Autorización - Quién autorizó');
    
    print('\n💡 MÉTRICAS ADICIONALES CALCULABLES:');
    print('═══════════════════════════════════════════════════════════════');
    print('  📊 Eficiencia = (Registros con pago / Total registros) * 100%');
    print('  💰 Productividad = Total pagado / Empleados únicos');
    print('  🏗️ Carga de trabajo = Total registros / Cuadrillas únicas');
    print('  📈 Intensidad = Promedio por registro vs promedio general');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await db.close();
  }
}
