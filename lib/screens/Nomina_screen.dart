import 'package:flutter/material.dart';

class NominaScreen extends StatefulWidget {
  const NominaScreen({super.key});

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> {
  bool showFullTable = false;

  @override
  Widget build(BuildContext context) {
    final table = _NominaTable();
    return Container(
      color: const Color(0xFFF3E9D2),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de filtros semana/cuadrilla y botón cargar platilla
                Padding(
                  padding: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Semana
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Semana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.green[900])),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _DateSelector(label: 'Inicio'),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      _DateSelector(label: 'Final'),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(width: 48),
                              // Cuadrilla
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Cuadrilla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.green[900])),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('JESUS BADILLO CASTILLO', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
                                        Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 24),
                      // Botón cargar platilla
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7BAE2F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        ),
                        onPressed: () {},
                        child: Text('Cargar platilla', style: TextStyle(fontSize: 22, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                // Buscador y tarjetas indicadores
                Padding(
                  padding: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Buscador
                      Container(
                        width: 420,
                        height: 48,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF7BAE2F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.search, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Color(0xFF7BAE2F)),
                        onPressed: () {},
                      ),
                      Spacer(),
                      // Indicadores cuadrados mejor alineados y sin overflow
                      _IndicatorCard(
                        label: 'Empleados en cuadrilla',
                        value: '30',
                        icon: Icons.person,
                        iconColor: Color(0xFF7BAE2F),
                        valueStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        labelStyle: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 16),
                      _IndicatorCard(
                        label: 'Total Cuadrilla',
                        value: '15,525',
                        icon: Icons.attach_money,
                        iconColor: Color(0xFF7BAE2F),
                        valueStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        labelStyle: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Tabla de nómina
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 0),
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
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showFullTable = true;
                                });
                              },
                              icon: Icon(Icons.fullscreen, color: Color(0xFF43A047)),
                              label: Text('Ver tabla completa', style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: table,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Botones de acción
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7BAE2F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                        ),
                        onPressed: () {},
                        child: Text('Confirmar y guardar', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            ),
                            onPressed: () {},
                            child: Text('PDF', style: TextStyle(fontSize: 20, color: Colors.white)),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7BAE2F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            ),
                            onPressed: () {},
                            child: Text('EXCEL', style: TextStyle(fontSize: 20, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dialogo de tabla completa
          if (showFullTable)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Material(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.85,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: _NominaTable(),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red, size: 32),
                              onPressed: () {
                                setState(() {
                                  showFullTable = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  const _DateSelector({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 6),
          Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueStyle,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(label, style: labelStyle ?? TextStyle(fontSize: 18, color: Colors.grey[700]), overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          SizedBox(width: 8),
          Icon(icon, color: iconColor),
          SizedBox(width: 8),
          Text(value, style: valueStyle ?? TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _NominaTable extends StatelessWidget {
  const _NominaTable();

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Color(0xFFF3F3F3)),
      columnSpacing: 32,
      columns: const [
        DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Dias trabajados', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Pago diario', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('total semanal', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('come comedero', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Deducciones', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Neto a pagar', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('Adela Rodriguez Ramirez')),
          DataCell(Text('4')),
          DataCell(Text('375')),
          DataCell(Text('1,500')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('1,500')),
        ]),
        DataRow(cells: [
          DataCell(Text('Elizabeth Rodriguez Ramirez')),
          DataCell(Text('7')),
          DataCell(Text('375')),
          DataCell(Text('2,625')),
          DataCell(Text('si')),
          DataCell(Text('200')),
          DataCell(Text('2,425')),
        ]),
        DataRow(cells: [
          DataCell(Text('Pedro Sanchez Velasco')),
          DataCell(Text('6')),
          DataCell(Text('375')),
          DataCell(Text('2,250')),
          DataCell(Text('si')),
          DataCell(Text('200')),
          DataCell(Text('2,050')),
        ]),
        DataRow(cells: [
          DataCell(Text('Magdalena Bautista Ramirez')),
          DataCell(Text('6')),
          DataCell(Text('375')),
          DataCell(Text('2,250')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('2,250')),
        ]),
        DataRow(cells: [
          DataCell(Text('Leonides Cruz Quiroz')),
          DataCell(Text('7')),
          DataCell(Text('375')),
          DataCell(Text('2,625')),
          DataCell(Text('si')),
          DataCell(Text('200')),
          DataCell(Text('2,425')),
        ]),
        DataRow(cells: [
          DataCell(Text('Fabian Cruz Quiroz')),
          DataCell(Text('7')),
          DataCell(Text('375')),
          DataCell(Text('2,625')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('2,625')),
        ]),
        DataRow(cells: [
          DataCell(Text('Fabian Cruz Quiroz')),
          DataCell(Text('6')),
          DataCell(Text('375')),
          DataCell(Text('2,250')),
          DataCell(Text('')),
          DataCell(Text('')),
          DataCell(Text('2,250')),
        ]),
      ],
    );
  }
}
