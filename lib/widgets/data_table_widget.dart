import 'package:flutter/material.dart';

/// A generic scrollable data table that can be reused across screens.
class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  /// Subencabezados alineados con cada columna (opcional).
  final List<String>? subHeaders;
  final double horizontalSpacing;
  final double verticalSpacing;

  const DataTableWidget({
    Key? key,
    required this.columns,
    required this.rows,
    this.subHeaders,
    this.horizontalSpacing = 24.0,
    this.verticalSpacing = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subHeaders = this.subHeaders;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Fila de encabezados
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: columns.map((col) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)),
            )).toList(),
          ),
          // Fila de subencabezados si existen
          if (subHeaders != null)
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: subHeaders.map((sub) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          // Filas de datos
          ...rows.map((row) => TableRow(
            children: row.map((cell) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(cell),
            )).toList(),
          )),
        ],
      ),
    );
  }
}
