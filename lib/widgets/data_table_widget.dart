import 'package:flutter/material.dart';

/// Tabla de datos genérica y reutilizable con scroll horizontal.
///
/// Este widget implementa una tabla con las siguientes características:
/// - Encabezados personalizables
/// - Subencabezados opcionales
/// - Scroll horizontal para tablas anchas
/// - Espaciado configurable entre celdas
/// - Bordes ligeros para mejor legibilidad
///
/// Se utiliza en varias pantallas del sistema para mostrar datos tabulares como:
/// - Lista de empleados
/// - Reportes de nómina
/// - Resúmenes de actividades
class DataTableWidget extends StatelessWidget {
  /// Títulos de las columnas de la tabla
  final List<String> columns;
  /// Datos de las filas. Cada fila es una lista de strings alineada con las columnas
  final List<List<String>> rows;
  /// Subtítulos opcionales alineados con cada columna
  final List<String>? subHeaders;
  /// Espacio horizontal entre celdas
  final double horizontalSpacing;
  /// Espacio vertical entre celdas
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
