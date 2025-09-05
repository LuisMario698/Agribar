// lib/services/usuarios_service.dart
import 'package:agribar/services/database_service.dart';

class UsuariosService {
  final DatabaseService _db = DatabaseService();

  /// Obtiene todos los usuarios del sistema con información del rol
  /// Retorna una lista de mapas con la información de cada usuario y su rol
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          u.id_usuario,
          u.nombre_usuario,
          u.correo,
          u.rol,
          r.descripcion as rol_descripcion
        FROM usuarios u
        LEFT JOIN roles r ON u.rol = r.id_rol
        ORDER BY u.nombre_usuario;
      ''');

      await _db.close();

      return results.map((row) => {
        'id_usuario': row[0],
        'nombre_usuario': row[1],
        'correo': row[2],
        'rol': row[3], // ID del rol
        'rol_descripcion': row[4], // Descripción del rol
      }).toList();
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      await _db.close();
      return [];
    }
  }

  /// Obtiene un usuario específico por su ID con información del rol
  /// Retorna un mapa con la información del usuario o null si no existe
  Future<Map<String, dynamic>?> obtenerUsuarioPorId(int id) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          u.id_usuario,
          u.nombre_usuario,
          u.correo,
          u.rol,
          r.descripcion as rol_descripcion
        FROM usuarios u
        LEFT JOIN roles r ON u.rol = r.id_rol
        WHERE u.id_usuario = @id;
      ''', substitutionValues: {'id': id});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id_usuario': row[0],
          'nombre_usuario': row[1],
          'correo': row[2],
          'rol': row[3], // ID del rol
          'rol_descripcion': row[4], // Descripción del rol
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
  /// Retorna un mapa con la información del usuario incluyendo la contraseña y rol
  Future<Map<String, dynamic>?> obtenerUsuarioParaAuth(String nombreUsuario) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          u.id_usuario,
          u.nombre_usuario,
          u.correo,
          u.contraseña,
          u.rol,
          r.descripcion as rol_descripcion
        FROM usuarios u
        LEFT JOIN roles r ON u.rol = r.id_rol
        WHERE u.nombre_usuario = @nombre;
      ''', substitutionValues: {'nombre': nombreUsuario});

      await _db.close();

      if (results.isNotEmpty) {
        final row = results.first;
        return {
          'id_usuario': row[0],
          'nombre_usuario': row[1],
          'correo': row[2],
          'contraseña': row[3],
          'rol': row[4], // ID del rol
          'rol_descripcion': row[5], // Descripción del rol
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
  /// Retorna true si se creó exitosamente, false en caso contrario
  Future<bool> crearUsuario({
    required String nombreUsuario,
    required String correo,
    required String password,
    required int rolId,
  }) async {
    try {
      await _db.connect();

      // Verificar si ya existe un usuario con ese nombre o correo
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

      // Verificar que el rol existe
      final existeRol = await _db.connection.query('''
        SELECT id_rol FROM roles WHERE id_rol = @rol_id;
      ''', substitutionValues: {'rol_id': rolId});

      if (existeRol.isEmpty) {
        print('❌ El rol especificado no existe');
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
        'rol': rolId,
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
  /// Retorna true si se actualizó exitosamente, false en caso contrario
  Future<bool> actualizarUsuario({
    required int id,
    String? nombreUsuario,
    String? correo,
    String? password,
    int? rolId,
  }) async {
    try {
      await _db.connect();

      // Construir consulta dinámica según los campos a actualizar
      List<String> setClauses = [];
      Map<String, dynamic> values = {'id': id};

      if (nombreUsuario != null && nombreUsuario.isNotEmpty) {
        // Verificar que el nombre de usuario no esté en uso por otro usuario
        final existeNombre = await _db.connection.query('''
          SELECT id_usuario FROM usuarios 
          WHERE nombre_usuario = @nombre AND id_usuario != @id;
        ''', substitutionValues: {'nombre': nombreUsuario, 'id': id});

        if (existeNombre.isNotEmpty) {
          print('❌ El nombre de usuario ya está en uso');
          await _db.close();
          return false;
        }

        setClauses.add('nombre_usuario = @nombre');
        values['nombre'] = nombreUsuario;
      }

      if (correo != null && correo.isNotEmpty) {
        // Verificar que el correo no esté en uso por otro usuario
        final existeCorreo = await _db.connection.query('''
          SELECT id_usuario FROM usuarios 
          WHERE correo = @correo AND id_usuario != @id;
        ''', substitutionValues: {'correo': correo, 'id': id});

        if (existeCorreo.isNotEmpty) {
          print('❌ El correo ya está en uso');
          await _db.close();
          return false;
        }

        setClauses.add('correo = @correo');
        values['correo'] = correo;
      }

      if (password != null && password.isNotEmpty) {
        setClauses.add('contraseña = @password');
        values['password'] = _hashPassword(password);
      }

      if (rolId != null) {
        // Verificar que el rol existe
        final existeRol = await _db.connection.query('''
          SELECT id_rol FROM roles WHERE id_rol = @rol_id;
        ''', substitutionValues: {'rol_id': rolId});

        if (existeRol.isEmpty) {
          print('❌ El rol especificado no existe');
          await _db.close();
          return false;
        }

        setClauses.add('rol = @rol');
        values['rol'] = rolId;
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
      try {
        await _db.close();
      } catch (closeError) {
        print('❌ Error al cerrar conexión: $closeError');
      }
      return false;
    }
  }

  /// Elimina un usuario del sistema
  /// Retorna true si se eliminó exitosamente, false en caso contrario
  Future<bool> eliminarUsuario(int id) async {
    try {
      await _db.connect();

      // Verificar que el usuario existe
      final existe = await _db.connection.query('''
        SELECT id_usuario FROM usuarios 
        WHERE id_usuario = @id;
      ''', substitutionValues: {'id': id});

      if (existe.isEmpty) {
        print('❌ Usuario no encontrado');
        await _db.close();
        return false;
      }

      // Realizar eliminación física
      final result = await _db.connection.execute('''
        DELETE FROM usuarios 
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

  /// Verifica si un nombre de usuario ya existe
  /// Retorna true si existe, false en caso contrario
  Future<bool> existeNombreUsuario(String nombreUsuario, {int? excludeId}) async {
    try {
      await _db.connect();

      String query = '''
        SELECT id_usuario FROM usuarios 
        WHERE nombre_usuario = @nombre
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
  /// Retorna lista de usuarios con el rol especificado
  Future<List<Map<String, dynamic>>> obtenerUsuariosPorRol(int rolId) async {
    try {
      await _db.connect();
      
      final results = await _db.connection.query('''
        SELECT 
          u.id_usuario,
          u.nombre_usuario,
          u.correo,
          u.rol,
          r.descripcion as rol_descripcion
        FROM usuarios u
        LEFT JOIN roles r ON u.rol = r.id_rol
        WHERE u.rol = @rol_id
        ORDER BY u.nombre_usuario;
      ''', substitutionValues: {'rol_id': rolId});

      await _db.close();

      return results.map((row) => {
        'id_usuario': row[0],
        'nombre_usuario': row[1],
        'correo': row[2],
        'rol': row[3], // id del rol
        'rol_descripcion': row[4], // Descripción del rol
      }).toList();
    } catch (e) {
      print('❌ Error al obtener usuarios por rol: $e');
      await _db.close();
      return [];
    }
  }
  String _hashPassword(String password) {
    // Por simplicidad, se retorna la contraseña tal como está
    // En el futuro se implementara la encriptación aquí
    return password;
  }

  /// Valida las credenciales de un usuario
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
