import 'package:flutter/material.dart';
import '../../widgets_shared/index.dart';

/// Widget que encapsula una tabla de datos genérica con un título y una barra de búsqueda
/// Puede ser reutilizado en diferentes secciones de la aplicación
class GenericTable<T> extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<T> data;
  final List<DataCell> Function(T row, int rowIdx) buildCells;
  final Widget? searchBar;
  final Color textColor;
  final Color backgroundColor;

  const GenericTable({
    Key? key,
    required this.title,
    required this.headers,
    required this.data,
    required this.buildCells,
    this.searchBar,
    this.textColor = const Color(0xFF23611C),
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la tabla
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Barra de búsqueda opcional
          if (searchBar != null) ...[searchBar!, SizedBox(height: 24)],

          // Tabla de datos
          Container(
            height: 450,
            child: GenericDataTable<T>(
              data: data,
              headers: headers,
              buildCells: buildCells,
            ),
          ),
        ],
      ),
    );
  }
}
