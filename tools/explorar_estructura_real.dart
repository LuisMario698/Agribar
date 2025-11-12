import 'package:postgres/postgres.dart';

void main() async {
  print('=== EXPLORANDO ESTRUCTURA REAL DE LA BASE DE DATOS ===\n');
  
  late PostgreSQLConnection connection;
  
  try {
    connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );
    
    await connection.open();
    print('✅ Conexión exitosa\n');
    
    // 1. Listar todas las tablas
    await listarTablas(connection);
    
    // 2. Explorar estructura de empleados
    await explorarTabla(connection, 'empleados');
    
    // 3. Explorar estructura de cuadrillas
    await explorarTabla(connection, 'cuadrillas');
    
    // 4. Explorar estructura de nómina
    await explorarTabla(connection, 'nomina_empleados_semanal');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    try {
      await connection.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      // Ignorar errores al cerrar
    }
  }
}

Future<void> listarTablas(PostgreSQLConnection connection) async {
  print('📋 TABLAS EN LA BASE DE DATOS:');
  try {
    final result = await connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    ''');
    
    for (final row in result) {
      print('  • ${row[0]}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> explorarTabla(PostgreSQLConnection connection, String tableName) async {
  print('🔍 ESTRUCTURA DE LA TABLA: $tableName');
  try {
    final result = await connection.query('''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = '$tableName' AND table_schema = 'public'
      ORDER BY ordinal_position
    ''');
    
    if (result.isNotEmpty) {
      for (final row in result) {
        print('  ${row[0]} (${row[1]})${row[2] == 'YES' ? ' NULL' : ' NOT NULL'}');
      }
      
      // Mostrar algunos datos de ejemplo
      final dataResult = await connection.query('SELECT * FROM $tableName LIMIT 3');
      print('  \n  📊 DATOS DE EJEMPLO:');
      for (int i = 0; i < dataResult.length && i < 3; i++) {
        print('    Registro ${i + 1}: ${dataResult[i]}');
      }
    } else {
      print('  ⚠️ Tabla no encontrada o sin columnas');
    }
    print('');
  } catch (e) {
    print('  Error explorando $tableName: $e\n');
  }
}
