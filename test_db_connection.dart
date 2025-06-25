
import 'package:postgres/postgres.dart';

void main() async {
  print('=== Iniciando prueba de conexión a PostgreSQL... ===');
  
  final connection = PostgreSQLConnection(
    'localhost',  // Host
    5432,         // Puerto
    'AGRIBAR',    // Nombre de la base de datos
    username: 'postgres',
    password: 'admin',
  );
  
  try {
    print('Intentando conectar a la base de datos...');
    await connection.open();
    print('✅ ¡CONEXIÓN EXITOSA!');
    
    // Realizar una consulta simple para verificar la versión
    final versionResults = await connection.query('SELECT version();');
    print('→ Versión de PostgreSQL: ${versionResults.first.first}');
    
    // Verificar las tablas existentes
    final tableResults = await connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    ''');
    
    if (tableResults.isEmpty) {
      print('→ No se encontraron tablas en la base de datos.');
    } else {
      print('\n→ Tablas encontradas en la base de datos:');
      for (final row in tableResults) {
        print('  • ${row[0]}');
      }
    }
    
    // Verificar permisos del usuario
    print('\n→ Verificando permisos del usuario:');
    final userResults = await connection.query(
      "SELECT usename, usecreatedb, usesuper FROM pg_user WHERE usename = 'postgres';"
    );
    
    if (userResults.isNotEmpty) {
      final row = userResults.first;
      print('  • Usuario: ${row[0]}');
      print('  • Puede crear bases de datos: ${row[1] ? 'Sí' : 'No'}');
      print('  • Es superusuario: ${row[2] ? 'Sí' : 'No'}');
    }
    
    // Probar una consulta simple de inserción y borrado
    print('\n→ Probando operaciones básicas:');
    try {
      // Crear tabla temporal
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS test_connection (
          id SERIAL PRIMARY KEY,
          test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          message TEXT
        );
      ''');
      print('  • Tabla de prueba creada correctamente');
      
      // Insertar datos
      final insertResult = await connection.execute(
        "INSERT INTO test_connection (message) VALUES ('Prueba exitosa')"
      );
      print('  • Inserción realizada: $insertResult fila(s) afectada(s)');
      
      // Leer datos
      final readResult = await connection.query('SELECT * FROM test_connection ORDER BY id DESC LIMIT 1');
      print('  • Lectura exitosa: ID=${readResult.first[0]}, Mensaje=${readResult.first[2]}');
      
      // Eliminar tabla de prueba
      await connection.execute('DROP TABLE test_connection');
      print('  • Tabla de prueba eliminada correctamente');
    } catch (e) {
      print('  • ⚠️ Error al probar operaciones básicas: $e');
      print('  • Es posible que no tengas todos los permisos necesarios');
    }
    
    print('\n✅ Prueba completa. La conexión a la base de datos funciona correctamente.');
    await connection.close();
  } catch (e) {
    print('❌ ERROR DE CONEXIÓN: $e');
    
    // Consejos adicionales basados en el tipo de error
    if (e.toString().contains('Operation not permitted')) {
      print('\n⚠️ Operación no permitida. Posibles soluciones:');
      print('1. Es posible que tu aplicación necesite permisos de red. En macOS, esto ocurre frecuentemente.');
      print('2. Intenta estas opciones:');
      print('   - Ejecuta Flutter con permisos: sudo flutter run');
      print('   - Prueba con diferentes hosts: localhost, 127.0.0.1, ::1');
      print('   - Verifica que la red no esté bloqueando las conexiones (Firewall, etc.)');
      print('   - Revisa la configuración de PostgreSQL en /opt/homebrew/var/postgresql@14/postgresql.conf');
      print('     y asegúrate que listen_addresses incluye localhost o *');
    } else if (e.toString().contains('database "AGRIBAR" does not exist')) {
      print('\n⚠️ La base de datos "AGRIBAR" no existe. Para crearla, ejecuta:');
      print('psql -U postgres -c "CREATE DATABASE \\"AGRIBAR\\";"');
    } else if (e.toString().contains('password authentication failed')) {
      print('\n⚠️ Error de autenticación. Verifica tu contraseña para el usuario postgres.');
    } else if (e.toString().contains('could not connect to server')) {
      print('\n⚠️ No se pudo conectar al servidor. Verifica que PostgreSQL esté en ejecución:');
      print('brew services start postgresql@14');
      print('\nPara verificar el estado: brew services list | grep postgresql');
    } else if (e.toString().contains('connection refused')) {
      print('\n⚠️ Conexión rechazada. Posibles soluciones:');
      print('1. Verifica que PostgreSQL esté en ejecución: brew services start postgresql@14');
      print('2. Verifica que el puerto 5432 no esté bloqueado por el firewall');
      print('3. Asegúrate que PostgreSQL está configurado para aceptar conexiones de localhost');
    }
  }
}