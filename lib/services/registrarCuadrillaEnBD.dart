import '../services/database_service.dart';

/// Registra una nueva cuadrilla en la base de datos PostgreSQL.
Future<void> registrarCuadrillaEnBD(Map<String, dynamic> cuadrilla) async {
  final db = DatabaseService();

  try {
    await db.connect();

    await db.connection.query('''
      INSERT INTO cuadrillas (clave, nombre, grupo, actividad, estado)
      VALUES (@clave, @nombre, @grupo, @actividad, @estado)
    ''', substitutionValues: {
      'clave': cuadrilla['clave'],
      'nombre': cuadrilla['nombre'],
      'grupo': cuadrilla['grupo'],
      'actividad': cuadrilla['actividad'],
      'estado': cuadrilla['estado'] ?? true, // true = habilitada por default
    });

    print('✅ Cuadrilla registrada correctamente');
  } catch (e) {
    print('❌ Error al registrar cuadrilla: $e');
  } finally {
    await db.close();
  }
}

Future<String> generarSiguienteClaveCuadrilla() async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query(
    "SELECT clave FROM cuadrillas WHERE clave LIKE 'CU%' ORDER BY CAST(SUBSTRING(clave FROM 3) AS INTEGER) DESC LIMIT 1;"
  );

  await db.close();

  if (result.isEmpty) return 'CU001';

  final ultimaClave = result.first[0] as String;
  final numero = int.tryParse(ultimaClave.substring(2)) ?? 0;
  final siguiente = numero + 1;

  return 'CU${siguiente.toString().padLeft(3, '0')}';
}
