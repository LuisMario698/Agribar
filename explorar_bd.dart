import 'package:agribar/services/database_service.dart';

/// Script completo para explorar TODA la base de datos AGRIBAR
void main() async {
  print('🗄️ EXPLORANDO TODA LA BASE DE DATOS AGRIBAR');
  print('=============================================');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. OBTENER TODAS LAS TABLAS
    print('\n📋 OBTENIENDO LISTA DE TODAS LAS TABLAS:');
    final tablas = await db.connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    ''');
    
    print('✅ Encontradas ${tablas.length} tablas:');
    for (var tabla in tablas) {
      print('   - ${tabla[0]}');
    }
    
    // 2. EXPLORAR ESTRUCTURA DE CADA TABLA
    print('\n🏗️ ESTRUCTURA DETALLADA DE CADA TABLA:');
    print('=====================================');
    
    for (var tabla in tablas) {
      final nombreTabla = tabla[0] as String;
      print('\n📊 TABLA: $nombreTabla');
      print('${'='*50}');
      
      // Obtener estructura de columnas
      final columnas = await db.connection.query('''
        SELECT 
          column_name, 
          data_type, 
          is_nullable,
          column_default
        FROM information_schema.columns 
        WHERE table_name = @tabla 
        ORDER BY ordinal_position;
      ''', substitutionValues: {'tabla': nombreTabla});
      
      print('📝 COLUMNAS (${columnas.length} total):');
      for (var col in columnas) {
        final nombre = col[0];
        final tipo = col[1];
        final nullable = col[2] == 'YES' ? 'NULL' : 'NOT NULL';
        final defaultVal = col[3] ?? 'sin default';
        print('   - $nombre: $tipo ($nullable) - Default: $defaultVal');
      }
      
      // Contar registros
      try {
        final count = await db.connection.query('SELECT COUNT(*) FROM $nombreTabla;');
        final numRegistros = count[0][0];
        print('📊 REGISTROS: $numRegistros');
        
        // Si hay datos, mostrar algunos ejemplos
        if (numRegistros > 0) {
          final ejemplos = await db.connection.query('''
            SELECT * FROM $nombreTabla 
            ORDER BY 
              CASE WHEN column_name = 'id' THEN 1
                   WHEN column_name LIKE '%id%' THEN 2
                   WHEN column_name LIKE '%fecha%' THEN 3
                   ELSE 4 END,
              ctid 
            LIMIT 3;
          '''.replaceAll('column_name', columnas.isNotEmpty ? columnas[0][0] : 'ctid'));
          
          print('💾 EJEMPLOS DE DATOS (primeros 3 registros):');
          for (int i = 0; i < ejemplos.length; i++) {
            print('   Registro ${i+1}:');
            for (int j = 0; j < columnas.length && j < ejemplos[i].length; j++) {
              final nombreCol = columnas[j][0];
              final valor = ejemplos[i][j];
              print('     $nombreCol: $valor');
            }
            print('     ────────────');
          }
        }
        
        // Análisis especial para tablas importantes
        if (nombreTabla == 'nomina_empleados_semanal') {
          print('🎯 ANÁLISIS ESPECIAL PARA NÓMINA SEMANAL:');
          await analizarNominaSemanal(db, nombreTabla);
        } else if (nombreTabla == 'nomina_empleados_historial') {
          print('🎯 ANÁLISIS ESPECIAL PARA NÓMINA HISTORIAL:');
          await analizarNominaHistorial(db, nombreTabla);
        } else if (nombreTabla.contains('semana')) {
          print('🎯 ANÁLISIS ESPECIAL PARA TABLA DE SEMANAS:');
          await analizarTablasSemanas(db, nombreTabla);
        }
        
      } catch (e) {
        print('❌ Error al analizar $nombreTabla: $e');
      }
      
      print('\n');
    }
    
    // 3. ANÁLISIS DE RELACIONES
    print('\n🔗 ANÁLISIS DE RELACIONES ENTRE TABLAS:');
    print('======================================');
    await analizarRelaciones(db);
    
  } catch (e) {
    print('❌ Error general: $e');
  } finally {
    await db.close();
  }
  
  print('\n🏁 EXPLORACIÓN COMPLETA TERMINADA');
}

// Función para analizar nomina_empleados_semanal en detalle
Future<void> analizarNominaSemanal(DatabaseService db, String tabla) async {
  try {
    // Verificar campos de actividades y ranchos por día
    final camposEspeciales = await db.connection.query('''
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = @tabla 
      AND (column_name LIKE 'act_%' OR column_name LIKE 'campo_%' OR column_name LIKE 'ran_%' OR column_name LIKE 'dia_%')
      ORDER BY column_name;
    ''', substitutionValues: {'tabla': tabla});
    
    print('   🏃‍♂️ CAMPOS DE ACTIVIDADES/RANCHOS POR DÍA:');
    for (var campo in camposEspeciales) {
      print('     - ${campo[0]}');
    }
    
    // Si hay datos, mostrar estructura de un registro completo
    final hayDatos = await db.connection.query('SELECT COUNT(*) FROM $tabla;');
    if ((hayDatos[0][0] as int) > 0) {
      final registro = await db.connection.query('SELECT * FROM $tabla LIMIT 1;');
      if (registro.isNotEmpty) {
        print('   📋 EJEMPLO DE REGISTRO COMPLETO:');
        final columnas = await db.connection.query('''
          SELECT column_name 
          FROM information_schema.columns 
          WHERE table_name = @tabla 
          ORDER BY ordinal_position;
        ''', substitutionValues: {'tabla': tabla});
        
        for (int i = 0; i < columnas.length && i < registro[0].length; i++) {
          final nombreCol = columnas[i][0];
          final valor = registro[0][i];
          if (nombreCol.startsWith('act_') || nombreCol.startsWith('campo_') || 
              nombreCol.startsWith('ran_') || nombreCol.startsWith('dia_')) {
            print('     ⭐ $nombreCol: $valor');
          } else {
            print('     - $nombreCol: $valor');
          }
        }
      }
    }
  } catch (e) {
    print('   ❌ Error en análisis especial: $e');
  }
}

// Función para analizar nomina_empleados_historial
Future<void> analizarNominaHistorial(DatabaseService db, String tabla) async {
  try {
    final estadisticas = await db.connection.query('''
      SELECT 
        COUNT(*) as total_registros,
        COUNT(DISTINCT id_empleado) as empleados_unicos,
        COUNT(DISTINCT id_cuadrilla) as cuadrillas_unicas,
        SUM(total) as suma_total,
        MIN(fecha_cierre) as fecha_minima,
        MAX(fecha_cierre) as fecha_maxima
      FROM $tabla;
    ''');
    
    if (estadisticas.isNotEmpty) {
      final stats = estadisticas[0];
      print('   📈 ESTADÍSTICAS:');
      print('     - Total registros: ${stats[0]}');
      print('     - Empleados únicos: ${stats[1]}');
      print('     - Cuadrillas únicas: ${stats[2]}');
      print('     - Suma total: \$${stats[3]}');
      print('     - Período: ${stats[4]} a ${stats[5]}');
    }
  } catch (e) {
    print('   ❌ Error en análisis historial: $e');
  }
}

// Función para analizar tablas de semanas
Future<void> analizarTablasSemanas(DatabaseService db, String tabla) async {
  try {
    final semanas = await db.connection.query('''
      SELECT * FROM $tabla 
      ORDER BY 
        CASE WHEN column_exists('fecha_inicio') THEN fecha_inicio
             WHEN column_exists('fecha') THEN fecha
             ELSE ctid END 
      LIMIT 5;
    '''.replaceAll('column_exists', '''
      EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = '$tabla' AND column_name ='''));
    
    print('   📅 SEMANAS REGISTRADAS:');
    final columnas = await db.connection.query('''
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = @tabla 
      ORDER BY ordinal_position;
    ''', substitutionValues: {'tabla': tabla});
    
    for (int i = 0; i < semanas.length; i++) {
      print('     Semana ${i+1}:');
      for (int j = 0; j < columnas.length && j < semanas[i].length; j++) {
        final nombreCol = columnas[j][0];
        final valor = semanas[i][j];
        print('       $nombreCol: $valor');
      }
    }
  } catch (e) {
    print('   ❌ Error en análisis semanas: $e');
  }
}

// Función para analizar relaciones entre tablas
Future<void> analizarRelaciones(DatabaseService db) async {
  try {
    final relaciones = await db.connection.query('''
      SELECT 
        tc.table_name as tabla_origen,
        kcu.column_name as columna_origen,
        ccu.table_name as tabla_referencia,
        ccu.column_name as columna_referencia
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
      ORDER BY tc.table_name, kcu.column_name;
    ''');
    
    print('🔗 RELACIONES ENCONTRADAS (Foreign Keys):');
    for (var rel in relaciones) {
      print('   ${rel[0]}.${rel[1]} → ${rel[2]}.${rel[3]}');
    }
    
    // Buscar relaciones implícitas por nombres de columnas
    print('\n🔍 POSIBLES RELACIONES IMPLÍCITAS (por nombres de columnas):');
    final tablasConId = await db.connection.query('''
      SELECT table_name, column_name
      FROM information_schema.columns
      WHERE column_name LIKE '%id_%' OR column_name = 'id'
      ORDER BY table_name, column_name;
    ''');
    
    Map<String, List<String>> tablasPorId = {};
    for (var row in tablasConId) {
      final tabla = row[0] as String;
      final columna = row[1] as String;
      if (!tablasPorId.containsKey(columna)) {
        tablasPorId[columna] = [];
      }
      tablasPorId[columna]!.add(tabla);
    }
    
    for (var entry in tablasPorId.entries) {
      if (entry.value.length > 1) {
        print('   ${entry.key}: ${entry.value.join(", ")}');
      }
    }
    
  } catch (e) {
    print('❌ Error analizando relaciones: $e');
  }
}
