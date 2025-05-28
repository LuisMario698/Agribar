import 'package:flutter/material.dart';

class GenericDataTable<T> extends StatelessWidget {
  final List<T> data;
  final List<String> headers;
  final List<DataCell> Function(T row, int rowIdx) buildCells;
  final int minRows;

  /// Si se requiere una acción por fila (ej: botón), puede incluirse en buildCells
  const GenericDataTable({
    required this.data,
    required this.headers,
    required this.buildCells,
    this.minRows = 20,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int extraRows = data.length < minRows ? minRows - data.length : 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
        padding: EdgeInsets.all(0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    border: TableBorder.all(
                      color: Color(0xFFE5E5E5),
                      width: 1.2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    headingRowColor: MaterialStateProperty.all(
                      Color(0xFFF3F3F3),
                    ),
                    columnSpacing: 24,
                    columns:
                        headers.map((header) {
                          return DataColumn(
                            label: Text(
                              header,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                    rows: [
                      ...List.generate(data.length, (rowIdx) {
                        return DataRow(cells: buildCells(data[rowIdx], rowIdx));
                      }),
                      ...List.generate(extraRows, (i) {
                        return DataRow(
                          cells: List.generate(headers.length, (colIdx) {
                            return DataCell(Text(''));
                          }),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
