import '../services/database_service.dart';

/// Registra una nueva cuadrilla en la base de datos PostgreSQL.
Future<void> registrarCuadrillaEnBD(Map<String, dynamic> cuadrilla) async {
  final db = DatabaseService();

  try {
    await db.connect();

    // Generar la siguiente clave automáticamente
    final siguienteClave = await _generarSiguienteClave(db);

    await db.connection.query('''
      INSERT INTO cuadrillas (clave, nombre, grupo, actividad, estado)
      VALUES (@clave, @nombre, @grupo, @actividad, @estado)
    ''', substitutionValues: {
      'clave': siguienteClave,
      'nombre': cuadrilla['nombre'],
      'grupo': cuadrilla['grupo'],
      'actividad': cuadrilla['actividad'],
      'estado': cuadrilla['estado'] ?? true, // true = habilitada por default
    });

    print('✅ Cuadrilla registrada correctamente con clave: $siguienteClave');
  } catch (e) {
    print('❌ Error al registrar cuadrilla: $e');
  } finally {
    await db.close();
  }
}

/// Genera la siguiente clave numérica secuencial
Future<String> _generarSiguienteClave(DatabaseService db) async {
  final result = await db.connection.query(
    "SELECT clave FROM cuadrillas WHERE clave ~ '^[0-9]+\$' ORDER BY CAST(clave AS INTEGER) DESC LIMIT 1;"
  );

  if (result.isEmpty) return '1';

  final ultimaClave = result.first[0] as String;
  final numero = int.tryParse(ultimaClave) ?? 0;
  final siguiente = numero + 1;

  return siguiente.toString();
}