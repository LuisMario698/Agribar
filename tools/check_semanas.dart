import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    '3.222.249.113',
    5432,
    'AGRIBAR',
    username: 'admin',
    password: 'Lostraders698',
  );

  try {
    await connection.open();
    print('=== Conexión exitosa a la base de datos ===\n');

    // Consultar todas las semanas
    print('=== TODAS LAS SEMANAS ===');
    final todasSemanas = await connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        COUNT(n.id) as registros_nomina
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada
      ORDER BY s.fecha_inicio DESC
    ''');

    for (var row in todasSemanas) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}, Registros: ${row[4]}');
    }

    print('\n=== SEMANAS QUE APARECEN EN DROPDOWN ACTUAL ===');
    final semanasDropdown = await connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.fecha_inicio DESC
    ''');

    for (var row in semanasDropdown) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}');
    }

    print('\n=== SEMANAS NO CERRADAS ===');
    final semanasNoCerradas = await connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        COUNT(n.id) as registros_nomina
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = false
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada
      ORDER BY s.fecha_inicio DESC
    ''');

    for (var row in semanasNoCerradas) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}, Registros: ${row[4]}');
    }

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
