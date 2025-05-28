import 'package:flutter/material.dart';
import '../../../widgets_shared/index.dart';

class CuadrillaDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> cuadrillas;
  final void Function(int) onToggleHabilitado;
  const CuadrillaDataTable({
    Key? key,
    required this.cuadrillas,
    required this.onToggleHabilitado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericDataTable<Map<String, dynamic>>(
      data: cuadrillas,
      headers: const ['Nombre', 'Clave', 'Grupo', 'Actividad', 'Estado'],
      buildCells:
          (row, idx) => [
            DataCell(
              Text(
                row['nombre'],
                style: TextStyle(
                  color: row['habilitado'] == false ? Colors.grey[600] : null,
                ),
              ),
            ),
            DataCell(
              Text(
                row['clave'],
                style: TextStyle(
                  color: row['habilitado'] == false ? Colors.grey[600] : null,
                ),
              ),
            ),
            DataCell(
              Text(
                row['grupo'],
                style: TextStyle(
                  color: row['habilitado'] == false ? Colors.grey[600] : null,
                ),
              ),
            ),
            DataCell(
              Text(
                row['actividad'],
                style: TextStyle(
                  color: row['habilitado'] == false ? Colors.grey[600] : null,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 120,
                child: ElevatedButton(
                  onPressed: () => onToggleHabilitado(idx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        row['habilitado']
                            ? Color(0xFFE53935)
                            : Color(0xFF0B7A2F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    row['habilitado'] ? 'Deshabilitar' : 'Habilitar',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
    );
  }
}
