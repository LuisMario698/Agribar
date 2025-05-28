/// Widget de tabla de días trabajados para la pantalla de nómina
/// Muestra y permite editar los datos de tiempo trabajado (TT) y horas (H)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiasTrabajadosTable extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? selectedWeek;
  final List<List<int>>? diasH;
  final List<List<int>>? diasTT;
  final void Function(List<List<int>> h, List<List<int>> tt)? onChanged;
  final bool readOnly;
  final bool isExpanded;

  const DiasTrabajadosTable({
    required this.empleados,
    required this.selectedWeek,
    this.diasH,
    this.diasTT,
    this.onChanged,
    this.readOnly = false,
    this.isExpanded = false,
    Key? key,
  }) : super(key: key);

  @override
  State<DiasTrabajadosTable> createState() => _DiasTrabajadosTableState();
}

class _DiasTrabajadosTableState extends State<DiasTrabajadosTable> {
  late List<List<int>> hValues;
  late List<List<int>> ttValues;
  final Map<String, TextEditingController> _controllersH = {};
  final Map<String, TextEditingController> _controllersTT = {};
  final Map<String, FocusNode> _focusNodesH = {};
  final Map<String, FocusNode> _focusNodesTT = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initLocalData();
  }

  @override
  void didUpdateWidget(DiasTrabajadosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initLocalData();
  }

  void _initLocalData() {
    final diasSemana =
        widget.selectedWeek != null
            ? List.generate(
              widget.selectedWeek!.duration.inDays + 1,
              (i) => widget.selectedWeek!.start.add(Duration(days: i)),
            )
            : List.generate(7, (i) => DateTime(2023, 1, i + 1));
    int diasCount = diasSemana.length;
    hValues =
        widget.diasH != null &&
                widget.diasH!.length == widget.empleados.length &&
                widget.diasH!.every((l) => l.length == diasCount)
            ? widget.diasH!.map((l) => List<int>.from(l)).toList()
            : List.generate(
              widget.empleados.length,
              (i) => List<int>.filled(diasCount, 0),
            );
    ttValues =
        widget.diasTT != null &&
                widget.diasTT!.length == widget.empleados.length &&
                widget.diasTT!.every((l) => l.length == diasCount)
            ? widget.diasTT!.map((l) => List<int>.from(l)).toList()
            : List.generate(
              widget.empleados.length,
              (i) => List<int>.filled(diasCount, 0),
            );
    for (int eIdx = 0; eIdx < widget.empleados.length; eIdx++) {
      for (int i = 0; i < diasCount; i++) {
        String keyH = '${eIdx}_h_$i';
        String keyTT = '${eIdx}_tt_$i';
        _controllersH[keyH] = TextEditingController(
          text: hValues[eIdx][i].toString(),
        );
        _controllersTT[keyTT] = TextEditingController(
          text: ttValues[eIdx][i].toString(),
        );
        _focusNodesH[keyH] = FocusNode();
        _focusNodesTT[keyTT] = FocusNode();
        _controllersH[keyH]?.addListener(() {
          int v = int.tryParse(_controllersH[keyH]?.text ?? '0') ?? 0;
          hValues[eIdx][i] = v;
          widget.onChanged?.call(hValues, ttValues);
          setState(() {});
        });
        _controllersTT[keyTT]?.addListener(() {
          int v = int.tryParse(_controllersTT[keyTT]?.text ?? '0') ?? 0;
          ttValues[eIdx][i] = v;
          widget.onChanged?.call(hValues, ttValues);
          setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    for (var c in _controllersH.values) {
      c.dispose();
    }
    for (var c in _controllersTT.values) {
      c.dispose();
    }
    for (var f in _focusNodesH.values) {
      f.dispose();
    }
    for (var f in _focusNodesTT.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diasSemana =
        widget.selectedWeek != null
            ? List.generate(
              widget.selectedWeek!.duration.inDays + 1,
              (i) => widget.selectedWeek!.start.add(Duration(days: i)),
            )
            : List.generate(7, (i) => DateTime(2023, 1, i + 1));
    final dayNames = ['dom', 'lun', 'mar', 'mie', 'jue', 'vie', 'sab'];
    int diasCount = diasSemana.length;
    int totalCols = 2 + diasCount * 2 + 1; // Clave, Nombre, (TT+H)*dias, Total

    // Definir los anchos personalizados
    Map<int, TableColumnWidth> columnWidths = {
      0: FixedColumnWidth(widget.isExpanded ? 99 : 60), // Clave
      1: FixedColumnWidth(widget.isExpanded ? 239 : 200), // Nombre
    };
    for (int i = 0; i < diasCount * 2; i++) {
      columnWidths[2 + i] = FixedColumnWidth(
        widget.isExpanded ? 79 : 48,
      ); // TT y H
    }
    columnWidths[totalCols - 1] = FixedColumnWidth(
      widget.isExpanded ? 99 : 60,
    ); // Total

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade500, width: 1),
            columnWidths: columnWidths,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                children: [
                  _headerCell('Clave', fontSize: widget.isExpanded ? 14 : 12),
                  _headerCell('Nombre', fontSize: widget.isExpanded ? 14 : 12),
                  ...diasSemana.expand(
                    (date) => [
                      _headerCell(
                        dayNames[date.weekday % 7].toUpperCase(),
                        fontSize: widget.isExpanded ? 14 : 12,
                      ),
                      _headerCell('', fontSize: widget.isExpanded ? 14 : 12),
                    ],
                  ),
                  _headerCell('Total', fontSize: widget.isExpanded ? 14 : 12),
                ],
              ),
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                children: [
                  const TableCell(child: SizedBox()),
                  const TableCell(child: SizedBox()),
                  ...List.generate(
                    diasCount,
                    (i) => [
                      _headerCell('TT', fontSize: widget.isExpanded ? 14 : 12),
                      _headerCell('H', fontSize: widget.isExpanded ? 14 : 12),
                    ],
                  ).expand((x) => x),
                  const TableCell(child: SizedBox()),
                ],
              ),
              ...List.generate(widget.empleados.length, (eIdx) {
                int total = 0;
                for (int i = 0; i < diasCount; i++) {
                  total += hValues[eIdx][i] + ttValues[eIdx][i];
                }
                return TableRow(
                  children: [
                    _bodyCell(
                      widget.empleados[eIdx]['clave'].toString(),
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                    _bodyCell(
                      widget.empleados[eIdx]['nombre'].toString(),
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                    ...List.generate(
                      diasCount,
                      (i) => [
                        _editableCell(
                          ttValues[eIdx][i].toString(),
                          'tt_${eIdx}_$i',
                          (val) {
                            int? newValue = int.tryParse(val);
                            if (newValue != null) {
                              ttValues[eIdx][i] = newValue;
                              widget.onChanged?.call(hValues, ttValues);
                              setState(() {});
                            }
                          },
                          _controllersTT,
                          _focusNodesTT,
                          fontSize: widget.isExpanded ? 14 : 12,
                        ),
                        _editableCell(
                          hValues[eIdx][i].toString(),
                          'h_${eIdx}_$i',
                          (val) {
                            int? newValue = int.tryParse(val);
                            if (newValue != null) {
                              hValues[eIdx][i] = newValue;
                              widget.onChanged?.call(hValues, ttValues);
                              setState(() {});
                            }
                          },
                          _controllersH,
                          _focusNodesH,
                          fontSize: widget.isExpanded ? 14 : 12,
                        ),
                      ],
                    ).expand((x) => x),
                    _bodyCell(
                      total.toString(),
                      bold: true,
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text, {double fontSize = 12}) => TableCell(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
    ),
  );

  Widget _bodyCell(String text, {bool bold = false, double fontSize = 12}) =>
      TableCell(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ),
      );

  Widget _editableCell(
    String value,
    String key,
    void Function(String) onChanged,
    Map<String, TextEditingController> controllers,
    Map<String, FocusNode> focusNodes, {
    double fontSize = 12,
  }) {
    if (widget.readOnly) {
      return Text(
        value,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      );
    }

    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: value);
      focusNodes[key] = FocusNode();
    }
    return TextField(
      controller: controllers[key],
      focusNode: focusNodes[key],
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: fontSize),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        border: InputBorder.none,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.isEmpty) {
          onChanged('0');
        } else {
          onChanged(value);
        }
      },
      onTap: () {
        controllers[key]?.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controllers[key]!.text.length,
        );
      },
    );
  }
}
