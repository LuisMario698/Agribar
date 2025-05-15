import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

// === Constantes de estilo globales ===
const double kTableCardTopMargin = 50;
const double kTableCardSideMargin = 0;
const double kTableCardRadius = 18;
const double kTableCardShadowBlur = 12;
const double kTableButtonTop = 12;
const double kTableButtonRight = 40;
const double kColumnClaveWidth = 55;
const double kColumnNombreWidth = 140;
const double kColumnTotalSemanalWidth = 85;
const double kColumnComederoWidth = 60;
const double kColumnObsWidth = 120;
const double kColumnOtrasPercWidth = 120;
const double kColumnDeduccionesWidth = 80;
const double kColumnNetoWidth = 85;
const double kColumnDiaWidth = 45;
const double kIndicatorCardWidth = 260;
const double kIndicatorCardHeight = 80;
const double kIndicatorIconSize = 22;
const double kButtonRadius = 12;
const double kButtonFontSize = 16;
const double kDataRowHeight = 48;
const Color kGreen = Color(0xFF7BAE2F);
const Color kGreenDark = Color(0xFF43A047);
const Color kTableHeaderColor = Color(0xFFF3F3F3);
const Color kTableBorderColor = Color(0xFFBDBDBD);
const Color kBackgroundColor = Color(0xFFF3E9D2);

// Modelo para empleado
class Empleado {
  String clave;
  String nombre;
  String totalSemanal;
  String comedero;
  String observaciones;
  String otrasPercepciones;
  String deducciones;
  String netoPagar;
  Map<String, String> diasTrabajados;

  Empleado({
    required this.clave,
    required this.nombre,
    required this.totalSemanal,
    required this.comedero,
    required this.observaciones,
    required this.otrasPercepciones,
    required this.deducciones,
    required this.netoPagar,
    required this.diasTrabajados,
  });

  Empleado copy() {
    return Empleado(
      clave: clave,
      nombre: nombre,
      totalSemanal: totalSemanal,
      comedero: comedero,
      observaciones: observaciones,
      otrasPercepciones: otrasPercepciones,
      deducciones: deducciones,
      netoPagar: netoPagar,
      diasTrabajados: Map.from(diasTrabajados),
    );
  }
}

class NominaScreen extends StatefulWidget {
  final bool showFullTable;
  final VoidCallback? onCloseFullTable;
  final VoidCallback? onOpenFullTable;
  const NominaScreen({super.key, this.showFullTable = false, this.onCloseFullTable, this.onOpenFullTable});

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> {
  bool showFullTable = false;
  bool showDiasTrabajados = false;
  List<Empleado> empleados = [];
  final dias = ['01/07/2024', '02/07/2024', '03/07/2024', '04/07/2024', '05/07/2024', '06/07/2024', '07/07/2024'];

  @override
  void initState() {
    super.initState();
    // Inicializar datos de ejemplo
    empleados = [
      Empleado(
        clave: '1950',
        nombre: 'Adela Rodriguez Ramirez',
        totalSemanal: '241,500',
        comedero: '',
        observaciones: '',
        otrasPercepciones: '',
        deducciones: '',
        netoPagar: '241,500',
        diasTrabajados: Map.fromIterables(dias, List.filled(dias.length, '1')),
      ),
      // ... Agregar el resto de empleados de ejemplo ...
    ];
  }

  void _openFullTable() {
    setState(() {
      showFullTable = true;
      showDiasTrabajados = false;
    });
  }

  void _openDiasTrabajados() {
    setState(() {
      showFullTable = true;
      showDiasTrabajados = true;
    });
  }

  void _closeFullTable() {
    setState(() {
      showFullTable = false;
      showDiasTrabajados = false;
    });
  }

  void _addEmpleado() {
    setState(() {
      // Crear nuevo empleado con todos los campos vacíos
      final nuevoEmpleado = Empleado(
        clave: '',
        nombre: '',
        totalSemanal: '',
        comedero: '',
        observaciones: '',
        otrasPercepciones: '',
        deducciones: '',
        netoPagar: '',
        diasTrabajados: Map.fromIterables(dias, List.filled(dias.length, '')),
      );
      
      // Insertar al principio de la lista
      empleados.insert(0, nuevoEmpleado);
    });
  }

  // Función auxiliar para ordenar empleados (vacíos primero)
  List<Empleado> _getSortedEmpleados() {
    return List.from(empleados)..sort((a, b) {
      // Si alguno está vacío, va primero
      bool aVacio = a.clave.isEmpty && a.nombre.isEmpty;
      bool bVacio = b.clave.isEmpty && b.nombre.isEmpty;
      
      if (aVacio && !bVacio) return -1;
      if (!aVacio && bVacio) return 1;
      
      // Si ambos están vacíos o ambos tienen datos, mantener el orden original
      return 0;
    });
  }

  void _removeEmpleado(int index) {
    setState(() {
      empleados.removeAt(index);
    });
  }

  void _updateEmpleado(int index, Empleado empleado) {
    setState(() {
      empleados[index] = empleado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row con label 'Nómina' y card de total semana acumulado
                Padding(
                  padding: const EdgeInsets.only(top: 0, left: 32, right: 32, bottom: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Spacer(),
                    ],
                  ),
                ),
                // Card de filtros semana/cuadrilla y botón cargar platilla
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black12,
                              blurRadius: AppDimens.cardShadowBlur,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Semana
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Semana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green[900])),
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
                            SizedBox(width: 32),
                            // Cuadrilla
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Cuadrilla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green[900])),
                                SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('JESUS BADILLO CASTILLO', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                      Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 24),
                      // Botón cargar platilla
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.buttonRadius)),
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          minimumSize: Size(0, 100),
                        ),
                        onPressed: () {},
                        child: Text('Cargar platilla', style: TextStyle(fontSize: 22, color: AppColors.white)),
                      ),
                    ],
                  ),
                ),
                // Buscador y tarjetas indicadores
                Padding(
                  padding: const EdgeInsets.only(top: 0, left: 32, right: 32, bottom: 0),
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
                      Spacer(),
                      // Indicadores
                      _IndicatorCard(
                        label: 'Empleados en cuadrilla',
                        value: '30',
                        icon: Icons.person,
                        iconColor: AppColors.green,
                        valueStyle: AppTextStyles.indicatorValue,
                        labelStyle: AppTextStyles.indicatorLabel.copyWith(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 16),
                      _IndicatorCard(
                        label: 'Total Cuadrilla',
                        value: '15,525',
                        icon: Icons.attach_money,
                        iconColor: AppColors.green,
                        valueStyle: AppTextStyles.indicatorValue,
                        labelStyle: AppTextStyles.indicatorLabel.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // Tabla de nómina y botón flotante
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 32, right: 32, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FloatingTableButton(
                              onPressed: _openDiasTrabajados,
                              label: 'Ver días trabajados',
                              icon: Icons.visibility,
                              color: AppColors.greenDark,
                            ),
                            ElevatedButton.icon(
                              onPressed: _addEmpleado,
                              icon: Icon(Icons.add),
                              label: Text('Agregar Empleado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            _FloatingTableButton(
                              onPressed: _openFullTable,
                              label: 'Ver tabla completa',
                              icon: Icons.fullscreen,
                              color: AppColors.greenDark,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 0, right: 0),
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
                            scrollDirection: Axis.vertical,
                            child: _DiasTrabajadosTable(
                              empleados: _getSortedEmpleados(),
                              dias: dias,
                              onEmpleadoUpdated: _updateEmpleado,
                              onEmpleadoRemoved: _removeEmpleado,
                              onEmpleadoAdded: _addEmpleado,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botones de acción y botón ver días trabajados
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () {},
                            child: Text('Confirmar y guardar', style: AppTextStyles.button),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () {},
                            child: Text('PDF', style: AppTextStyles.button),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            onPressed: () {},
                            child: Text('EXCEL', style: AppTextStyles.button),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dialogo de tabla completa o días trabajados
          if (showFullTable)
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              width: 420,
                              height: 48,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black26,
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                          ),
                          SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black26,
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                minimumSize: Size(0, 0),
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: _closeFullTable,
                              child: Text('Volver', style: AppTextStyles.button),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _addEmpleado,
                              icon: Icon(Icons.add),
                              label: Text('Agregar Empleado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: showDiasTrabajados ? _NominaTable(
                            empleados: _getSortedEmpleados(),
                            onEmpleadoUpdated: _updateEmpleado,
                            onEmpleadoRemoved: _removeEmpleado,
                            onEmpleadoAdded: _addEmpleado,
                          ) : _DiasTrabajadosTable(
                            empleados: _getSortedEmpleados(),
                            dias: dias,
                            onEmpleadoUpdated: _updateEmpleado,
                            onEmpleadoRemoved: _removeEmpleado,
                            onEmpleadoAdded: _addEmpleado,
                          ),
                        ),
                      ),
                    ],
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

class _FloatingTableButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Color color;
  const _FloatingTableButton({this.onPressed, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          shadowColor: AppColors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  final String initialValue;
  final double width;
  final int? minLines;
  final Function(String) onChanged;

  const _EditableCell(
    this.initialValue,
    this.width, {
    this.minLines,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      width: width,
      child: TextField(
        controller: TextEditingController(text: initialValue),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: InputBorder.none,
        ),
        style: AppTextStyles.tableCell,
        textAlign: TextAlign.center,
        minLines: minLines ?? 1,
        maxLines: minLines ?? 1,
        onChanged: onChanged,
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
      width: AppDimens.indicatorCardWidth,
      height: AppDimens.indicatorCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: labelStyle ?? AppTextStyles.indicatorLabel.copyWith(color: Colors.grey[800]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: valueStyle ?? AppTextStyles.indicatorValue.copyWith(color: Colors.black),
                textAlign: TextAlign.center,
              ),
              SizedBox(width: 8),
              Icon(icon, color: iconColor, size: AppDimens.indicatorIconSize),
            ],
          ),
        ],
      ),
    );
  }
}

class _NominaTable extends StatelessWidget {
  final List<Empleado> empleados;
  final Function(int, Empleado) onEmpleadoUpdated;
  final Function(int) onEmpleadoRemoved;
  final VoidCallback onEmpleadoAdded;

  static const List<String> diasSemana = [
    'jue', 'vie', 'sab', 'dom', 'lun', 'mar', 'mier'
  ];

  const _NominaTable({
    required this.empleados,
    required this.onEmpleadoUpdated,
    required this.onEmpleadoRemoved,
    required this.onEmpleadoAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          border: TableBorder.all(color: AppColors.tableBorder, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            0: const FixedColumnWidth(50),  // Clave
            1: const FixedColumnWidth(120), // Nombre
            for (int i = 0; i < diasSemana.length * 2; i++)
              i + 2: const FixedColumnWidth(35), // H y TT columns
            diasSemana.length * 2 + 2: const FixedColumnWidth(60), // Total
          },
          children: [
            // Primera fila: Encabezados de días que abarcan dos columnas
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.tableHeader,
              ),
              children: [
                _buildHeaderCell('Clave', height: 40),
                _buildHeaderCell('Nombre', height: 40),
                for (var dia in diasSemana)
                  ...[
                    _buildHeaderCell(dia.toUpperCase(), height: 40, fontSize: 12),
                    Container(), // Placeholder to ensure consistent column count
                  ],
                _buildHeaderCell('Total', height: 40),
              ],
            ),
            // Segunda fila: Subencabezados H y TT
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.tableHeader,
              ),
              children: [
                Container(height: 30),  // Clave
                Container(height: 30),  // Nombre
                for (var _ in diasSemana)
                  ...[
                    _buildHeaderCell('H', height: 30, fontSize: 10),
                    _buildHeaderCell('TT', height: 30, fontSize: 10),
                  ],
                Container(height: 30),  // Total
              ],
            ),
            // Filas de datos
            for (var entry in empleados.asMap().entries)
              TableRow(
                children: [
                  _buildDataCell(
                    entry.value.clave,
                    width: 50,
                    onChanged: (value) {
                      final updated = entry.value.copy();
                      updated.clave = value;
                      onEmpleadoUpdated(entry.key, updated);
                    },
                  ),
                  _buildDataCell(
                    entry.value.nombre,
                    width: 120,
                    maxLines: 2,
                    onChanged: (value) {
                      final updated = entry.value.copy();
                      updated.nombre = value;
                      onEmpleadoUpdated(entry.key, updated);
                    },
                  ),
                  ...diasSemana.expand((dia) => [
                    _buildDataCell(
                      entry.value.diasTrabajados['${dia}_H'] ?? '',
                      width: 35,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.diasTrabajados['${dia}_H'] = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    _buildDataCell(
                      entry.value.diasTrabajados['${dia}_TT'] ?? '',
                      width: 35,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.diasTrabajados['${dia}_TT'] = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                  ]),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value.diasTrabajados.entries
                        .where((e) => e.key.contains('_H') || e.key.contains('_TT'))
                        .map((e) => int.tryParse(e.value) ?? 0)
                        .fold(0, (a, b) => a + b)
                        .toString(),
                      style: AppTextStyles.tableCell.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold
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

  Widget _buildHeaderCell(String text, {double? height, double fontSize = 12}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.tableHeader.copyWith(fontSize: fontSize),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(String text, {
    double? width,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        key: ValueKey(text), // Add key to maintain focus
        controller: TextEditingController(text: text),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.tableCell.copyWith(fontSize: 13),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr, // Fix backwards text
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
}

class _DiasTrabajadosTable extends StatelessWidget {
  final List<Empleado> empleados;
  final List<String> dias;
  final Function(int, Empleado) onEmpleadoUpdated;
  final Function(int) onEmpleadoRemoved;
  final VoidCallback onEmpleadoAdded;

  const _DiasTrabajadosTable({
    required this.empleados,
    required this.dias,
    required this.onEmpleadoUpdated,
    required this.onEmpleadoRemoved,
    required this.onEmpleadoAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.all(color: AppColors.tableBorder, width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(60),  // Clave
              1: const FixedColumnWidth(180), // Nombre
              for (int i = 0; i < dias.length; i++)
                i + 2: const FixedColumnWidth(80), // Días
              dias.length + 2: const FixedColumnWidth(70),   // Total días
              dias.length + 3: const FixedColumnWidth(80),   // Debo
              dias.length + 4: const FixedColumnWidth(80),   // Total
              dias.length + 5: const FixedColumnWidth(80),   // Comedero
              dias.length + 6: const FixedColumnWidth(80),   // Total Neto
            },
            children: [
              // Primera fila - Encabezados principales
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.tableHeader,
                ),
                children: [
                  _buildHeaderCell('Clave'),
                  _buildHeaderCell('Nombre'),
                  for (var dia in dias) _buildHeaderCell(dia),
                  _buildHeaderCell('Total'),
                  _buildHeaderCell('Debo'),
                  _buildHeaderCell('Total'),
                  _buildHeaderCell('Comedero'),
                  _buildHeaderCell('Total Neto'),
                ],
              ),
              // Segunda fila - TT
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.tableHeader,
                ),
                children: [
                  Container(height: 30),  // Clave
                  Container(height: 30),  // Nombre
                  for (var _ in dias) _buildHeaderCell('TT', fontSize: 12),
                  Container(height: 30),  // Total
                  Container(height: 30),  // Debo
                  Container(height: 30),  // Total
                  Container(height: 30),  // Comedero
                  Container(height: 30),  // Total Neto
                ],
              ),
              // Filas de datos
              for (var entry in empleados.asMap().entries)
                TableRow(
                  children: [
                    _buildDataCell(
                      entry.value.clave,
                      width: 60,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.clave = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    _buildDataCell(
                      entry.value.nombre,
                      width: 180,
                      maxLines: 2,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.nombre = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    for (var dia in dias)
                      _buildDataCell(
                        entry.value.diasTrabajados[dia] ?? '',
                        width: 80,
                        onChanged: (value) {
                          final updated = entry.value.copy();
                          updated.diasTrabajados[dia] = value;
                          onEmpleadoUpdated(entry.key, updated);
                        },
                      ),
                    // Total días
                    Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      alignment: Alignment.center,
                      child: Text(
                        (entry.value.diasTrabajados.values
                            .map((v) => int.tryParse(v) ?? 0)
                            .fold(0, (a, b) => a + b))
                            .toString(),
                        style: AppTextStyles.tableCell.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    // Debo
                    _buildDataCell(
                      entry.value.totalSemanal,
                      width: 80,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.totalSemanal = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    // Total
                    _buildDataCell(
                      entry.value.otrasPercepciones,
                      width: 80,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.otrasPercepciones = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    // Comedero
                    _buildDataCell(
                      entry.value.comedero,
                      width: 80,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.comedero = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                    // Total Neto
                    _buildDataCell(
                      entry.value.netoPagar,
                      width: 80,
                      onChanged: (value) {
                        final updated = entry.value.copy();
                        updated.netoPagar = value;
                        onEmpleadoUpdated(entry.key, updated);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? height, double fontSize = 14}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTextStyles.tableHeader.copyWith(fontSize: fontSize),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(String text, {
    double? width,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        key: ValueKey(text),
        controller: TextEditingController(text: text),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.tableCell.copyWith(fontSize: 13),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
}

// Ajustar estilos de texto
class AppTextStyles {
  static const tableHeader = TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black);
  static const tableCell = TextStyle(fontSize: 13, color: Colors.black);
  static const indicatorValue = TextStyle(fontWeight: FontWeight.bold, fontSize: 22);
  static const indicatorLabel = TextStyle(fontWeight: FontWeight.w500, fontSize: 14);
  static const button = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white);
}
