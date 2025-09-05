import 'package:agribar/services/database_service.dart';

Future<void> registrarActividadEnBD(Map<String, dynamic> actividad) async {
  final db = DatabaseService();
  await db.connect();

  await db.connection.query('''
    INSERT INTO actividades (clave, fecha, importe, nombre)
    VALUES (@clave, @fecha, @importe, @nombre)
  ''', substitutionValues: {
    'clave': actividad['clave'],
    'fecha': actividad['fecha'], // Asegúrate que esté en formato YYYY-MM-DD
    'importe': actividad['importe'] as double,
    'nombre': actividad['nombre'],
  });

  await db.close();
}

Future<String> generarSiguienteClaveActividad() async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT clave FROM actividades
    ORDER BY CAST(clave AS INTEGER) DESC
    LIMIT 1
  ''');

  await db.close();

  // Si no hay actividades, comienza en '1'
  if (result.isEmpty) return '1';

  final ultimaClave = result.first[0] as String;
  final numero = int.tryParse(ultimaClave) ?? 0;
  final siguiente = numero + 1;

  return siguiente.toString();
}

Future<List<Map<String, dynamic>>> obtenerActividadesDesdeBD() async {
  final db = DatabaseService();
  await db.connect();

  try {
    print('🔍 Ejecutando consulta SQL para obtener actividades...');
    final result = await db.connection.query('''
      SELECT id_actividad, clave, nombre, importe, fecha, COUNT(*) OVER() as total_rows
      FROM actividades
      ORDER BY fecha DESC, clave ASC;
    ''');

    print('📊 Resultados obtenidos: ${result.length} filas');
    
    if (result.isEmpty) {
      print('⚠️ No se encontraron actividades en la base de datos');
      return [];
    }

    print('🔍 Primera fila de muestra:');
    print('  Columnas disponibles: ${result.first.toColumnMap().keys.join(', ')}');
    print('  Valores: ${result.first.toColumnMap()}');

    final resultados = result.map((row) {
      final map = {
        'id': row[0], // id_actividad
        'clave': row[1],
        'nombre': row[2],
        'importe': row[3],
        'fecha': row[4], // Agregada la columna fecha
      };
      print('  Procesando actividad: ${map.toString()}');
      return map;
    }).toList();

    print('✅ Total actividades procesadas: ${resultados.length}');
    return resultados;
  } catch (e, stack) {
    print('❌ Error al obtener actividades:');
    print('  Error: $e');
    print('  Stack: $stack');
    rethrow;
  } finally {
    await db.close();
  }
}

Future<List<String>> obtenerNombresActividadesDesdeBD() async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT DISTINCT nombre 
    FROM actividades 
    ORDER BY nombre ASC;
  ''');

  await db.close();

  return result.map((row) => row[0] as String).toList();
}