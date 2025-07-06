// lib/services/roles_service.dart
import 'package:agribar/services/database_service.dart';

class RolesService {
  final DatabaseService _db = DatabaseService();

  /// Obtiene todos los roles del sistema
  /// Retorna una lista de mapas con la información de cada rol
  Future<List<Map<String, dynamic>>> obtenerRoles() async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_rol,
          descripcion,
          acceso_empleados,
          acceso_cuadrillas,
          acceso_actividades,
          acceso_nomina,
          acceso_configurar_usuarios,
          importar_informacion,
          exportar_informacion,
          acceso_modificar_empleados
        FROM roles
        ORDER BY descripcion;
      ''');

      await _db.close();

      return results.map((row) => {
        'id_rol': row[0],
        'descripcion': row[1],
        'acceso_empleados': row[2],
        'acceso_cuadrillas': row[3],
        'acceso_actividades': row[4],
        'acceso_nomina': row[5],
        'acceso_configurar_usuarios': row[6],
        'importar_informacion': row[7],
        'exportar_informacion': row[8],
        'acceso_modificar_empleados': row[9],
      }).toList();
    } catch (e) {
      print('❌ Error al obtener roles: $e');
      await _db.close();
      return [];
    }
  }

  /// Obtiene un rol específico por su ID
  /// Retorna un mapa con la información del rol o null si no existe
  Future<Map<String, dynamic>?> obtenerRolPorId(int id) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_rol,
          descripcion,
          acceso_empleados,
          acceso_cuadrillas,
          acceso_actividades,
          acceso_nomina,
          acceso_configurar_usuarios,
          importar_informacion,
          exportar_informacion,
          acceso_modificar_empleados
        FROM roles
        WHERE id_rol = @id;
      ''', substitutionValues: {'id': id});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id_rol': row[0],
          'descripcion': row[1],
          'acceso_empleados': row[2],
          'acceso_cuadrillas': row[3],
          'acceso_actividades': row[4],
          'acceso_nomina': row[5],
          'acceso_configurar_usuarios': row[6],
          'importar_informacion': row[7],
          'exportar_informacion': row[8],
          'acceso_modificar_empleados': row[9],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener rol por ID: $e');
      await _db.close();
      return null;
    }
  }
  /// Obtiene solo las descripciones de los roles para dropdowns
  /// Retorna una lista de mapas con id_rol y descripcion
  Future<List<Map<String, dynamic>>> obtenerRolesParaDropdown() async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT id_rol, descripcion
        FROM roles
        ORDER BY descripcion;
      ''');

      await _db.close();

      return results.map((row) => {
        'id_rol': row[0],
        'descripcion': row[1],
      }).toList();
    } catch (e) {
      print('❌ Error al obtener roles para dropdown: $e');
      await _db.close();
      return [];
    }
  }
}
