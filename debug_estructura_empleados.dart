import 'lib/services/database_service.dart';

void main() async {
  print('🔍 VERIFICANDO ESTRUCTURA DE TABLA EMPLEADOS\n');

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // Verificar columnas de la tabla empleados
    print('📋 COLUMNAS DE LA TABLA EMPLEADOS:');
    print('=' * 50);
    final columnas = await db.connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'empleados'
      ORDER BY ordinal_position;
    ''');
    
    if (columnas.isEmpty) {
      print('❌ No se encontraron columnas o la tabla empleados no existe');
    } else {
      for (var col in columnas) {
        print('   • ${col[0]} (${col[1]}) ${col[2] == 'YES' ? 'NULL' : 'NOT NULL'}');
      }
    }
    
    // Ver algunos registros de ejemplo
    print('\n📊 PRIMEROS 5 EMPLEADOS (EJEMPLO):');
    print('=' * 50);
    final empleados = await db.connection.query('''
      SELECT * FROM empleados LIMIT 5;
    ''');
    
    if (empleados.isNotEmpty) {
      for (int i = 0; i < empleados.length; i++) {
        print('Empleado ${i + 1}:');
        for (int j = 0; j < columnas.length && j < empleados[i].length; j++) {
          final nombreCol = columnas[j][0];
          final valor = empleados[i][j];
          print('   $nombreCol: $valor');
        }
        print('   ───────────────────');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
