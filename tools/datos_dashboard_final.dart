import 'package:postgres/postgres.dart';

void main() async {
  print('=== 📊 DATOS REALES DE AGRIBAR - DASHBOARD ===\n');
  
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
    
    await mostrarResumenEjecutivo(connection);
    await mostrarCuadrillasTop(connection);
    await mostrarEmpleadosDestacados(connection);
    await mostrarDistribucionSemanal(connection);
    await mostrarActividadesYRanchos(connection);
    
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

Future<void> mostrarResumenEjecutivo(PostgreSQLConnection connection) async {
  print('📈 RESUMEN EJECUTIVO:');
  try {
    // Estadísticas generales
    final empleadosResult = await connection.query('SELECT COUNT(*) FROM empleados WHERE habilitado = true');
    final cuadrillasResult = await connection.query('SELECT COUNT(*) FROM cuadrillas WHERE estado = true');
    final actividadesResult = await connection.query('SELECT COUNT(*) FROM actividades');
    final semanaActualResult = await connection.query('SELECT MAX(id_semana) FROM nomina_empleados_semanal');
    
    print('  🏢 Empleados activos: ${empleadosResult.first[0]}');
    print('  👷 Cuadrillas activas: ${cuadrillasResult.first[0]}');
    print('  🚜 Actividades disponibles: ${actividadesResult.first[0]}');
    print('  📅 Semana actual de nómina: ${semanaActualResult.first[0]}');
    
    // Nómina de la semana actual
    final nominaResult = await connection.query('''
      SELECT 
        COUNT(DISTINCT id_empleado),
        COUNT(*) 
      FROM nomina_empleados_semanal 
      WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    
    print('  💰 Empleados con nómina esta semana: ${nominaResult.first[0]}');
    print('  📝 Registros de nómina: ${nominaResult.first[1]}');
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> mostrarCuadrillasTop(PostgreSQLConnection connection) async {
  print('👷 TOP 8 CUADRILLAS POR EMPLEADOS:');
  try {
    final result = await connection.query('''
      SELECT 
        c.nombre,
        c.grupo,
        c.actividad,
        COUNT(n.id_empleado) as empleados
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true 
        AND n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre, c.grupo, c.actividad
      HAVING COUNT(n.id_empleado) > 0
      ORDER BY empleados DESC
      LIMIT 8
    ''');
    
    for (final row in result) {
      print('  • ${row[0]}');
      print('    Grupo: ${row[1] ?? 'Sin grupo'}');
      print('    Actividad: ${row[2] ?? 'Sin actividad'}');
      print('    Empleados: ${row[3]}');
      print('');
    }
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> mostrarEmpleadosDestacados(PostgreSQLConnection connection) async {
  print('🏆 EMPLEADOS CON REGISTROS RECIENTES:');
  try {
    final result = await connection.query('''
      SELECT DISTINCT
        e.nombre,
        e.apellido_paterno,
        e.codigo,
        c.nombre as cuadrilla
      FROM nomina_empleados_semanal n
      JOIN empleados e ON n.id_empleado = e.id_empleado
      LEFT JOIN cuadrillas c ON n.id_cuadrilla = c.id_cuadrilla
      WHERE n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      ORDER BY e.nombre
      LIMIT 10
    ''');
    
    int contador = 1;
    for (final row in result) {
      print('  $contador. ${row[0]} ${row[1]} (Código: ${row[2]})');
      print('     Cuadrilla: ${row[3] ?? 'Sin asignar'}');
      contador++;
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> mostrarDistribucionSemanal(PostgreSQLConnection connection) async {
  print('📅 DATOS DISPONIBLES POR SEMANA:');
  try {
    final result = await connection.query('''
      SELECT 
        id_semana,
        COUNT(DISTINCT id_empleado) as empleados,
        COUNT(DISTINCT id_cuadrilla) as cuadrillas,
        COUNT(*) as registros
      FROM nomina_empleados_semanal
      GROUP BY id_semana
      ORDER BY id_semana DESC
      LIMIT 5
    ''');
    
    for (final row in result) {
      print('  Semana ${row[0]}: ${row[1]} empleados, ${row[2]} cuadrillas, ${row[3]} registros');
    }
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

Future<void> mostrarActividadesYRanchos(PostgreSQLConnection connection) async {
  print('🌾 INFORMACIÓN ADICIONAL:');
  try {
    // Verificar qué tablas existen para actividades y ranchos
    final tablas = await connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name IN ('actividades', 'ranchos', 'registro_actividades')
      ORDER BY table_name
    ''');
    
    print('  📋 Tablas disponibles:');
    for (final row in tablas) {
      print('    • ${row[0]}');
    }
    
    // Mostrar algunas actividades si existe la tabla
    try {
      final actividades = await connection.query('SELECT id_actividad, nombre FROM actividades LIMIT 5');
      print('  \n  🚜 Primeras 5 actividades:');
      for (final row in actividades) {
        print('    ${row[0]}. ${row[1]}');
      }
    } catch (e) {
      print('  ⚠️ No se pudo consultar actividades: $e');
    }
    
    // Mostrar algunos ranchos si existe la tabla
    try {
      final ranchos = await connection.query('SELECT id_rancho, nombre FROM ranchos LIMIT 5');
      print('  \n  🏡 Primeros 5 ranchos:');
      for (final row in ranchos) {
        print('    ${row[0]}. ${row[1]}');
      }
    } catch (e) {
      print('  ⚠️ No se pudo consultar ranchos: $e');
    }
    
    print('');
  } catch (e) {
    print('Error: $e\n');
  }
}

// Función adicional para datos específicos del dashboard
Future<void> obtenerDatosParaDashboard(PostgreSQLConnection connection) async {
  print('📊 DATOS ESPECÍFICOS PARA DASHBOARD:');
  try {
    // Datos para gráfica de pie - Cuadrillas por grupo
    print('  🥧 Datos para gráfica circular (Cuadrillas por grupo):');
    final pieResult = await connection.query('''
      SELECT 
        COALESCE(grupo, 'Sin grupo') as grupo,
        COUNT(*) as cantidad
      FROM cuadrillas
      WHERE estado = true
      GROUP BY grupo
      ORDER BY cantidad DESC
      LIMIT 6
    ''');
    
    for (final row in pieResult) {
      print('    ${row[0]}: ${row[1]} cuadrillas');
    }
    
    // Datos para gráfica de barras - Empleados por cuadrilla top
    print('  \n  📊 Datos para gráfica de barras (Top cuadrillas):');
    final barResult = await connection.query('''
      SELECT 
        SUBSTRING(c.nombre FROM 1 FOR 20) as nombre_corto,
        COUNT(n.id_empleado) as empleados
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true 
        AND n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre
      HAVING COUNT(n.id_empleado) > 0
      ORDER BY empleados DESC
      LIMIT 5
    ''');
    
    for (final row in barResult) {
      print('    ${row[0]}: ${row[1]} empleados');
    }
    
    print('');
  } catch (e) {
    print('Error obteniendo datos para dashboard: $e\n');
  }
}
