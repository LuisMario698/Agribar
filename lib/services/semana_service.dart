// lib/services/semana_service.dart

import 'package:agribar/services/database_service.dart';

class SemanaService {
  /// Obtiene la semana actualmente abierta
  Future<Map<String, dynamic>?> obtenerSemanaAbierta() async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
        FROM semanas_nomina
        WHERE esta_cerrada = false
        ORDER BY creado_en DESC
        LIMIT 1;
      ''');

      if (result.isEmpty) return null;

      final row = result.first;
      print('Se obtuvo semana abierta');
      return {
        'id': row[0],
        'fechaInicio': row[1],
        'fechaFin': row[2],
        'cerrada': row[3],
      };

    } catch (e) {
      print('Error al obtener semana abierta: $e');
      return null;
    } finally {
      await db.close();
    }
  }

  /// Crea una nueva semana con validación de exactamente 7 días
  Future<Map<String, dynamic>?> crearNuevaSemana(DateTime inicio, DateTime fin) async {
    // 🎯 VALIDACIÓN: Verificar que sean exactamente 7 días
    final daysDifference = fin.difference(inicio).inDays + 1;
    if (daysDifference != 7) {
      print('❌ Error: La semana debe tener exactamente 7 días. Días proporcionados: $daysDifference');
      throw Exception('Una semana de nómina debe tener exactamente 7 días. Días proporcionados: $daysDifference');
    }

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

      if (result.isNotEmpty) {
        return {
          'id': result.first[0],
          'fechaInicio': inicio,
          'fechaFin': fin,
        };
      }
    } catch (e) {
      print('❌ Error al crear semana: $e');
      return null;
    } finally {
      await db.close();
    }

    return null;
  }

  /// Cierra una semana específica
  Future<bool> cerrarSemana(int idSemana) async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.execute('''
        UPDATE semanas_nomina
        SET esta_cerrada = true
        WHERE id_semana = @id;
      ''', substitutionValues: {
        'id': idSemana,
      });

      return result > 0;
    } catch (e) {
      print('Error al cerrar semana: $e');
      return false;
    } finally {
      await db.close();
    }
  }

  /// Verifica si hay alguna semana activa
  Future<bool> haySemanaActiva() async {
    final db = DatabaseService();
    await db.connect();

    try {
      final result = await db.connection.query('''
        SELECT COUNT(*) FROM semanas_nomina WHERE esta_cerrada = false;
      ''');

      final int count = result.first[0];
      return count > 0;
    } catch (e) {
      print('Error al verificar semana activa: $e');
      return false;
    } finally {
      await db.close();
    }
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

      return result.map((row) => {
        'id': row[0],
        'fechaInicio': row[1],
        'fechaFin': row[2],
        'creadoEn': row[3],
      }).toList();

    } catch (e) {
      print('Error al obtener todas las semanas abiertas: $e');
      return [];
    } finally {
      await db.close();
    }
  }

  /// Elimina completamente una semana de la base de datos
  static Future<bool> eliminarSemanaCompleta(int semanaId) async {
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
      return false;
    } finally {
      await db.close();
    }
  }

  /// Guarda los empleados asignados a una cuadrilla para una semana específica
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
        final id = emp['id'] ?? emp['id_empleado'];
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
}

/// Función global para mantener compatibilidad con el código existente
Future<List<Map<String, dynamic>>> obtenerTodasSemanasAbiertas() async {
  final service = SemanaService();
  return await service.obtenerTodasSemanasAbiertas();
}
