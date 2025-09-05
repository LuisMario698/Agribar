import 'package:postgres/postgres.dart';

void main() async {
  print('=== EXPLORANDO DATOS REALES PARA DASHBOARD ===\n');
  
  late PostgreSQLConnection connection;
  
  try {
    // Configuración de conexión directa a PostgreSQL
    connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );
    
    await connection.open();
    
    print('✅ Conexión a PostgreSQL exitosa\n');
    
    // 1. Contar empleados activos con nómina
    await consultarEmpleadosActivos(connection);
    
    // 2. Datos de cuadrillas 
    await consultarCuadrillas(connection);
    
    // 3. Top empleados
    await consultarTopEmpleados(connection);
    
    // 4. Actividades por cuadrilla
    await consultarActividades(connection);
    
    // 5. Resumen de nómina semanal
    await consultarResumenNomina(connection);
    
    // 6. Distribución por días
    await consultarDistribucionDias(connection);
    
  } catch (e) {
    print('❌ Error de conexión: $e');
    print('Verifique que PostgreSQL esté ejecutándose y las credenciales sean correctas.');
  } finally {
    try {
      await connection.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      // Ignorar errores al cerrar
    }
  }
}

Future<void> consultarEmpleadosActivos(PostgreSQLConnection connection) async {
  print('👥 EMPLEADOS ACTIVOS:');
  try {
    final result = await connection.query('''
      SELECT COUNT(DISTINCT e.id_empleado) as empleados_activos,
             COALESCE(SUM(n.total_ganancia), 0) as total_ganancias,
             COALESCE(AVG(n.total_ganancia), 0) as promedio_ganancia
      FROM empleados e
      LEFT JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    
    for (final row in result) {
      print('  Empleados con nómina activa: ${row[0]}');
      print('  Total ganancias semana actual: \$${(row[1] as num).toStringAsFixed(2)}');
      print('  Promedio por empleado: \$${(row[2] as num).toStringAsFixed(2)}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarCuadrillas(PostgreSQLConnection connection) async {
  print('👷 CUADRILLAS:');
  try {
    final result = await connection.query('''
      SELECT 
        c.nombre as cuadrilla,
        COUNT(e.id_empleado) as total_miembros,
        COALESCE(SUM(n.total_ganancia), 0) as ganancia_total
      FROM cuadrillas c
      LEFT JOIN empleados e ON c.id_cuadrilla = e.id_cuadrilla
      LEFT JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre
      HAVING COUNT(e.id_empleado) > 0
      ORDER BY total_miembros DESC
    ''');
    
    for (final row in result) {
      print('  ${row[0]}: ${row[1]} miembros, Total: \$${(row[2] as num).toStringAsFixed(2)}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarTopEmpleados(PostgreSQLConnection connection) async {
  print('🏆 TOP 5 EMPLEADOS MEJOR PAGADOS:');
  try {
    final result = await connection.query('''
      SELECT e.nombre, n.total_ganancia, c.nombre as cuadrilla
      FROM empleados e
      JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      LEFT JOIN cuadrillas c ON e.id_cuadrilla = c.id_cuadrilla
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      ORDER BY n.total_ganancia DESC
      LIMIT 5
    ''');
    
    int posicion = 1;
    for (final row in result) {
      print('  $posicion. ${row[0]} - \$${(row[1] as num).toStringAsFixed(2)} (${row[2] ?? 'Sin cuadrilla'})');
      posicion++;
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarActividades(PostgreSQLConnection connection) async {
  print('🚜 ACTIVIDADES MÁS ACTIVAS:');
  try {
    final result = await connection.query('''
      SELECT 
        a.nombre as actividad,
        COUNT(DISTINCT ac.id_cuadrilla) as cuadrillas_asignadas,
        COALESCE(SUM(ac.horas_trabajadas), 0) as total_horas
      FROM actividades a
      LEFT JOIN actividades_cuadrillas ac ON a.id_actividad = ac.id_actividad
      WHERE a.estado = 'activa'
      GROUP BY a.id_actividad, a.nombre
      HAVING COUNT(DISTINCT ac.id_cuadrilla) > 0
      ORDER BY cuadrillas_asignadas DESC
      LIMIT 5
    ''');
    
    for (final row in result) {
      print('  ${row[0]}: ${row[1]} cuadrillas, ${(row[2] as num).toStringAsFixed(1)} horas');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarResumenNomina(PostgreSQLConnection connection) async {
  print('💰 RESUMEN NÓMINA ACTUAL:');
  try {
    final result = await connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        COUNT(n.id_empleado) as empleados_registrados,
        SUM(n.total_ganancia) as total_semana
      FROM semanas s
      LEFT JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      WHERE s.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin
    ''');
    
    for (final row in result) {
      print('  Semana ${row[0]}: ${row[1]} a ${row[2]}');
      print('  Empleados registrados: ${row[3]}');
      print('  Total nómina: \$${(row[4] as num?)?.toStringAsFixed(2) ?? '0.00'}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarDistribucionDias(PostgreSQLConnection connection) async {
  print('📅 DISTRIBUCIÓN POR DÍAS (simulada):');
  try {
    // Obtener total de la semana para distribución
    final totalResult = await connection.query('''
      SELECT COALESCE(SUM(n.total_ganancia), 0) as total_semana
      FROM nomina_empleados_semanal n
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    
    if (totalResult.isNotEmpty) {
      final totalSemana = (totalResult.first[0] as num).toDouble();
      
      // Distribución típica agrícola (Lunes=18%, Martes=22%, etc.)
      final distribucion = [0.18, 0.22, 0.16, 0.20, 0.14, 0.10, 0.0];
      final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      
      print('  Total semana: \$${totalSemana.toStringAsFixed(2)}');
      for (int i = 0; i < 7; i++) {
        final montoDia = totalSemana * distribucion[i];
        print('  ${dias[i]}: \$${montoDia.toStringAsFixed(2)} (${(distribucion[i] * 100).toInt()}%)');
      }
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}
