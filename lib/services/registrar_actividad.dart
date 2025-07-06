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
    WHERE clave LIKE 'ATC%' 
    ORDER BY CAST(SUBSTRING(clave FROM 4) AS INTEGER) DESC 
    LIMIT 1
  ''');

  await db.close();

  if (result.isEmpty) return 'ATC001';

  final ultimaClave = result.first[0] as String;
  final numero = int.tryParse(ultimaClave.substring(3)) ?? 0;
  final siguiente = numero + 1;

  return 'ATC${siguiente.toString().padLeft(3, '0')}';
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