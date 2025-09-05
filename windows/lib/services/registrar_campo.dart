import 'package:agribar/services/database_service.dart';

Future<List<Map<String, dynamic>>> obtenerCamposDesdeBD() async {
  final db = DatabaseService();
  await db.connect();

  try {
    print('🔍 Ejecutando consulta SQL para obtener campos...');
    final result = await db.connection.query('''
      SELECT id_rancho, nombre, COUNT(*) OVER() as total_rows
      FROM ranchos
      ORDER BY nombre ASC;
    ''');

    print('📊 Resultados obtenidos: ${result.length} filas');
    
    if (result.isEmpty) {
      print('⚠️ No se encontraron campos en la base de datos');
      return [];
    }

    print('🔍 Primera fila de muestra:');
    print('  Columnas disponibles: ${result.first.toColumnMap().keys.join(', ')}');
    print('  Valores: ${result.first.toColumnMap()}');

    final resultados = result.map((row) {
      final map = {
        'id': row[0], // id_rancho
        'clave': '', // No hay clave en la tabla ranchos
        'nombre': row[1], // nombre
      };
      print('  Procesando campo: ${map.toString()}');
      return map;
    }).toList();

    print('✅ Total campos procesados: ${resultados.length}');
    return resultados;
  } catch (e, stack) {
    print('❌ Error al obtener campos:');
    print('  Error: $e');
    print('  Stack: $stack');
    // Si la tabla no existe, devolver lista vacía en lugar de error
    return [];
  } finally {
    await db.close();
  }
}

Future<List<String>> obtenerNombresCamposDesdeBD() async {
  final db = DatabaseService();
  await db.connect();

  try {
    final result = await db.connection.query('''
      SELECT DISTINCT nombre 
      FROM ranchos 
      ORDER BY nombre ASC;
    ''');

    await db.close();
    return result.map((row) => row[0] as String).toList();
  } catch (e) {
    await db.close();
    print('❌ Error al obtener nombres de campos: $e');
    return [];
  }
}

Future<void> registrarCampoEnBD(Map<String, dynamic> campo) async {
  final db = DatabaseService();
  await db.connect();

  try {
    await db.connection.query('''
      INSERT INTO ranchos (clave, nombre)
      VALUES (@clave, @nombre)
    ''', substitutionValues: {
      'clave': campo['clave'],
      'nombre': campo['nombre'],
    });
  } catch (e) {
    print('❌ Error al registrar campo: $e');
    rethrow;
  } finally {
    await db.close();
  }
}

Future<String> generarSiguienteClaveCampo() async {
  final db = DatabaseService();
  await db.connect();

  try {
    final result = await db.connection.query('''
      SELECT clave FROM ranchos
      ORDER BY CAST(clave AS INTEGER) DESC
      LIMIT 1
    ''');

    await db.close();

    // Si no hay campos, comienza en '1'
    if (result.isEmpty) return '1';

    final ultimaClave = result.first[0] as String;
    final numero = int.tryParse(ultimaClave) ?? 0;
    final siguiente = numero + 1;

    return siguiente.toString();
  } catch (e) {
    await db.close();
    print('❌ Error al generar siguiente clave de campo: $e');
    return '1';
  }
}
