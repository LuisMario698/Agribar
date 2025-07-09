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

  return results
      .map((row) => {'id': row[0], 'nombre': row[1], 'empleados': []})
      .toList();
}

Future<List<Map<String, dynamic>>> obtenerEmpleadosHabilitados() async {
  final db = DatabaseService();

  try {
    await db.connect();

    final results = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre ||' '|| e.apellido_paterno ||' '|| e.apellido_materno as nombre,
        e.curp,
        e.rfc,
        e.nss,
        e.estado_origen,
        e.codigo
      FROM empleados e

    ''');
    
    await db.close();

    final empleadosList = results
        .map(
          (row) => {
            'id': row[0].toString(),
            'nombre': row[1],
            'curp': row[2],
            'rfc': row[3],
            'nss': row[4],
            'lugarProcedencia': row[5],
            'numeroEmpleado': row[6],
            'seleccionado': false,
          },
        )
        .toList();
        
    return empleadosList;
  } catch (e) {
    print('❌ Error al obtener empleados habilitados: $e');
    await db.close();
    return [];
  }
}

Future<List<Map<String, String>>> obtenerReportePorCuadrilla() async {
  final db = DatabaseService();
  await db.connect();

  final results = await db.connection.mappedResultsQuery('''
       SELECT 
      c.id_cuadrilla,
      c.nombre AS cuadrilla,
      SUM(n.total) AS suma
    FROM nomina_empleados_historial n
    JOIN cuadrillas c ON c.id_cuadrilla = n.id_cuadrilla
    GROUP BY c.id_cuadrilla, c.nombre
    ORDER BY c.nombre;
    ''');

  await db.close();

  return results.map<Map<String, String>>((row) {
    final flatRow = {...?row['cuadrillas'], ...?row['']}; // Une los dos mapas

    return {
      'id_cuadrilla': '${flatRow['id_cuadrilla']}',
      'cuadrilla': '${flatRow['cuadrilla'] ?? ''}',
      'total': '${flatRow['suma'] ?? '0'}',
    };
  }).toList();
}

Future<List<Map<String, String>>> obtenerReportePorEmpleado() async {
  final db = DatabaseService();
  await db.connect();

  final results = await db.connection.mappedResultsQuery('''
    SELECT 
      e.id_empleado,
      e.codigo,
      CONCAT(e.nombre, ' ', e.apellido_paterno, ' ', e.apellido_materno) AS nombre,
      n.fecha_cierre,
      n.total AS suma
    FROM nomina_empleados_historial n
    JOIN empleados e ON e.id_empleado = n.id_empleado
    ORDER BY e.nombre
  ''');

  await db.close();

  return results.map<Map<String, String>>((row) {
    // Une los submapas en uno solo
    final flatRow = row.entries
        .expand((entry) => entry.value.entries)
        .fold<Map<String, dynamic>>({}, (acc, entry) {
          acc[entry.key] = entry.value;
          return acc;
        });

    return {
      'id_empleado': '${flatRow['id_empleado']}',
      'codigo': '${flatRow['codigo']}',
      'nombre': '${flatRow['nombre']}',
      'fecha': '${flatRow['fecha_cierre']}',
      'total': '${flatRow['suma'] ?? '0'}',
    };
  }).toList();
}


Future<List<Map<String, dynamic>>> obtenerCuadrillas() async {
  final db = DatabaseService();
  await db.connect();
  final result = await db.connection.query('SELECT id_cuadrilla, nombre FROM cuadrillas WHERE estado = true ORDER BY nombre;');
  await db.close();
  return result.map((row) => {
    'id': row[0],
    'nombre': row[1],
  }).toList();
}