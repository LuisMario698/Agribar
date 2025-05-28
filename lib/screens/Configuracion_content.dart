import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/login_screen.dart';
import '../utils/auth_utils.dart';
import '../widgets/widgets.dart';

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
                        Expanded(child: _buildImportSection()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildUserSection()),
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
                      child: CustomButton(
                        text: 'Cerrar Sesión',
                        type: ButtonType.danger,
                        onPressed: () {
                          CustomConfirmationDialog.showLogout(
                            context: context,
                            onConfirm: () {
                              AuthUtils.logout(context);
                            },
                          );
                        },
                        icon: Icon(Icons.logout, color: Colors.white),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Administrar Usuarios',
              leading: Icon(Icons.manage_accounts, color: Colors.grey[700]),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 24),
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
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        itemBuilder:
                            (context) => [
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
                                    const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
            CustomButton(
              text: 'Agregar usuario',
              type: ButtonType.primary,
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () => _showUserDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile(String type) async {
    try {
      // Mostrar overlay de carga
      final loadingOverlay = LoadingOverlay(
        isVisible: true,
        message: 'Importando ${type.toLowerCase()}...',
        child: Container(), // Contenedor vacío ya que el overlay es modal
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => loadingOverlay,
      );

      // Simulamos un proceso de importación
      await Future.delayed(const Duration(seconds: 2));

      // Cerramos el diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      CustomSnackBar.showSuccess(context, '${type} importados correctamente');
    } catch (e) {
      // En caso de error, mostrar mensaje
      CustomSnackBar.showError(
        context,
        'Error al importar ${type.toLowerCase()}: $e',
      );
    }
  }

  Widget _buildImportSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Cargar desde excel',
              leading: Icon(Icons.file_upload, color: Colors.grey[700]),
              backgroundColor: Colors.transparent,
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
    return CustomButton(
      text: text,
      type: ButtonType.secondary,
      icon: Icon(Icons.download, color: Color(0xFF0B7A2F)),
      onPressed: () => _importFile(text),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      backgroundColor: Colors.grey[100],
      foregroundColor: Colors.grey[800],
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
    final userName = _users[index]['name'];
    CustomConfirmationDialog.showDelete(
      context: context,
      title: 'Eliminar usuario',
      message: '¿Estás seguro que deseas eliminar a $userName?',
      onConfirm: () {
        setState(() {
          _users.removeAt(index);
        });
      },
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
            CustomInputField(
              controller: _nameController,
              label: 'Usuario',
              prefix: Icon(Icons.person_outline),
              fillColor: Color(0xFFF5F5F5),
            ),
            const SizedBox(height: 16),
            CustomInputField(
              controller: _passwordController,
              label: 'Contraseña',
              prefix: Icon(Icons.lock_outline),
              obscureText: true,
              fillColor: Color(0xFFF5F5F5),
            ),
            const SizedBox(height: 16),
            CustomDropdownField<String>(
              label: 'Rol',
              value: _selectedRole,
              items: _roles,
              itemLabel: (role) => role,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
              fillColor: Color(0xFFF5F5F5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: widget.initialUser == null ? 'Añadir' : 'Guardar',
                    type: ButtonType.success,
                    onPressed: () {
                      if (_nameController.text.trim().isEmpty ||
                          _passwordController.text.trim().isEmpty) {
                        // Mostrar mensaje de error
                        CustomSnackBar.showError(
                          context,
                          'Por favor complete todos los campos',
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
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    type: ButtonType.danger,
                    onPressed: () => Navigator.of(context).pop(),
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
