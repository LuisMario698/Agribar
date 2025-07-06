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
  }) : super(key: key);  @override
  Widget build(BuildContext context) {
    // Obtener el ancho disponible de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth * 0.95; // 95% del ancho de pantalla
    final columnWidth = availableWidth / columns.length; // Distribuir equitativamente

    return Center(
      child: Container(
        width: availableWidth,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: availableWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columnSpacing: 40, // Aumentado de 32 a 40
                  headingRowHeight: 80, // Aumentado de 70 a 80
                  dataRowHeight: 75, // Aumentado de 65 a 75
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Aumentado de 16 a 18
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 16, // Aumentado de 15 a 16
                    color: Colors.black87,
                  ),
                  columns: columns.map((col) => DataColumn(
                    label: Container(
                      width: columnWidth - 40, // Restar el columnSpacing
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, // Aumentado de 16.0 a 20.0
                          vertical: 16.0, // Aumentado de 12.0 a 16.0
                        ),
                        child: Text(
                          col,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                  rows: rows.map((row) => DataRow(
                    cells: row.map((cell) => DataCell(
                      Container(
                        width: columnWidth - 40, // Restar el columnSpacing
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, // Aumentado de 16.0 a 20.0
                            vertical: 16.0, // Aumentado de 12.0 a 16.0
                          ),
                          child: Text(
                            cell,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  )).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
