import 'lib/services/database_service.dart';

void main() async {
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('=== TODAS LAS SEMANAS EN LA BASE DE DATOS ===');
    final todasSemanas = await db.connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.autorizado_por,
        s.fecha_autorizacion,
        COUNT(n.id) as registros_nomina
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada, s.autorizado_por, s.fecha_autorizacion
      ORDER BY s.fecha_inicio DESC
    ''');
    
    for (var row in todasSemanas) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}, Registros: ${row[6]}');
    }
    
    print('\n=== SEMANAS QUE APARECEN EN REPORTES (FILTRO ACTUAL) ===');
    final semanasReportes = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada,
        s.autorizado_por,
        s.fecha_autorizacion
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.fecha_inicio DESC
    ''');
    
    for (var row in semanasReportes) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}');
    }
    
    print('\n=== SEMANAS SIN REGISTROS DE NÓMINA ===');
    final semanasSinRegistros = await db.connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
      WHERE n.id_semana IS NULL
      ORDER BY s.fecha_inicio DESC
    ''');
    
    for (var row in semanasSinRegistros) {
      print('ID: ${row[0]}, Inicio: ${row[1]}, Fin: ${row[2]}, Cerrada: ${row[3]}');
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}
