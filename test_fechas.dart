import 'package:postgres/postgres.dart';

/// Test directo de la base de datos para verificar formato de fechas
void main() async {
  print('🔍 VERIFICANDO FORMATO DE FECHAS EN BD');
  print('=====================================');

  late PostgreSQLConnection connection;

  try {
    // Conectar a la base de datos
    connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'Lugama8313',
    );

    await connection.open();
    print('✅ Conectado a la base de datos AGRIBAR');

    // Verificar formato de fechas en nomina_empleados_historial
    print('\n📅 Verificando formato de fecha_cierre:');
    final result = await connection.query('''
      SELECT 
        id_empleado,
        fecha_cierre,
        fecha_cierre::text as fecha_texto,
        to_char(fecha_cierre, 'YYYYMMDD') as fecha_yyyymmdd,
        total
      FROM nomina_empleados_historial 
      ORDER BY fecha_cierre DESC 
      LIMIT 3
    ''');

    for (var row in result) {
      print('   - Empleado: ${row[0]}');
      print('     Fecha original: ${row[1]}');
      print('     Fecha como texto: ${row[2]}');
      print('     Fecha YYYYMMDD: ${row[3]}');
      print('     Total: \$${row[4]}');
      print('     ───────────────────');
    }

    // Verificar fechas en semanas_nomina si existen
    print('\n📅 Verificando fechas en semanas_nomina:');
    final semanasResult = await connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        to_char(fecha_inicio, 'YYYYMMDD') as inicio_yyyymmdd,
        to_char(fecha_fin, 'YYYYMMDD') as fin_yyyymmdd
      FROM semanas_nomina 
      ORDER BY fecha_inicio DESC 
      LIMIT 3
    ''');

    if (semanasResult.isNotEmpty) {
      for (var row in semanasResult) {
        print('   - Semana ID: ${row[0]}');
        print('     Inicio: ${row[1]} → ${row[3]}');
        print('     Fin: ${row[2]} → ${row[4]}');
        print('     ───────────────────');
      }
    } else {
      print('   ⚠️ No hay datos en semanas_nomina');
    }

  } catch (e) {
    print('❌ ERROR: $e');
  } finally {
    try {
      await connection.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      print('Error cerrando conexión: $e');
    }
  }

  print('\n🏁 Verificación de fechas completada');
}
