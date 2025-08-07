import 'package:postgres/postgres.dart';

/// Test directo de consultas con formato YYYYMMDD
void main() async {
  print('🗓️ === PRUEBAS FORMATO YYYYMMDD ===');
  print('===================================');

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

    // Test 1: Datos básicos sin filtro de fecha
    print('\n1️⃣ DATOS BÁSICOS SIN FILTRO:');
    final basicResult = await connection.query('''
      SELECT 
        c.nombre as cuadrilla,
        neh.total,
        to_char(neh.fecha_cierre, 'YYYYMMDD') as fecha_yyyymmdd,
        to_char(neh.fecha_cierre, 'YYYY-MM-DD') as fecha_legible
      FROM nomina_empleados_historial neh
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
      ORDER BY neh.fecha_cierre DESC
      LIMIT 3
    ''');

    for (var row in basicResult) {
      print('   - Cuadrilla: ${row[0]}');
      print('     Total: \$${row[1]}');
      print('     Fecha YYYYMMDD: ${row[2]}');
      print('     Fecha legible: ${row[3]}');
      print('     ───────────────────');
    }

    // Test 2: Filtro por fecha específica (hoy)
    final DateTime hoy = DateTime.now();
    final String hoyYYYYMMDD = '${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}';
    
    print('\n2️⃣ FILTRO POR FECHA HOY ($hoyYYYYMMDD):');
    final filtroResult = await connection.query('''
      SELECT 
        c.nombre as cuadrilla,
        SUM(neh.total) as total_cuadrilla,
        COUNT(*) as empleados
      FROM nomina_empleados_historial neh
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
      WHERE to_char(neh.fecha_cierre, 'YYYYMMDD') = @fecha
      GROUP BY c.nombre
      ORDER BY total_cuadrilla DESC
    ''', substitutionValues: {'fecha': hoyYYYYMMDD});

    if (filtroResult.isNotEmpty) {
      for (var row in filtroResult) {
        print('   - ${row[0]}: \$${row[1]} (${row[2]} empleados)');
      }
    } else {
      print('   ⚠️ No hay datos para la fecha $hoyYYYYMMDD');
    }

    // Test 3: Rango de fechas (últimos 7 días)
    final DateTime hace7Dias = hoy.subtract(Duration(days: 7));
    final String hace7DiasYYYYMMDD = '${hace7Dias.year}${hace7Dias.month.toString().padLeft(2, '0')}${hace7Dias.day.toString().padLeft(2, '0')}';
    
    print('\n3️⃣ RANGO DE FECHAS ($hace7DiasYYYYMMDD - $hoyYYYYMMDD):');
    final rangoResult = await connection.query('''
      SELECT 
        to_char(neh.fecha_cierre, 'YYYYMMDD') as fecha,
        COUNT(DISTINCT c.nombre) as cuadrillas,
        COUNT(DISTINCT neh.id_empleado) as empleados,
        SUM(neh.total) as total_dia
      FROM nomina_empleados_historial neh
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
      WHERE to_char(neh.fecha_cierre, 'YYYYMMDD') >= @fechaInicio
        AND to_char(neh.fecha_cierre, 'YYYYMMDD') <= @fechaFin
      GROUP BY to_char(neh.fecha_cierre, 'YYYYMMDD')
      ORDER BY fecha DESC
    ''', substitutionValues: {
      'fechaInicio': hace7DiasYYYYMMDD,
      'fechaFin': hoyYYYYMMDD,
    });

    if (rangoResult.isNotEmpty) {
      for (var row in rangoResult) {
        print('   - Fecha ${row[0]}: ${row[1]} cuadrillas, ${row[2]} empleados, \$${row[3]}');
      }
      
      // Calcular totales del rango
      final totalEmpleados = rangoResult.fold(0, (sum, row) => sum + (row[2] as int));
      final totalDinero = rangoResult.fold(0.0, (sum, row) => sum + (double.tryParse(row[3].toString()) ?? 0.0));
      
      print('\n📊 RESUMEN DEL RANGO:');
      print('   - Total empleados únicos por día: $totalEmpleados');
      print('   - Total dinero: \$${totalDinero.toStringAsFixed(2)}');
      print('   - Días con actividad: ${rangoResult.length}');
    } else {
      print('   ⚠️ No hay datos en el rango especificado');
    }

    // Test 4: Expansión de datos por día (simulando el servicio expandido)
    print('\n4️⃣ SIMULACIÓN DE DATOS EXPANDIDOS:');
    final expandidoResult = await connection.query('''
      WITH expansion_dias AS (
        SELECT dia_num FROM generate_series(1, 7) as dia_num
      ),
      datos_expandidos AS (
        SELECT 
          c.nombre as cuadrilla_nombre,
          neh.fecha_cierre::date as fecha_base,
          ed.dia_num,
          CASE ed.dia_num
            WHEN 1 THEN COALESCE(neh.dia_1, 0)
            WHEN 2 THEN COALESCE(neh.dia_2, 0)
            WHEN 3 THEN COALESCE(neh.dia_3, 0)
            WHEN 4 THEN COALESCE(neh.dia_4, 0)
            WHEN 5 THEN COALESCE(neh.dia_5, 0)
            WHEN 6 THEN COALESCE(neh.dia_6, 0)
            WHEN 7 THEN COALESCE(neh.dia_7, 0)
          END as pago_dia
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        CROSS JOIN expansion_dias ed
      )
      SELECT 
        cuadrilla_nombre,
        COUNT(CASE WHEN pago_dia > 0 THEN 1 END) as dias_con_pago,
        SUM(pago_dia) as total_expandido,
        AVG(CASE WHEN pago_dia > 0 THEN pago_dia END) as promedio_dia_trabajado
      FROM datos_expandidos
      GROUP BY cuadrilla_nombre
      HAVING SUM(pago_dia) > 0
      ORDER BY total_expandido DESC
      LIMIT 5
    ''');

    if (expandidoResult.isNotEmpty) {
      for (var row in expandidoResult) {
        print('   - ${row[0]}:');
        print('     Días con pago: ${row[1]}');
        print('     Total expandido: \$${row[2]}');
        print('     Promedio por día trabajado: \$${row[3]?.toStringAsFixed(2) ?? '0.00'}');
        print('     ───────────────────');
      }
    }

    print('\n🎉 === PRUEBAS YYYYMMDD COMPLETADAS ===');

  } catch (e, stackTrace) {
    print('❌ ERROR EN PRUEBAS: $e');
    print('🔍 Stack trace: $stackTrace');
  } finally {
    try {
      await connection.close();
      print('\n🔒 Conexión cerrada');
    } catch (e) {
      print('Error cerrando conexión: $e');
    }
  }
}
