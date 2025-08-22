import 'package:agribar/services/database_service.dart';

void main() async {
  print('🔍 Debuggeando la función SQL gasto_por_actividad_semana...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Probemos la función directamente
    print('📋 Ejecutando función SQL...');
    final result = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(17)
    ''');
    
    print('✅ Resultado obtenido: ${result.length} filas');
    
    for (int i = 0; i < result.length; i++) {
      final row = result[i];
      print('\n--- Fila ${i + 1} ---');
      print('Columnas: ${row.length}');
      for (int j = 0; j < row.length; j++) {
        print('  [$j]: ${row[j]} (${row[j].runtimeType})');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
