import 'package:agribar/services/database_service.dart';

void main() async {
  print('=== EXPLORANDO DATOS REALES PARA DASHBOARD ===\n');
  
  final dbService = DatabaseService();
  
  try {
    await dbService.connect();
    print('✅ Conexión a base de datos exitosa\n');
    
    // 1. Explorar tablas principales
    await explorarTablasDisponibles(dbService);
    
    // 2. Datos de empleados y nómina
    await explorarDatosEmpleados(dbService);
    
    // 3. Datos de cuadrillas
    await explorarDatosCuadrillas(dbService);
    
    // 4. Datos de actividades
    await explorarDatosActividades(dbService);
    
    // 5. Datos de semanas
    await explorarDatosSemanas(dbService);
    
    // 6. Resumen de nómina
    await explorarResumenNomina(dbService);
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await dbService.close();
    print('\n🔒 Conexión cerrada');
  }
}

Future<void> explorarTablasDisponibles(DatabaseService dbService) async {
  print('📋 TABLAS DISPONIBLES:');
  try {
    final results = await dbService.connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    ''');
    
    for (final row in results) {
      print('  - ${row[0]}');
    }
    print('');
  } catch (e) {
    print('Error explorando tablas: $e\n');
  }
}

Future<void> explorarDatosEmpleados(DatabaseService dbService) async {
  print('👥 DATOS DE EMPLEADOS:');
  try {
    // Total de empleados
    final countResult = await dbService.connection.query('SELECT COUNT(*) FROM empleados');
    print('  Total empleados: ${countResult.first[0]}');
    
    // Empleados con nómina actual
    final nominaResult = await dbService.connection.query('''
      SELECT COUNT(DISTINCT e.id_empleado) as empleados_activos,
             COUNT(*) as registros_nomina,
             SUM(n.total_ganancia) as total_ganancias,
             AVG(n.total_ganancia) as promedio_ganancia
      FROM empleados e
      JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    
    if (nominaResult.isNotEmpty) {
      final row = nominaResult.first;
      print('  Empleados activos (semana actual): ${row[0]}');
      print('  Registros de nómina: ${row[1]}');
      print('  Total ganancias: \$${(row[2] as num?)?.toStringAsFixed(2) ?? '0.00'}');
      print('  Promedio ganancia: \$${(row[3] as num?)?.toStringAsFixed(2) ?? '0.00'}');
    }
    
    // Top 5 empleados mejor pagados
    final topEmpleados = await dbService.connection.query('''
      SELECT e.nombre, n.total_ganancia, c.nombre as cuadrilla
      FROM empleados e
      JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      LEFT JOIN cuadrillas c ON e.id_cuadrilla = c.id_cuadrilla
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      ORDER BY n.total_ganancia DESC
      LIMIT 5
    ''');
    
    print('  Top 5 empleados mejor pagados:');
    for (int i = 0; i < topEmpleados.length; i++) {
      final emp = topEmpleados[i];
      print('    ${i + 1}. ${emp[0]} - \$${(emp[1] as num).toStringAsFixed(2)} (${emp[2] ?? 'Sin cuadrilla'})');
    }
    print('');
  } catch (e) {
    print('Error explorando empleados: $e\n');
  }
}

Future<void> explorarDatosCuadrillas(DatabaseService dbService) async {
  print('👷 DATOS DE CUADRILLAS:');
  try {
    // Total de cuadrillas
    final countResult = await dbService.connection.query('SELECT COUNT(*) FROM cuadrillas');
    print('  Total cuadrillas: ${countResult.first[0]}');
    
    // Cuadrillas con miembros y ganancias
    final cuadrillasData = await dbService.connection.query('''
      SELECT 
        c.nombre as cuadrilla,
        COUNT(e.id_empleado) as total_miembros,
        COALESCE(SUM(n.total_ganancia), 0) as ganancia_total,
        COALESCE(AVG(n.total_ganancia), 0) as ganancia_promedio
      FROM cuadrillas c
      LEFT JOIN empleados e ON c.id_cuadrilla = e.id_cuadrilla
      LEFT JOIN nomina_empleados_semanal n ON e.id_empleado = n.id_empleado
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre
      HAVING COUNT(e.id_empleado) > 0
      ORDER BY total_miembros DESC
    ''');
    
    print('  Cuadrillas activas:');
    for (final cuadrilla in cuadrillasData) {
      print('    - ${cuadrilla[0]}: ${cuadrilla[1]} miembros, '
            'Total: \$${(cuadrilla[2] as num).toStringAsFixed(2)}, '
            'Promedio: \$${(cuadrilla[3] as num).toStringAsFixed(2)}');
    }
    print('');
  } catch (e) {
    print('Error explorando cuadrillas: $e\n');
  }
}

Future<void> explorarDatosActividades(DatabaseService dbService) async {
  print('🚜 DATOS DE ACTIVIDADES:');
  try {
    // Total de actividades
    final countResult = await dbService.connection.query('SELECT COUNT(*) FROM actividades');
    print('  Total actividades: ${countResult.first[0]}');
    
    // Actividades activas con cuadrillas asignadas
    final actividadesData = await dbService.connection.query('''
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
      LIMIT 10
    ''');
    
    print('  Actividades con más cuadrillas asignadas:');
    for (final actividad in actividadesData) {
      print('    - ${actividad[0]}: ${actividad[1]} cuadrillas, '
            '${(actividad[2] as num).toStringAsFixed(1)} horas');
    }
    print('');
  } catch (e) {
    print('Error explorando actividades: $e\n');
  }
}

Future<void> explorarDatosSemanas(DatabaseService dbService) async {
  print('📅 DATOS DE SEMANAS:');
  try {
    // Semanas disponibles
    final semanasData = await dbService.connection.query('''
      SELECT s.id_semana, s.fecha_inicio, s.fecha_fin, s.estado,
             COUNT(n.id_empleado) as empleados_registrados
      FROM semanas s
      LEFT JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.estado
      ORDER BY s.id_semana DESC
      LIMIT 5
    ''');
    
    print('  Últimas 5 semanas:');
    for (final semana in semanasData) {
      print('    Semana ${semana[0]}: ${semana[1]} a ${semana[2]} '
            '(${semana[3]}) - ${semana[4]} empleados');
    }
    
    // Semana actual
    final semanaActual = await dbService.connection.query('''
      SELECT MAX(id_semana) FROM nomina_empleados_semanal
    ''');
    if (semanaActual.isNotEmpty && semanaActual.first[0] != null) {
      print('  Semana actual con datos: ${semanaActual.first[0]}');
    }
    print('');
  } catch (e) {
    print('Error explorando semanas: $e\n');
  }
}

Future<void> explorarResumenNomina(DatabaseService dbService) async {
  print('💰 RESUMEN DE NÓMINA:');
  try {
    // Resumen de la semana actual
    final resumenData = await dbService.connection.query('''
      SELECT 
        r.total_semana,
        r.total_empleados,
        r.promedio_empleado,
        s.fecha_inicio,
        s.fecha_fin
      FROM resumen_nomina r
      JOIN semanas s ON r.id_semana = s.id_semana
      WHERE r.id_semana = (SELECT MAX(id_semana) FROM resumen_nomina)
    ''');
    
    if (resumenData.isNotEmpty) {
      final resumen = resumenData.first;
      print('  Semana del ${resumen[3]} al ${resumen[4]}:');
      print('    Total semana: \$${(resumen[0] as num).toStringAsFixed(2)}');
      print('    Total empleados: ${resumen[1]}');
      print('    Promedio por empleado: \$${(resumen[2] as num).toStringAsFixed(2)}');
    }
    
    // Distribución de pagos por día de la semana
    final pagosPorDia = await dbService.connection.query('''
      SELECT 
        EXTRACT(DOW FROM s.fecha_inicio) as dia_semana,
        SUM(COALESCE(n.total_ganancia, 0)) as total_dia
      FROM semanas s
      LEFT JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      WHERE s.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY EXTRACT(DOW FROM s.fecha_inicio)
      ORDER BY dia_semana
    ''');
    
    if (pagosPorDia.isNotEmpty) {
      print('  Distribución de pagos por día:');
      final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
      for (final dia in pagosPorDia) {
        final diaSemana = (dia[0] as num).toInt();
        final total = (dia[1] as num).toDouble();
        print('    ${dias[diaSemana]}: \$${total.toStringAsFixed(2)}');
      }
    }
    print('');
  } catch (e) {
    print('Error explorando resumen de nómina: $e\n');
  }
}
