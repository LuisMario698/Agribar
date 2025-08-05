import 'lib/services/database_service.dart';

void main() async {
  print("🔍 Probando consulta de cuadrillas con clave...");
  
  try {
    final db = DatabaseService();
    await db.connect();

    // Probar la consulta exacta que usamos
    final results = await db.connection.query('''
      SELECT id_cuadrilla, clave, nombre
      FROM cuadrillas
      WHERE estado = true
      ORDER BY nombre;
    ''');

    await db.close();

    print("✅ Consulta exitosa. Resultados:");
    for (int i = 0; i < results.length; i++) {
      final row = results.elementAt(i);
      print("  Fila $i: id=${row[0]}, clave=${row[1]}, nombre=${row[2]}");
    }

    print("\n📊 Datos mapeados:");
    final mapped = results.map((row) => {
      'id': row[0], 
      'clave': row[1], 
      'nombre': row[2], 
      'empleados': []
    }).toList();
    
    for (var cuadrilla in mapped) {
      print("  ${cuadrilla['clave']} - ${cuadrilla['nombre']}");
    }

  } catch (e) {
    print("❌ Error: $e");
  }
}
