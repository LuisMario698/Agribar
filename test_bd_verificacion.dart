// Script simple para verificar cambios en la BD
import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Verificando cambios en la base de datos...');
  
  try {
    // Crear conexión directa
    final connection = PostgreSQLConnection(
      '192.168.0.136',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: '12345678',
    );
    
    await connection.open();
    print('✅ Conexión establecida');
    
    // Verificar estructura de la tabla semanas_nomina
    print('\n📋 Verificando estructura de tabla semanas_nomina...');
    final estructura = await connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'semanas_nomina'
      ORDER BY ordinal_position;
    ''');
    
    print('Columnas en semanas_nomina:');
    for (var col in estructura) {
      print('  - ${col[0]} (${col[1]}) - Nullable: ${col[2]}');
    }
    
    // Verificar semanas existentes con información de autorización
    print('\n📊 Verificando semanas con información de autorización...');
    final semanas = await connection.query('''
      SELECT id_semana, esta_cerrada, autorizado_por, fecha_autorizacion
      FROM semanas_nomina 
      ORDER BY id_semana DESC
      LIMIT 10;
    ''');
    
    print('Últimas 10 semanas:');
    for (var semana in semanas) {
      print('  - Semana ${semana[0]}: cerrada=${semana[1]}, autorizado_por="${semana[2]}", fecha=${semana[3]}');
    }
    
    await connection.close();
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
