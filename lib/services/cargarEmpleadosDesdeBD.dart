// lib/services/cargarEmpleadosDesdeBD.dart
import 'database_service.dart';

/// Obtiene todos los empleados de la base de datos combinando las 3 tablas:
/// - empleados: datos personales básicos
/// - datos_laborales: información laboral y estado de habilitación
/// - datos_nomina: información salarial
Future<List<Map<String, dynamic>>> obtenerEmpleadosDesdeBD() async {
  final db = DatabaseService();
  
  try {
    print('🔗 Conectando a la base de datos...');
    await db.connect();
    
    print('📋 Ejecutando consulta de empleados...');
    final results = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.codigo,
        e.nombre,
        e.apellido_paterno,
        e.apellido_materno,
        e.curp,
        e.rfc,
        e.nss,
        e.estado_origen,
        dl.id_datos_laborales,
        dl.tipo,
        dl.id_cuadrilla,
        dl.fecha_ingreso,
        dl.empresa,
        dl.puesto,
        dl.registro_patronal,
        dl.inactivo,
        dl.deshabilitado,
        dn.id_datos_nomina,
        dn.sueldo,
        dn.domingo_laboral,
        dn.descuento_comedor,
        dn.tipo_descuento_infonavit,
        dn.descuento_infonavit
      FROM empleados e
      LEFT JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado
      LEFT JOIN datos_nomina dn ON e.id_empleado = dn.id_empleado
      ORDER BY e.codigo;
    ''');

    print('📊 Consulta ejecutada. Filas obtenidas: ${results.length}');
    await db.close();

    final listaEmpleados = results.map((row) {
      final inactivo = row[16] as bool? ?? false;
      final deshabilitado = row[17] as bool? ?? false;
      return {
        'id_empleado': row[0] as int,
        'clave': row[1] as String? ?? '',
        'nombre': row[2] as String? ?? '',
        'apellidoPaterno': row[3] as String? ?? '',
        'apellidoMaterno': row[4] as String? ?? '',
        'curp': row[5] as String? ?? '',
        'rfc': row[6] as String? ?? '',
        'nss': row[7] as String? ?? '',
        'estadoorigen': row[8] as String? ?? '',
        'id_datos_laborales': row[9] as int?,
        'tipo': row[10] as String? ?? '',
        'cuadrilla': row[11]?.toString() ?? '',
        'fecha_ingreso': row[12]?.toString() ?? '',
        'empresa': row[13] as String? ?? '',
        'puesto': row[14] as String? ?? '',
        'registro_patronal': row[15] as String? ?? '',
        'inactivo': inactivo,
        'deshabilitado': deshabilitado,
        'habilitado': !deshabilitado, // Usando valor temporal para pruebas
        'id_datos_nomina': row[18] as int?,
        'sueldo': row[19]?.toString() ?? '0.00',
        'domingo_laboral': row[20]?.toString() ?? '0.00',
        'descuento_comedor': row[21]?.toString() ?? '0.00',
        'tipo_descuento_infonavit': row[22] as String? ?? '',
        'descuento_infonavit': row[23]?.toString() ?? '0.00',
      };
    }).toList();

    print('✅ Datos procesados. Total empleados: ${listaEmpleados.length}');
    return listaEmpleados;

  } catch (e) {
    print('❌ Error al cargar empleados: $e');
    await db.close();
    return [];
  }
}

/// Obtiene los nombres de las cuadrillas para mostrar en lugar de solo el ID
Future<Map<int, String>> obtenerNombresCuadrillas() async {
  final db = DatabaseService();
  
  try {
    await db.connect();
    
    final results = await db.connection.query('''
      SELECT id_cuadrilla, nombre
      FROM cuadrillas
      ORDER BY nombre;
    ''');

    await db.close();

    Map<int, String> nombresCuadrillas = {};
    for (final row in results) {
      nombresCuadrillas[row[0] as int] = row[1] as String;
    }
    
    return nombresCuadrillas;

  } catch (e) {
    print('Error al cargar nombres de cuadrillas: $e');
    await db.close();
    return {};
  }
}
