import 'lib/services/database_service.dart';

void main() async {
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('=== Verificando estructura de datos ===');
    
    // Verificar cuadrillas existentes
    print('\n1. Cuadrillas disponibles:');
    final cuadrillas = await db.connection.query('''
      SELECT id_cuadrilla, clave, nombre 
      FROM cuadrillas 
      ORDER BY clave
      LIMIT 10
    ''');
    
    for (var c in cuadrillas) {
      print('  - ID: ${c[0]}, Clave: ${c[1]}, Nombre: ${c[2]}');
    }
    
    // Verificar datos de nómina para la semana 19
    print('\n2. Datos de nómina semana 19:');
    final nomina = await db.connection.query('''
      SELECT DISTINCT n.id_cuadrilla, c.nombre as cuadrilla_nombre, c.clave
      FROM nomina_empleados_historial n
      LEFT JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
      WHERE n.id_semana = 19 
        AND n.id_cuadrilla IS NOT NULL
      ORDER BY c.clave
      LIMIT 10
    ''');
    
    for (var n in nomina) {
      print('  - Cuadrilla ID: ${n[0]}, Nombre: ${n[1]}, Clave: ${n[2]}');
    }
    
    // Verificar actividades trabajadas en semana 19
    print('\n3. Actividades trabajadas en semana 19:');
    final actividades = await db.connection.query('''
      SELECT DISTINCT a.act_id, act.nombre
      FROM nomina_empleados_historial n
      CROSS JOIN LATERAL (
        VALUES 
          (n.act_1), (n.act_2), (n.act_3), (n.act_4),
          (n.act_5), (n.act_6), (n.act_7)
      ) AS a(act_id)
      LEFT JOIN actividades act ON act.id_actividad = a.act_id
      WHERE n.id_semana = 19 
        AND a.act_id IS NOT NULL 
        AND a.act_id <> 0
      ORDER BY act.nombre
      LIMIT 10
    ''');
    
    for (var a in actividades) {
      print('  - Actividad ID: ${a[0]}, Nombre: ${a[1]}');
    }
    
    // Probar consulta directa con una actividad real
    if (actividades.isNotEmpty) {
      final actId = actividades.first[0];
      print('\n4. Probando consulta directa para actividad ID: $actId');
      
      final resultado = await db.connection.query('''
        SELECT 
          c.clave as cuadrilla_clave,
          c.nombre as cuadrilla_nombre,
          COUNT(DISTINCT n.id_empleado) as empleados_unicos,
          SUM(a.pago) as total_pagado
        FROM nomina_empleados_historial n
        CROSS JOIN LATERAL (
          VALUES 
            (n.act_1, COALESCE(n.dia_1,0)),
            (n.act_2, COALESCE(n.dia_2,0)),
            (n.act_3, COALESCE(n.dia_3,0)),
            (n.act_4, COALESCE(n.dia_4,0)),
            (n.act_5, COALESCE(n.dia_5,0)),
            (n.act_6, COALESCE(n.dia_6,0)),
            (n.act_7, COALESCE(n.dia_7,0))
        ) AS a(act_id, pago)
        LEFT JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
        WHERE n.id_semana = 19
          AND a.act_id = $actId
          AND a.act_id IS NOT NULL 
          AND a.act_id <> 0
          AND c.id_cuadrilla IS NOT NULL
        GROUP BY c.clave, c.nombre, c.id_cuadrilla
        ORDER BY total_pagado DESC
        LIMIT 5
      ''');
      
      print('Resultados encontrados: ${resultado.length}');
      for (var r in resultado) {
        print('  - ${r[1]} (${r[0]}): ${r[2]} empleados, \$${r[3]}');
      }
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}
