import 'package:agribar/services/database_service.dart';

/// Servicio para obtener datos de reportes basados en nóminas REALES desde nomina_empleados_historial
/// FECHAS MANEJADAS EN FORMATO YYYYMMDD
class ReportesService {

  /// Obtener lista de ranchos reales (de la tabla ranchos)
  Future<List<String>> obtenerRanchos() async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.query('''
        SELECT DISTINCT nombre 
        FROM ranchos 
        ORDER BY nombre ASC;
      ''');

      List<String> ranchos = ['Todos'];
      ranchos.addAll(result.map((row) => row[0] as String).toList());
      return ranchos;
    } catch (e) {
      print('Error al obtener ranchos: $e');
      return ['Todos'];
    } finally {
      await db.close();
    }
  }

  /// Obtener lista de actividades reales
  Future<List<String>> obtenerActividades() async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.query('''
        SELECT nombre 
        FROM actividades 
        ORDER BY nombre ASC;
      ''');

      List<String> actividades = ['Todas'];
      actividades.addAll(result.map((row) => row[0] as String).toList());
      return actividades;
    } catch (e) {
      print('Error al obtener actividades: $e');
      return ['Todas'];
    } finally {
      await db.close();
    }
  }

  /// Convertir DateTime a formato YYYYMMDD string
  String _formatoYYYYMMDD(DateTime fecha) {
    return '${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}';
  }

  /// 1. REPORTE GENERAL - Con soporte de fechas YYYYMMDD
  Future<List<Map<String, dynamic>>> obtenerReporteGeneral({
    String? rancho,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      // Usar datos de nomina_empleados_historial expandidos día por día
      String query = '''
        WITH expansion_dias AS (
          SELECT dia_num FROM generate_series(1, 7) as dia_num
        ),
        datos_expandidos AS (
          SELECT 
            neh.id_empleado,
            neh.id_cuadrilla,
            c.nombre as cuadrilla_nombre,
            neh.fecha_cierre::date as fecha_trabajo,
            ed.dia_num,
            CASE ed.dia_num
              WHEN 1 THEN COALESCE(neh.dia_1, 0)
              WHEN 2 THEN COALESCE(neh.dia_2, 0)
              WHEN 3 THEN COALESCE(neh.dia_3, 0)
              WHEN 4 THEN COALESCE(neh.dia_4, 0)
              WHEN 5 THEN COALESCE(neh.dia_5, 0)
              WHEN 6 THEN COALESCE(neh.dia_6, 0)
              WHEN 7 THEN COALESCE(neh.dia_7, 0)
            END as pago_dia,
            CASE ed.dia_num
              WHEN 1 THEN neh.act_1
              WHEN 2 THEN neh.act_2
              WHEN 3 THEN neh.act_3
              WHEN 4 THEN neh.act_4
              WHEN 5 THEN neh.act_5
              WHEN 6 THEN neh.act_6
              WHEN 7 THEN neh.act_7
            END as id_actividad,
            CASE ed.dia_num
              WHEN 1 THEN neh.campo_1
              WHEN 2 THEN neh.campo_2
              WHEN 3 THEN neh.campo_3
              WHEN 4 THEN neh.campo_4
              WHEN 5 THEN neh.campo_5
              WHEN 6 THEN neh.campo_6
              WHEN 7 THEN neh.campo_7
            END as id_rancho
          FROM nomina_empleados_historial neh
          JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
          CROSS JOIN expansion_dias ed
        )
        SELECT 
          COALESCE(r.nombre, de.cuadrilla_nombre, 'Sin rancho') as rancho_nombre,
          COALESCE(a.nombre, 'Trabajo General') as actividad_nombre,
          COUNT(DISTINCT de.fecha_trabajo) as dias_trabajados,
          COUNT(DISTINCT de.id_empleado) as empleados_involucrados,
          SUM(de.pago_dia) as gasto_total,
          AVG(de.pago_dia) as promedio
        FROM datos_expandidos de
        LEFT JOIN actividades a ON de.id_actividad = a.id_actividad
        LEFT JOIN ranchos r ON de.id_rancho = r.id_rancho
        WHERE de.pago_dia > 0
      ''';

      Map<String, dynamic> params = {};

      // Filtros de fecha en formato YYYYMMDD
      if (fechaInicio != null) {
        query += ' AND to_char(de.fecha_trabajo, \'YYYYMMDD\') >= @fechaInicio';
        params['fechaInicio'] = _formatoYYYYMMDD(fechaInicio);
      }
      
      if (fechaFin != null) {
        query += ' AND to_char(de.fecha_trabajo, \'YYYYMMDD\') <= @fechaFin';
        params['fechaFin'] = _formatoYYYYMMDD(fechaFin);
      }

      if (rancho != null && rancho != 'Todos') {
        query += ' AND (r.nombre = @rancho OR de.cuadrilla_nombre = @rancho)';
        params['rancho'] = rancho;
      }

      query += '''
        GROUP BY r.nombre, a.nombre, de.cuadrilla_nombre
        HAVING SUM(de.pago_dia) > 0
        ORDER BY gasto_total DESC;
      ''';

      print('🔍 Ejecutando consulta reporte general YYYYMMDD: $query');
      print('📊 Parámetros: $params');

      final result = await db.connection.query(query, substitutionValues: params);

      if (result.isEmpty) {
        // Fallback simple si falla la consulta expandida
        return await _obtenerReporteSimple(rancho: rancho, fechaInicio: fechaInicio, fechaFin: fechaFin);
      }

      return result.map((row) => {
        'rancho': row[0] as String,
        'actividad': row[1] as String,
        'dias_trabajados': row[2] as int,
        'empleados_involucrados': row[3] as int,
        'gasto_total': double.tryParse(row[4].toString()) ?? 0.0,
        'promedio': double.tryParse(row[5].toString()) ?? 0.0,
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReporteGeneral: $e');
      // Fallback a consulta simple
      return await _obtenerReporteSimple(rancho: rancho, fechaInicio: fechaInicio, fechaFin: fechaFin);
    } finally {
      await db.close();
    }
  }

  /// Fallback simple para reporte general
  Future<List<Map<String, dynamic>>> _obtenerReporteSimple({
    String? rancho,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      String query = '''
        SELECT 
          c.nombre as rancho_nombre,
          'Trabajo General' as actividad_nombre,
          COUNT(DISTINCT to_char(neh.fecha_cierre, 'YYYYMMDD')) as dias_trabajados,
          COUNT(DISTINCT neh.id_empleado) as empleados_involucrados,
          SUM(COALESCE(neh.total, 0)) as gasto_total,
          AVG(COALESCE(neh.total, 0)) as promedio
        FROM nomina_empleados_historial neh
        JOIN empleados e ON neh.id_empleado = e.id_empleado
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE 1=1
      ''';

      Map<String, dynamic> params = {};

      if (fechaInicio != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') >= @fechaInicio';
        params['fechaInicio'] = _formatoYYYYMMDD(fechaInicio);
      }
      
      if (fechaFin != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') <= @fechaFin';
        params['fechaFin'] = _formatoYYYYMMDD(fechaFin);
      }

      if (rancho != null && rancho != 'Todos') {
        query += ' AND c.nombre = @rancho';
        params['rancho'] = rancho;
      }

      query += '''
        GROUP BY c.nombre
        HAVING SUM(COALESCE(neh.total, 0)) > 0
        ORDER BY gasto_total DESC;
      ''';

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'rancho': row[0] as String,
        'actividad': row[1] as String,
        'dias_trabajados': row[2] as int,
        'empleados_involucrados': row[3] as int,
        'gasto_total': double.tryParse(row[4].toString()) ?? 0.0,
        'promedio': double.tryParse(row[5].toString()) ?? 0.0,
      }).toList();

    } finally {
      await db.close();
    }
  }

  /// 2. REPORTE POR RANCHO - Con fechas YYYYMMDD
  Future<List<Map<String, dynamic>>> obtenerReportePorRancho({
    required String rancho,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      String query = '''
        SELECT 
          'Trabajo en $rancho' as actividad,
          COUNT(DISTINCT neh.id_empleado) as empleados,
          SUM(COALESCE(neh.total, 0)) as gasto_total,
          AVG(COALESCE(neh.total, 0)) as promedio_empleado,
          COUNT(DISTINCT to_char(neh.fecha_cierre, 'YYYYMMDD')) as dias_trabajados
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE c.nombre = @rancho
      ''';

      Map<String, dynamic> params = {'rancho': rancho};

      if (fechaInicio != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') >= @fechaInicio';
        params['fechaInicio'] = _formatoYYYYMMDD(fechaInicio);
      }
      
      if (fechaFin != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') <= @fechaFin';
        params['fechaFin'] = _formatoYYYYMMDD(fechaFin);
      }

      query += '''
        GROUP BY 'Trabajo en $rancho'
        HAVING SUM(COALESCE(neh.total, 0)) > 0;
      ''';

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'actividad': row[0] as String,
        'empleados': row[1] as int,
        'gasto_total': double.tryParse(row[2].toString()) ?? 0.0,
        'promedio_empleado': double.tryParse(row[3].toString()) ?? 0.0,
        'dias_trabajados': row[4] as int,
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReportePorRancho: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// 3. REPORTE POR ACTIVIDAD - Con fechas YYYYMMDD
  Future<List<Map<String, dynamic>>> obtenerReportePorActividad({
    required String actividad,
    String? rancho,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      String query = '''
        SELECT 
          to_char(neh.fecha_cierre, 'YYYY-MM-DD') as fecha,
          c.nombre as rancho,
          c.nombre as cuadrilla,
          COUNT(neh.id_empleado) as empleados,
          SUM(COALESCE(neh.total, 0)) as gasto_dia,
          AVG(COALESCE(neh.total, 0)) as promedio_empleado
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE 1=1
      ''';

      Map<String, dynamic> params = {};

      if (rancho != null && rancho != 'Todos') {
        query += ' AND c.nombre = @rancho';
        params['rancho'] = rancho;
      }
      
      if (fechaInicio != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') >= @fechaInicio';
        params['fechaInicio'] = _formatoYYYYMMDD(fechaInicio);
      }
      
      if (fechaFin != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') <= @fechaFin';
        params['fechaFin'] = _formatoYYYYMMDD(fechaFin);
      }

      query += '''
        GROUP BY neh.fecha_cierre::date, c.nombre
        HAVING SUM(COALESCE(neh.total, 0)) > 0
        ORDER BY neh.fecha_cierre::date DESC;
      ''';

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'fecha': row[0] as String,
        'rancho': row[1] as String,
        'cuadrilla': row[2] as String,
        'empleados': row[3] as int,
        'gasto_dia': double.tryParse(row[4].toString()) ?? 0.0,
        'promedio_empleado': double.tryParse(row[5].toString()) ?? 0.0,
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReportePorActividad: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// 4. RESUMEN GENERAL - Con fechas YYYYMMDD
  Future<Map<String, dynamic>> obtenerResumenGeneral({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      String query = '''
        SELECT 
          COUNT(DISTINCT neh.id_empleado) as total_empleados,
          COUNT(DISTINCT c.id_cuadrilla) as ranchos_activos,
          COUNT(DISTINCT to_char(neh.fecha_cierre, 'YYYYMMDD')) as dias_trabajados,
          SUM(COALESCE(neh.total, 0)) as monto_total,
          COUNT(*) as actividades_realizadas
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE 1=1
      ''';

      Map<String, dynamic> params = {};
      
      if (fechaInicio != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') >= @fechaInicio';
        params['fechaInicio'] = _formatoYYYYMMDD(fechaInicio);
      }
      
      if (fechaFin != null) {
        query += ' AND to_char(neh.fecha_cierre, \'YYYYMMDD\') <= @fechaFin';
        params['fechaFin'] = _formatoYYYYMMDD(fechaFin);
      }

      print('🔍 Ejecutando consulta resumen general: $query');
      print('📊 Parámetros: $params');

      final result = await db.connection.query(query, substitutionValues: params);

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'total_empleados': row[0] as int,
          'ranchos_activos': row[1] as int,
          'dias_trabajados': row[2] as int,
          'monto_total': double.tryParse(row[3].toString()) ?? 0.0,
          'actividades_realizadas': row[4] as int,
        };
      }

      return {
        'total_empleados': 0,
        'ranchos_activos': 0,
        'dias_trabajados': 0,
        'monto_total': 0.0,
        'actividades_realizadas': 0,
      };

    } catch (e) {
      print('❌ Error en obtenerResumenGeneral: $e');
      return {
        'total_empleados': 0,
        'ranchos_activos': 0,
        'dias_trabajados': 0,
        'monto_total': 0.0,
        'actividades_realizadas': 0,
      };
    } finally {
      await db.close();
    }
  }
}
