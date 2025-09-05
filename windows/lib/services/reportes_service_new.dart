import 'package:agribar/services/database_service.dart';

/// Servicio para obtener datos de reportes basados en nóminas REALES desde nomina_empleados_historial
class ReportesService {

  /// Obtener lista de ranchos reales
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
        SELECT DISTINCT nombre 
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

  /// FUNCIONES AUXILIARES para compatibilidad con código existente
  Future<List<String>> obtenerNombresActividadesDesdeBD() async {
    final actividades = await obtenerActividades();
    return actividades.where((a) => a != 'Todas').toList();
  }

  Future<List<String>> obtenerNombresCamposDesdeBD() async {
    final ranchos = await obtenerRanchos();
    return ranchos.where((r) => r != 'Todos').toList();
  }

  /// 1. REPORTE GENERAL - Datos reales de nomina_empleados_historial
  Future<List<Map<String, dynamic>>> obtenerReporteGeneral({
    String? rancho,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();

    try {
      // Consulta usando nomina_empleados_historial
      String query = '''
        SELECT 
          c.nombre as rancho_nombre,
          'Trabajo General' as actividad_nombre,
          COUNT(DISTINCT neh.fecha_cierre::date) as dias_trabajados,
          COUNT(DISTINCT neh.id_empleado) as empleados_involucrados,
          SUM(COALESCE(neh.total, 0)) as gasto_total,
          AVG(COALESCE(neh.total, 0)) as promedio
        FROM nomina_empleados_historial neh
        JOIN empleados e ON neh.id_empleado = e.id_empleado
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE 1=1
      ''';

      Map<String, dynamic> params = {};

      // Filtro por fecha si se proporciona
      if (fechaInicio != null) {
        query += ' AND neh.fecha_cierre >= @fechaInicio';
        params['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
      }
      
      if (fechaFin != null) {
        query += ' AND neh.fecha_cierre <= @fechaFin';
        params['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
      }

      // Filtro por rancho (usando cuadrilla como rancho temporalmente)
      if (rancho != null && rancho != 'Todos') {
        query += ' AND c.nombre = @rancho';
        params['rancho'] = rancho;
      }

      query += '''
        GROUP BY c.nombre
        HAVING SUM(COALESCE(neh.total, 0)) > 0
        ORDER BY gasto_total DESC;
      ''';

      print('🔍 Ejecutando consulta reporte general: $query');
      print('📊 Parámetros: $params');

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'rancho': row[0] as String,
        'actividad': row[1] as String,
        'dias_trabajados': row[2] as int,
        'empleados_involucrados': row[3] as int,
        'gasto_total': (row[4] as num).toDouble(),
        'promedio': (row[5] as num).toDouble(),
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReporteGeneral: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// 2. REPORTE POR RANCHO - Usando nomina_empleados_historial
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
          'Actividad Principal' as actividad,
          COUNT(DISTINCT neh.fecha_cierre::date) as dias,
          COUNT(DISTINCT neh.id_empleado) as empleados,
          COUNT(DISTINCT neh.id_cuadrilla) as cuadrillas,
          SUM(COALESCE(neh.total, 0)) as gasto_total,
          AVG(COALESCE(neh.total, 0)) as promedio,
          MIN(COALESCE(neh.total, 0)) as minimo,
          MAX(COALESCE(neh.total, 0)) as maximo
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE c.nombre = @rancho
      ''';

      Map<String, dynamic> params = {'rancho': rancho};

      if (fechaInicio != null) {
        query += ' AND neh.fecha_cierre >= @fechaInicio';
        params['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
      }
      
      if (fechaFin != null) {
        query += ' AND neh.fecha_cierre <= @fechaFin';
        params['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
      }

      query += '''
        GROUP BY c.nombre
        HAVING SUM(COALESCE(neh.total, 0)) > 0;
      ''';

      print('🔍 Ejecutando consulta reporte por rancho: $query');
      print('📊 Parámetros: $params');

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'actividad': row[0] as String,
        'dias': row[1] as int,
        'empleados': row[2] as int,
        'cuadrillas': row[3] as int,
        'gasto_total': (row[4] as num).toDouble(),
        'promedio': (row[5] as num).toDouble(),
        'minimo': (row[6] as num).toDouble(),
        'maximo': (row[7] as num).toDouble(),
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReportePorRancho: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// 3. REPORTE POR ACTIVIDAD - Por fecha desde nomina_empleados_historial
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
          neh.fecha_cierre::date as fecha,
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
        query += ' AND neh.fecha_cierre >= @fechaInicio';
        params['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
      }
      
      if (fechaFin != null) {
        query += ' AND neh.fecha_cierre <= @fechaFin';
        params['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
      }

      query += '''
        GROUP BY neh.fecha_cierre::date, c.nombre
        HAVING SUM(COALESCE(neh.total, 0)) > 0
        ORDER BY fecha DESC;
      ''';

      print('🔍 Ejecutando consulta reporte por actividad: $query');
      print('📊 Parámetros: $params');

      final result = await db.connection.query(query, substitutionValues: params);

      return result.map((row) => {
        'fecha': (row[0] as DateTime).toIso8601String().split('T')[0],
        'rancho': row[1] as String,
        'cuadrilla': row[2] as String,
        'empleados': row[3] as int,
        'gasto_dia': (row[4] as num).toDouble(),
        'promedio_empleado': (row[5] as num).toDouble(),
      }).toList();

    } catch (e) {
      print('❌ Error en obtenerReportePorActividad: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtener resumen general para las métricas superiores
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
          COUNT(DISTINCT neh.fecha_cierre::date) as dias_trabajados,
          SUM(COALESCE(neh.total, 0)) as monto_total,
          COUNT(*) as actividades_realizadas
        FROM nomina_empleados_historial neh
        JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
        WHERE 1=1
      ''';

      Map<String, dynamic> params = {};

      if (fechaInicio != null) {
        query += ' AND neh.fecha_cierre >= @fechaInicio';
        params['fechaInicio'] = fechaInicio.toIso8601String().split('T')[0];
      }
      
      if (fechaFin != null) {
        query += ' AND neh.fecha_cierre <= @fechaFin';
        params['fechaFin'] = fechaFin.toIso8601String().split('T')[0];
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
          'monto_total': (row[3] as num?)?.toDouble() ?? 0.0,
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
