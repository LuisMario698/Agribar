/// Widget para la visualización general de empleados.
/// Muestra métricas y una tabla con los datos de los empleados.

import 'package:flutter/material.dart';
import 'widgets_general/EmpleadosMetricsRow.dart';
import '../../../widgets_shared/index.dart';

class EmpleadosGeneralTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Calcular empleados activos e inactivos
    int empleadosActivos =
        empleadosData.where((emp) => emp['habilitado'] == true).length;
    int empleadosInactivos =
        empleadosData.where((emp) => emp['habilitado'] == false).length;

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
                controller: TextEditingController(),
                hintText: 'Buscar empleado por nombre o clave...',
                onSearchPressed: () {},
                fillColor: Color(0xFFF3F1EA),
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
            data: empleadosData,
            headers: empleadosHeaders,
            buildCells:
                (row, rowIdx) => [
                  DataCell(Text(row['clave'] ?? '')),
                  DataCell(Text(row['nombre'] ?? '')),
                  DataCell(Text(row['apellidoPaterno'] ?? '')),
                  DataCell(Text(row['apellidoMaterno'] ?? '')),
                  DataCell(Text(row['cuadrilla'] ?? '')),
                  DataCell(Text(row['sueldo'] ?? '')),
                  DataCell(Text(row['tipo'] ?? '')),
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
                        onPressed: () => toggleHabilitado(rowIdx),
                        child: Text(
                          row['habilitado'] ? 'Deshabilitar' : 'Habilitar',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
          ),
        ),
      ],
    );
  }
}
