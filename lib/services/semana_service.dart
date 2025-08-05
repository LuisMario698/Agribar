// lib/services/semana_service.dart

import 'package:agribar/services/database_service.dart';

class SemanaService {
  Future<Map<String, dynamic>?> obtenerSemanaAbierta() async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin
        FROM semanas_nomina
        WHERE esta_cerrada = false
        LIMIT 1;
      ''');

      if (result.isEmpty) return null;

      final row = result.first;
       print('Se obtuvo semana abierta');
      return {
        'id': row[0],
        'inicio': row[1],
        'fin': row[2],
      
      };

    } catch (e) {
      print('Error al obtener semana abierta: \$e');
      return null;
    } finally {
      await db.close();
    }
  }

Future<Map<String, dynamic>?> crearNuevaSemana(DateTime inicio, DateTime fin) async {
  final db = DatabaseService();
  await db.connect();

  try {
    final result = await db.connection.query('''
      INSERT INTO semanas_nomina (fecha_inicio, fecha_fin, esta_cerrada, creado_en)
      VALUES (@inicio, @fin, false, NOW())
      RETURNING id_semana;
    ''', substitutionValues: {
      'inicio': inicio.toIso8601String().substring(0, 10),
      'fin': fin.toIso8601String().substring(0, 10),
    });

    await db.close();

    if (result.isNotEmpty) {
      return {
        'id': result.first[0],
        'fechaInicio': inicio,
        'fechaFin': fin,
      };
    }
  } catch (e) {
    print('❌ Error al crear semana: $e');
    await db.close();
    return null;
  }

  return null;
}

  Future<bool> cerrarSemana(int idSemana) async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.execute('''
        UPDATE semanas_nomina
        SET cerrada = true
        WHERE id_semana = @id;
      ''', substitutionValues: {
        'id': idSemana,
      });

      return result > 0;
    } catch (e) {
      print('Error al cerrar semana: \$e');
      return false;
    } finally {
      await db.close();
    }
  }
}
Future<Map<String, dynamic>?> crearNuevaSemana(DateTime inicio, DateTime fin) async {
  final db = DatabaseService();
  await db.connect();

  try {
    final result = await db.connection.query('''
      INSERT INTO semanas_nomina (fecha_inicio, fecha_fin, esta_cerrada, creado_en)
      VALUES (@inicio, @fin, false, NOW())
      RETURNING id_semana;
    ''', substitutionValues: {
      'inicio': inicio.toIso8601String().substring(0, 10),
      'fin': fin.toIso8601String().substring(0, 10),
    });

    await db.close();

    if (result.isNotEmpty) {
      return {
        'id': result.first[0],
        'fechaInicio': inicio,
        'fechaFin': fin,
      };
    }
  } catch (e) {
    print('❌ Error al crear semana: $e');
    await db.close();
    return null;
  }

  return null;
}
Future<bool> haySemanaActiva() async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT COUNT(*) FROM semanas_nomina WHERE esta_cerrada = false;
  ''');

  await db.close();

  final int count = result.first[0];
  return count > 0;
}

Future<Map<String, dynamic>?>   obtenerSemanaAbierta() async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
 SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
    FROM semanas_nomina
    WHERE esta_cerrada = false
    ORDER BY creado_en DESC
    LIMIT 1;
  ''');

  await db.close();

  if (result.isEmpty) return null;

  final row = result.first;
  return {
    'id': row[0],
    'fechaInicio': row[1],
    'fechaFin': row[2],
    'cerrada': row[3],
  };
}

/// Obtiene todas las semanas abiertas/activas
Future<List<Map<String, dynamic>>> obtenerTodasSemanasAbiertas() async {
  final db = DatabaseService();
  await db.connect();

  try {
    final result = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, creado_en
      FROM semanas_nomina
      WHERE esta_cerrada = false
      ORDER BY fecha_inicio DESC;
    ''');

    await db.close();

    return result.map((row) => {
      'id': row[0],
      'fechaInicio': row[1],
      'fechaFin': row[2],
      'creadoEn': row[3],
    }).toList();

  } catch (e) {
    print('Error al obtener todas las semanas abiertas: $e');
    await db.close();
    return [];
  }
}

/// Elimina completamente una semana de la base de datos
Future<bool> eliminarSemanaCompleta(int semanaId) async {
  final db = DatabaseService();
  await db.connect();

  try {
    // Iniciar transacción para asegurar que todo se elimine correctamente
    await db.connection.query('BEGIN');

    // 1. Eliminar todos los registros de nómina de empleados de esta semana
    await db.connection.query('''
      DELETE FROM nomina_empleados_semanal 
      WHERE id_semana = @semanaId;
    ''', substitutionValues: {'semanaId': semanaId});

    // 2. Eliminar la semana de la tabla principal
    final result = await db.connection.query('''
      DELETE FROM semanas_nomina 
      WHERE id_semana = @semanaId;
    ''', substitutionValues: {'semanaId': semanaId});

    // Confirmar transacción
    await db.connection.query('COMMIT');

    await db.close();

    // Verificar si se eliminó alguna fila
    return result.affectedRowCount > 0;

  } catch (e) {
    // Hacer rollback en caso de error
    try {
      await db.connection.query('ROLLBACK');
    } catch (rollbackError) {
      print('Error en rollback: $rollbackError');
    }
    
    print('Error al eliminar semana completa: $e');
    await db.close();
    return false;
  }
}

Future<void> guardarEmpleadosCuadrillaSemana({
  required int semanaId,
  required int cuadrillaId,
  required List<Map<String, dynamic>> empleados,
}) async {
  final db = DatabaseService();
  await db.connect();

  try {
    // 🔧 OBTENER empleados actuales en la BD para esta cuadrilla
    final empleadosActualesResult = await db.connection.query('''
      SELECT id_empleado
      FROM nomina_empleados_semanal
      WHERE id_semana = @semanaId AND id_cuadrilla = @cuadrillaId;
    ''', substitutionValues: {
      'semanaId': semanaId,
      'cuadrillaId': cuadrillaId,
    });
    
    // Convertir a Set para facilitar comparaciones
    final empleadosEnBD = empleadosActualesResult.map((row) => row[0] as int).toSet();
    final empleadosNuevos = empleados.map((emp) {
      // Manejar tanto int como string
      final id = emp['id'];
      if (id is int) return id;
      if (id is String) return int.parse(id);
      return -1; // Valor por defecto si no es int ni string
    }).toSet();
    
    // 🔧 IDENTIFICAR empleados a agregar (están en la lista nueva pero no en BD)
    final empleadosAAgregar = empleadosNuevos.difference(empleadosEnBD);
    
    // 🔧 IDENTIFICAR empleados a eliminar (están en BD pero no en la lista nueva)
    final empleadosAEliminar = empleadosEnBD.difference(empleadosNuevos);
    
    print('📊 Cuadrilla $cuadrillaId - En BD: ${empleadosEnBD.length}, Nuevos: ${empleadosNuevos.length}');
    print('   ➕ A agregar: ${empleadosAAgregar.length} empleados');
    print('   ➖ A eliminar: ${empleadosAEliminar.length} empleados');
    
    // 🔧 ELIMINAR solo los empleados que fueron removidos de la cuadrilla
    if (empleadosAEliminar.isNotEmpty) {
      for (final empleadoId in empleadosAEliminar) {
        await db.connection.execute('''
          DELETE FROM nomina_empleados_semanal 
          WHERE id_semana = @semanaId AND id_cuadrilla = @cuadrillaId AND id_empleado = @empleadoId;
        ''', substitutionValues: {
          'semanaId': semanaId,
          'cuadrillaId': cuadrillaId,
          'empleadoId': empleadoId,
        });
      }
      print('   🗑️ Eliminados ${empleadosAEliminar.length} empleados de la BD');
    }
    
    // 🔧 AGREGAR solo los empleados nuevos
    if (empleadosAAgregar.isNotEmpty) {
      for (final empleadoId in empleadosAAgregar) {
        await db.connection.execute('''
          INSERT INTO nomina_empleados_semanal (id_semana, id_cuadrilla, id_empleado)
          VALUES (@semanaId, @cuadrillaId, @empleadoId);
        ''', substitutionValues: {
          'semanaId': semanaId,
          'cuadrillaId': cuadrillaId,
          'empleadoId': empleadoId,
        });
      }
      print('   ➕ Agregados ${empleadosAAgregar.length} empleados nuevos a la BD');
    }
    
    // Los empleados que ya estaban en la BD mantienen todos sus datos de nómina
    final empleadosConservados = empleadosEnBD.intersection(empleadosNuevos);
    if (empleadosConservados.isNotEmpty) {
      print('   💾 Conservados ${empleadosConservados.length} empleados con sus datos de nómina');
    }
    
    print('✅ Cuadrilla $cuadrillaId actualizada correctamente sin perder datos de nómina');
  } catch (e) {
    print('❌ Error al guardar cuadrilla: $e');
    rethrow; // Relanzar la excepción para que el llamador pueda manejarla
  } finally {
    await db.close();
  }
}
Future<List<Map<String, dynamic>>> obtenerCuadrillasDeSemana(int semanaId) async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT c.id_cuadrilla, c.nombre
    FROM cuadrillas c
    JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla
    WHERE nes.id_semana = @id_semana
    GROUP BY c.id_cuadrilla, c.nombre
    ORDER BY c.nombre;
  ''', substitutionValues: {
    'semanaId': semanaId,
  });

  await db.close();

  return result.map((row) => {
    'id': row[0],
    'nombre': row[1],
  }).toList();
}

Future<List<Map<String, dynamic>>> obtenerNominaEmpleadosDeCuadrilla(int semanaId, int cuadrillaId) async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT 
      e.id_empleado,
      e.nombre,
      e.codigo,
      n.dia_1,
      n.dia_2,
      n.dia_3,
      n.dia_4,
      n.dia_5,
      n.dia_6,
      n.dia_7,
      n.act_1,
      n.act_2,
      n.act_3,
      n.act_4,
      n.act_5,
      n.act_6,
      n.act_7,
      n.campo_1,
      n.campo_2,
      n.campo_3,
      n.campo_4,
      n.campo_5,
      n.campo_6,
      n.campo_7,
      n.total,
      n.debe,
      n.subtotal,
      n.comedor,
      n.total_neto
    FROM nomina_empleados_semanal n
    JOIN empleados e ON e.id_empleado = n.id_empleado
    WHERE n.id_semana = @semanaId AND n.id_cuadrilla = @cuadrillaId;
  ''', substitutionValues: {
    'semanaId': semanaId,
    'cuadrillaId': cuadrillaId,
  });

  await db.close();

  return result.map((row) => {
    'id': row[0],
    'nombre': row[1],
    'codigo': row[2],
    // Salarios por día (día 0 = primer día, etc.)
    'dia_0_s': row[3],  // dia_1 en BD
    'dia_1_s': row[4],  // dia_2 en BD
    'dia_2_s': row[5],  // dia_3 en BD
    'dia_3_s': row[6],  // dia_4 en BD
    'dia_4_s': row[7],  // dia_5 en BD
    'dia_5_s': row[8],  // dia_6 en BD
    'dia_6_s': row[9],  // dia_7 en BD
    // IDs de actividad por día
    'dia_0_id': row[10], // act_1 en BD
    'dia_1_id': row[11], // act_2 en BD
    'dia_2_id': row[12], // act_3 en BD
    'dia_3_id': row[13], // act_4 en BD
    'dia_4_id': row[14], // act_5 en BD
    'dia_5_id': row[15], // act_6 en BD
    'dia_6_id': row[16], // act_7 en BD
    // IDs de campo/rancho por día
    'dia_0_campo': row[17], // campo_1 en BD
    'dia_1_campo': row[18], // campo_2 en BD
    'dia_2_campo': row[19], // campo_3 en BD
    'dia_3_campo': row[20], // campo_4 en BD
    'dia_4_campo': row[21], // campo_5 en BD
    'dia_5_campo': row[22], // campo_6 en BD
    'dia_6_campo': row[23], // campo_7 en BD
    // Totales
    'total': row[24],
    'debe': row[25],
    'subtotal': row[26],
    'comedor': row[27],
    'totalNeto': row[28],
  }).toList();
}
