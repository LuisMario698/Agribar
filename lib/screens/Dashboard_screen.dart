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
  const DashboardScreen({
    super.key,
    this.appTheme = AppTheme.light, // Por defecto usa el tema claro
    this.onThemeChanged,
     required this.nombre, required this.rol
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Estado del DashboardScreen que mantiene la lógica de navegación
/// y la interacción con el menú lateral.
class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0; // Índice del elemento seleccionado en el menú
  int? hoveredIndex; // Índice del elemento sobre el que está el cursor
  final ScrollController _scrollController = ScrollController();

  /// Lista de elementos del menú lateral
  /// Cada elemento contiene un ícono y una etiqueta
  final List<_SidebarItemData> menuItems = [
    _SidebarItemData(icon: Icons.home, label: 'Dashboard'), // Panel principal
    _SidebarItemData(
      icon: Icons.people,
      label: 'Empleados',
    ), // Gestión de empleados
    _SidebarItemData(
      icon: Icons.groups,
      label: 'Cuadrillas',
    ), // Gestión de cuadrillas
    _SidebarItemData(
      icon: Icons.event_note,
      label: 'Actividades',
    ), // Registro de actividades
    _SidebarItemData(
      icon: Icons.attach_money,
      label: 'Nomina',
    ), // Gestión de nómina
    _SidebarItemData(
      icon: Icons.bar_chart,
      label: 'Reportes',
    ), // Generación de reportes
    _SidebarItemData(
      icon: Icons.settings,
      label: 'Configuraciones',
    ), // Configuración del sistema
  ];

  @override
  void dispose() {
    _scrollController.dispose(); // Liberar recursos del controlador de scroll
    super.dispose();
  }

  /// Retorna el widget correspondiente a la sección seleccionada
  /// basado en el índice actual del menú.
  Widget _getBodyContent() {
    switch (selectedIndex) {
      case 0:
        return DashboardHomeContent(userName: widget.nombre,userRole: widget.rol,);
      case 1:
        return EmpleadosContent();
      case 2:
        return CuadrillaContent();
      case 3:
        return ActividadesContent();
      case 4:
        return NominaScreen();
      case 5:
        return ReportesScreen();
      case 6:
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
                                onTap:
                                    () => setState(() => selectedIndex = index),
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
  const _SidebarItemData({required this.icon, required this.label});
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final double fontSize;
  const _MetricCard({
    required this.title,
    required this.value, this.icon, this.iconColor, this.valueColor, required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black,
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 8),
                Icon(icon, color: iconColor ?? Colors.black, size: 32),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Abr', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

