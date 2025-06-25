// lib/services/usuarios_service.dart
import 'package:agribar/services/database_service.dart';

class UsuariosService {
  final DatabaseService _db = DatabaseService();

  /// Obtiene todos los usuarios del sistema
  /// Retorna una lista de mapas con la información de cada usuario
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_usuario,
          nombre_usuario,
          correo,
          rol
        FROM usuarios
        ORDER BY nombre_usuario;
      ''');

      await _db.close();

      return results.map((row) => {
        'id_usuario': row[0],
        'nombre_usuario': row[1],
        'correo': row[2],
        'rol': row[3],
      }).toList();
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      await _db.close();
      return [];
    }
  }

  /// Obtiene un usuario específico por su ID
  /// [id] - ID del usuario a buscar
  /// Retorna un mapa con la información del usuario o null si no existe
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(int id) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_usuario,
          nombre_usuario,
          correo,
          rol
        FROM usuarios
        WHERE id_usuario = @id;
      ''', substitutionValues: {'id': id});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id_usuario': row[0],
          'nombre_usuario': row[1],
          'correo': row[2],
          'rol': row[3],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener usuario por ID: $e');
      await _db.close();
      return null;
    }
  }

  /// Obtiene un usuario por nombre de usuario para autenticación
  /// [nombreUsuario] - Nombre de usuario
  /// Retorna un mapa con la información del usuario incluyendo la contraseña
  Future<Map<String, dynamic>?> obtenerUsuarioParaAuth(String nombreUsuario) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_usuario,
          nombre_usuario,
          correo,
          contraseña,
          rol
        FROM usuarios
        WHERE nombre_usuario = @nombre;
      ''', substitutionValues: {'nombre': nombreUsuario});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id_usuario': row[0],
          'nombre_usuario': row[1],
          'correo': row[2],
          'contraseña': row[3],
          'rol': row[4],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener usuario para autenticación: $e');
      await _db.close();
      return null;
    }
  }

  /// Crea un nuevo usuario en el sistema
  /// [nombreUsuario] - Nombre de usuario único
  /// [correo] - Correo electrónico del usuario
  /// [password] - Contraseña en texto plano
  /// [rol] - Rol del usuario (Admin, Supervisor, Capturista)
  /// Retorna true si se creó exitosamente, false en caso contrario
  Future<bool> crearUsuario({
    required String nombreUsuario,
    required String correo,
    required String password,
    required String rol,
  }) async {
    try {
      await _db.connect();

      // Verificar si ya existe un usuario con ese nombre
      final existeUsuario = await _db.connection.query('''
        SELECT id_usuario FROM usuarios 
        WHERE nombre_usuario = @nombre OR correo = @correo;
      ''', substitutionValues: {
        'nombre': nombreUsuario,
        'correo': correo,
      });

      if (existeUsuario.isNotEmpty) {
        print('❌ Ya existe un usuario con ese nombre de usuario o correo');
        await _db.close();
        return false;
      }

      // Insertar nuevo usuario
      final result = await _db.connection.execute('''
        INSERT INTO usuarios (
          nombre_usuario,
          correo,
          contraseña,
          rol
        ) VALUES (
          @nombre,
          @correo,
          @password,
          @rol
        );
      ''', substitutionValues: {
        'nombre': nombreUsuario,
        'correo': correo,
        'password': _hashPassword(password),
        'rol': rol,
      });

      await _db.close();
      print('✅ Usuario creado exitosamente');
      return result > 0;
    } catch (e) {
      print('❌ Error al crear usuario: $e');
      await _db.close();
      return false;
    }
  }

  /// Actualiza los datos de un usuario existente
  /// [id] - ID del usuario a actualizar
  /// [nombreUsuario] - Nuevo nombre de usuario (opcional)
  /// [correo] - Nuevo correo (opcional)
  /// [password] - Nueva contraseña (opcional)
  /// [rol] - Nuevo rol (opcional)
  /// Retorna true si se actualizó exitosamente, false en caso contrario
  Future<bool> actualizarUsuario({
    required int id,
    String? nombreUsuario,
    String? correo,
    String? password,
    String? rol,
  }) async {
    try {
      await _db.connect();

      // Construir consulta dinámica según los campos a actualizar
      List<String> setClauses = [];
      Map<String, dynamic> values = {'id': id};

      if (nombreUsuario != null) {
        setClauses.add('nombre_usuario = @nombre');
        values['nombre'] = nombreUsuario;
      }

      if (correo != null) {
        setClauses.add('correo = @correo');
        values['correo'] = correo;
      }

      if (password != null) {
        setClauses.add('contraseña = @password');
        values['password'] = _hashPassword(password);
      }

      if (rol != null) {
        setClauses.add('rol = @rol');
        values['rol'] = rol;
      }

      if (setClauses.isEmpty) {
        print('❌ No hay campos para actualizar');
        await _db.close();
        return false;
      }

      final query = '''
        UPDATE usuarios 
        SET ${setClauses.join(', ')}
        WHERE id_usuario = @id;
      ''';

      final result = await _db.connection.execute(query, substitutionValues: values);

      await _db.close();
      print('✅ Usuario actualizado exitosamente');
      return result > 0;
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      await _db.close();
      return false;
    }
  }

  /// Elimina un usuario del sistema (eliminación lógica)
  /// [id] - ID del usuario a eliminar
  /// Retorna true si se eliminó exitosamente, false en caso contrario
  Future<bool> eliminarUsuario(int id) async {
    try {
      await _db.connect();

      // Verificar que el usuario existe y está activo
      final existe = await _db.connection.query('''
        SELECT id_usuario FROM usuarios 
        WHERE id_usuario = @id AND activo = true;
      ''', substitutionValues: {'id': id});

      if (existe.isEmpty) {
        print('❌ Usuario no encontrado o ya está inactivo');
        await _db.close();
        return false;
      }

      // Realizar eliminación lógica (marcar como inactivo)
      final result = await _db.connection.execute('''
        UPDATE usuarios 
        SET activo = false
        WHERE id_usuario = @id;
      ''', substitutionValues: {'id': id});

      await _db.close();
      print('✅ Usuario eliminado exitosamente');
      return result > 0;
    } catch (e) {
      print('❌ Error al eliminar usuario: $e');
      await _db.close();
      return false;
    }
  }

  /// Cambia el estado de un usuario (activar/desactivar)
  /// [id] - ID del usuario
  /// [activo] - Nuevo estado del usuario
  /// Retorna true si se cambió exitosamente, false en caso contrario
  Future<bool> cambiarEstadoUsuario(int id, bool activo) async {
    try {
      await _db.connect();

      final result = await _db.connection.execute('''
        UPDATE usuarios 
        SET activo = @activo
        WHERE id_usuario = @id;
      ''', substitutionValues: {
        'id': id,
        'activo': activo,
      });

      await _db.close();
      print('✅ Estado del usuario cambiado exitosamente');
      return result > 0;
    } catch (e) {
      print('❌ Error al cambiar estado del usuario: $e');
      await _db.close();
      return false;
    }
  }

  /// Verifica si un nombre de usuario ya existe
  /// [nombreUsuario] - Nombre de usuario a verificar
  /// [excludeId] - ID de usuario a excluir de la verificación (útil para actualizaciones)
  /// Retorna true si existe, false en caso contrario
  Future<bool> existeNombreUsuario(String nombreUsuario, {int? excludeId}) async {
    try {
      await _db.connect();

      String query = '''
        SELECT id_usuario FROM usuarios 
        WHERE nombre_usuario = @nombre AND activo = true
      ''';
      
      Map<String, dynamic> values = {'nombre': nombreUsuario};

      if (excludeId != null) {
        query += ' AND id_usuario != @excludeId';
        values['excludeId'] = excludeId;
      }

      final results = await _db.connection.query(query, substitutionValues: values);

      await _db.close();
      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar nombre de usuario: $e');
      await _db.close();
      return false;
    }
  }

  /// Obtiene usuarios por rol específico
  /// [rol] - Rol a filtrar (Admin, Supervisor, Capturista)
  /// Retorna lista de usuarios con el rol especificado
  Future<List<Map<String, dynamic>>> obtenerUsuariosPorRol(String rol) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          id_usuario,
          nombre_usuario,
          email,
          rol,
          fecha_creacion,
          activo
        FROM usuarios
        WHERE rol = @rol AND activo = true
        ORDER BY nombre_usuario;
      ''', substitutionValues: {'rol': rol});

      await _db.close();

      return results.map((row) => {
        'id': row[0],
        'nombre_usuario': row[1],
        'email': row[2],
        'rol': row[3],
        'fecha_creacion': row[4],
        'activo': row[5],
      }).toList();
    } catch (e) {
      print('❌ Error al obtener usuarios por rol: $e');
      await _db.close();
      return [];
    }
  }

  /// Función privada para hashear contraseñas
  /// [password] - Contraseña en texto plano
  /// Retorna la contraseña hasheada
  String _hashPassword(String password) {
    // Por simplicidad, aquí se retorna la contraseña tal como está
    // En producción, se debería usar una librería como crypto para hashear
    // Ejemplo: return sha256.convert(utf8.encode(password)).toString();
    return password;
  }

  /// Valida las credenciales de un usuario
  /// [nombreUsuario] - Nombre de usuario
  /// [password] - Contraseña en texto plano
  /// Retorna el usuario si las credenciales son válidas, null en caso contrario
  Future<Map<String, dynamic>?> validarCredenciales(String nombreUsuario, String password) async {
    try {
      final usuario = await obtenerUsuarioParaAuth(nombreUsuario);
      
      if (usuario != null && usuario['contraseña'] == _hashPassword(password)) {
        // Remover la contraseña del objeto de retorno por seguridad
        usuario.remove('contraseña');
        return usuario;
      }
      
      return null;
    } catch (e) {
      print('❌ Error al validar credenciales: $e');
      return null;
    }
  }
}
