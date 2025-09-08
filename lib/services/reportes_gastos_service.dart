import '../services/database_service.dart';

class ReportesGastosService {
  /// Obtiene el reporte general de gastos por actividad para una semana específica (SIMPLIFICADO)
  Future<List<Map<String, dynamic>>> obtenerReporteGeneralPorSemana(
    int semanaId,
  ) async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      print('📊 [REPORTES SIMPLE] Generando reporte para semana $semanaId...');
      
      // 🎯 LÓGICA MUY SIMPLE: Intentar primero semanal, luego historial
      List<Map<String, dynamic>> result = [];
      
      // Intentar con tabla semanal primero
      try {
        print('🔍 [REPORTES] Intentando tabla semanal...');
        
        // 🎯 CONSULTA SIMPLE: Descomponer los datos día por día
        final resultSemanal = await db.connection.query('''
          WITH actividades_expandidas AS (
            -- Expandir datos de cada empleado día por día
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              1 as dia_num,
              n.act_1 as id_actividad,
              COALESCE(n.dia_1, 0) as pago,
              n.campo_1 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_1 IS NOT NULL AND n.act_1 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              2 as dia_num,
              n.act_2 as id_actividad,
              COALESCE(n.dia_2, 0) as pago,
              n.campo_2 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_2 IS NOT NULL AND n.act_2 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              3 as dia_num,
              n.act_3 as id_actividad,
              COALESCE(n.dia_3, 0) as pago,
              n.campo_3 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_3 IS NOT NULL AND n.act_3 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              4 as dia_num,
              n.act_4 as id_actividad,
              COALESCE(n.dia_4, 0) as pago,
              n.campo_4 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_4 IS NOT NULL AND n.act_4 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              5 as dia_num,
              n.act_5 as id_actividad,
              COALESCE(n.dia_5, 0) as pago,
              n.campo_5 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_5 IS NOT NULL AND n.act_5 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              6 as dia_num,
              n.act_6 as id_actividad,
              COALESCE(n.dia_6, 0) as pago,
              n.campo_6 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_6 IS NOT NULL AND n.act_6 > 0
            
            UNION ALL
            
            SELECT 
              n.id_empleado,
              n.id_cuadrilla,
              7 as dia_num,
              n.act_7 as id_actividad,
              COALESCE(n.dia_7, 0) as pago,
              n.campo_7 as id_rancho,
              s.fecha_inicio,
              s.fecha_fin,
              s.autorizado_por
            FROM nomina_empleados_semanal n
            JOIN semanas_nomina s ON s.id_semana = n.id_semana
            WHERE n.id_semana = @semanaId AND n.act_7 IS NOT NULL AND n.act_7 > 0
          )
          SELECT 
            COALESCE(a.nombre, 'Sin nombre') as actividad_nombre,
            a.clave as actividad_clave,
            SUM(ae.pago) as total_pagado,
            COUNT(*) as registros_totales,
            COUNT(DISTINCT ae.id_empleado) as empleados_unicos,
            COUNT(DISTINCT ae.id_cuadrilla) as cuadrillas_unicas,
            AVG(ae.pago) as promedio_pago,
            MIN(ae.pago) as pago_minimo,
            MAX(ae.pago) as pago_maximo,
            COALESCE(r.nombre, 'Sin rancho') as rancho_nombre,
            ae.fecha_inicio,
            ae.fecha_fin,
            ae.autorizado_por
          FROM actividades_expandidas ae
          LEFT JOIN actividades a ON a.id_actividad = ae.id_actividad
          LEFT JOIN ranchos r ON r.id_rancho = ae.id_rancho
          GROUP BY a.nombre, a.clave, r.nombre, ae.fecha_inicio, ae.fecha_fin, ae.autorizado_por
          ORDER BY total_pagado DESC
        ''', substitutionValues: {'semanaId': semanaId});

        print('🔍 [REPORTES] Resultados en tabla semanal: ${resultSemanal.length}');

        if (resultSemanal.isNotEmpty) {
          print('✅ [REPORTES] Usando datos de tabla semanal');
          result = resultSemanal.map((row) => {
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
          }).toList();
          
          return result;
        } else {
          print('⚠️ [REPORTES] Sin resultados en tabla semanal, intentando historial...');
        }
      } catch (e) {
        print('⚠️ [REPORTES] Error en tabla semanal: $e');
      }
      
      // Si no hay datos en semanal, intentar con historial
      try {
        print('🔍 [REPORTES] Intentando tabla historial...');
        final resultHistorial = await db.connection.query('''
          SELECT 
            a.nombre as actividad_nombre,
            a.clave as actividad_clave,
            SUM(COALESCE(h.dia_1,0) + COALESCE(h.dia_2,0) + COALESCE(h.dia_3,0) + 
                COALESCE(h.dia_4,0) + COALESCE(h.dia_5,0) + COALESCE(h.dia_6,0) + COALESCE(h.dia_7,0)) as total_pagado,
            COUNT(*) as registros_totales,
            COUNT(DISTINCT h.id_empleado) as empleados_unicos,
            COUNT(DISTINCT h.id_cuadrilla) as cuadrillas_unicas,
            AVG(COALESCE(h.dia_1,0) + COALESCE(h.dia_2,0) + COALESCE(h.dia_3,0) + 
                COALESCE(h.dia_4,0) + COALESCE(h.dia_5,0) + COALESCE(h.dia_6,0) + COALESCE(h.dia_7,0)) as promedio_pago,
            0 as pago_minimo,
            0 as pago_maximo,
            'Múltiples' as rancho_nombre,
            s.fecha_inicio,
            s.fecha_fin,
            s.autorizado_por
          FROM nomina_empleados_historial h
          JOIN semanas_nomina s ON s.id_semana = h.id_semana
          LEFT JOIN actividades a ON (a.id_actividad IN (h.act_1, h.act_2, h.act_3, h.act_4, h.act_5, h.act_6, h.act_7))
          WHERE h.id_semana = @semanaId
          AND a.nombre IS NOT NULL
          AND (
            (h.act_1 = a.id_actividad AND COALESCE(h.dia_1,0) > 0) OR
            (h.act_2 = a.id_actividad AND COALESCE(h.dia_2,0) > 0) OR
            (h.act_3 = a.id_actividad AND COALESCE(h.dia_3,0) > 0) OR
            (h.act_4 = a.id_actividad AND COALESCE(h.dia_4,0) > 0) OR
            (h.act_5 = a.id_actividad AND COALESCE(h.dia_5,0) > 0) OR
            (h.act_6 = a.id_actividad AND COALESCE(h.dia_6,0) > 0) OR
            (h.act_7 = a.id_actividad AND COALESCE(h.dia_7,0) > 0)
          )
          GROUP BY a.nombre, a.clave, s.fecha_inicio, s.fecha_fin, s.autorizado_por
          HAVING SUM(COALESCE(h.dia_1,0) + COALESCE(h.dia_2,0) + COALESCE(h.dia_3,0) + 
                     COALESCE(h.dia_4,0) + COALESCE(h.dia_5,0) + COALESCE(h.dia_6,0) + COALESCE(h.dia_7,0)) > 0
          ORDER BY total_pagado DESC
        ''', substitutionValues: {'semanaId': semanaId});

        print('✅ [REPORTES] Datos encontrados en tabla historial: ${resultHistorial.length}');
        result = resultHistorial.map((row) => {
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
        }).toList();
        
      } catch (e) {
        print('⚠️ [REPORTES] Error en tabla historial: $e');
      }
      
      print('📊 [REPORTES] Total resultados: ${result.length}');
      return result;
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
        CROSS JOIN nomina_empleados_semanal n
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
        CROSS JOIN nomina_empleados_semanal n
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
        CROSS JOIN nomina_empleados_semanal n
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

  /// Obtiene todas las semanas cerradas disponibles para reportes (FILTRA POR ACTIVIDADES VÁLIDAS)
  Future<List<Map<String, dynamic>>> obtenerSemanasDisponibles() async {
    final db = DatabaseService();
    await db.connect();
    
    try {
      print('📊 [REPORTES FILTRO] Obteniendo semanas con actividades válidas...');
      
      // 🎯 NUEVA LÓGICA: Solo semanas con actividades válidas (no NULL, no 0)
      final result = await db.connection.query('''
        SELECT DISTINCT 
          s.id_semana,
          s.fecha_inicio,
          s.fecha_fin,
          s.esta_cerrada,
          s.autorizado_por,
          s.fecha_autorizacion
        FROM semanas_nomina s
        WHERE s.esta_cerrada = true
        AND (
          -- Verificar en tabla semanal
          EXISTS (
            SELECT 1 FROM nomina_empleados_semanal n 
            WHERE n.id_semana = s.id_semana 
            AND (
              (n.act_1 IS NOT NULL AND n.act_1 > 0) OR
              (n.act_2 IS NOT NULL AND n.act_2 > 0) OR
              (n.act_3 IS NOT NULL AND n.act_3 > 0) OR
              (n.act_4 IS NOT NULL AND n.act_4 > 0) OR
              (n.act_5 IS NOT NULL AND n.act_5 > 0) OR
              (n.act_6 IS NOT NULL AND n.act_6 > 0) OR
              (n.act_7 IS NOT NULL AND n.act_7 > 0)
            )
          )
          OR
          -- Verificar en tabla historial
          EXISTS (
            SELECT 1 FROM nomina_empleados_historial h 
            WHERE h.id_semana = s.id_semana 
            AND (
              (h.act_1 IS NOT NULL AND h.act_1 > 0) OR
              (h.act_2 IS NOT NULL AND h.act_2 > 0) OR
              (h.act_3 IS NOT NULL AND h.act_3 > 0) OR
              (h.act_4 IS NOT NULL AND h.act_4 > 0) OR
              (h.act_5 IS NOT NULL AND h.act_5 > 0) OR
              (h.act_6 IS NOT NULL AND h.act_6 > 0) OR
              (h.act_7 IS NOT NULL AND h.act_7 > 0)
            )
          )
        )
        ORDER BY s.id_semana DESC
      ''');

      print('📊 [REPORTES] Semanas con actividades válidas: ${result.length}');
      
      List<Map<String, dynamic>> semanasDisponibles = [];
      
      for (var row in result) {
        final semanaId = row[0] as int;
        final fechaInicio = row[1] as DateTime;
        final fechaFin = row[2] as DateTime;
        
        // Verificar adicionalmente que tenga actividades válidas con nombres
        try {
          final verificarActividades = await db.connection.query('''
            SELECT COUNT(DISTINCT a.id_actividad)
            FROM (
              SELECT unnest(ARRAY[n.act_1, n.act_2, n.act_3, n.act_4, n.act_5, n.act_6, n.act_7]) as id_actividad
              FROM nomina_empleados_semanal n
              WHERE n.id_semana = @semanaId
              
              UNION
              
              SELECT unnest(ARRAY[h.act_1, h.act_2, h.act_3, h.act_4, h.act_5, h.act_6, h.act_7]) as id_actividad
              FROM nomina_empleados_historial h
              WHERE h.id_semana = @semanaId
            ) actividades_todas
            JOIN actividades a ON a.id_actividad = actividades_todas.id_actividad
            WHERE actividades_todas.id_actividad IS NOT NULL 
            AND actividades_todas.id_actividad > 0
            AND a.nombre IS NOT NULL
          ''', substitutionValues: {'semanaId': semanaId});
          
          final actividadesValidas = verificarActividades.first[0] as int;
          
          if (actividadesValidas > 0) {
            semanasDisponibles.add({
              'id': semanaId,
              'fecha_inicio': fechaInicio,
              'fecha_fin': fechaFin,
              'cerrada': row[3] as bool,
              'autorizado_por': row[4] as String?,
              'fecha_autorizacion': row[5] as DateTime?,
              'nombre': '${_formatearFecha(fechaInicio)} - ${_formatearFecha(fechaFin)}'
            });
            print('✅ [REPORTES] Semana $semanaId incluida ($actividadesValidas actividades válidas)');
          } else {
            print('⚠️ [REPORTES] Semana $semanaId excluida (sin actividades válidas)');
          }
        } catch (e) {
          print('⚠️ [REPORTES] Error verificando semana $semanaId: $e');
        }
      }
      
      print('📊 [REPORTES] Total semanas disponibles para reportes: ${semanasDisponibles.length}');
      return semanasDisponibles;
      
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
        INNER JOIN nomina_empleados_semanal n ON n.id_semana = s.id_semana
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
        LEFT JOIN nomina_empleados_semanal n ON n.id_semana = s.id_semana
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
        CROSS JOIN nomina_empleados_semanal n
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
