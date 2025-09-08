import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔍 Verificando estructura de nomina_empleados_historial...');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // Obtener estructura de la tabla historial
    final columnas = await db.connection.query('''
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial' 
      ORDER BY ordinal_position;
    ''');

    print('\n📋 ESTRUCTURA DE nomina_empleados_historial:');
    print('=' * 60);
    for (var col in columnas) {
      String columna = col[0].toString();
      String tipo = col[1].toString();
      String nullable = col[2].toString();
      print('${columna.padRight(25)} | ${tipo.padRight(15)} | nullable: $nullable');
    }

    // Obtener estructura de la tabla semanal para comparar
    final columnasSemanal = await db.connection.query('''
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      ORDER BY ordinal_position;
    ''');

    print('\n📋 ESTRUCTURA DE nomina_empleados_semanal:');
    print('=' * 60);
    for (var col in columnasSemanal) {
      String columna = col[0].toString();
      String tipo = col[1].toString();
      String nullable = col[2].toString();
      print('${columna.padRight(25)} | ${tipo.padRight(15)} | nullable: $nullable');
    }

    // Verificar datos con nulls en historial
    print('\n🔍 Verificando registros con NULL en historial...');
    final nulls = await db.connection.query('''
      SELECT COUNT(*) as total, 
             SUM(CASE WHEN dia_7 IS NULL THEN 1 ELSE 0 END) as dia7_nulls,
             SUM(CASE WHEN dia_1_actividad_id IS NULL THEN 1 ELSE 0 END) as act1_nulls,
             SUM(CASE WHEN dia_7_actividad_id IS NULL THEN 1 ELSE 0 END) as act7_nulls,
             SUM(CASE WHEN dia_1_campo_id IS NULL THEN 1 ELSE 0 END) as campo1_nulls,
             SUM(CASE WHEN dia_7_campo_id IS NULL THEN 1 ELSE 0 END) as campo7_nulls
      FROM nomina_empleados_historial;
    ''');

    if (nulls.isNotEmpty) {
      var row = nulls.first;
      print('Total registros: ${row[0]}');
      print('dia_7 con NULL: ${row[1]}');
      print('dia_1_actividad_id con NULL: ${row[2]}');
      print('dia_7_actividad_id con NULL: ${row[3]}');
      print('dia_1_campo_id con NULL: ${row[4]}');
      print('dia_7_campo_id con NULL: ${row[5]}');
    }

    await db.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
