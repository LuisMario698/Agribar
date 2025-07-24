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

  final result = await db.connection.query('''
    SELECT clave, fecha, importe, nombre
    FROM actividades
    ORDER BY fecha DESC;
  ''');

  await db.close();

  return result.map((row) {
    return {
      'clave': row[0],
      'fecha': row[1].toString().split(' ')[0], // Solo fecha sin hora
      'importe': row[2],
      'nombre': row[3],
    };
  }).toList();
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