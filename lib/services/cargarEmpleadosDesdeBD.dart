// lib/services/cargarEmpleadosDesdeBD.dart
import 'database_service.dart';

// Cache optimizado para empleados
Map<String, dynamic> _cacheEmpleados = {};
DateTime? _ultimaActualizacion;
const Duration _tiempoExpiracionCache = Duration(minutes: 15);

/// Método optimizado con paginación para mejor rendimiento
Future<List<Map<String, dynamic>>> obtenerEmpleadosDesdeBD({bool forzarRecarga = false}) async {
  const cacheKey = 'empleados_principales';
  
  // Verificar cache
  if (!forzarRecarga && _cacheEmpleados.containsKey(cacheKey) && _ultimaActualizacion != null) {
    final tiempoTranscurrido = DateTime.now().difference(_ultimaActualizacion!);
    if (tiempoTranscurrido < _tiempoExpiracionCache) {
      return _cacheEmpleados[cacheKey] as List<Map<String, dynamic>>;
    }
  }

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // Query para obtener TODOS los empleados
    final results = await db.connection.query('''
      SELECT 
        id_empleado,
        codigo,
        nombre,
        apellido_paterno,
        apellido_materno,
        curp,
        rfc,
        nss,
        estado_origen,
        habilitado
      FROM empleados
      ORDER BY codigo;
    ''');

    await db.close();

    final listaEmpleados = results.map((row) {
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
        'habilitado': row[9] as bool? ?? true,
      };
    }).toList();

    // Actualizar cache
    _cacheEmpleados[cacheKey] = listaEmpleados;
    _ultimaActualizacion = DateTime.now();
    
    return listaEmpleados;

  } catch (e) {
    print('❌ Error al cargar empleados: $e');
    await db.close();
    return _cacheEmpleados[cacheKey] as List<Map<String, dynamic>>? ?? [];
  }
}

/// Obtiene empleados con paginación para mejorar rendimiento en tablas grandes
Future<Map<String, dynamic>> obtenerEmpleadosPaginados({
  int pagina = 1,
  int elementosPorPagina = 50,
  String? filtro,
  bool soloHabilitados = false,
}) async {
  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // Construir condiciones WHERE
    List<String> condiciones = [];
    Map<String, dynamic> parametros = {};
    
    if (soloHabilitados) {
      condiciones.add('habilitado = @habilitado');
      parametros['habilitado'] = true;
    }
    
    if (filtro != null && filtro.isNotEmpty) {
      condiciones.add('''
        (LOWER(codigo) LIKE @filtro OR 
         LOWER(nombre) LIKE @filtro OR 
         LOWER(apellido_paterno) LIKE @filtro OR 
         LOWER(apellido_materno) LIKE @filtro OR
         LOWER(CONCAT(nombre, ' ', apellido_paterno, ' ', apellido_materno)) LIKE @filtro)
      ''');
      parametros['filtro'] = '%${filtro.toLowerCase()}%';
    }
    
    String whereClause = condiciones.isNotEmpty ? 'WHERE ${condiciones.join(' AND ')}' : '';
    
    // Contar total de registros
    final countResult = await db.connection.query('''
      SELECT COUNT(*) as total
      FROM empleados
      $whereClause
    ''', substitutionValues: parametros);
    
    final totalRegistros = countResult.first[0] as int;
    final totalPaginas = (totalRegistros / elementosPorPagina).ceil();
    
    // Obtener registros paginados
    final offset = (pagina - 1) * elementosPorPagina;
    parametros['limit'] = elementosPorPagina;
    parametros['offset'] = offset;
    
    final results = await db.connection.query('''
      SELECT 
        id_empleado,
        codigo,
        nombre,
        apellido_paterno,
        apellido_materno,
        curp,
        rfc,
        nss,
        estado_origen,
        habilitado
      FROM empleados
      $whereClause
      ORDER BY codigo
      LIMIT @limit OFFSET @offset;
    ''', substitutionValues: parametros);

    await db.close();

    final listaEmpleados = results.map((row) {
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
        'habilitado': row[9] as bool? ?? true,
      };
    }).toList();

    return {
      'empleados': listaEmpleados,
      'paginaActual': pagina,
      'totalPaginas': totalPaginas,
      'totalRegistros': totalRegistros,
      'elementosPorPagina': elementosPorPagina,
    };

  } catch (e) {
    print('❌ Error al cargar empleados paginados: $e');
    await db.close();
    return {
      'empleados': <Map<String, dynamic>>[],
      'paginaActual': 1,
      'totalPaginas': 0,
      'totalRegistros': 0,
      'elementosPorPagina': elementosPorPagina,
    };
  }
}

/// Actualizar empleado específico en cache
void actualizarEmpleadoEnCache(int idEmpleado, Map<String, dynamic> cambios) {
  _cacheEmpleados.forEach((key, value) {
    if (value is List<Map<String, dynamic>>) {
      final index = value.indexWhere((emp) => emp['id_empleado'] == idEmpleado);
      if (index != -1) {
        value[index] = {...value[index], ...cambios};
      }
    }
  });
}

/// Limpiar cache de empleados
void limpiarCacheEmpleados() {
  _cacheEmpleados.clear();
  _ultimaActualizacion = null;
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
