// lib/services/database_service.dart
import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection _connection;

  Future<void> connect() async {
    _connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );
    await _connection.open();
    print('✅ Conexión establecida con PostgreSQL');
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> close() async {
    await _connection.close();
    print('❌ Conexión cerrada');
  }
}
Future<List<Map<String, dynamic>>> obtenerCuadrillasHabilitadas() async {
  final db = DatabaseService();
  await db.connect();

  final results = await db.connection.query('''
    SELECT id_cuadrilla, nombre
    FROM cuadrillas
    WHERE estado = true
    ORDER BY nombre;
  ''');

  await db.close();

  return results.map((row) => {
    'id': row[0],
    'nombre': row[1],
    'empleados': [],
  }).toList();
}

Future<List<Map<String, dynamic>>> obtenerEmpleadosHabilitados() async {
  final db = DatabaseService();

  try {
    await db.connect();

    final results = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre,
        dl.puesto,
        e.curp,
        e.rfc,
        e.nss,
        e.estado_origen,
        dl.tipo,
        e.codigo
      FROM empleados e
      JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado
      WHERE dl.deshabilitado = false;
    ''');

    await db.close();

    return results.map((row) => {
      'id': row[0].toString(),
      'nombre': row[1],
      'puesto': row[2],
      'curp': row[3],
      'rfc': row[4],
      'nss': row[5],
      'lugarProcedencia': row[6],
      'tipoEmpleado': row[7],
      'numeroEmpleado': row[8],
      'seleccionado': false,
    }).toList();
  } catch (e) {
    print('❌ Error al obtener empleados habilitados: $e');
    await db.close();
    return [];
  }
}


class NominaLogic {
  // Verifica si hay una semana abierta
  Future<Map<String, dynamic>?> obtenerSemanaAbierta() async {
    final db = DatabaseService();
    await db.connect();

    final result = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin
      FROM semanas_nomina
      WHERE esta_cerrada = false
      ORDER BY fecha_inicio DESC
      LIMIT 1;
    ''');

    await db.close();

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id_semana': row[0],
      'fecha_inicio': row[1],
      'fecha_fin': row[2],
    };
  }

  // Guarda una nueva semana abierta
  Future<int?> crearSemana(DateTime inicio, DateTime fin) async {
    final db = DatabaseService();
    await db.connect();

    final result = await db.connection.query('''
      INSERT INTO semanas_nomina (fecha_inicio, fecha_fin, esta_cerrada)
      VALUES (@inicio, @fin, false)
      RETURNING id_semana;
    ''', substitutionValues: {
      'inicio': inicio.toIso8601String(),
      'fin': fin.toIso8601String(),
    });

    await db.close();
    return result.isNotEmpty ? result.first[0] : null;
  }

  // Cierra la semana actual (requiere validación previa del supervisor)
  Future<void> cerrarSemana(int idSemana) async {
    final db = DatabaseService();
    await db.connect();

    await db.connection.query('''
      UPDATE semanas_nomina
      SET esta_cerrada = true
      WHERE id_semana = @id;
    ''', substitutionValues: {
      'id': idSemana,
    });

    await db.close();
  }
}
