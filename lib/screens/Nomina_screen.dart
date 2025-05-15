import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

// === Constantes de estilo globales ===
const double kTableCardTopMargin = 50;
const double kTableCardSideMargin = 0;
const double kTableCardRadius = 18;
const double kTableCardShadowBlur = 12;
const double kTableButtonTop = 12;
const double kTableButtonRight = 40;
const double kColumnClaveWidth = 70;
const double kColumnNombreWidth = 180;
const double kColumnTotalSemanalWidth = 110;
const double kColumnComederoWidth = 70;
const double kColumnObsWidth = 180;
const double kColumnOtrasPercWidth = 180;
const double kColumnDeduccionesWidth = 90;
const double kColumnNetoWidth = 110;
const double kColumnDiaWidth = 60;
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
  final String value;
  final double width;
  final int minLines;
  final Function(String) onChanged;

  const _EditableCell(
    this.value,
    this.width, {
    this.minLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: value,
            selection: TextSelection.collapsed(offset: value.length),
          ),
        ),
        textAlign: TextAlign.center,
        minLines: minLines,
        maxLines: null, // Permite multilinea
        scrollPadding: EdgeInsets.all(8),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: InputBorder.none,
        ),
        style: AppTextStyles.tableCell,
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

  const _NominaTable({
    required this.empleados,
    required this.onEmpleadoUpdated,
    required this.onEmpleadoRemoved,
    required this.onEmpleadoAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Ajusta la altura según tu diseño
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.tableHeader),
          columnSpacing: 16,
          border: TableBorder.all(color: AppColors.tableBorder, width: 1),
          columns: const [
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnClaveWidth,
                  child: Text('Clave', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnNombreWidth,
                  child: Text('Nombre', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnTotalSemanalWidth,
                  child: Text('Total semanal', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnComederoWidth,
                  child: Text('Comedero', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnObsWidth,
                  child: Text('Observaciones', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnOtrasPercWidth,
                  child: Text('Otras percepciones', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnDeduccionesWidth,
                  child: Text('Deducciones', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnNetoWidth,
                  child: Text('Neto a pagar', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
          rows: empleados.asMap().entries.map((entry) {
            final index = entry.key;
            final empleado = entry.value;
            return DataRow(
              cells: [
                DataCell(_EditableCell(
                  empleado.clave,
                  kColumnClaveWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.clave = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.nombre,
                  kColumnNombreWidth,
                  minLines: 2,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.nombre = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.totalSemanal,
                  kColumnTotalSemanalWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.totalSemanal = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.comedero,
                  kColumnComederoWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.comedero = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.observaciones,
                  kColumnObsWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.observaciones = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.otrasPercepciones,
                  kColumnOtrasPercWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.otrasPercepciones = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.deducciones,
                  kColumnDeduccionesWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.deducciones = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.netoPagar,
                  kColumnNetoWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.netoPagar = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
              ],
            );
          }).toList(),
        ),
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
    return SizedBox(
      height: 400, // Ajusta la altura según tu diseño
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.tableHeader),
          columnSpacing: 12,
          border: TableBorder.all(color: AppColors.tableBorder, width: 1),
          columns: [
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnClaveWidth,
                  child: Text('Clave', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: SizedBox(
                  width: kColumnNombreWidth,
                  child: Text('Nombre', style: AppTextStyles.tableHeader, textAlign: TextAlign.center),
                ),
              ),
            ),
            ...dias.map((d) => DataColumn(
              label: Center(child: Text(d, style: AppTextStyles.tableHeader.copyWith(fontSize: 11), textAlign: TextAlign.center)),
            )),
            DataColumn(
              label: Center(child: Text('Debo', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
            ),
            DataColumn(
              label: Center(child: Text('Total', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
            ),
            DataColumn(
              label: Center(child: Text('Comedor', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
            ),
            DataColumn(
              label: Center(child: Text('Total neto', style: AppTextStyles.tableHeader, textAlign: TextAlign.center)),
            ),
          ],
          rows: empleados.asMap().entries.map((entry) {
            final index = entry.key;
            final empleado = entry.value;
            return DataRow(
              cells: [
                DataCell(_EditableCell(
                  empleado.clave,
                  kColumnClaveWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.clave = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.nombre,
                  kColumnNombreWidth,
                  minLines: 2,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.nombre = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                ...dias.map((d) => DataCell(_EditableCell(
                  empleado.diasTrabajados[d] ?? '',
                  kColumnDiaWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.diasTrabajados[d] = value;
                    onEmpleadoUpdated(index, updated);
                  },
                ))),
                DataCell(_EditableCell(
                  empleado.deducciones,
                  kColumnDeduccionesWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.deducciones = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.netoPagar,
                  kColumnNetoWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.netoPagar = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.comedero,
                  kColumnComederoWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.comedero = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
                DataCell(_EditableCell(
                  empleado.netoPagar,
                  kColumnNetoWidth,
                  onChanged: (value) {
                    final updated = empleado.copy();
                    updated.netoPagar = value;
                    onEmpleadoUpdated(index, updated);
                  },
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Ajustar estilos de texto
class AppTextStyles {
  static const tableHeader = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black);
  static const tableCell = TextStyle(fontSize: 14, color: Colors.black);
  static const indicatorValue = TextStyle(fontWeight: FontWeight.bold, fontSize: 22);
  static const indicatorLabel = TextStyle(fontWeight: FontWeight.w500, fontSize: 14);
  static const button = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white);
}
