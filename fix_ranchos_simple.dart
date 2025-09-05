import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔧 Asignación simple de ranchos...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Estrategia simple: asignar ranchos rotativamente basado en ID de actividad
    print('📋 Asignando ranchos a semana 18...');
    
    // Para cada día, asignar rancho basado en actividad
    for (int dia = 1; dia <= 7; dia++) {
      final result = await db.connection.execute('''
        UPDATE nomina_empleados_historial 
        SET campo_$dia = CASE 
          WHEN act_$dia = 0 OR act_$dia IS NULL THEN 0
          WHEN act_$dia % 3 = 1 THEN 1  -- San Francisco
          WHEN act_$dia % 3 = 2 THEN 2  -- San Valentín  
          WHEN act_$dia % 3 = 0 THEN 3  -- Santa Amalia
        END
        WHERE id_semana = 18
      ''');
      print('  ✅ Día $dia: $result registros actualizados');
    }
    
    // Verificar resultado
    print('\n📊 Verificando asignaciones...');
    final verificacion = await db.connection.query('''
      SELECT 
        r.nombre as rancho,
        a.nombre as actividad,
        COUNT(*) as cantidad,
        SUM(datos.pago) as total_pago
      FROM nomina_empleados_historial n
      CROSS JOIN LATERAL (
        VALUES
          (n.act_1, n.campo_1, COALESCE(n.dia_1, 0)),
          (n.act_2, n.campo_2, COALESCE(n.dia_2, 0)),
          (n.act_3, n.campo_3, COALESCE(n.dia_3, 0)),
          (n.act_4, n.campo_4, COALESCE(n.dia_4, 0)),
          (n.act_5, n.campo_5, COALESCE(n.dia_5, 0)),
          (n.act_6, n.campo_6, COALESCE(n.dia_6, 0)),
          (n.act_7, n.campo_7, COALESCE(n.dia_7, 0))
      ) AS datos(act_id, rancho_id, pago)
      LEFT JOIN actividades a ON a.id_actividad = datos.act_id
      LEFT JOIN ranchos r ON r.id_rancho = datos.rancho_id
      WHERE n.id_semana = 18 
        AND datos.act_id IS NOT NULL 
        AND datos.act_id <> 0
        AND datos.rancho_id IS NOT NULL
        AND datos.rancho_id <> 0
        AND datos.pago <> 0
      GROUP BY r.nombre, a.nombre
      ORDER BY r.nombre, a.nombre
    ''');
    
    print('✅ Asignaciones para semana 18:');
    for (final row in verificacion) {
      print('  - ${row[0]} → ${row[1]}: ${row[2]} registros, \$${row[3]} total');
    }
    
    // También probar los reportes
    print('\n🧪 Probando función SQL con semana 18...');
    final reporteGeneral = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(18)
    ''');
    
    print('📊 Reporte general semana 18:');
    for (final row in reporteGeneral) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
    // Probar reporte por rancho
    print('\n🏞️ Reporte por rancho (San Francisco) semana 18:');
    final reporteRancho = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(18, NULL, 1)
    ''');
    
    for (final row in reporteRancho) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
