// lib/services/database_service.dart
import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection _connection;

  Future<void> connect() async {
    try {
      _connection = PostgreSQLConnection(
        'localhost',  // Host
        5432,
        'AGRIBAR',
        username: 'postgres',
        password: 'admin',
      );
      await _connection.open();
    } catch (e) {
      print('❌ Error al conectar con PostgreSQL: $e');
      rethrow;
    }
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> close() async {
    try {
      if (_connection.isClosed) {
        return;
      }
      await _connection.close();
    } catch (e) {
      print('❌ Error al cerrar conexión: $e');
    }
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
        e.nombre ||' '|| e.apellido_paterno ||' '|| e.apellido_materno as nombre,
        'ID: ' ||CAST(dl.id_empleado AS TEXT) ||' Puesto '|| dl.puesto as puesto,
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

