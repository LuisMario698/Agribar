import 'package:flutter/material.dart';

/// Generic table for days worked in payroll.
class DiasTrabajadosTable extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? selectedWeek;
  final List<List<int>>? diasH;
  final List<List<int>>? diasTT;
  final void Function(List<List<int>> h, List<List<int>> tt)? onChanged;
  final bool readOnly;
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

  @override
  void initState() {
    super.initState();
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
    int intValue = int.tryParse(value) ?? 0;
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
    // Build header and subheader labels
    final dateLabels = List.generate(diasCount, (d) {
      final dateStr = widget.selectedWeek != null
          ? '${widget.selectedWeek!.start.add(Duration(days: d)).day}/${widget.selectedWeek!.start.add(Duration(days: d)).month}'
          : 'D${d + 1}';
      return dateStr;
    });
    final headerCells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text('Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];
    for (var label in dateLabels) {
      // Day header spans H and TT columns (duplicated)
      headerCells.addAll([
        Padding(padding: const EdgeInsets.all(4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
      ]);
    }
    // Add Total column header
    headerCells.add(Padding(padding: const EdgeInsets.all(4), child: Text('Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))));
    final subheaderCells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text('', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];
    for (int i = 0; i < diasCount; i++) {
      subheaderCells.addAll([
        Padding(padding: const EdgeInsets.all(4), child: Text('H', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: const EdgeInsets.all(4), child: Text('TT', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      ]);
    }
    // Add blank subheader for Total
    subheaderCells.add(Padding(padding: const EdgeInsets.all(4), child: Text('', style: const TextStyle(fontWeight: FontWeight.bold))));
    // Build data rows
    final dataRows = widget.empleados.asMap().entries.map((entry) {
      final empIndex = entry.key;
      final emp = entry.value;
      final cells = <Widget>[];
      cells.add(Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Text(emp['nombre'] ?? '')));
      int sumRow = 0;
      for (int d = 0; d < diasCount; d++) {
        final h = localH[empIndex][d];
        final tt = localTT[empIndex][d];
        sumRow += h + tt;
        // H cell
        cells.add(Padding(
          padding: const EdgeInsets.all(4),
          child: widget.readOnly
              ? Text(h.toString(), textAlign: TextAlign.center)
              : SizedBox(
                  width: 40,
                  child: TextFormField(
                    initialValue: h.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (v) => _onCellChanged(empIndex, d, true, v),
                  ),
                ),
        ));
        // TT cell
        cells.add(Padding(
          padding: const EdgeInsets.all(4),
          child: widget.readOnly
              ? Text(tt.toString(), textAlign: TextAlign.center)
              : SizedBox(
                  width: 40,
                  child: TextFormField(
                    initialValue: tt.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (v) => _onCellChanged(empIndex, d, false, v),
                  ),
                ),
        ));
      }
      // Total cell per row
      cells.add(Padding(padding: const EdgeInsets.all(4), child: Text(sumRow.toString(), textAlign: TextAlign.center)));
      return TableRow(children: cells);
    }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        // First column intrinsic width, others fixed for H/TT
        defaultColumnWidth: const FixedColumnWidth(60),
        columnWidths: {0: const IntrinsicColumnWidth()},
        children: [
          TableRow(decoration: BoxDecoration(color: Colors.grey.shade200), children: headerCells),
          TableRow(decoration: BoxDecoration(color: Colors.grey.shade100), children: subheaderCells),
          ...dataRows,
        ],
      ),
    );
  }
}
