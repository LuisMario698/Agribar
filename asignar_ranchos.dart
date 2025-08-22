import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔧 Asignando ranchos por defecto a los datos...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Primero verificar cuántos registros no tienen ranchos asignados
    final sinRanchos = await db.connection.query('''
      SELECT COUNT(*) 
      FROM nomina_empleados_historial 
      WHERE id_semana = 17 
        AND (campo_1 = 0 OR campo_1 IS NULL)
        AND (campo_2 = 0 OR campo_2 IS NULL)
        AND (campo_3 = 0 OR campo_3 IS NULL)
        AND (campo_4 = 0 OR campo_4 IS NULL)
        AND (campo_5 = 0 OR campo_5 IS NULL)
        AND (campo_6 = 0 OR campo_6 IS NULL)
        AND (campo_7 = 0 OR campo_7 IS NULL)
    ''');
    
    print('📊 Registros sin ranchos asignados: ${sinRanchos.first[0]}');
    
    // Obtener los ranchos disponibles
    final ranchos = await db.connection.query('''
      SELECT id_rancho, nombre FROM ranchos ORDER BY id_rancho
    ''');
    
    print('🏞️ Ranchos disponibles:');
    for (final rancho in ranchos) {
      print('  - ${rancho[1]} (ID: ${rancho[0]})');
    }
    
    // Asignar ranchos de forma estratégica basado en actividades
    print('\n🔧 Asignando ranchos...');
    
    // Asignar San Francisco (ID: 1) a actividades de JEFE DE LINEA (ID: 2)
    var updated1 = await db.connection.execute('''
      UPDATE nomina_empleados_historial 
      SET campo_1 = CASE WHEN act_1 = 2 THEN 1 ELSE campo_1 END,
          campo_2 = CASE WHEN act_2 = 2 THEN 1 ELSE campo_2 END,
          campo_3 = CASE WHEN act_3 = 2 THEN 1 ELSE campo_3 END,
          campo_4 = CASE WHEN act_4 = 2 THEN 1 ELSE campo_4 END,
          campo_5 = CASE WHEN act_5 = 2 THEN 1 ELSE campo_5 END,
          campo_6 = CASE WHEN act_6 = 2 THEN 1 ELSE campo_6 END,
          campo_7 = CASE WHEN act_7 = 2 THEN 1 ELSE campo_7 END
      WHERE id_semana = 17
    ''');
    print('✅ Asignados a San Francisco: $updated1 registros actualizados');
    
    // Asignar San Valentín (ID: 2) a actividades de JEFE DE EMPAQUE (ID: 3)
    var updated2 = await db.connection.execute('''
      UPDATE nomina_empleados_historial 
      SET campo_1 = CASE WHEN act_1 = 3 THEN 2 ELSE campo_1 END,
          campo_2 = CASE WHEN act_2 = 3 THEN 2 ELSE campo_2 END,
          campo_3 = CASE WHEN act_3 = 3 THEN 2 ELSE campo_3 END,
          campo_4 = CASE WHEN act_4 = 3 THEN 2 ELSE campo_4 END,
          campo_5 = CASE WHEN act_5 = 3 THEN 2 ELSE campo_5 END,
          campo_6 = CASE WHEN act_6 = 3 THEN 2 ELSE campo_6 END,
          campo_7 = CASE WHEN act_7 = 3 THEN 2 ELSE campo_7 END
      WHERE id_semana = 17
    ''');
    print('✅ Asignados a San Valentín: $updated2 registros actualizados');
    
    // Asignar Santa Amalia (ID: 3) a actividades de DESTAJO (ID: 1)
    var updated3 = await db.connection.execute('''
      UPDATE nomina_empleados_historial 
      SET campo_1 = CASE WHEN act_1 = 1 THEN 3 ELSE campo_1 END,
          campo_2 = CASE WHEN act_2 = 1 THEN 3 ELSE campo_2 END,
          campo_3 = CASE WHEN act_3 = 1 THEN 3 ELSE campo_3 END,
          campo_4 = CASE WHEN act_4 = 1 THEN 3 ELSE campo_4 END,
          campo_5 = CASE WHEN act_5 = 1 THEN 3 ELSE campo_5 END,
          campo_6 = CASE WHEN act_6 = 1 THEN 3 ELSE campo_6 END,
          campo_7 = CASE WHEN act_7 = 1 THEN 3 ELSE campo_7 END
      WHERE id_semana = 17
    ''');
    print('✅ Asignados a Santa Amalia: $updated3 registros actualizados');
    
    // Verificar resultado
    print('\n📊 Verificando asignaciones...');
    final verificacion = await db.connection.query('''
      SELECT 
        r.nombre as rancho,
        a.nombre as actividad,
        COUNT(*) as cantidad
      FROM nomina_empleados_historial n
      CROSS JOIN LATERAL (
        VALUES
          (n.act_1, n.campo_1, n.dia_1),
          (n.act_2, n.campo_2, n.dia_2),
          (n.act_3, n.campo_3, n.dia_3),
          (n.act_4, n.campo_4, n.dia_4),
          (n.act_5, n.campo_5, n.dia_5),
          (n.act_6, n.campo_6, n.dia_6),
          (n.act_7, n.campo_7, n.dia_7)
      ) AS datos(act_id, rancho_id, pago)
      LEFT JOIN actividades a ON a.id_actividad = datos.act_id
      LEFT JOIN ranchos r ON r.id_rancho = datos.rancho_id
      WHERE n.id_semana = 17 
        AND datos.act_id IS NOT NULL 
        AND datos.act_id <> 0
        AND datos.rancho_id IS NOT NULL
        AND datos.rancho_id <> 0
      GROUP BY r.nombre, a.nombre
      ORDER BY r.nombre, a.nombre
    ''');
    
    print('✅ Asignaciones completadas:');
    for (final row in verificacion) {
      print('  - ${row[0]} → ${row[1]}: ${row[2]} registros');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
