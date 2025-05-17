import 'package:flutter/material.dart';
import 'Dashboard_content.dart';
import 'Cuadrilla_Content.dart';
//import 'Empleados_content.dart';
import 'Nomina_screen.dart' as nomina_screen;
import '../theme/app_styles.dart';
import 'Reportes_screen.dart';

// === Constantes de estilo globales ===
const double kSidebarWidth = 260;
const double kSidebarLogoHeight = 120;
const double kSidebarLogoIconSize = 48;
const double kSidebarLogoFontSize = 24;
const double kSidebarLogoSubFontSize = 14;
const double kSidebarItemRadius = 8;
const double kSidebarItemActiveWidth = 6;
const double kSidebarItemIconSize = 24;
const double kSidebarItemFontSize = 16;
const double kSidebarItemVerticalMargin = 4;
const double kDashboardPaddingTop = 8;
const double kDashboardPaddingSide = 32;
const double kDashboardPaddingBottom = 32;
const double kDashboardTitleFontSize = 54;
const double kDashboardTitleHeight = 1.1;
const double kDashboardSearchWidth = 420;
const double kDashboardSearchHeight = 48;
const double kDashboardCardRadius = 20;
const double kDashboardCardShadowBlur = 12;
const double kDashboardCardPaddingH = 24;
const double kDashboardCardPaddingV = 20;
const double kDashboardMetricFontSize = 32;
const double kDashboardMetricTitleFontSize = 22;
const double kDashboardMetricIconSize = 32;
const Color kSidebarActiveColor = Color(0xFF5BA829);
const Color kSidebarHoverColor = Color(0xFFF6FBF7);
const Color kSidebarDefaultColor = Colors.transparent;
const Color kSidebarActiveTextColor = Color(0xFF5BA829);
const Color kSidebarDefaultTextColor = Colors.grey;
const Color kSidebarLogoColor = Color(0xFF6B4F27);
const Color kSidebarLogoSubColor = Color(0xFF5BA829);
const Color kDashboardBackground = Color(0xFFF3E9D2);
const Color kDashboardTitleColor = Color(0xFF1B5E20);
const Color kDashboardButtonColor = Color(0xFF7BAE2F);
const Color kDashboardButtonTextColor = Colors.white;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;
  int? hoveredIndex;
  bool showFullTable = false;
  final List<_SidebarItemData> menuItems = [
    _SidebarItemData(icon: Icons.home, label: 'Dashboard'),
    _SidebarItemData(icon: Icons.people, label: 'Empleados'),
    _SidebarItemData(icon: Icons.groups, label: 'Cuadrillas'),
    _SidebarItemData(icon: Icons.event_note, label: 'Actividades'),
    _SidebarItemData(icon: Icons.attach_money, label: 'Nomina'),
    _SidebarItemData(icon: Icons.bar_chart, label: 'Reportes'),
    _SidebarItemData(icon: Icons.settings, label: 'Configuracion'),
  ];

  // Utilidad para sombra fuerte
  final BoxShadow strongShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 18,
    offset: Offset(0, 8),
  );

  Widget _getBodyContent() {
    switch (selectedIndex) {
      case 0:
        return DashboardHomeContent();
      //case 1:
       // return EmpleadosContent();
      case 2:
        return CuadrillaContent();
      case 4:
        return nomina_screen.NominaScreen(
          showFullTable: showFullTable,
          onCloseFullTable: () {
            setState(() {
              showFullTable = false;
            });
          },
          onOpenFullTable: () {
            setState(() {
              showFullTable = true;
            });
          },
        );
      case 5:
        return ReportesScreen();
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
            width: 260.0,
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black12,
                  blurRadius: AppDimens.cardShadowBlur,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  height: kSidebarLogoHeight,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: kSidebarLogoIconSize,
                        color: kSidebarLogoColor,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AGRIBAR',
                            style: TextStyle(
                              fontSize: kSidebarLogoFontSize,
                              fontWeight: FontWeight.bold,
                              color: kSidebarLogoColor,
                            ),
                          ),
                          Text(
                            'S. de R.L. de C.V.',
                            style: TextStyle(
                              fontSize: kSidebarLogoSubFontSize,
                              color: kSidebarLogoSubColor,
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
                // Main scrollable content
                Expanded(
                  child: Container(
                    color: kDashboardBackground,
                    padding: const EdgeInsets.only(top: kDashboardPaddingTop, left: kDashboardPaddingSide, right: kDashboardPaddingSide, bottom: kDashboardPaddingBottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 0, bottom: 20),
                          child: (selectedIndex == 4 && showFullTable)
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      menuItems[selectedIndex].label,
                                      style: TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.greenDark,
                                        height: 1.1,
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      width: kDashboardSearchWidth,
                                      height: kDashboardSearchHeight,
                                      decoration: BoxDecoration(
                                        boxShadow: [strongShadow],
                                        borderRadius: BorderRadius.circular(kDashboardCardRadius),
                                      ),
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: 'Buscar',
                                          prefixIcon: Icon(Icons.search),
                                          filled: true,
                                          fillColor: Color(0xFFF5F5F5),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(kDashboardCardRadius),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [strongShadow],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.green,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.buttonRadius)),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            showFullTable = false;
                                          });
                                        },
                                        child: Text('Volver', style: AppTextStyles.button),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      menuItems[selectedIndex].label,
                                      style: TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromARGB(255, 23, 139, 29),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Expanded(child: _getBodyContent()),
                      ],
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
}

class _SidebarItemData {
  final IconData icon;
  final String label;
  const _SidebarItemData({required this.icon, required this.label});
}

// === Widget reutilizable: Sidebar Item ===
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
    return MouseRegion(
      onEnter: (_) => onHover?.call(true),
      onExit: (_) => onHover?.call(false),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: kSidebarItemVerticalMargin),
            decoration: BoxDecoration(
              color: active
                  ? kSidebarHoverColor
                  : hovered
                      ? kSidebarHoverColor
                      : kSidebarDefaultColor,
              borderRadius: BorderRadius.circular(kSidebarItemRadius),
            ),
            child: ListTile(
              leading: Icon(
                icon,
                color: active ? kSidebarActiveTextColor : Colors.grey[600],
                size: kSidebarItemIconSize,
              ),
              title: Text(
                label,
                style: TextStyle(
                  color: active ? kSidebarActiveTextColor : Colors.grey[700],
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: kSidebarItemFontSize,
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
                width: kSidebarItemActiveWidth,
                decoration: BoxDecoration(
                  color: kSidebarActiveColor,
                  borderRadius: BorderRadius.circular(kSidebarItemRadius),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// === Widget reutilizable: Métrica Dashboard ===
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
    this.fontSize = kDashboardMetricFontSize,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: kDashboardCardPaddingH, vertical: kDashboardCardPaddingV),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kDashboardCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: kDashboardCardShadowBlur,
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
              fontSize: kDashboardMetricTitleFontSize,
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
                Icon(icon, color: iconColor ?? Colors.black, size: kDashboardMetricIconSize),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kDashboardCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kDashboardCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
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
