import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Probando función SQL con diferentes parámetros...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('📊 1. Función sin filtros (solo semana):');
    final resultado1 = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(17)
    ''');
    print('✅ Resultados: ${resultado1.length}');
    for (final row in resultado1) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
    print('\n🏞️ 2. Función con filtro de rancho (San Francisco = 1):');
    final resultado2 = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(17, NULL, 1)
    ''');
    print('✅ Resultados: ${resultado2.length}');
    for (final row in resultado2) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
    print('\n⚒️ 3. Función con filtro de actividad (JEFE DE LINEA = 2):');
    final resultado3 = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(17, 2, NULL)
    ''');
    print('✅ Resultados: ${resultado3.length}');
    for (final row in resultado3) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
    print('\n🔍 4. Función con ambos filtros (JEFE DE LINEA en San Francisco):');
    final resultado4 = await db.connection.query('''
      SELECT * FROM gasto_por_actividad_semana(17, 2, 1)
    ''');
    print('✅ Resultados: ${resultado4.length}');
    for (final row in resultado4) {
      print('  - ${row[0]}: \$${row[1]} (${row[2]} registros)');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
