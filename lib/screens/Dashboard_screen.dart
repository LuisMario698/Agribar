/// Archivo: Dashboard_screen.dart
/// Pantalla principal del sistema Agribar que implementa el panel de control
/// y la navegación principal de la aplicación.
///
/// Esta pantalla es responsable de:
/// - Gestionar la barra lateral de navegación
/// - Controlar el cambio entre diferentes secciones
/// - Mantener el estado del tema de la aplicación
/// - Mostrar el contenido correspondiente a cada sección

import 'package:flutter/material.dart';
import 'Dashboard_content.dart';
import 'Empleados_content.dart';
import 'Nomina_screen.dart';
import 'Actividades_content.dart';
import 'Configuracion_content.dart';
import 'AppTheme.dart';
import 'Cuadrilla_Content.dart';
import 'Reportes_screen.dart';
import 'Login_screen.dart';
import '../services/database_migration_service.dart';
import '../widgets/nomina_tab_change_interceptor.dart';

/// Widget principal del panel de control.
///
/// Maneja el estado del tema y la navegación entre diferentes secciones
/// de la aplicación a través de una barra lateral.
class DashboardScreen extends StatefulWidget {
  final AppTheme appTheme; // Tema actual de la aplicación
  final void Function(AppTheme)?
  onThemeChanged; // Callback para cambiar el tema
  final String nombre;
  final int rol;
  final String? tipoUsuario;
  final List<String>? seccionesPermitidas;
  
  const DashboardScreen({
    super.key,
    this.appTheme = AppTheme.light, // Por defecto usa el tema claro
    this.onThemeChanged,
    required this.nombre, 
    required this.rol,
    this.tipoUsuario,
    this.seccionesPermitidas,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Estado del DashboardScreen que mantiene la lógica de navegación
/// y la interacción con el menú lateral.
class _DashboardScreenState extends State<DashboardScreen> with NominaTabChangeGuardMixin {
  int selectedIndex = 0; // Índice del elemento seleccionado en el menú
  int? hoveredIndex; // Índice del elemento sobre el que está el cursor
  final ScrollController _scrollController = ScrollController();
  
  // Variables para manejar cambios no guardados en nómina
  bool _tieneCambiosNoGuardados = false;
  
  // Función de guardado que será proporcionada por NominaScreen
  Future<void> Function()? _funcionGuardadoNomina;

  /// Lista de elementos del menú lateral
  /// Cada elemento contiene un ícono y una etiqueta
  final List<_SidebarItemData> _allMenuItems = [
    _SidebarItemData(icon: Icons.home, label: 'Dashboard', seccion: 'dashboard'), // Panel principal
    _SidebarItemData(
      icon: Icons.people,
      label: 'Empleados',
      seccion: 'empleados',
    ), // Gestión de empleados
    _SidebarItemData(
      icon: Icons.groups,
      label: 'Cuadrillas',
      seccion: 'cuadrillas',
    ), // Gestión de cuadrillas
    _SidebarItemData(
      icon: Icons.event_note,
      label: 'Actividades',
      seccion: 'actividades',
    ), // Registro de actividades
    _SidebarItemData(
      icon: Icons.attach_money,
      label: 'Nomina',
      seccion: 'nomina',
    ), // Gestión de nómina
    _SidebarItemData(
      icon: Icons.bar_chart,
      label: 'Reportes',
      seccion: 'reportes',
    ), // Generación de reportes
    _SidebarItemData(
      icon: Icons.settings,
      label: 'Configuraciones',
      seccion: 'configuracion',
    ), // Configuración del sistema
  ];

  /// Lista filtrada de elementos del menú según permisos del usuario
  List<_SidebarItemData> get menuItems {
    if (widget.seccionesPermitidas == null) {
      // Si no hay permisos específicos, mostrar todo (compatibilidad)
      return _allMenuItems;
    }

    // Filtrar elementos según permisos
    List<_SidebarItemData> itemsPermitidos = [];
    
    for (var item in _allMenuItems) {
      if (item.seccion == 'dashboard') {
        // Dashboard siempre visible
        itemsPermitidos.add(item);
      } else if (widget.seccionesPermitidas!.contains(item.seccion)) {
        // Solo agregar si tiene permisos
        itemsPermitidos.add(item);
      }
    }
    
    return itemsPermitidos;
  }

  @override
  void initState() {
    super.initState();
    // 🚀 Ejecutar migración automáticamente al inicio
    _verificarYEjecutarMigracion();
  }

  /// Verifica y ejecuta la migración de base de datos si es necesario
  Future<void> _verificarYEjecutarMigracion() async {
    try {
      print('🔍 Verificando estado de migración de BD...');
      final yaAplicada = await DatabaseMigrationService.verificarMigracionAplicada();
      
      if (!yaAplicada) {
        print('⚙️ Aplicando migración para permitir múltiples cuadrillas...');
        final exito = await DatabaseMigrationService.permitirEmpleadoEnMultiplesCuadrillas();
        
        if (exito) {
          print('✅ Migración aplicada exitosamente');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Sistema actualizado: Los empleados ahora pueden estar en múltiples cuadrillas por semana'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('❌ Error al aplicar migración');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Error al actualizar sistema. Contacte al administrador.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        print('✅ Migración ya aplicada previamente');
      }
    } catch (e) {
      print('❌ Error al verificar migración: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Liberar recursos del controlador de scroll
    super.dispose();
  }

  /// Maneja el cambio de pestaña con verificación de cambios no guardados
  Future<void> _onTabSelected(int newIndex) async {
    // Si estamos saliendo de la pestaña de nómina (índice 4) y hay cambios no guardados
    if (selectedIndex == 4 && newIndex != 4 && _tieneCambiosNoGuardados) {
      final puedeNavegar = await verificarCambiosAntesDeCambiarTab(
        tieneCambiosNoGuardados: _tieneCambiosNoGuardados,
        onGuardar: () async {
          // Llamar a la función de guardado real de NominaScreen
          if (_funcionGuardadoNomina != null) {
            try {
              await _funcionGuardadoNomina!();
              setState(() {
                _tieneCambiosNoGuardados = false;
              });
            } catch (e) {
              // El error ya se maneja en _guardarNomina(), solo aseguramos que no cambie el estado
              print('Error al guardar desde el interceptor: $e');
              rethrow; // Re-lanzar para que el diálogo maneje el error
            }
          } else {
            // Fallback si no hay función de guardado configurada
            setState(() {
              _tieneCambiosNoGuardados = false;
            });
          }
        },
        onSalirSinGuardar: () {
          // Descartar cambios
          setState(() {
            _tieneCambiosNoGuardados = false;
          });
        },
        mensajePersonalizado: 
          'Los cambios en la nómina se perderán si cambias de sección sin guardar.\n\n¿Qué deseas hacer?',
      );
      
      if (!puedeNavegar) return; // Cancelar navegación
    }
    
    setState(() {
      selectedIndex = newIndex;
    });
  }

  /// Callback para recibir notificaciones de cambios desde NominaScreen
  void _onNominaChanged(bool tieneCambios) {
    setState(() {
      _tieneCambiosNoGuardados = tieneCambios;
    });
  }

  /// Método para establecer la función de guardado de nómina
  void _setFuncionGuardadoNomina(Future<void> Function() funcionGuardado) {
    _funcionGuardadoNomina = funcionGuardado;
  }

  /// Retorna el widget correspondiente a la sección seleccionada
  /// basado en el índice actual del menú filtrado.
  Widget _getBodyContent() {
    // Obtener el elemento seleccionado de la lista filtrada
    final selectedItem = selectedIndex < menuItems.length 
        ? menuItems[selectedIndex] 
        : null;
    
    if (selectedItem == null) {
      return Center(
        child: Text(
          'Sección no encontrada',
          style: TextStyle(
            color: widget.appTheme == AppTheme.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      );
    }

    // Usar la sección real en lugar del índice
    switch (selectedItem.seccion) {
      case 'dashboard':
        return DashboardHomeContent(
          userName: widget.nombre,
          userRole: widget.rol,
          tipoUsuario: widget.tipoUsuario ?? 'Usuario',
          seccionesPermitidas: widget.seccionesPermitidas ?? [],
        );
      case 'empleados':
        return EmpleadosContent();
      case 'cuadrillas':
        return CuadrillaContent();
      case 'actividades':
        return ActividadesContent();
      case 'nomina':
        return NominaScreen(
          onCambiosChanged: _onNominaChanged,
          onGuardadoCallbackSet: _setFuncionGuardadoNomina,
        );
      case 'reportes':
        return ReportesScreen();
      case 'configuracion':
        return ConfiguracionContent();
      default:
        return Center(
          child: Text(
            'Próximamente...',
            style: TextStyle(
              color:
                  widget.appTheme == AppTheme.dark
                      ? Colors.white
                      : Colors.black,
            ),
          ),
        );
    }
  }

  /// Construye la card del usuario y el botón de cerrar sesión
  Widget _buildUserCard(bool isDark, Color sidebarColor, Color sidebarText) {
    // Obtener el color del tipo de usuario usando ControlUsuarioService
    Color getUserTypeColor() {
      if (widget.tipoUsuario != null) {
        switch (widget.tipoUsuario!.toLowerCase()) {
          case 'administrador':
            return Color(0xFF7BAE2F); // Verde
          case 'supervisor':
            return Color(0xFF7B6A3A); // Marrón
          case 'capturista':
            return Color(0xFF2B8DDB); // Azul
          default:
            return Color(0xFF6B7280); // Gris
        }
      }
      return Color(0xFF6B7280); // Gris por defecto
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Separador
          Container(
            height: 1,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
            ),
          ),
          // Card del usuario
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2D2D2D) : Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar con color del tipo de usuario
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: getUserTypeColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    // Información del usuario
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nombre,
                            style: TextStyle(
                              color: sidebarText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.tipoUsuario ?? 'Usuario',
                            style: TextStyle(
                              color: getUserTypeColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.logout, size: 18),
                    label: Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
  }

  /// Muestra el diálogo de confirmación para cerrar sesión
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appTheme == AppTheme.dark;
    final bgColor = isDark ? Color(0xFF232323) : Color(0xFFF3E9D2);
    final sidebarColor = isDark ? Color(0xFF181818) : Colors.white;
    final sidebarText = isDark ? Colors.white : Colors.grey[700]!;
    final sidebarActive = Color(0xFF5BA829);
    final sidebarHover = isDark ? Color(0xFF2D2D2D) : Color(0xFFF6FBF7);
    final sidebarIcon = isDark ? Colors.white : Colors.grey[600]!;
    final sidebarActiveText = Color(0xFF5BA829);

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: sidebarColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo y título
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Row(
                    children: [Image.asset('assets/logo.jpg', width: 210)],
                  ),
                ),
                // Menú scrollable
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children:
                            menuItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _SidebarItem(
                                icon: item.icon,
                                label: item.label,
                                selected: selectedIndex == index,
                                hovered: hoveredIndex == index,
                                onTap: () => _onTabSelected(index),
                                onHover:
                                    (isHovered) => setState(
                                      () =>
                                          hoveredIndex =
                                              isHovered ? index : null,
                                    ),
                                isDark: isDark,
                                sidebarActive: sidebarActive,
                                sidebarHover: sidebarHover,
                                sidebarText: sidebarText,
                                sidebarActiveText: sidebarActiveText,
                                sidebarIcon: sidebarIcon,
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
                // Card del usuario y botón de cerrar sesión
                _buildUserCard(isDark, sidebarColor, sidebarText),
              ],
            ),
          ),
          // Contenido principal
          Expanded(child: _getBodyContent()),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  final IconData icon;
  final String label;
  final String seccion;
  const _SidebarItemData({
    required this.icon, 
    required this.label, 
    required this.seccion,
  });
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool hovered;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHover;
  final bool isDark;
  final Color sidebarActive;
  final Color sidebarHover;
  final Color sidebarText;
  final Color sidebarActiveText;
  final Color sidebarIcon;
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.hovered = false,
    this.onTap,
    this.onHover,
    required this.isDark,
    required this.sidebarActive,
    required this.sidebarHover,
    required this.sidebarText,
    required this.sidebarActiveText,
    required this.sidebarIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = selected;
    final Color bgColor =
        active
            ? sidebarHover
            : hovered
            ? sidebarHover
            : Colors.transparent;
    final Color textColor = active ? sidebarActiveText : sidebarText;
    final Color iconColor = active ? sidebarActive : sidebarIcon;

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(icon, color: iconColor),
              title: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: active,
              onTap: onTap,
            ),
          ),
          if (active)
            Positioned(
              top: 12,
              bottom: 12,
              right: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: sidebarActive,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}