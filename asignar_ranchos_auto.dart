import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Identificando actividades y asignando ranchos automáticamente...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Identificar todas las actividades
    print('📋 Todas las actividades en la base de datos:');
    final actividades = await db.connection.query('''
      SELECT id_actividad, nombre, clave FROM actividades ORDER BY id_actividad
    ''');
    
    final mapaActividades = <int, String>{};
    for (final act in actividades) {
      final id = act[0] as int;
      final nombre = act[1] as String;
      mapaActividades[id] = nombre;
      print('  - ID $id: $nombre');
    }
    
    // Ver todos los ranchos disponibles
    print('\n🏞️ Todos los ranchos disponibles:');
    final ranchos = await db.connection.query('''
      SELECT id_rancho, nombre FROM ranchos ORDER BY id_rancho
    ''');
    
    final mapaRanchos = <int, String>{};
    for (final rancho in ranchos) {
      final id = rancho[0] as int;
      final nombre = rancho[1] as String;
      mapaRanchos[id] = nombre;
      print('  - ID $id: $nombre');
    }
    
    // Función para asignar ranchos automáticamente
    Future<void> asignarRanchosASemana(int semanaId) async {
      print('\n🔧 Asignando ranchos a semana $semanaId...');
      
      // Crear un mapeo de actividades a ranchos de forma estratégica
      final asignaciones = <int, int>{
        1: 3, // DESTAJO → Santa Amalia
        2: 1, // JEFE DE LINEA → San Francisco  
        3: 2, // JEFE DE EMPAQUE → San Valentín
        4: 1, // (Nueva actividad) → San Francisco
        5: 2, // (Nueva actividad) → San Valentín  
        6: 3, // (Nueva actividad) → Santa Amalia
        7: 1, // (Nueva actividad) → San Francisco
        8: 2, // (Nueva actividad) → San Valentín
        9: 3, // (Nueva actividad) → Santa Amalia
        10: 1, // (Nueva actividad) → San Francisco
      };
      
      for (final dia in [1, 2, 3, 4, 5, 6, 7]) {
        final updates = <String>[];
        final actField = 'act_$dia';
        final campoField = 'campo_$dia';
        
        for (final actividad in asignaciones.keys) {
          final rancho = asignaciones[actividad]!;
          updates.add('$campoField = CASE WHEN $actField = $actividad THEN $rancho ELSE $campoField END');
        }
        
        if (updates.isNotEmpty) {
          final updateQuery = '''
            UPDATE nomina_empleados_historial 
            SET ${updates.join(', ')}
            WHERE id_semana = $semanaId
          ''';
          
          final result = await db.connection.execute(updateQuery);
          print('  ✅ Día $dia: $result registros actualizados');
        }
      }
    }
    
    // Asignar ranchos a semana 18
    await asignarRanchosASemana(18);
    
    // Verificar resultado para semana 18
    print('\n📊 Verificando asignaciones para semana 18...');
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
      GROUP BY r.nombre, a.nombre
      ORDER BY r.nombre, a.nombre
    ''');
    
    print('✅ Asignaciones completadas para semana 18:');
    for (final row in verificacion) {
      print('  - ${row[0]} → ${row[1]}: ${row[2]} registros, \$${row[3]} total');
    }
    
    // También asegurar que semana 17 esté bien
    print('\n🔄 Verificando semana 17...');
    await asignarRanchosASemana(17);
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
