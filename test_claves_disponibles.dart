// Test para verificar que las claves disponibles funcionen correctamente
import 'lib/services/database_service.dart';

void main() async {
  print('🔍 Probando consulta de claves disponibles...');
  
  try {
    final db = DatabaseService();
    await db.connect();
    
    // Consulta de prueba
    final result = await db.connection.query("""
      WITH RECURSIVE numeros AS (
        SELECT 1 as num
        UNION ALL
        SELECT num + 1 
        FROM numeros 
        WHERE num < 100
      ),
      claves_usadas AS (
        SELECT clave::INTEGER as clave_num 
        FROM cuadrillas 
        WHERE clave ~ '^[0-9]+\$'
      )
      SELECT numeros.num::text as clave_disponible
      FROM numeros
      LEFT JOIN claves_usadas ON numeros.num = claves_usadas.clave_num
      WHERE claves_usadas.clave_num IS NULL
      ORDER BY numeros.num
      LIMIT 10;
    """);
    
    if (result.isNotEmpty) {
      print('✅ Claves disponibles encontradas: ${result.length}');
      print('📋 Primeras claves: ${result.map((row) => row[0]).join(", ")}');
    } else {
      print('⚠️ No se encontraron claves disponibles en el rango 001-100');
    }
    
    // También verificar claves existentes
    final existentes = await db.connection.query(
      "SELECT clave FROM cuadrillas WHERE clave ~ '^[0-9]+\$' ORDER BY CAST(clave AS INTEGER) LIMIT 10"
    );
    
    print('🔢 Claves ya en uso: ${existentes.map((row) => row[0]).join(", ")}');
    
    await db.close();
    print('✅ Test completado exitosamente');
    
  } catch (e) {
    print('❌ Error durante el test: $e');
  }
}