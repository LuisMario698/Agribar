import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 PRUEBA DE CONEXIÓN A BASE DE DATOS');
  print('=====================================');
  
  final db = DatabaseService();
  
  try {
    print('🔌 Intentando conectar...');
    await db.connect();
    print('✅ Conexión exitosa!');
    
    // Verificar que la tabla semanas_nomina existe
    print('\n🔍 Verificando tabla semanas_nomina...');
    final tablaExiste = await db.connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name = 'semanas_nomina';
    ''');
    
    if (tablaExiste.isNotEmpty) {
      print('✅ Tabla semanas_nomina existe');
      
      // Ver estructura de la tabla
      print('\n📋 Estructura de la tabla:');
      final estructura = await db.connection.query('''
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'semanas_nomina'
        ORDER BY ordinal_position;
      ''');
      
      for (final column in estructura) {
        print('  - ${column[0]}: ${column[1]} (nullable: ${column[2]})');
      }
      
      // Ver semanas existentes
      print('\n📊 Semanas en la base de datos:');
      final semanas = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
        FROM semanas_nomina
        ORDER BY id_semana DESC
        LIMIT 5;
      ''');
      
      if (semanas.isEmpty) {
        print('  ❌ No hay semanas en la base de datos');
      } else {
        for (final semana in semanas) {
          final estado = semana[3] == true ? 'Cerrada' : 'Abierta';
          print('  - Semana ${semana[0]}: ${semana[1]} a ${semana[2]} ($estado)');
        }
      }
      
    } else {
      print('❌ Tabla semanas_nomina NO existe');
    }
    
    // Probar un UPDATE simple
    print('\n🧪 Probando operación UPDATE...');
    final resultadoTest = await db.connection.execute('''
      SELECT 1 as test;
    ''');
    print('✅ Operación de prueba exitosa: $resultadoTest');
    
  } catch (e) {
    print('❌ ERROR: $e');
    print('Tipo: ${e.runtimeType}');
  } finally {
    try {
      await db.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      print('❌ Error al cerrar: $e');
    }
  }
  
  print('\n🏁 Prueba completada');
}
