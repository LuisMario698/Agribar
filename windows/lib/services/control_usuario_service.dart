// lib/services/control_usuario_service.dart

import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/usuarios_service.dart';
import 'package:agribar/services/roles_service.dart';

/// Servicio de control de usuario mejorado para el sistema Agribar
/// Maneja los 3 tipos de usuario: Capturista, Supervisor y Administrador
/// Integra con el sistema existente de usuarios y roles
class ControlUsuarioService {
  final DatabaseService _db = DatabaseService();
  final UsuariosService _usuariosService = UsuariosService();
  final RolesService _rolesService = RolesService();

  // Constantes para los tipos de usuario
  static const int ROLE_SUPERVISOR = 1;
  static const int ROLE_ADMINISTRADOR = 2; 
  static const int ROLE_CAPTURISTA = 3;

  static const Map<String, int> USER_TYPES = {
    'supervisor': ROLE_SUPERVISOR,
    'administrador': ROLE_ADMINISTRADOR,
    'capturista': ROLE_CAPTURISTA,
  };

  /// Obtiene todos los usuarios con información detallada de roles
  Future<List<Map<String, dynamic>>> obtenerTodosLosUsuarios() async {
    try {
      final usuarios = await _usuariosService.obtenerUsuarios();
      
      // Enriquecer con información adicional de tipo de usuario
      return usuarios.map((usuario) {
        final tipoUsuario = _getTipoUsuarioFromRolId(usuario['rol']);
        return {
          ...usuario,
          'tipo_usuario': tipoUsuario,
          'permisos': _getPermisosForRol(usuario['rol']),
          'color_ui': _getColorForRol(usuario['rol']),
        };
      }).toList();
    } catch (e) {
      print('❌ Error en ControlUsuarioService.obtenerTodosLosUsuarios: $e');
      return [];
    }
  }

  /// Crea un nuevo usuario con tipo específico
  Future<bool> crearUsuarioConTipo({
    required String nombreUsuario,
    required String correo,
    required String password,
    required String tipoUsuario, // 'capturista', 'supervisor', 'administrador'
  }) async {
    try {
      final rolId = USER_TYPES[tipoUsuario.toLowerCase()];
      
      if (rolId == null) {
        print('❌ Tipo de usuario no válido: $tipoUsuario');
        return false;
      }

      // Validar que el rol existe en la base de datos
      final rol = await _rolesService.obtenerRolPorId(rolId);
      if (rol == null) {
        print('❌ El rol con ID $rolId no existe en la base de datos');
        return false;
      }

      return await _usuariosService.crearUsuario(
        nombreUsuario: nombreUsuario,
        correo: correo,
        password: password,
        rolId: rolId,
      );
    } catch (e) {
      print('❌ Error en ControlUsuarioService.crearUsuarioConTipo: $e');
      return false;
    }
  }

  /// Valida credenciales y retorna información del usuario con tipo y permisos desde BD
  Future<Map<String, dynamic>?> validarCredencialesConTipo(
    String nombreUsuario, 
    String password
  ) async {
    try {
      final usuario = await _usuariosService.validarCredenciales(nombreUsuario, password);
      
      if (usuario != null) {
        final usuarioId = usuario['id_usuario'];
        final permisos = await obtenerPermisosUsuario(usuarioId);
        final seccionesPermitidas = await obtenerSeccionesPermitidas(usuarioId);
        
      if (permisos != null) {
        final tipoUsuario = _getTipoUsuarioFromRolId(usuario['rol']);
        return {
          ...usuario,
          'rol_id': usuario['rol'], // Añadir el rol_id para validaciones
          'tipo': tipoUsuario, // Tipo con primera letra mayúscula
          'tipo_usuario': tipoUsuario,
          'permisos': permisos,
          'secciones_permitidas': seccionesPermitidas,
          'puede_acceder_configuracion': permisos['acceso_configurar_usuarios'] ?? false,
          'puede_modificar_empleados': permisos['acceso_modificar_empleados'] ?? false,
          'puede_gestionar_nomina': permisos['acceso_nomina'] ?? false,
          'color_ui': _getColorForRol(usuario['rol']),
        };
      }
      }
      
      return null;
    } catch (e) {
      print('❌ Error en ControlUsuarioService.validarCredencialesConTipo: $e');
      return null;
    }
  }

  /// Obtiene los permisos de un usuario directamente desde la base de datos
  Future<Map<String, bool>?> obtenerPermisosUsuario(int usuarioId) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          r.acceso_empleados,
          r.acceso_cuadrillas,
          r.acceso_actividades,
          r.acceso_nomina,
          r.acceso_configurar_usuarios,
          r.importar_informacion,
          r.exportar_informacion,
          r.acceso_modificar_empleados
        FROM usuarios u
        INNER JOIN roles r ON u.rol = r.id_rol
        WHERE u.id_usuario = @usuario_id;
      ''', substitutionValues: {'usuario_id': usuarioId});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'acceso_empleados': row[0] == true,
          'acceso_cuadrillas': row[1] == true,
          'acceso_actividades': row[2] == true,
          'acceso_nomina': row[3] == true,
          'acceso_configurar_usuarios': row[4] == true,
          'importar_informacion': row[5] == true,
          'exportar_informacion': row[6] == true,
          'acceso_modificar_empleados': row[7] == true,
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error en ControlUsuarioService.obtenerPermisosUsuario: $e');
      await _db.close();
      return null;
    }
  }

  /// Verifica si un usuario puede acceder a una sección específica
  Future<bool> puedeAccederSeccion(int usuarioId, String seccion) async {
    final permisos = await obtenerPermisosUsuario(usuarioId);
    if (permisos == null) return false;

    switch (seccion.toLowerCase()) {
      case 'empleados':
        return permisos['acceso_empleados'] ?? false;
      case 'cuadrillas':
        return permisos['acceso_cuadrillas'] ?? false;
      case 'actividades':
        return permisos['acceso_actividades'] ?? false;
      case 'nomina':
        return permisos['acceso_nomina'] ?? false;
      case 'configuracion':
        return permisos['acceso_configurar_usuarios'] ?? false;
      case 'reportes':
        // Los reportes requieren acceso a nómina o ser supervisor/admin
        return permisos['acceso_nomina'] ?? false;
      default:
        return false;
    }
  }

  /// Verifica si un usuario puede realizar una acción específica
  Future<bool> puedeRealizarAccion(int usuarioId, String accion) async {
    final permisos = await obtenerPermisosUsuario(usuarioId);
    if (permisos == null) return false;

    switch (accion.toLowerCase()) {
      case 'modificar_empleados':
        return permisos['acceso_modificar_empleados'] ?? false;
      case 'importar_datos':
        return permisos['importar_informacion'] ?? false;
      case 'exportar_datos':
        return permisos['exportar_informacion'] ?? false;
      case 'gestionar_usuarios':
        return permisos['acceso_configurar_usuarios'] ?? false;
      case 'ver_nomina':
        return permisos['acceso_nomina'] ?? false;
      case 'gestionar_cuadrillas':
        return permisos['acceso_cuadrillas'] ?? false;
      default:
        return false;
    }
  }

  /// Obtiene las secciones permitidas para un usuario
  Future<List<String>> obtenerSeccionesPermitidas(int usuarioId) async {
    final permisos = await obtenerPermisosUsuario(usuarioId);
    if (permisos == null) return [];

    List<String> seccionesPermitidas = [];

    if (permisos['acceso_empleados'] == true) {
      seccionesPermitidas.add('empleados');
    }
    if (permisos['acceso_cuadrillas'] == true) {
      seccionesPermitidas.add('cuadrillas');
    }
    if (permisos['acceso_actividades'] == true) {
      seccionesPermitidas.add('actividades');
    }
    if (permisos['acceso_nomina'] == true) {
      seccionesPermitidas.add('nomina');
      seccionesPermitidas.add('reportes'); // Los reportes requieren acceso a nómina
    }
    if (permisos['acceso_configurar_usuarios'] == true) {
      seccionesPermitidas.add('configuracion');
    }

    return seccionesPermitidas;
  }

  /// Obtiene información completa del usuario con permisos desde BD
  Future<Map<String, dynamic>?> obtenerUsuarioConPermisos(int usuarioId) async {
    try {
      final usuario = await _usuariosService.obtenerUsuarioPorId(usuarioId);
      if (usuario == null) return null;

      final permisos = await obtenerPermisosUsuario(usuarioId);
      if (permisos == null) return null;

      final seccionesPermitidas = await obtenerSeccionesPermitidas(usuarioId);

      return {
        ...usuario,
        'permisos': permisos,
        'secciones_permitidas': seccionesPermitidas,
        'tipo_usuario': _getTipoUsuarioFromRolId(usuario['rol']),
        'color_ui': _getColorForRol(usuario['rol']),
      };
    } catch (e) {
      print('❌ Error en ControlUsuarioService.obtenerUsuarioConPermisos: $e');
      return null;
    }
  }

  /// Métodos privados de utilidad
  
  String _getTipoUsuarioFromRolId(int rolId) {
    switch (rolId) {
      case ROLE_CAPTURISTA:
        return 'Capturista';
      case ROLE_SUPERVISOR:
        return 'Supervisor';
      case ROLE_ADMINISTRADOR:
        return 'Administrador';
      default:
        return 'Desconocido';
    }
  }

  Map<String, bool> _getPermisosForRol(int rolId) {
    switch (rolId) {
      case ROLE_CAPTURISTA:
        return {
          'acceso_empleados': true,
          'acceso_cuadrillas': false,
          'acceso_actividades': true,
          'acceso_nomina': false,
          'acceso_configurar_usuarios': false,
          'importar_informacion': false,
          'exportar_informacion': false,
          'acceso_modificar_empleados': false,
        };
      case ROLE_SUPERVISOR:
        return {
          'acceso_empleados': true,
          'acceso_cuadrillas': true,
          'acceso_actividades': true,
          'acceso_nomina': true,
          'acceso_configurar_usuarios': false,
          'importar_informacion': true,
          'exportar_informacion': true,
          'acceso_modificar_empleados': true,
        };
      case ROLE_ADMINISTRADOR:
        return {
          'acceso_empleados': true,
          'acceso_cuadrillas': true,
          'acceso_actividades': true,
          'acceso_nomina': true,
          'acceso_configurar_usuarios': true,
          'importar_informacion': true,
          'exportar_informacion': true,
          'acceso_modificar_empleados': true,
        };
      default:
        return {};
    }
  }

  String _getColorForRol(int rolId) {
    switch (rolId) {
      case ROLE_ADMINISTRADOR:
        return '#7BAE2F'; // Verde
      case ROLE_SUPERVISOR:
        return '#7B6A3A'; // Marrón
      case ROLE_CAPTURISTA:
        return '#2B8DDB'; // Azul
      default:
        return '#6B7280'; // Gris
    }
  }
}
