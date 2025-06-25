import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/login_screen.dart';
import '../utils/auth_utils.dart';
import '../services/usuarios_service.dart';

class ConfiguracionContent extends StatefulWidget {
  const ConfiguracionContent({Key? key}) : super(key: key);

  @override
  State<ConfiguracionContent> createState() => _ConfiguracionContentState();
}

class _ConfiguracionContentState extends State<ConfiguracionContent> {
  bool showTableModal = false; // Controla la visibilidad del modal de tabla
  List<List<String>>? loadedData; // Datos cargados desde archivos
  String? modalTitle; // Título del modal actual
  
  final UsuariosService _usuariosService = UsuariosService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Carga los usuarios desde la base de datos
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final usuarios = await _usuariosService.obtenerUsuarios();
      setState(() {
        _users = usuarios.map((usuario) => {
          'id_usuario': usuario['id_usuario'],
          'name': usuario['nombre_usuario'],
          'role': usuario['rol'],
          'correo': usuario['correo'],
          'color': _getColorForRole(usuario['rol']),
        }).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error cargando usuarios: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  /// Asigna un color basado en el rol del usuario
  Color _getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF7BAE2F); // Verde para administradores
      case 'capturista':
        return const Color(0xFF2B8DDB); // Azul para capturistas
      case 'supervisor':
        return const Color(0xFF7B6A3A); // Marrón para supervisores
      default:
        return const Color(0xFF6B7280); // Gris para otros roles
    }
  }



  void _showUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => const _AddUserDialog(),
    ).then((success) {
      if (success == true) {
        _loadUsers(); // Recargar la lista de usuarios
      }
    });
  }




  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            
            return Container(
              padding: const EdgeInsets.all(32),
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? constraints.maxWidth : 1400,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isSmallScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildImportSection(),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildUserSection(),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildImportSection(),
                        const SizedBox(height: 24),
                        _buildUserSection(),
                      ],
                    ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black26,
                            builder: (context) => AlertDialog(
                              title: const Text('Cerrar sesión'),
                              content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Cerrar sesión'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.manage_accounts, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  'Administrar Usuarios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (_isLoadingUsers)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoadingUsers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_users.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: user['color'] as Color,
                          child: Text(
                            user['name'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user['role'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (user['correo'] != null)
                                Text(
                                  user['correo'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit),
                                  const SizedBox(width: 8),
                                  const Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red),
                                  const SizedBox(width: 8),
                                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditUserDialog(context, index);
                            } else if (value == 'delete') {
                              _showDeleteUserDialog(context, index);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B7A2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile(String type) async {
    try {
      // Aquí se implementaría la lógica real de importación de archivos
      // Por ahora mostraremos un diálogo de éxito

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Importar ${type.toLowerCase()}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Importando ${type.toLowerCase()}...'),
                ],
              ),
            ),
      );

      // Simulamos un proceso de importación
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop(); // Cerramos el diálogo de carga

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Éxito'),
              content: Text('${type} importados correctamente.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Error al importar ${type.toLowerCase()}: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildImportSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_upload, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Text(
                  'Cargar desde excel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildImportButton('Cuadrillas', Icons.groups),
            const SizedBox(height: 12),
            _buildImportButton('Actividades', Icons.work),
            const SizedBox(height: 12),
            _buildImportButton('Empleados', Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(String text, IconData icon) {
    return InkWell(
      onTap: () => _importFile(text),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Icon(Icons.download, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, int index) {
    final user = _users[index];
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _AddUserDialog(initialUser: user),
    ).then((editedUser) {
      if (editedUser != null) {
        setState(() {
          _users[index] = editedUser as Map<String, dynamic>;
        });
      }
    });
  }

  void _showDeleteUserDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar usuario'),
            content: Text(
              '¿Estás seguro que deseas eliminar a ${_users[index]['name']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _users.removeAt(index);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final Map<String, dynamic>? initialUser;

  const _AddUserDialog({Key? key, this.initialUser}) : super(key: key);

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'Capturista';
  bool _isLoading = false;

  final List<String> _roles = ['Admin', 'Supervisor', 'Capturista'];
  final UsuariosService _usuariosService = UsuariosService();

  Color _getColorForRole(String role) {
    switch (role) {
      case 'Admin':
        return const Color(0xFF7BAE2F);
      case 'Supervisor':
        return const Color(0xFF7B6A3A);
      case 'Capturista':
        return const Color(0xFF2B8DDB);
      default:
        return const Color(0xFF2B8DDB);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialUser?['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialUser?['correo'] ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialUser?['password'] ?? '',
    );
    if (widget.initialUser != null) {
      _selectedRole = widget.initialUser!['role'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialUser == null
                  ? 'AÑADIR NUEVO USUARIO'
                  : 'EDITAR USUARIO',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Icon(Icons.account_circle, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de Usuario',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              items:
                  _roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BAE2F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.initialUser == null ? 'Añadir' : 'Guardar',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
    // Validar campos
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar formato de correo básico
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un correo válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (widget.initialUser == null) {
        // Crear nuevo usuario
        success = await _usuariosService.crearUsuario(
          nombreUsuario: _nameController.text.trim(),
          correo: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          rol: _selectedRole,
        );
      } else {
        // Actualizar usuario existente
        success = await _usuariosService.actualizarUsuario(
          id: widget.initialUser!['id_usuario'],
          nombreUsuario: _nameController.text.trim(),
          correo: _emailController.text.trim(),
          password: _passwordController.text.isNotEmpty ? _passwordController.text.trim() : null,
          rol: _selectedRole,
        );
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialUser == null 
                    ? 'Usuario creado exitosamente'
                    : 'Usuario actualizado exitosamente'
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar éxito
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el usuario. Verifique que el nombre de usuario y correo no estén en uso.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 768 ? 300 : double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.black26,
            builder:
                (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                    '¿Estás seguro que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        AuthUtils.logout(context);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Cerrar sesión'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
