import 'package:flutter/material.dart';

/// Widget personalizado para tabla de datos
/// Proporciona una tabla scrolleable y estilizada
class CustomDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final double? height;
  final Color? headerColor;
  final Color? borderColor;
  final double? columnSpacing;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;
  final BorderRadius? borderRadius;

  const CustomDataTable({
    Key? key,
    required this.headers,
    required this.rows,
    this.height = 400,
    this.headerColor,
    this.borderColor,
    this.columnSpacing = 24,
    this.padding,
    this.showBorder = true,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  child: DataTable(
                    columnSpacing: columnSpacing!,
                    border:
                        showBorder
                            ? TableBorder.all(
                              color: borderColor ?? Color(0xFFE5E5E5),
                              width: 1.2,
                              borderRadius:
                                  borderRadius ?? BorderRadius.circular(12),
                            )
                            : null,
                    headingRowColor: MaterialStateProperty.all(
                      headerColor ?? Color(0xFFF3F3F3),
                    ),
                    columns:
                        headers
                            .map(
                              (header) => DataColumn(
                                label: Text(
                                  header,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                            .toList(),
                    rows:
                        rows
                            .map(
                              (row) => DataRow(
                                cells:
                                    row.map((cell) => DataCell(cell)).toList(),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
