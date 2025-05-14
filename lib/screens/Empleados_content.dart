import 'package:flutter/material.dart';

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Color(0xFFF3F3F3)),
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

class _EmpleadosTab extends StatelessWidget {
  final String text;
  final bool selected;
  const _EmpleadosTab({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.black : Colors.grey[700],
            ),
          ),
          SizedBox(height: 4),
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 3,
            width: selected ? 60 : 0,
            decoration: BoxDecoration(
              color: selected ? Color(0xFF5BA829) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
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
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 8),
          Icon(icon, color: Colors.black, size: 32),
        ],
      ),
    );
  }
}
