import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;

/// Tabla para captura y visualización de días trabajados en nómina.
///
/// Este widget implementa una tabla especializada para el registro de:
/// - Días normales trabajados (TT)
/// - Horas extra trabajadas (H)
/// - Totales semanales por empleado
///
/// Características principales:
/// - Edición en línea de días trabajados
/// - Modo de solo lectura para consultas
/// - Vista expandible para mejor visualización
/// - Actualización en tiempo real
/// - Cálculos automáticos de totales
///
/// Se utiliza principalmente en la pantalla de nómina para:
/// - Captura semanal de días trabajados
/// - Revisión de registros históricos
/// - Cálculo de pagos basados en días trabajados 
class DiasTrabajadosTable extends StatefulWidget {
  /// Lista de empleados con sus datos básicos
  final List<Map<String, dynamic>> empleados;
  /// Rango de fechas de la semana seleccionada
  final DateTimeRange? selectedWeek;
  /// Matriz de horas extra por empleado y día
  final List<List<int>>? diasH;
  /// Matriz de días trabajados por empleado y día
  final List<List<int>>? diasTT;
  /// Callback que se ejecuta cuando cambian los días trabajados
  final void Function(List<List<int>> h, List<List<int>> tt)? onChanged;
  /// Si es true, la tabla será de solo lectura
  final bool readOnly;
  /// Si es true, la tabla se muestra en modo expandido
  final bool isExpanded;

  const DiasTrabajadosTable({
    Key? key,
    required this.empleados,
    this.selectedWeek,
    this.diasH,
    this.diasTT,
    this.onChanged,
    this.readOnly = false,
    this.isExpanded = false,
  }) : super(key: key);

  @override
  _DiasTrabajadosTableState createState() => _DiasTrabajadosTableState();
}

class _DiasTrabajadosTableState extends State<DiasTrabajadosTable> {
  late List<List<int>> localH;
  late List<List<int>> localTT;
  late int diasCount;
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(DiasTrabajadosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize data when widget is updated (e.g., when table is shown again)
    if (widget.diasH != oldWidget.diasH || widget.diasTT != oldWidget.diasTT) {
      _initializeData();
    }
  }

  void _initializeData() {
    diasCount = widget.selectedWeek != null
        ? widget.selectedWeek!.duration.inDays + 1
        : 7;
    
    // Initialize local state from widget.diasH/TT or default zeros
    localH = widget.diasH != null
        ? widget.diasH!.map((row) => List<int>.from(row)).toList()
        : List.generate(
            widget.empleados.length, (_) => List.filled(diasCount, 0));
    
    localTT = widget.diasTT != null
        ? widget.diasTT!.map((row) => List<int>.from(row)).toList()
        : List.generate(
            widget.empleados.length, (_) => List.filled(diasCount, 0));
  }
  void _onCellChanged(int empIndex, int dayIndex, bool isH, String value) {
    // Remove the "$" symbol and any non-digit characters
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    int intValue = int.tryParse(cleanValue) ?? 0;
    setState(() {
      if (isH) {
        localH[empIndex][dayIndex] = intValue;
      } else {
        localTT[empIndex][dayIndex] = intValue;
      }
    });
    if (widget.onChanged != null) {
      widget.onChanged!(localH, localTT);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el ancho disponible y forzar un ancho mínimo para garantizar scroll
        final availableWidth = constraints.maxWidth;
          // Definir anchos base
        final nameWidth = 250.0; // Ancho fijo para la columna de nombre
        final dayWidth = 160.0; // Ancho fijo por día
        final totalWidth = 120.0; // Ancho fijo para el total
        
        // Calcular ancho total necesario y forzar un mínimo
        final totalNeededWidth = max(
          nameWidth + (dayWidth * diasCount) + totalWidth,
          nameWidth + 500.0 // Forzar un ancho mínimo que garantice scroll
        );
        
        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: availableWidth,
            constraints: BoxConstraints(maxWidth: availableWidth),
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: totalNeededWidth + 10, // Add extra padding for scrollbar
                  child: DataTable(
                    // Establecer un ancho mínimo que asegure el scroll cuando hay muchas columnas
                    columnSpacing: widget.isExpanded ? 4 : 2,
                    horizontalMargin: 8,
                    headingRowHeight: widget.isExpanded ? 52 : 48,
                    dataRowHeight: widget.isExpanded ? 56 : 52,
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    headingTextStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    dataTextStyle: TextStyle(
                      fontSize: widget.isExpanded ? 14 : 13,
                    ),
                    showBottomBorder: true,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: nameWidth,
                          child: const Text(
                            'Nombre',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      ...List.generate(diasCount, (i) {
                        final date = widget.selectedWeek != null
                            ? widget.selectedWeek!.start.add(Duration(days: i))
                            : DateTime.now().add(Duration(days: i));
                        final dateFormat = DateFormat('EEE\nd/M', 'es');
                        return DataColumn(
                          label: SizedBox(
                            width: dayWidth,
                            child: Text(
                              dateFormat.format(date).toLowerCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }),
                      DataColumn(
                        label: SizedBox(
                          width: totalWidth,
                          child: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    rows: [
                      // Fila de subencabezados (H/TT)
                      DataRow(
                        color: MaterialStateProperty.all(Colors.grey.shade50),
                        cells: [
                          DataCell(SizedBox(width: nameWidth)),
                          ...List.generate(diasCount, (i) =>
                            DataCell(
                              SizedBox(
                                width: dayWidth,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'H',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'TT',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          DataCell(SizedBox(width: totalWidth)),
                        ],
                      ),
                      // Filas de datos
                      ...widget.empleados.asMap().entries.map((entry) {
                        final empIndex = entry.key;
                        final emp = entry.value;
                        int sumRow = 0;

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: nameWidth,
                                child: Text(emp['nombre'] ?? '', 
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            ...List.generate(diasCount, (d) {
                              final h = localH[empIndex][d];
                              final tt = localTT[empIndex][d];
                              sumRow += h + tt;

                              return DataCell(
                                SizedBox(
                                  width: dayWidth,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Expanded(
                                        child: widget.readOnly
                                            ? Text(h.toString(),
                                                textAlign: TextAlign.center)
                                            : TextFormField(
                                                key: ValueKey('h_${emp['id']}_$d'),
                                                initialValue: h.toString(),
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: widget.isExpanded ? 12 : 8,
                                                  ),
                                                  border: const OutlineInputBorder(),
                                                  prefixText: '\$',
                                                ),
                                                onChanged: (v) => _onCellChanged(empIndex, d, true, v),
                                              ),
                                      ),                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: widget.readOnly
                                            ? Text(tt.toString(),
                                                textAlign: TextAlign.center)
                                            : TextFormField(
                                                key: ValueKey('tt_${emp['id']}_$d'),
                                                initialValue: tt.toString(),
                                                keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  prefixText: '\$',
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: widget.isExpanded ? 12 : 8,
                                                  ),
                                                  border: const OutlineInputBorder(),
                                                ),
                                                onChanged: (v) => _onCellChanged(empIndex, d, false, v),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            DataCell(
                              SizedBox(
                                width: totalWidth,
                                child: Text(
                                  sumRow.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: widget.isExpanded ? 15 : 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade200),
                      verticalInside: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
