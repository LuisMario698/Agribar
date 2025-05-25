import 'package:flutter/material.dart';

/// Widget modular para edición en la tabla de nómina.
class EditableDataTableWidget extends StatelessWidget {
  // Abreviaturas de días en español (1=lun ... 7=dom)
  static const List<String> _weekdayAbbr = ['', 'lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int index, String key, dynamic value) onChanged;
  final bool isExpanded;

  const EditableDataTableWidget({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    required this.onChanged,
    this.isExpanded = false,
  }) : super(key: key);

  List<DataColumn> _buildColumns() {
    final cols = <DataColumn>[
      DataColumn(label: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
    ];
    final diasCount = semanaSeleccionada != null
        ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
        : 7;
    DateTime date = semanaSeleccionada?.start ?? DateTime.now();
    for (int i = 0; i < diasCount; i++) {
      // Usar abreviatura de día si hay semana seleccionada, sino numerar como D1..Dn
      final label = semanaSeleccionada != null
          ? _weekdayAbbr[date.weekday]
          : 'D${i + 1}';
      cols.add(DataColumn(label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));
      if (semanaSeleccionada != null) date = date.add(Duration(days: 1));
    }
    cols.addAll([
      DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataColumn(label: Text('Debe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataColumn(label: Text('Comedor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      DataColumn(label: Text('Neto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
    ]);
    return cols;
  }

  // Subencabezados alineados: vacíos en Clave y Nombre, 'TT' para cada día, vacíos en Total, Debe, Subtotal, Comedor, Neto
  List<String> _buildSubHeaders() {
    final sub = <String>['', ''];
    final diasCount = semanaSeleccionada != null
        ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
        : 7;
    for (int i = 0; i < diasCount; i++) {
      sub.add('TT');
    }
    // Total, Debe, Subtotal, Comedor, Neto
    sub.addAll(['', '', '', '', '']);
    return sub;
  }

  @override
  Widget build(BuildContext context) {
    // Construir columnas, subencabezados y filas de datos
    final columns = _buildColumns();
    final subHeaders = _buildSubHeaders();
    // Obtener celdas de datos como lista de Strings/TextFormFields
    List<TableRow> dataRows = [];
    // Filas de datos generadas dinámicamente
    for (var entry in empleados.asMap().entries) {
      int idx = entry.key;
      final emp = entry.value;
      final diasCount = semanaSeleccionada != null
          ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
          : 7;
      final totalDias = (emp['dias'] as List<int>).fold(0, (a, b) => a + b);
      final debo = emp['debo'] as int? ?? 0;
      final subtotal = totalDias - debo;
      final comedor = emp['comedor'] as int? ?? 0;
      final neto = subtotal - comedor;
      // Preparar celdas
      List<Widget> cells = [];
      cells.add(Padding(padding: const EdgeInsets.all(8), child: Text(emp['clave']?.toString() ?? '')));
      cells.add(Padding(padding: const EdgeInsets.all(8), child: Text(emp['nombre']?.toString() ?? '')));
      for (int i = 0; i < diasCount; i++) {
        cells.add(Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 40,
            child: TextFormField(
              initialValue: (emp['dias'][i] as int).toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => onChanged(idx, 'dia_$i', int.tryParse(v) ?? 0),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            ),
          ),
        ));
      }
      cells.add(Padding(padding: const EdgeInsets.all(8), child: Text('\$${totalDias}')));
      cells.add(Padding(padding: const EdgeInsets.all(4), child: SizedBox(
        width: 60,
        child: TextFormField(
          initialValue: debo.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(idx, 'debo', int.tryParse(v) ?? 0),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        ),
      )));
      cells.add(Padding(padding: const EdgeInsets.all(8), child: Text('\$${subtotal}')));
      cells.add(Padding(padding: const EdgeInsets.all(4), child: SizedBox(
        width: 60,
        child: TextFormField(
          initialValue: comedor.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(idx, 'comedor', int.tryParse(v) ?? 0),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        ),
      )));
      cells.add(Padding(padding: const EdgeInsets.all(8), child: Text('\$${neto}')));
      dataRows.add(TableRow(children: cells));
    }
    // Expandir al ancho disponible y centrar la tabla
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.center,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: {for (var i = 0; i < columns.length; i++) i: const IntrinsicColumnWidth()},
                children: [
                  // Encabezados
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: columns.map((col) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: (col.label is Text)
                            ? Text((col.label as Text).data ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                            : col.label,
                      );
                    }).toList(),
                  ),
                  // Subencabezados
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: subHeaders.map((sub) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    }).toList(),
                  ),
                  // Filas de datos
                  ...dataRows,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
