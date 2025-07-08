/// Widget para la visualización general de empleados.
/// Muestra métricas y una tabla con los datos de los empleados.

import 'package:flutter/material.dart';
import 'widgets_general/EmpleadosMetricsRow.dart';
import '../widgets_shared/widgets_shared/index.dart';

class EmpleadosGeneralTab extends StatefulWidget {
  final List<Map<String, dynamic>> empleadosData;
  final List<String> empleadosHeaders;
  final Function(int) toggleHabilitado;

  const EmpleadosGeneralTab({
    Key? key,
    required this.empleadosData,
    required this.empleadosHeaders,
    required this.toggleHabilitado,
  }) : super(key: key);

  @override
  State<EmpleadosGeneralTab> createState() => _EmpleadosGeneralTabState();
}

class _EmpleadosGeneralTabState extends State<EmpleadosGeneralTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _filteredData = widget.empleadosData;
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredData = widget.empleadosData;
      });
      return;
    }

    setState(() {
      _filteredData =
          widget.empleadosData.where((empleado) {
            final clave = (empleado['clave'] ?? '').toLowerCase();
            final nombre = (empleado['nombre'] ?? '').toLowerCase();
            final apellidoPaterno =
                (empleado['apellidoPaterno'] ?? '').toLowerCase();
            final apellidoMaterno =
                (empleado['apellidoMaterno'] ?? '').toLowerCase();
            final cuadrilla = (empleado['cuadrilla'] ?? '').toLowerCase();

            return clave.contains(query) ||
                nombre.contains(query) ||
                apellidoPaterno.contains(query) ||
                apellidoMaterno.contains(query) ||
                cuadrilla.contains(query) ||
                '$nombre $apellidoPaterno $apellidoMaterno'.contains(query);
          }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredData = widget.empleadosData;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular empleados activos e inactivos basado en los datos filtrados
    int empleadosActivos =
        _filteredData.where((emp) => emp['habilitado'] == true).length;
    int empleadosInactivos =
        _filteredData.where((emp) => emp['habilitado'] == false).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila con búsqueda y métricas
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Barra de búsqueda
            Expanded(
              flex: 50,
              child: GenericSearchBar(
                controller: _searchController,
                hintText: 'Buscar empleado por nombre o clave...',
                onClearPressed: _clearSearch,
                fillColor: Color(0xFFF3F1EA),
                searchIcon: Icons.person_search,
              ),
            ),
            const SizedBox(width: 16),
            // Métricas
            Expanded(
              flex: 50,
              child: EmpleadosMetricsRow(
                activos: empleadosActivos,
                inactivos: empleadosInactivos,
              ),
            ),
          ],
        ),
        SizedBox(height: 32),
        // Tabla modular genérica
        Expanded(
          child: GenericDataTable<Map<String, dynamic>>(
            data: _filteredData,
            headers: widget.empleadosHeaders,
            buildCells: (row, rowIdx) {
              // Buscar el índice real en los datos originales para el toggle
              final originalIndex = widget.empleadosData.indexWhere(
                (emp) => emp['clave'] == row['clave'],
              );

              return [
                DataCell(Text(row['clave'] ?? '')),
                DataCell(Text(row['nombre'] ?? '')),
                DataCell(Text(row['apellidoPaterno'] ?? '')),
                DataCell(Text(row['apellidoMaterno'] ?? '')),
                DataCell(Text(row['curp'] ?? '')),
                DataCell(Text(row['rfc'] ?? '')),
                DataCell(Text(row['estadoorigen'] ?? '')),
                DataCell(
                  Container(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            row['habilitado']
                                ? Color(0xFFE53935)
                                : Color(0xFF0B7A2F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => widget.toggleHabilitado(originalIndex),
                      child: Text(
                        row['habilitado'] ? 'Deshabilitar' : 'Habilitar',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }
}
