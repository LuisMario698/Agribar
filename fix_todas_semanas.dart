import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔧 Asignando ranchos a TODAS las semanas...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Obtener todas las semanas
    final semanas = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin 
      FROM semanas_nomina 
      ORDER BY id_semana
    ''');
    
    print('📋 Semanas encontradas: ${semanas.length}');
    
    // Función para asignar ranchos a una semana
    Future<void> asignarRanchos(int semanaId) async {
      print('\n🔧 Procesando semana $semanaId...');
      
      // Estrategia: actividad ID % 3 determina el rancho
      for (int dia = 1; dia <= 7; dia++) {
        await db.connection.execute('''
          UPDATE nomina_empleados_historial 
          SET campo_$dia = CASE 
            WHEN act_$dia = 0 OR act_$dia IS NULL THEN 0
            WHEN act_$dia % 3 = 1 THEN 1  -- San Francisco
            WHEN act_$dia % 3 = 2 THEN 2  -- San Valentín  
            WHEN act_$dia % 3 = 0 THEN 3  -- Santa Amalia
          END
          WHERE id_semana = $semanaId
            AND (campo_$dia IS NULL OR campo_$dia = 0)
        ''');
      }
    }
    
    // Asignar ranchos a todas las semanas
    for (final semana in semanas) {
      final semanaId = semana[0] as int;
      await asignarRanchos(semanaId);
    }
    
    // Verificar resultados
    print('\n📊 Verificando resultados por semana...');
    for (final semana in semanas) {
      final semanaId = semana[0] as int;
      final fechaInicio = semana[1] as DateTime;
      
      print('\n📅 Semana $semanaId (${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}):');
      
      // Contar asignaciones
      final asignaciones = await db.connection.query('''
        SELECT 
          r.nombre as rancho,
          COUNT(*) as cantidad,
          SUM(datos.pago) as total
        FROM nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES
            (n.campo_1, COALESCE(n.dia_1, 0)),
            (n.campo_2, COALESCE(n.dia_2, 0)),
            (n.campo_3, COALESCE(n.dia_3, 0)),
            (n.campo_4, COALESCE(n.dia_4, 0)),
            (n.campo_5, COALESCE(n.dia_5, 0)),
            (n.campo_6, COALESCE(n.dia_6, 0)),
            (n.campo_7, COALESCE(n.dia_7, 0))
        ) AS datos(rancho_id, pago)
        LEFT JOIN ranchos r ON r.id_rancho = datos.rancho_id
        WHERE n.id_semana = $semanaId 
          AND datos.rancho_id IS NOT NULL
          AND datos.rancho_id <> 0
          AND datos.pago <> 0
        GROUP BY r.nombre
        ORDER BY r.nombre
      ''');
      
      if (asignaciones.isEmpty) {
        print('  ❌ Sin asignaciones de rancho');
      } else {
        for (final row in asignaciones) {
          print('  ✅ ${row[0]}: ${row[1]} registros, \$${row[2]} total');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
