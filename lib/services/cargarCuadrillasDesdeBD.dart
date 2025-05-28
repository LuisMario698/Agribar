import '../services/database_service.dart';

/// Carga las cuadrillas desde la base de datos PostgreSQL.
/// Retorna una lista de mapas con los datos.
Future<List<Map<String, dynamic>>> obtenerCuadrillasDesdeBD() async {
  final db = DatabaseService();
  List<Map<String, dynamic>> cuadrillas = [];

  try {
    await db.connect();

    final result = await db.connection.query('''
      SELECT id_cuadrilla, clave, nombre, grupo, actividad, estado AS habilitado
      FROM cuadrillas
    ''');

    cuadrillas = result.map((row) => {
      'id': row[0],
      'clave': row[1],
      'nombre': row[2],
      'grupo': row[3],
      'actividad': row[4],
      'habilitado': row[5] ?? true,
    }).toList();
  } catch (e) {
    print('❌ Error al obtener cuadrillas: $e');
  } finally {
    await db.close();
  }

  return cuadrillas;
}