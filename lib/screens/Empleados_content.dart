import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

// === Constantes de estilo globales ===
const double kEmpleadosTabFontSize = 18;
const double kEmpleadosTabRadius = 4;
const double kEmpleadosTabUnderlineHeight = 3;
const double kEmpleadosTabUnderlineWidth = 60;
const double kEmpleadosTabSpacing = 24;
const double kEmpleadosMetricCardRadius = 30;
const double kEmpleadosMetricCardShadowBlur = 12;
const double kEmpleadosMetricCardPaddingH = 32;
const double kEmpleadosMetricCardPaddingV = 16;
const double kEmpleadosMetricTitleFontSize = 20;
const double kEmpleadosMetricValueFontSize = 32;
const double kEmpleadosMetricIconSize = 32;
const double kEmpleadosTableCardRadius = 18;
const double kEmpleadosTableCardShadowBlur = 12;
const double kEmpleadosTableCardPadding = 16;
const Color kEmpleadosTabSelectedColor = Colors.black;
const Color kEmpleadosTabUnselectedColor = Colors.grey;
const Color kEmpleadosTabUnderlineColor = Color(0xFF5BA829);
const Color kEmpleadosMetricCardColor = Colors.white;
const Color kEmpleadosTableHeaderColor = Color(0xFFF3F3F3);
const Color kEmpleadosTableCardColor = Colors.white;
const Color kEmpleadosTableBorderColor = Color(0xFFBDBDBD);

class EmpleadosContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Row(
          children: [
            _EmpleadosTab(text: 'General', selected: true),
            _EmpleadosTab(text: 'Registro'),
            _EmpleadosTab(text: 'Gestion'),
            _EmpleadosTab(text: 'Registro del Sistema'),
          ],
        ),
        SizedBox(height: 16),
        // Métricas
        Row(
          children: [
            _EmpleadosMetricCard(
              title: 'Empleados activos',
              value: '87',
              icon: Icons.person,
            ),
            SizedBox(width: 32),
            _EmpleadosMetricCard(
              title: 'Empleados inactivos',
              value: '87',
              icon: Icons.person,
            ),
          ],
        ),
        SizedBox(height: 32),
        // Tabla
        Expanded(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black12,
                    blurRadius: AppDimens.cardShadowBlur,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(AppDimens.tableCardPadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(kEmpleadosTableHeaderColor),
                  border: TableBorder.all(color: kEmpleadosTableBorderColor, width: 1),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Clave',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nombre',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Apellido Paterno',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Apellido Materno',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cuadrilla',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Sueldo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: const [
                    DataRow(
                      cells: [
                        DataCell(Text('*390')),
                        DataCell(Text('Juan Carlos')),
                        DataCell(Text('Rodríguez')),
                        DataCell(Text('Fierro')),
                        DataCell(Text('JOSE FRANCISCO GONZALES REA')),
                        DataCell(Text('241.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('000001*390')),
                        DataCell(Text('Celestino')),
                        DataCell(Text('Hernandez')),
                        DataCell(Text('Martinez')),
                        DataCell(Text('Indirectos')),
                        DataCell(Text('2375.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('000002*390')),
                        DataCell(Text('Ines')),
                        DataCell(Text('Cruz')),
                        DataCell(Text('Quiroz')),
                        DataCell(Text('Indirectos')),
                        DataCell(Text('2375.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('000003*390')),
                        DataCell(Text('Feliciano')),
                        DataCell(Text('Cruz')),
                        DataCell(Text('Quiroz')),
                        DataCell(Text('Indirectos')),
                        DataCell(Text('2375.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('000003*390')),
                        DataCell(Text('Refugio Socorro')),
                        DataCell(Text('Ramirez')),
                        DataCell(Text('Carre--o')),
                        DataCell(Text('Indirectos')),
                        DataCell(Text('2375.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('000004*390')),
                        DataCell(Text('Adela')),
                        DataCell(Text('Rodriguez')),
                        DataCell(Text('Ramirez')),
                        DataCell(Text('Indirectos')),
                        DataCell(Text('2375.00')),
                        DataCell(Text('Fijo')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// === Widget reutilizable: Tab de empleados ===
class _EmpleadosTab extends StatelessWidget {
  final String text;
  final bool selected;
  const _EmpleadosTab({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: kEmpleadosTabSpacing),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: kEmpleadosTabFontSize,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.greenDark : Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: kEmpleadosTabUnderlineHeight,
            width: selected ? kEmpleadosTabUnderlineWidth : 0,
            decoration: BoxDecoration(
              color: selected ? kEmpleadosTabUnderlineColor : Colors.transparent,
              borderRadius: BorderRadius.circular(kEmpleadosTabRadius),
            ),
          ),
        ],
      ),
    );
  }
}

// === Widget reutilizable: Métrica empleados ===
class _EmpleadosMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _EmpleadosMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: kEmpleadosMetricCardPaddingH, vertical: kEmpleadosMetricCardPaddingV),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kEmpleadosMetricCardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: kEmpleadosMetricCardShadowBlur,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: kEmpleadosMetricTitleFontSize,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: kEmpleadosMetricValueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 8),
          Icon(icon, color: Colors.black, size: kEmpleadosMetricIconSize),
        ],
      ),
    );
  }
}
