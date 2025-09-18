import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/usuarios_service.dart';
import '../services/roles_service.dart';
import '../theme/app_styles.dart';

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
    _loadUsersAndRoles();
  }

  /// Carga los usuarios y roles desde la base de datos
  Future<void> _loadUsersAndRoles() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      // Cargar usuarios
      final usuarios = await _usuariosService.obtenerUsuarios();
      setState(() {
        _users = usuarios.map((usuario) => {
          'id_usuario': usuario['id_usuario'],
          'name': usuario['nombre_usuario'], // Para mostrar en la UI
          'nombre_usuario': usuario['nombre_usuario'], // Para editar
          'role': usuario['rol_descripcion'] ?? 'Sin rol',
          'rol': usuario['rol'], // ID del rol para editar
          'correo': usuario['correo'],
          'color': _getColorForRole(usuario['rol_descripcion'] ?? ''),
        }).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  /// Carga solo los usuarios desde la base de datos
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final usuarios = await _usuariosService.obtenerUsuarios();
      setState(() {
        _users = usuarios.map((usuario) => {
          'id_usuario': usuario['id_usuario'],
          'name': usuario['nombre_usuario'], // Para mostrar en la UI
          'nombre_usuario': usuario['nombre_usuario'], // Para editar
          'role': usuario['rol_descripcion'] ?? 'Sin rol',
          'rol': usuario['rol'], // ID del rol para editar
          'correo': usuario['correo'],
          'color': _getColorForRole(usuario['rol_descripcion'] ?? ''),
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

  Color _getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return AppColors.green; // Verde principal para administradores
      case 'capturista':
        return const Color(0xFF2196F3); // Azul para capturistas
      case 'supervisor':
        return const Color(0xFFFF9800); // Naranja para supervisores
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
            return Container(
              padding: const EdgeInsets.all(32),
              width: constraints.maxWidth * 0.95, // Usar 95% del ancho disponible
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserSection(),
                  const SizedBox(height: 24),
                  // Label simple de resolución abajo a la derecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Resolución: ${MediaQuery.of(context).size.width.toInt()} x ${MediaQuery.of(context).size.height.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header moderno con iconos y gradiente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.green,
                    AppColors.greenDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administración de Usuarios',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestiona los usuarios del sistema',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingUsers)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Botón de agregar usuario en la parte superior
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.green,
                    AppColors.greenDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUserDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Agregar nuevo usuario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contenido de usuarios en tabla
            if (_isLoadingUsers)
              Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando usuarios...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_users.isEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega el primer usuario al sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Tabla de usuarios con scroll
              _buildUsersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas rápidas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Text(
                '${_users.length} usuario${_users.length != 1 ? 's' : ''} registrado${_users.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Tabla con scroll
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header de la tabla
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar + Usuario (40%)
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Usuario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    // Rol (20%)
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Rol',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Correo (30%)
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Correo Electrónico',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    // Acciones (10%)
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Acciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido de la tabla con scroll
              Container(
                height: _users.length > 6 ? 350 : (_users.length * 65.0), // Altura dinámica
                constraints: const BoxConstraints(
                  minHeight: 100,
                  maxHeight: 350,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_users.length, (index) {
                      final user = _users[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Usuario (Avatar + Nombre) - 40%
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          user['color'] as Color,
                                          (user['color'] as Color).withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (user['color'] as Color).withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        user['name'].toString().substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Información del usuario
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user['name'].toString(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: ${user['id_usuario']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Rol - 20%
                            Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (user['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (user['color'] as Color).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  user['role'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: user['color'] as Color,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            
                            // Correo - 30%
                            Expanded(
                              flex: 3,
                              child: user['correo'] != null
                                  ? Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            user['correo'].toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Sin correo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                            ),
                            
                            // Acciones - 10%
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botón editar
                                  Container(
                                    width: 28,
                                    height: 28,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showEditUserDialog(context, index),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          color: Colors.blue[600],
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón eliminar
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showDeleteUserDialog(context, index),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Icon(
                                          Icons.delete_rounded,
                                          color: Colors.red[600],
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditUserDialog(BuildContext context, int index) {
    final user = _users[index];
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => _AddUserDialog(initialUser: user),
    ).then((success) {
      if (success == true) {
        _loadUsers(); // Recargar la lista de usuarios
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
                onPressed: () async {
                  try {
                    final userId = _users[index]['id_usuario'];
                    final success = await _usuariosService.eliminarUsuario(userId);
                    
                    Navigator.of(context).pop();
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario eliminado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadUsers(); // Recargar la lista
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al eliminar el usuario'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
  int? _selectedRoleId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _roles = [];
  final UsuariosService _usuariosService = UsuariosService();
  final RolesService _rolesService = RolesService();

  Color _getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrador':
        return AppColors.green; // Verde principal para administradores
      case 'capturista':
        return const Color(0xFF2196F3); // Azul para capturistas
      case 'supervisor':
        return const Color(0xFFFF9800); // Naranja para supervisores
      default:
        return const Color(0xFF6B7280); // Gris para otros roles
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialUser?['nombre_usuario'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialUser?['correo'] ?? '',
    );
    _passwordController = TextEditingController(
      text: '', // No cargar contraseña por seguridad
    );
    _loadRoles();
    if (widget.initialUser != null) {
      _selectedRoleId = widget.initialUser!['rol']; // Usar 'rol' no 'rol_id'
    }
  }

  /// Carga la lista de roles disponibles
  Future<void> _loadRoles() async {
    try {
      final roles = await _rolesService.obtenerRolesParaDropdown();
      setState(() {
        _roles = roles;
        // Si no hay rol seleccionado y hay roles disponibles, seleccionar el primero
        if (_selectedRoleId == null && _roles.isNotEmpty) {
          _selectedRoleId = _roles.first['id_rol'];
        }
      });
    } catch (e) {
      print('Error cargando roles: $e');
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
      backgroundColor: Colors.transparent,
      child: Container(
        width: 450,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.green,
                    AppColors.greenDark,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      widget.initialUser == null 
                          ? Icons.person_add_rounded 
                          : Icons.edit_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.initialUser == null
                        ? 'Agregar Nuevo Usuario'
                        : 'Editar Usuario',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.initialUser == null
                        ? 'Complete los datos del nuevo usuario'
                        : 'Modifique los datos del usuario',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Contenido del formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo nombre
                    _buildStyledTextField(
                      controller: _nameController,
                      label: 'Nombre de Usuario',
                      icon: Icons.person_rounded,
                      hint: 'Ingrese el nombre de usuario',
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo email
                    _buildStyledTextField(
                      controller: _emailController,
                      label: 'Correo Electrónico',
                      icon: Icons.email_rounded,
                      hint: 'usuario@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo contraseña
                    _buildStyledTextField(
                      controller: _passwordController,
                      label: widget.initialUser == null ? 'Contraseña' : 'Nueva Contraseña (opcional)',
                      icon: Icons.lock_rounded,
                      hint: widget.initialUser == null ? 'Ingrese una contraseña segura' : 'Dejar vacío para mantener actual',
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    
                    // Dropdown de roles estilizado
                    _buildStyledRoleDropdown(),
                    
                    const SizedBox(height: 32),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: _buildCancelButton(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildSaveButton(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.green, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol del Usuario',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedRoleId,
            decoration: InputDecoration(
              hintText: 'Seleccione un rol',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.work_rounded, color: AppColors.green, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            selectedItemBuilder: (BuildContext context) {
              return _roles.map<Widget>((role) {
                final color = _getColorForRole(role['descripcion']);
                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role['descripcion'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                );
              }).toList();
            },
            items: _roles.map((role) {
              final color = _getColorForRole(role['descripcion']);
              return DropdownMenuItem<int>(
                value: role['id_rol'],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForRole(role['descripcion']),
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role['descripcion'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getDescriptionForRole(role['descripcion']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRoleId = value!;
              });
            },
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.green,
            AppColors.greenDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveUser,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.initialUser == null ? Icons.add_rounded : Icons.save_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.initialUser == null ? 'Agregar Usuario' : 'Guardar Cambios',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrador':
        return Icons.admin_panel_settings;
      case 'capturista':
        return Icons.edit;
      case 'supervisor':
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  String _getDescriptionForRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrador':
        return 'Acceso total al sistema';
      case 'capturista':
        return 'Registro de información';
      case 'supervisor':
        return 'Supervisión y reportes';
      default:
        return 'Usuario estándar';
    }
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

    // Validar que se haya seleccionado un rol
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un rol'),
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
          rolId: _selectedRoleId!,
        );
      } else {
        // Actualizar usuario existente
        success = await _usuariosService.actualizarUsuario(
          id: widget.initialUser!['id_usuario'],
          nombreUsuario: _nameController.text.trim(),
          correo: _emailController.text.trim(),
          password: _passwordController.text.isNotEmpty ? _passwordController.text.trim() : null,
          rolId: _selectedRoleId!, // Usar ! ya que se validó arriba
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


