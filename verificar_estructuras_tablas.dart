import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 COMPARANDO ESTRUCTURA DE TABLAS SEMANAL VS HISTORIAL\n');
  
  // Conectar a PostgreSQL
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'agribar_bd',
    username: 'postgres',
    password: '12345'
  );
  
  try {
    await connection.open();
    print('✅ Conexión establecida\n');
    
    // Obtener estructura de nomina_empleados_semanal
    print('📋 ESTRUCTURA DE nomina_empleados_semanal:');
    final estructuraSemanal = await connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal'
      ORDER BY ordinal_position;
    ''');
    
    print('Columnas de nomina_empleados_semanal (${estructuraSemanal.length}):');
    for (var row in estructuraSemanal) {
      print('  ${row[0]} (${row[1]}) - Nullable: ${row[2]}');
    }
    
    // Obtener estructura de nomina_empleados_historial
    print('\n📋 ESTRUCTURA DE nomina_empleados_historial:');
    final estructuraHistorial = await connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial'
      ORDER BY ordinal_position;
    ''');
    
    print('Columnas de nomina_empleados_historial (${estructuraHistorial.length}):');
    for (var row in estructuraHistorial) {
      print('  ${row[0]} (${row[1]}) - Nullable: ${row[2]}');
    }
    
    // Comparar columnas
    print('\n🔍 COMPARACIÓN:');
    final columnasSemanal = estructuraSemanal.map((row) => row[0] as String).toSet();
    final columnasHistorial = estructuraHistorial.map((row) => row[0] as String).toSet();
    
    final enSemanalNoHistorial = columnasSemanal.difference(columnasHistorial);
    final enHistorialNoSemanal = columnasHistorial.difference(columnasSemanal);
    final enAmbas = columnasSemanal.intersection(columnasHistorial);
    
    print('Columnas en SEMANAL pero no en HISTORIAL (${enSemanalNoHistorial.length}):');
    for (var col in enSemanalNoHistorial) {
      print('  - $col');
    }
    
    print('\nColumnas en HISTORIAL pero no en SEMANAL (${enHistorialNoSemanal.length}):');
    for (var col in enHistorialNoSemanal) {
      print('  - $col');
    }
    
    print('\nColumnas en AMBAS tablas (${enAmbas.length}):');
    for (var col in enAmbas) {
      print('  - $col');
    }
    
    // Test de inserción simple
    print('\n🧪 TEST DE INSERCIÓN:');
    try {
      final testQuery = '''
        INSERT INTO nomina_empleados_historial (
          SELECT * FROM nomina_empleados_semanal WHERE id_semana = 999 LIMIT 0
        );
      ''';
      await connection.execute(testQuery);
      print('✅ Sintaxis de INSERT correcta');
    } catch (e) {
      print('❌ Error en sintaxis de INSERT: $e');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
    print('\n🔄 Conexión cerrada');
  }
}
