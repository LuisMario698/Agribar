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

Future<void> guardarEmpleadosCuadrillaSemana({
  required int semanaId,
  required int cuadrillaId,
  required List<Map<String, dynamic>> empleados,
}) async {
  final db = DatabaseService();
  await db.connect();

  // Eliminar registros anteriores de esa cuadrilla en esa semana
  await db.connection.query('''
    DELETE FROM nomina_empleados_semanal
    WHERE id_semana  = @semanaId AND id_cuadrilla = @cuadrillaId;
  ''', substitutionValues: {
    'semanaId': semanaId,
    'cuadrillaId': cuadrillaId,
  });

  // Insertar nuevos empleados
  for (final empleado in empleados) {
    await db.connection.query('''
      INSERT INTO nomina_empleados_semanal (id_semana, id_cuadrilla, id_empleado)
      VALUES (@semanaId, @cuadrillaId, @empleadoId);
    ''', substitutionValues: {
      'semanaId': semanaId,
      'cuadrillaId': cuadrillaId,
      'empleadoId': empleado['id'],
    });
  }

  await db.close();
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
