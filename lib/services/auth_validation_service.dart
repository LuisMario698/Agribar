// lib/services/auth_validation_service.dart
import 'package:agribar/services/database_service.dart';
import 'cargarEmpleadosDesdeBD.dart';

class AuthValidationService {
  final DatabaseService _db = DatabaseService();

  /// Valida las credenciales de un usuario y verifica si tiene permisos específicos
  /// Retorna un mapa con la información del usuario si es válido, null si no
  Future<Map<String, dynamic>?> validarCredencialesConPermisos(
    String usuario, 
    String password
  ) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          u.id_usuario,
          u.nombre_usuario,
          u.rol,
          r.descripcion as rol_descripcion,
          r.acceso_empleados,
          r.acceso_cuadrillas
        FROM usuarios u
        JOIN roles r ON u.rol = r.id_rol
        WHERE u.nombre_usuario = @usuario AND u.contraseña = @password;
      ''', substitutionValues: {
        'usuario': usuario,
        'password': password,
      });

      await _db.close();

      if (results.isEmpty) {
        return null; // Credenciales inválidas
      }

      final userData = results.first;
      final rolId = userData[2] as int;
      final rolDescripcion = userData[3] as String;
      final accesoEmpleados = userData[4] as bool? ?? false;
      final accesoCuadrillas = userData[5] as bool? ?? false;

      // Verificar si el usuario tiene permisos para gestionar empleados o cuadrillas
      // Roles permitidos para gestión general: Supervisor (1), Administrador (2) y Capturista (3)
      // Para cierre de semanas: Solo Supervisor (1) y Administrador (2)
      if (rolId == 1 || rolId == 2 || rolId == 3) {
        if (accesoCuadrillas || accesoEmpleados) {
          return {
            'id_usuario': userData[0],
            'nombre_usuario': userData[1],
            'rol': rolId,
            'rol_descripcion': rolDescripcion,
            'acceso_empleados': accesoEmpleados,
            'acceso_cuadrillas': accesoCuadrillas,
            'puede_gestionar': true,
            'puede_cerrar_semana': rolId == 1 || rolId == 2, // Solo Supervisor y Administrador
          };
        }
      }

      return null; // No tiene permisos suficientes
    } catch (e) {
      print('❌ Error al validar credenciales: $e');
      await _db.close();
      return null;
    }
  }

  /// Actualiza el estado de una cuadrilla en la base de datos
  Future<bool> actualizarEstadoCuadrilla(String clave, bool nuevoEstado) async {
    try {
      await _db.connect();
      
      final result = await _db.connection.query('''
        UPDATE cuadrillas 
        SET estado = @estado 
        WHERE clave = @clave
        RETURNING id_cuadrilla, nombre, estado;
      ''', substitutionValues: {
        'estado': nuevoEstado,
        'clave': clave,
      });

      await _db.close();
      
      return result.isNotEmpty;
    } catch (e) {
      await _db.close();
      return false;
    }
  }

  /// Actualiza el estado de un empleado en la base de datos
  /// Actualiza directamente el campo 'habilitado' en la tabla empleados
  Future<bool> actualizarEstadoEmpleado(int idEmpleado, bool activo) async {
    try {
      await _db.connect();
      
      final result = await _db.connection.query('''
        UPDATE empleados 
        SET habilitado = @habilitado 
        WHERE id_empleado = @id_empleado
        RETURNING id_empleado;
      ''', substitutionValues: {
        'habilitado': activo,
        'id_empleado': idEmpleado,
      });

      await _db.close();
      
      // Actualizar cache si la operación fue exitosa
      if (result.isNotEmpty) {
        try {
          actualizarEmpleadoEnCache(idEmpleado, {'habilitado': activo});
        } catch (e) {
          print('⚠️ No se pudo actualizar cache: $e');
        }
      }
      
      return result.isNotEmpty;
    } catch (e) {
      await _db.close();
      return false;
    }
  }
}

/* 
🔧 CONFIGURACIÓN DE AUTENTICACIÓN Y PERMISOS:

1. PERMISOS ACTUALES:
   - Supervisores (ID: 1), Administradores (ID: 2) y Administradores (ID: 3) pueden gestionar cuadrillas y empleados
   - Otros roles requieren permisos específicos de acceso

2. FUNCIONALIDADES:
   - Validación de credenciales contra PostgreSQL
   - Verificación de permisos específicos por rol
   - Actualización de estados en base de datos
*/
