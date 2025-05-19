import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/login_screen.dart';
import '../utils/auth_utils.dart';

class ConfiguracionContent extends StatefulWidget {
  const ConfiguracionContent({Key? key}) : super(key: key);

  @override
  State<ConfiguracionContent> createState() => _ConfiguracionContentState();
}

class _ConfiguracionContentState extends State<ConfiguracionContent> {
  bool showTableModal = false; // Controla la visibilidad del modal de tabla
  List<List<String>>? loadedData; // Datos cargados desde archivos
  String? modalTitle; // Título del modal actual

  /// Lista de usuarios del sistema con sus roles y colores asociados.
  /// Cada usuario es representado por un Map con:
  /// - name: Nombre completo del usuario
  /// - role: Rol asignado (Admin, Capturista, Supervisor)
  /// - color: Color identificador del usuario
  final List<Map<String, dynamic>> _users = [
    {
      'name': 'José Luis Pérez López',
      'role': 'Admin',
      'color': const Color(0xFF7BAE2F), // Verde para administradores
    },
    {
      'name': 'Jesús Quintero Cázares',
      'role': 'Capturista',
      'color': const Color(0xFF2B8DDB), // Azul para capturistas
    },
    {
      'name': 'Adalberto Sainz Gómez',
      'role': 'Supervisor',
      'color': const Color(0xFF7B6A3A), // Marrón para supervisores
    },
  ];

  /// Simula la carga de datos desde un archivo.
  /// - Cuadrillas: Información de grupos de trabajo
  /// - Actividades: Lista de actividades disponibles
  void _simulateFilePick(String section) {
    // Simula la selección de un archivo y carga datos de ejemplo según la sección
    List<List<String>> data;
    String title;
    switch (section) {
      case 'Cuadrillas':
        title = 'Cuadrillas cargadas';
        data = [
          ['ID', 'Nombre', 'Supervisor'], // Encabezados
          ['1', 'Cuadrilla Norte', 'Juan Pérez'],
          ['2', 'Cuadrilla Sur', 'Ana López'],
        ];
        break;
      case 'Actividades':
        title = 'Actividades cargadas';
        data = [
          ['ID', 'Actividad', 'Fecha'],
          ['1', 'Riego', '2024-06-01'],
          ['2', 'Cosecha', '2024-06-02'],
        ];
        break;
      case 'Empleados':
        title = 'Empleados cargados';
        data = [
          ['ID', 'Nombre', 'Rol'],
          ['1', 'Carlos Ruiz', 'Supervisor'],
          ['2', 'María Torres', 'Capturista'],
        ];
        break;
      default:
        title = 'Datos cargados';
        data = [
          ['ID', 'Nombre', 'Rol'],
          ['1', 'Juan Pérez', 'Admin'],
        ];
    }
    setState(() {
      loadedData = data;
      modalTitle = title;
      showTableModal = true;
    });
  }

  void _closeModal() {
    setState(() {
      showTableModal = false;
      loadedData = null;
      modalTitle = null;
    });
  }

  void _showUserDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => const _AddUserDialog(),
    ).then((newUser) {
      if (newUser != null) {
        setState(() {
          _users.add(newUser as Map<String, dynamic>);
        });
      }
    });
  }

  void _handleEditUser(int index, Map<String, dynamic> editedUser) {
    setState(() {
      _users[index] = editedUser;
    });
  }

  void _handleDeleteUser(int index) {
    setState(() {
      _users.removeAt(index);
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  AuthUtils.logout(context);
                },
                child: const Text('Cerrar Sesión'),
                style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildUserSection(),
                const SizedBox(height: 32),
                _buildImportSection(),
                const SizedBox(height: 32),
                LogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Usuarios',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B7A2F),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user['color'] as Color,
                        child: Text(
                          user['name'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user['name'].toString()),
                      subtitle: Text(user['role'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => _showEditUserDialog(context, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                () => _showDeleteUserDialog(context, index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importar datos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildImportButton('Cuadrillas', Icons.groups),
                _buildImportButton('Actividades', Icons.work),
                _buildImportButton('Empleados', Icons.person),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _importFile(text),
      icon: Icon(icon),
      label: Text('Importar $text'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: Colors.black12),
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
  late TextEditingController _passwordController;
  String _selectedRole = 'Capturista';

  final List<String> _roles = ['Admin', 'Supervisor', 'Capturista'];

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
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_outline),
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
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty) {
                        // Mostrar mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor complete todos los campos',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop({
                        'name': _nameController.text.trim(),
                        'password': _passwordController.text.trim(),
                        'role': _selectedRole,
                        'color': _getColorForRole(_selectedRole),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BAE2F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.initialUser == null ? 'Añadir' : 'Guardar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1A1A),
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
