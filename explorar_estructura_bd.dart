import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Explorando estructura de la base de datos AGRIBAR...\n');
  
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'AGRIBAR',
    username: 'postgres',
    password: 'admin',
  );

  try {
    await connection.open();
    print('✅ Conexión establecida con la base de datos AGRIBAR\n');

    // 1. Obtener todas las tablas
    print('📋 TABLAS EN LA BASE DE DATOS:');
    print('=' * 50);
    final tablas = await connection.query('''
      SELECT table_name, table_type
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    ''');
    
    List<String> nombreTablas = [];
    for (final tabla in tablas) {
      print('• ${tabla[0]} (${tabla[1]})');
      nombreTablas.add(tabla[0].toString());
    }
    print('\n');

    // 2. Para cada tabla, obtener su estructura
    for (final nombreTabla in nombreTablas) {
      print('🗂️  ESTRUCTURA DE LA TABLA: $nombreTabla');
      print('=' * 60);
      
      final columnas = await connection.query('''
        SELECT 
          column_name,
          data_type,
          is_nullable,
          column_default,
          character_maximum_length
        FROM information_schema.columns 
        WHERE table_name = @tableName AND table_schema = 'public'
        ORDER BY ordinal_position;
      ''', substitutionValues: {'tableName': nombreTabla});
      
      print('Columnas:');
      for (final columna in columnas) {
        String nullable = columna[2] == 'YES' ? 'NULL' : 'NOT NULL';
        String tipo = columna[1].toString();
        if (columna[4] != null) {
          tipo += '(${columna[4]})';
        }
        String defaultVal = columna[3] != null ? ' DEFAULT ${columna[3]}' : '';
        print('  - ${columna[0]}: $tipo $nullable$defaultVal');
      }
      
      // Obtener claves primarias
      final pks = await connection.query('''
        SELECT column_name
        FROM information_schema.key_column_usage
        WHERE table_name = @tableName 
          AND table_schema = 'public'
          AND constraint_name LIKE '%_pkey';
      ''', substitutionValues: {'tableName': nombreTabla});
      
      if (pks.isNotEmpty) {
        print('🔑 Claves primarias:');
        for (final pk in pks) {
          print('  - ${pk[0]}');
        }
      }
      
      // Obtener claves foráneas
      final fks = await connection.query('''
        SELECT 
          kcu.column_name,
          ccu.table_name AS foreign_table_name,
          ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_name = @tableName
          AND tc.table_schema = 'public';
      ''', substitutionValues: {'tableName': nombreTabla});
      
      if (fks.isNotEmpty) {
        print('🔗 Claves foráneas:');
        for (final fk in fks) {
          print('  - ${fk[0]} -> ${fk[1]}.${fk[2]}');
        }
      }
      
      // Obtener algunos registros de ejemplo (máximo 3)
      try {
        final ejemplos = await connection.query('SELECT * FROM "$nombreTabla" LIMIT 3');
        if (ejemplos.isNotEmpty) {
          print('📄 Ejemplos de datos (primeros 3 registros):');
          for (int i = 0; i < ejemplos.length; i++) {
            print('  Registro ${i + 1}: ${ejemplos[i].toString()}');
          }
        }
      } catch (e) {
        print('⚠️  No se pudieron obtener ejemplos de datos: $e');
      }
      
      print('\n');
    }

    // 3. Obtener vistas
    print('👁️  VISTAS EN LA BASE DE DATOS:');
    print('=' * 50);
    final vistas = await connection.query('''
      SELECT table_name
      FROM information_schema.views 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    ''');
    
    if (vistas.isNotEmpty) {
      for (final vista in vistas) {
        print('• ${vista[0]}');
      }
    } else {
      print('No se encontraron vistas.');
    }
    print('\n');

    // 4. Obtener funciones
    print('⚙️  FUNCIONES EN LA BASE DE DATOS:');
    print('=' * 50);
    final funciones = await connection.query('''
      SELECT 
        routine_name,
        routine_type,
        data_type AS return_type
      FROM information_schema.routines 
      WHERE routine_schema = 'public'
      ORDER BY routine_name;
    ''');
    
    if (funciones.isNotEmpty) {
      for (final funcion in funciones) {
        print('• ${funcion[0]} (${funcion[1]}) -> ${funcion[2]}');
      }
    } else {
      print('No se encontraron funciones personalizadas.');
    }
    print('\n');

    // 5. Obtener índices
    print('📊 ÍNDICES EN LA BASE DE DATOS:');
    print('=' * 50);
    final indices = await connection.query('''
      SELECT 
        tablename,
        indexname,
        indexdef
      FROM pg_indexes 
      WHERE schemaname = 'public'
      ORDER BY tablename, indexname;
    ''');
    
    if (indices.isNotEmpty) {
      String tablaActual = '';
      for (final indice in indices) {
        if (indice[0] != tablaActual) {
          tablaActual = indice[0].toString();
          print('\nTabla: $tablaActual');
        }
        print('  • ${indice[1]}: ${indice[2]}');
      }
    } else {
      print('No se encontraron índices personalizados.');
    }
    print('\n');

    print('✅ Exploración de la base de datos completada!');

  } catch (e) {
    print('❌ Error al conectar con la base de datos: $e');
    print('\nVerifica que:');
    print('• PostgreSQL esté ejecutándose');
    print('• La base de datos "AGRIBAR" exista');
    print('• Las credenciales sean correctas (postgres/admin)');
    print('• El puerto 5432 esté disponible');
  } finally {
    await connection.close();
  }
}
