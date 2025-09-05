import 'package:postgres/postgres.dart';

void main() async {
  print('=== DATOS REALES DE TU EMPRESA AGRIBAR ===\n');
  
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
    print('✅ Conexión exitosa a base de datos AGRIBAR\n');
    
    // 1. Empleados activos y estadísticas generales
    await consultarEmpleadosGenerales(connection);
    
    // 2. Cuadrillas activas
    await consultarCuadrillasActivas(connection);
    
    // 3. Análisis de nómina semanal actual
    await consultarNominaActual(connection);
    
    // 4. Top empleados mejor pagados
    await consultarTopEmpleados(connection);
    
    // 5. Distribución por días de trabajo
    await consultarDistribucionDias(connection);
    
    // 6. Actividades disponibles
    await consultarActividades(connection);
    
    // 7. Análisis de cuadrillas por grupo
    await consultarCuadrillasPorGrupo(connection);
    
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

Future<void> consultarEmpleadosGenerales(PostgreSQLConnection connection) async {
  print('👥 EMPLEADOS ACTIVOS:');
  try {
    final result = await connection.query('''
      SELECT 
        COUNT(*) as total_empleados,
        COUNT(CASE WHEN habilitado = true THEN 1 END) as empleados_activos,
        COUNT(CASE WHEN estado_origen IS NOT NULL THEN 1 END) as con_estado_origen
      FROM empleados
    ''');
    
    for (final row in result) {
      print('  Total empleados registrados: ${row[0]}');
      print('  Empleados habilitados: ${row[1]}');
      print('  Con estado de origen: ${row[2]}');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarCuadrillasActivas(PostgreSQLConnection connection) async {
  print('👷 CUADRILLAS ACTIVAS:');
  try {
    final result = await connection.query('''
      SELECT 
        c.nombre,
        c.grupo,
        c.actividad,
        COUNT(n.id_empleado) as empleados_asignados,
        COALESCE(SUM(n.total_neto), 0) as total_pagado_neto
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true
      GROUP BY c.id_cuadrilla, c.nombre, c.grupo, c.actividad
      ORDER BY empleados_asignados DESC
      LIMIT 10
    ''');
    
    for (final row in result) {
      print('  Cuadrilla: ${row[0]}');
      print('    Grupo: ${row[1] ?? 'Sin grupo'}');
      print('    Actividad: ${row[2] ?? 'Sin actividad'}');
      print('    Empleados: ${row[3]}');
      print('    Total pagado (neto): \$${(row[4] as num).toStringAsFixed(2)}');
      print('');
    }
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarNominaActual(PostgreSQLConnection connection) async {
  print('💰 ANÁLISIS NÓMINA SEMANAL ACTUAL:');
  try {
    // Obtener la semana más reciente
    final semanaResult = await connection.query('''
      SELECT MAX(id_semana) as semana_actual
      FROM nomina_empleados_semanal
    ''');
    
    if (semanaResult.isNotEmpty && semanaResult.first[0] != null) {
      final semanaActual = semanaResult.first[0];
      print('  Semana actual: $semanaActual');
      
      final result = await connection.query('''
        SELECT 
          COUNT(DISTINCT id_empleado) as empleados_registrados,
          COUNT(DISTINCT id_cuadrilla) as cuadrillas_activas,
          COALESCE(SUM(total), 0) as total_bruto,
          COALESCE(SUM(debe), 0) as total_debe,
          COALESCE(SUM(comedor), 0) as total_comedor,
          COALESCE(SUM(total_neto), 0) as total_neto,
          COALESCE(AVG(total_neto), 0) as promedio_neto
        FROM nomina_empleados_semanal
        WHERE id_semana = $semanaActual AND total_neto > 0
      ''');
      
      for (final row in result) {
        print('  Empleados con nómina: ${row[0]}');
        print('  Cuadrillas activas: ${row[1]}');
        print('  Total bruto: \$${(row[2] as num).toStringAsFixed(2)}');
        print('  Total debe: \$${(row[3] as num).toStringAsFixed(2)}');
        print('  Total comedor: \$${(row[4] as num).toStringAsFixed(2)}');
        print('  TOTAL NETO: \$${(row[5] as num).toStringAsFixed(2)}');
        print('  Promedio por empleado: \$${(row[6] as num).toStringAsFixed(2)}');
      }
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarTopEmpleados(PostgreSQLConnection connection) async {
  print('🏆 TOP 10 EMPLEADOS MEJOR PAGADOS (SEMANA ACTUAL):');
  try {
    final result = await connection.query('''
      SELECT 
        e.nombre,
        e.apellido_paterno,
        n.total_neto,
        c.nombre as cuadrilla
      FROM nomina_empleados_semanal n
      JOIN empleados e ON n.id_empleado = e.id_empleado
      LEFT JOIN cuadrillas c ON n.id_cuadrilla = c.id_cuadrilla
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
        AND n.total_neto > 0
      ORDER BY n.total_neto DESC
      LIMIT 10
    ''');
    
    int posicion = 1;
    for (final row in result) {
      print('  $posicion. ${row[0]} ${row[1]} - \$${(row[2] as num).toStringAsFixed(2)}');
      print('     Cuadrilla: ${row[3] ?? 'Sin asignar'}');
      posicion++;
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarDistribucionDias(PostgreSQLConnection connection) async {
  print('📅 DISTRIBUCIÓN DE PAGOS POR DÍA (SEMANA ACTUAL):');
  try {
    final result = await connection.query('''
      SELECT 
        COALESCE(SUM(dia_1), 0) as lunes,
        COALESCE(SUM(dia_2), 0) as martes,
        COALESCE(SUM(dia_3), 0) as miercoles,
        COALESCE(SUM(dia_4), 0) as jueves,
        COALESCE(SUM(dia_5), 0) as viernes,
        COALESCE(SUM(dia_6), 0) as sabado,
        COALESCE(SUM(dia_7), 0) as domingo
      FROM nomina_empleados_semanal
      WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    for (final row in result) {
      for (int i = 0; i < 7; i++) {
        final valor = row[i] as num;
        print('  ${dias[i]}: \$${valor.toStringAsFixed(2)}');
      }
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarActividades(PostgreSQLConnection connection) async {
  print('🚜 ACTIVIDADES DISPONIBLES:');
  try {
    final result = await connection.query('''
      SELECT id_actividad, nombre, descripcion, estado
      FROM actividades
      ORDER BY id_actividad
      LIMIT 10
    ''');
    
    for (final row in result) {
      print('  ${row[0]}. ${row[1]}');
      if (row[2] != null && row[2].toString().isNotEmpty) {
        print('     Descripción: ${row[2]}');
      }
      print('     Estado: ${row[3] ?? 'Sin estado'}');
      print('');
    }
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> consultarCuadrillasPorGrupo(PostgreSQLConnection connection) async {
  print('📊 CUADRILLAS AGRUPADAS:');
  try {
    final result = await connection.query('''
      SELECT 
        COALESCE(grupo, 'Sin grupo') as grupo,
        COUNT(*) as total_cuadrillas,
        COUNT(CASE WHEN estado = true THEN 1 END) as cuadrillas_activas
      FROM cuadrillas
      GROUP BY grupo
      ORDER BY total_cuadrillas DESC
    ''');
    
    for (final row in result) {
      print('  Grupo: ${row[0]}');
      print('    Total cuadrillas: ${row[1]}');
      print('    Cuadrillas activas: ${row[2]}');
      print('');
    }
  } catch (e) {
    print('Error: $e\n');
  }
}
