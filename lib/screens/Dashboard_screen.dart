import 'package:flutter/material.dart';
import 'Dashboard_content.dart';
import 'Empleados_content.dart';
import 'Nomina_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  int? hoveredIndex;
  final List<_SidebarItemData> menuItems = [
    _SidebarItemData(icon: Icons.home, label: 'Dashboard'),
    _SidebarItemData(icon: Icons.people, label: 'Empleados'),
    _SidebarItemData(icon: Icons.groups, label: 'Cuadrillas'),
    _SidebarItemData(icon: Icons.event_note, label: 'Actividades'),
    _SidebarItemData(icon: Icons.attach_money, label: 'Nomina'),
    _SidebarItemData(icon: Icons.bar_chart, label: 'Reportes'),
    _SidebarItemData(icon: Icons.settings, label: 'Configuracion'),
  ];

  Widget _getBodyContent() {
    switch (selectedIndex) {
      case 0:
        return DashboardHomeContent();
      case 1:
        return EmpleadosContent();
      case 4:
        return NominaScreen();
      // Puedes agregar más casos para otras pantallas
      default:
        return Center(child: Text('Próximamente...'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Logo
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 48,
                        color: Color(0xFF5BA829),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AGRIBAR',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4F27),
                            ),
                          ),
                          Text(
                            'S. de R.L. de C.V.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5BA829),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu
                Expanded(
                  child: MouseRegion(
                    onExit: (_) {
                      setState(() {
                        hoveredIndex = null;
                      });
                    },
                    child: ListView.builder(
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        return _SidebarItem(
                          icon: menuItems[index].icon,
                          label: menuItems[index].label,
                          selected: selectedIndex == index,
                          hovered: hoveredIndex == index,
                          onHover: (hovering) {
                            setState(() {
                              hoveredIndex = hovering ? index : null;
                            });
                          },
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar with title
                Container(
                  height: 80,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  color: Color(0xFFF5F5F5),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    menuItems[selectedIndex].label,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // Main scrollable content
                Expanded(
                  child: Container(
                    color: const Color(0xFFF3E9D2),
                    padding: const EdgeInsets.all(32),
                    child: _getBodyContent(),
                  ),
                ),
              ],
            ),
          ),
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
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.hovered = false,
    this.onTap,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = selected;
    final Color activeColor = Color(0xFF5BA829);
    final Color hoverColor = Color(0xFFF6FBF7); // Blanco con matiz verde
    final Color defaultColor = Colors.transparent;
    final Color activeTextColor = Color(0xFF5BA829);
    final Color defaultTextColor = Colors.grey[700]!;

    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color:
                  active
                      ? hoverColor
                      : hovered
                      ? hoverColor
                      : defaultColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(
                icon,
                color: active ? activeTextColor : Colors.grey[600],
              ),
              title: Text(
                label,
                style: TextStyle(
                  color: active ? activeTextColor : defaultTextColor,
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
                  color: activeColor,
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
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.fontSize = 32,
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

class _AlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Alertas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.error, color: Colors.red[400]),
              SizedBox(width: 8),
              Text(
                'Cuadrillas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Faltan capturas en 3 cuadrillas}'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[400]),
              SizedBox(width: 8),
              Text(
                'Empleados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Errores en 2 empleados}'),
            ],
          ),
        ],
      ),
    );
  }
}
