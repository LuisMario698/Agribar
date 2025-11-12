import 'lib/services/database_service.dart';

void main() async {
  print('🔍 DEBUG ESPECÍFICO SEMANA 37');
  print('=' * 40);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Contar registros exactos
    print('\n1. Total registros semana 37:');
    final count = await db.connection.query(
      'SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = 37'
    );
    print('   Registros: ${count.first[0]}');
    
    // 2. Mostrar algunos registros de ejemplo
    print('\n2. Primeros 3 registros:');
    final samples = await db.connection.query('''
      SELECT id_empleado, id_cuadrilla, act_1, dia_1, act_2, dia_2, act_3, dia_3
      FROM nomina_empleados_semanal 
      WHERE id_semana = 37 
      LIMIT 3
    ''');
    
    for (var row in samples) {
      print('   Empleado ${row[0]}: act_1=${row[2]}/\$${row[3]}, act_2=${row[4]}/\$${row[5]}, act_3=${row[6]}/\$${row[7]}');
    }
    
    // 3. Actividades únicas presentes
    print('\n3. Actividades encontradas:');
    final actividades = await db.connection.query('''
      SELECT DISTINCT unnest(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) as actividad_id
      FROM nomina_empleados_semanal 
      WHERE id_semana = 37 
      AND unnest(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) IS NOT NULL
      ORDER BY actividad_id
    ''');
    
    print('   IDs: ${actividades.map((r) => r[0]).join(', ')}');
    
    // 4. Verificar tabla actividades
    print('\n4. Nombres de actividades:');
    if (actividades.isNotEmpty) {
      final actIds = actividades.map((r) => r[0]).join(',');
      final nombres = await db.connection.query('''
        SELECT id_actividad, nombre 
        FROM actividades 
        WHERE id_actividad IN ($actIds)
        ORDER BY id_actividad
      ''');
      
      for (var row in nombres) {
        print('   ${row[0]}: ${row[1]}');
      }
    }
    
    // 5. Probar consulta simple
    print('\n5. Prueba consulta simple:');
    final simple = await db.connection.query('''
      SELECT COUNT(*) 
      FROM nomina_empleados_semanal n
      JOIN actividades a ON a.id_actividad = n.act_1
      WHERE n.id_semana = 37 AND n.act_1 IS NOT NULL
    ''');
    print('   Join con act_1: ${simple.first[0]} registros');
    
    print('\n✅ DEBUG COMPLETADO');
    
  } catch (e, stack) {
    print('❌ Error: $e');
    print('Stack: $stack');
  } finally {
    await db.close();
  }
}
