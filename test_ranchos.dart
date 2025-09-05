import 'package:postgres/postgres.dart';

void main() async {
  print('=== EXPLORANDO RELACIONES RANCHOS ===\n');
  
  late PostgreSQLConnection connection;
  
  try {
    connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );
    
    await connection.open();
    print('✅ Conexión exitosa\n');
    
    // Ver datos de ranchos
    final ranchosResult = await connection.query('SELECT id_rancho, nombre FROM ranchos ORDER BY id_rancho');
    print('🏡 Ranchos disponibles:');
    for (final row in ranchosResult) {
      print('  ID: ${row[0]} - ${row[1]}');
    }
    
    // Intentar consulta simple - gastos por rancho usando campos de nomina
    print('  \n💰 Gastos por rancho (usando campos de nómina):');
    final gastosResult = await connection.query('''
      SELECT 
        COALESCE(r.nombre, 'Campo ' || campo_val) as nombre_campo,
        COUNT(DISTINCT n.id_empleado) as empleados,
        COALESCE(SUM(n.total_neto), 0) as total_gastos
      FROM (
        SELECT id_empleado, total_neto, campo_1 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_1 IS NOT NULL AND campo_1 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_2 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_2 IS NOT NULL AND campo_2 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_3 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_3 IS NOT NULL AND campo_3 <> 0
      ) n
      LEFT JOIN ranchos r ON r.id_rancho = n.campo_val
      GROUP BY COALESCE(r.nombre, 'Campo ' || campo_val)
      ORDER BY total_gastos DESC
      LIMIT 5
    ''');
    
    for (final row in gastosResult) {
      final gastos = row[2] is String ? double.tryParse(row[2]) ?? 0.0 : (row[2] as num).toDouble();
      print('  ${row[0]}: ${row[1]} empleados, \$${gastos.toStringAsFixed(2)}');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    try {
      await connection.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      // Ignorar errores al cerrar
    }
  }
}
