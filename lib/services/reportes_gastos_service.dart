import '../services/database_service.dart';

class ReportesGastosService {
  /// Obtiene el reporte general de gastos por actividad para una semana específica (versión mejorada)
  Future<List<Map<String, dynamic>>> obtenerReporteGeneralPorSemana(
    int semanaId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          act.nombre as actividad_nombre,
          act.clave as actividad_clave,
          SUM(a.pago) as total_pagado,
          COUNT(*) as registros_totales,
          COUNT(DISTINCT n.id_empleado) as empleados_unicos,
          COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_unicas,
          AVG(a.pago) as promedio_pago,
          MIN(a.pago) as pago_minimo,
          MAX(a.pago) as pago_maximo,
          r.nombre as rancho_nombre,
          sn.fecha_inicio,
          sn.fecha_fin,
          sn.autorizado_por,
          COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago,
          COUNT(CASE WHEN a.pago = 0 THEN 1 END) as registros_sin_pago,
          STRING_AGG(DISTINCT c.nombre, ', ') as cuadrillas_nombres,
          ROUND((COUNT(CASE WHEN a.pago > 0 THEN 1 END) * 100.0 / COUNT(*)), 1) as eficiencia_porcentaje,
          ROUND((SUM(a.pago) / COUNT(DISTINCT n.id_empleado)), 2) as productividad_por_empleado,
          ROUND((COUNT(*) / NULLIF(COUNT(DISTINCT n.id_cuadrilla), 0)), 1) as carga_por_cuadrilla
        FROM semanas_nomina sn
        CROSS JOIN nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        LEFT JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
        WHERE n.id_semana = sn.id_semana
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND sn.id_semana = @semanaId
        GROUP BY act.nombre, act.clave, r.nombre, sn.fecha_inicio, sn.fecha_fin, sn.autorizado_por
        ORDER BY total_pagado DESC
      ''', substitutionValues: {
        'semanaId': semanaId,
      });

      return result.map((row) => {
        'actividad_nombre': row[0] as String,
        'actividad_clave': row[1] as String?,
        'total_pagado': double.tryParse(row[2].toString()) ?? 0.0,
        'registros_totales': row[3] as int,
        'empleados_unicos': row[4] as int,
        'cuadrillas_unicas': row[5] as int,
        'promedio_pago': double.tryParse(row[6].toString()) ?? 0.0,
        'pago_minimo': double.tryParse(row[7].toString()) ?? 0.0,
        'pago_maximo': double.tryParse(row[8].toString()) ?? 0.0,
        'rancho_nombre': row[9] as String?,
        'fecha_inicio': row[10] as DateTime?,
        'fecha_fin': row[11] as DateTime?,
        'autorizado_por': row[12] as String?,
        'registros_con_pago': row[13] as int,
        'registros_sin_pago': row[14] as int,
        'cuadrillas_nombres': row[15] as String?,
        'eficiencia_porcentaje': double.tryParse(row[16].toString()) ?? 0.0,
        'productividad_por_empleado': double.tryParse(row[17].toString()) ?? 0.0,
        'carga_por_cuadrilla': double.tryParse(row[18].toString()) ?? 0.0,
      }).toList();
    } catch (e) {
      print('Error al obtener reporte general: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene el reporte por rancho específico (versión mejorada)
  Future<List<Map<String, dynamic>>> obtenerReportePorRancho(
    int semanaId,
    int ranchoId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          act.nombre as actividad_nombre,
          act.clave as actividad_clave,
          SUM(a.pago) as total_pagado,
          COUNT(*) as registros_totales,
          COUNT(DISTINCT n.id_empleado) as empleados_unicos,
          COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_unicas,
          AVG(a.pago) as promedio_pago,
          MIN(a.pago) as pago_minimo,
          MAX(a.pago) as pago_maximo,
          r.nombre as rancho_nombre,
          COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago,
          COUNT(CASE WHEN a.pago = 0 THEN 1 END) as registros_sin_pago,
          ROUND((COUNT(CASE WHEN a.pago > 0 THEN 1 END) * 100.0 / COUNT(*)), 1) as eficiencia_porcentaje,
          ROUND((SUM(a.pago) / COUNT(DISTINCT n.id_empleado)), 2) as productividad_por_empleado
        FROM semanas_nomina sn
        CROSS JOIN nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        WHERE n.id_semana = sn.id_semana
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND sn.id_semana = @semanaId
          AND a.rancho_id = @ranchoId
        GROUP BY act.nombre, act.clave, r.nombre
        ORDER BY total_pagado DESC
      ''', substitutionValues: {
        'semanaId': semanaId,
        'ranchoId': ranchoId,
      });

      return result.map((row) => {
        'actividad_nombre': row[0] as String,
        'actividad_clave': row[1] as String?,
        'total_pagado': double.tryParse(row[2].toString()) ?? 0.0,
        'registros_totales': row[3] as int,
        'empleados_unicos': row[4] as int,
        'cuadrillas_unicas': row[5] as int,
        'promedio_pago': double.tryParse(row[6].toString()) ?? 0.0,
        'pago_minimo': double.tryParse(row[7].toString()) ?? 0.0,
        'pago_maximo': double.tryParse(row[8].toString()) ?? 0.0,
        'rancho_nombre': row[9] as String?,
        'registros_con_pago': row[10] as int,
        'registros_sin_pago': row[11] as int,
        'eficiencia_porcentaje': double.tryParse(row[12].toString()) ?? 0.0,
        'productividad_por_empleado': double.tryParse(row[13].toString()) ?? 0.0,
      }).toList();
    } catch (e) {
      print('Error al obtener reporte por rancho: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene el reporte por actividad específica agrupado por cuadrilla
  Future<List<Map<String, dynamic>>> obtenerReportePorActividad(
    int semanaId,
    int actividadId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          c.clave as cuadrilla_clave,
          c.nombre as cuadrilla_nombre,
          SUM(a.pago) as total_pagado,
          COUNT(*) as registros_totales,
          COUNT(DISTINCT n.id_empleado) as empleados_unicos,
          AVG(a.pago) as promedio_pago,
          MIN(a.pago) as pago_minimo,
          MAX(a.pago) as pago_maximo,
          COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago,
          COUNT(CASE WHEN a.pago = 0 THEN 1 END) as registros_sin_pago,
          ROUND((COUNT(CASE WHEN a.pago > 0 THEN 1 END) * 100.0 / COUNT(*)), 1) as eficiencia_porcentaje,
          STRING_AGG(DISTINCT r.nombre, ', ') as ranchos_trabajados
        FROM semanas_nomina sn
        CROSS JOIN nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        LEFT JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
        WHERE n.id_semana = sn.id_semana
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND sn.id_semana = @semanaId
          AND a.act_id = @actividadId
          AND c.id_cuadrilla IS NOT NULL
        GROUP BY c.clave, c.nombre, c.id_cuadrilla
        ORDER BY total_pagado DESC
      ''', substitutionValues: {
        'semanaId': semanaId,
        'actividadId': actividadId,
      });

      return result.map((row) => {
        'cuadrilla_clave': row[0] as String?,
        'cuadrilla_nombre': row[1] as String?,
        'total_pagado': double.tryParse(row[2].toString()) ?? 0.0,
        'registros_totales': row[3] as int,
        'empleados_unicos': row[4] as int,
        'promedio_pago': double.tryParse(row[5].toString()) ?? 0.0,
        'pago_minimo': double.tryParse(row[6].toString()) ?? 0.0,
        'pago_maximo': double.tryParse(row[7].toString()) ?? 0.0,
        'registros_con_pago': row[8] as int,
        'registros_sin_pago': row[9] as int,
        'eficiencia_porcentaje': double.tryParse(row[10].toString()) ?? 0.0,
        'ranchos_trabajados': row[11] as String?,
      }).toList();
    } catch (e) {
      print('Error al obtener reporte por actividad: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene el resumen de ranchos que trabajaron en una actividad específica
  Future<List<Map<String, dynamic>>> obtenerResumenRanchosPorActividad(
    int semanaId,
    int actividadId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          r.nombre as rancho_nombre,
          SUM(a.pago) as total_ganancia,
          COUNT(DISTINCT n.id_empleado) as empleados_trabajaron,
          COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_trabajaron,
          COUNT(*) as actividades_realizadas,
          AVG(a.pago) as promedio_pago,
          COUNT(CASE WHEN a.pago > 0 THEN 1 END) as registros_con_pago
        FROM semanas_nomina sn
        CROSS JOIN nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        WHERE n.id_semana = sn.id_semana
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND sn.id_semana = @semanaId
          AND a.act_id = @actividadId
          AND r.id_rancho IS NOT NULL
        GROUP BY r.nombre, r.id_rancho
        ORDER BY total_ganancia DESC
      ''', substitutionValues: {
        'semanaId': semanaId,
        'actividadId': actividadId,
      });

      return result.map((row) => {
        'rancho_nombre': row[0] as String?,
        'total_ganancia': double.tryParse(row[1].toString()) ?? 0.0,
        'empleados_trabajaron': row[2] as int,
        'cuadrillas_trabajaron': row[3] as int,
        'actividades_realizadas': row[4] as int,
        'promedio_pago': double.tryParse(row[5].toString()) ?? 0.0,
        'registros_con_pago': row[6] as int,
      }).toList();
    } catch (e) {
      print('Error al obtener resumen de ranchos por actividad: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene todas las semanas cerradas disponibles para reportes
  Future<List<Map<String, dynamic>>> obtenerSemanasDisponibles() async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
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

      return result.map((row) => {
        'id': row[0] as int,
        'fecha_inicio': row[1] as DateTime,
        'fecha_fin': row[2] as DateTime,
        'cerrada': row[3] as bool,
        'autorizado_por': row[4] as String?,
        'fecha_autorizacion': row[5] as DateTime?,
        'nombre': '${_formatearFecha(row[1] as DateTime)} - ${_formatearFecha(row[2] as DateTime)}'
      }).toList();
    } catch (e) {
      print('Error al obtener semanas: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene todos los ranchos disponibles
  Future<List<Map<String, dynamic>>> obtenerRanchosDisponibles() async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          id_rancho,
          nombre
        FROM ranchos
        ORDER BY nombre
      ''');

      return result.map((row) => {
        'id': row[0] as int,
        'nombre': row[1] as String,
      }).toList();
    } catch (e) {
      print('Error al obtener ranchos: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene todas las actividades disponibles
  Future<List<Map<String, dynamic>>> obtenerActividadesDisponibles() async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          a.id_actividad,
          a.nombre,
          a.clave
        FROM actividades a
        WHERE a.nombre IS NOT NULL AND a.nombre <> ''
        ORDER BY a.nombre
      ''');

      return result.map((row) => {
        'id': row[0] as int,
        'nombre': row[1] as String,
        'clave': row[2] as String?,
      }).toList();
    } catch (e) {
      print('Error al obtener actividades: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene reportes filtrados por múltiples criterios
  Future<List<Map<String, dynamic>>> obtenerReporteConFiltros({
    required int semanaId,
    int? ranchoId,
    int? actividadId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      // Construir los parámetros dinámicamente
      final params = <String, dynamic>{'semanaId': semanaId};
      String whereClause = '';
      
      if (fechaInicio != null && fechaFin != null) {
        whereClause += ' AND s.fecha_inicio >= @fechaInicio AND s.fecha_fin <= @fechaFin';
        params['fechaInicio'] = fechaInicio;
        params['fechaFin'] = fechaFin;
      }
      
      // Usar variables para simplificar la consulta
      final ranchoFilter = ranchoId;
      final actividadFilter = actividadId;
      params['ranchoFilter'] = ranchoFilter;
      params['actividadFilter'] = actividadFilter;

      final result = await db.connection.query('''
        SELECT 
          act.nombre as actividad_nombre,
          act.clave as actividad_clave,
          SUM(a.pago) as total_pagado,
          COUNT(*) as registros,
          s.fecha_inicio,
          s.fecha_fin,
          r.nombre as rancho_nombre,
          s.autorizado_por
        FROM semanas_nomina s
        INNER JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
        CROSS JOIN LATERAL (
          VALUES
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        WHERE a.act_id IS NOT NULL AND a.act_id <> 0
          AND s.esta_cerrada = true
          AND (@ranchoFilter IS NULL OR a.rancho_id = @ranchoFilter)
          AND (@actividadFilter IS NULL OR a.act_id = @actividadFilter)
          $whereClause
        GROUP BY act.nombre, act.clave, s.fecha_inicio, s.fecha_fin, r.nombre, s.autorizado_por
        ORDER BY total_pagado DESC
      ''', substitutionValues: params);

      return result.map((row) => {
        'actividad_nombre': row[0] as String,
        'actividad_clave': row[1] as String?,
        'total_pagado': double.tryParse(row[2].toString()) ?? 0.0,
        'registros': row[3] as int,
        'fecha_inicio': row[4] as DateTime,
        'fecha_fin': row[5] as DateTime,
        'rancho_nombre': row[6] as String? ?? 'Sin rancho',
        'autorizado_por': row[7] as String?,
      }).toList();
    } catch (e) {
      print('Error al obtener reporte con filtros: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene un resumen de todas las semanas con sus totales
  Future<List<Map<String, dynamic>>> obtenerResumenSemanas() async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          s.id_semana,
          s.fecha_inicio,
          s.fecha_fin,
          s.autorizado_por,
          SUM(COALESCE(n.dia_1,0) + COALESCE(n.dia_2,0) + COALESCE(n.dia_3,0) + 
              COALESCE(n.dia_4,0) + COALESCE(n.dia_5,0) + COALESCE(n.dia_6,0) + 
              COALESCE(n.dia_7,0)) as total_semana,
          COUNT(DISTINCT n.id_empleado) as total_empleados,
          COUNT(DISTINCT n.cuadrilla) as total_cuadrillas
        FROM semanas_nomina s
        LEFT JOIN nomina_empleados_historial n ON n.id_semana = s.id_semana
        WHERE s.esta_cerrada = true
        GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.autorizado_por
        ORDER BY s.fecha_inicio DESC
      ''');

      return result.map((row) => {
        'id_semana': row[0] as int,
        'fecha_inicio': row[1] as DateTime,
        'fecha_fin': row[2] as DateTime,
        'autorizado_por': row[3] as String?,
        'total_semana': double.tryParse(row[4].toString()) ?? 0.0,
        'total_empleados': row[5] as int,
        'total_cuadrillas': row[6] as int,
        'nombre_semana': '${_formatearFecha(row[1] as DateTime)} - ${_formatearFecha(row[2] as DateTime)}'
      }).toList();
    } catch (e) {
      print('Error al obtener resumen de semanas: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Obtiene resumen agrupado por ranchos para una semana específica
  Future<List<Map<String, dynamic>>> obtenerResumenPorRanchos(
    int semanaId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      final result = await db.connection.query('''
        SELECT 
          r.nombre as rancho_nombre,
          SUM(a.pago) as total_ganancia,
          COUNT(DISTINCT n.id_empleado) as empleados_trabajaron,
          COUNT(DISTINCT a.act_id) as actividades_realizadas,
          COUNT(DISTINCT n.id_cuadrilla) as cuadrillas_trabajaron,
          COUNT(*) as registros_totales,
          AVG(a.pago) as promedio_ganancia,
          r.id_rancho
        FROM semanas_nomina sn
        CROSS JOIN nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0), n.campo_1),
            (n.act_2, COALESCE(n.dia_2,0), n.campo_2),
            (n.act_3, COALESCE(n.dia_3,0), n.campo_3),
            (n.act_4, COALESCE(n.dia_4,0), n.campo_4),
            (n.act_5, COALESCE(n.dia_5,0), n.campo_5),
            (n.act_6, COALESCE(n.dia_6,0), n.campo_6),
            (n.act_7, COALESCE(n.dia_7,0), n.campo_7)
        ) AS a(act_id, pago, rancho_id)
        LEFT JOIN actividades act ON act.id_actividad = a.act_id
        LEFT JOIN ranchos r ON r.id_rancho = a.rancho_id
        WHERE n.id_semana = sn.id_semana
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND sn.id_semana = @semanaId
          AND r.nombre IS NOT NULL
        GROUP BY r.id_rancho, r.nombre
        ORDER BY total_ganancia DESC
      ''', substitutionValues: {
        'semanaId': semanaId,
      });

      return result.map((row) => {
        'rancho_nombre': row[0] as String,
        'total_ganancia': double.tryParse(row[1].toString()) ?? 0.0,
        'empleados_trabajaron': row[2] as int,
        'actividades_realizadas': row[3] as int,
        'cuadrillas_trabajaron': row[4] as int,
        'registros_totales': row[5] as int,
        'promedio_ganancia': double.tryParse(row[6].toString()) ?? 0.0,
        'rancho_id': row[7] as int,
      }).toList();
    } catch (e) {
      print('Error al obtener resumen por ranchos: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Formatea una fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
