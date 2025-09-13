import 'package:flutter/material.dart';
import 'editable_table_cell.dart';

/// Helper class para construir filas de empleado en la tabla de nómina
class EmpleadoTableRowBuilder {
  final Map<String, dynamic> empleado;
  final int index;
  final DateTimeRange? semanaSeleccionada;
  final bool isExpanded;
  final bool readOnly;
  final Function(int index, String key, dynamic value)? onChanged;
  final Map<String, TextEditingController>? controllers;
  final Map<String, FocusNode>? focusNodes;

  const EmpleadoTableRowBuilder({
    required this.empleado,
    required this.index,
    this.semanaSeleccionada,
    this.isExpanded = false,
    this.readOnly = false,
    this.onChanged,
    this.controllers,
    this.focusNodes,
  });

  int get _numDays {
    return (semanaSeleccionada?.duration.inDays ?? 6) + 1;
  }

  String _formatCurrency(num value) {
    final doubleVal = value.toDouble();
  // Asegurar punto decimal (toStringAsFixed ya usa punto, pero mantenemos comentario aclaratorio)
  return '\$${doubleVal.toStringAsFixed(2)}';
  }

  void _handleCellChange(String key, dynamic value) {
    onChanged?.call(index, key, value);
  }

  /// Construye las celdas de la fila del empleado
  List<DataCell> buildCells() {
    num _parse(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v;
      if (v is bool) return v ? 400.0 : 0.0; // comedor boolean
      if (v is String) {
        final cleaned = v.replaceAll(',', '.');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    final total = _parse(empleado['total']);
    final debe = _parse(empleado['debe']);
    final subtotal = total + debe; // Nueva regla: debe suma
    final comedorValue = _parse(empleado['comedor']);
    final totalNeto = _parse(empleado['totalNeto'] ?? (subtotal - comedorValue));

    return [
      // Celda Código
      DataCell(SizedBox(
        width: isExpanded ? 70 : 75,
        child: Text(
          empleado['codigo']?.toString() ?? '',
          textAlign: TextAlign.center,
        ),
      )),
      // Celda Nombre
      DataCell(SizedBox(
        width: isExpanded ? 180 : 170,
        child: Text(
          empleado['nombre']?.toString() ?? '',
          textAlign: TextAlign.left,
        ),
      )),
      // Celdas de días
      ...List.generate(_numDays, (i) => _buildDayCell(i)),
      // Celda Total
      DataCell(SizedBox(
        width: isExpanded ? 90 : 85,
        child: Text(
          _formatCurrency(total),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isExpanded ? 15 : 13,
          ),
        ),
      )),
      // Celda Debe
      _buildEditableCell(
        'debe',
  _parse(empleado['debe']).toStringAsFixed(2),
        width: isExpanded ? 80 : 75,
        showCurrency: true,
      ),
      // Celda Subtotal
      DataCell(SizedBox(
        width: isExpanded ? 90 : 85,
        child: Text(
          _formatCurrency(subtotal),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isExpanded ? 15 : 13,
          ),
        ),
      )),
      // Celda Comedor
      _buildEditableCell(
        'comedor',
  _parse(empleado['comedor']).toStringAsFixed(2),
        width: isExpanded ? 80 : 75,
        showCurrency: true,
      ),
      // Celda Total Neto
      DataCell(SizedBox(
        width: isExpanded ? 90 : 85,
        child: Text(
          _formatCurrency(totalNeto),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isExpanded ? 15 : 13,
            color: totalNeto < 0 ? Colors.red : null,
          ),
        ),
      )),
    ];
  }

  DataCell _buildDayCell(int dayIndex) {
    return DataCell(
      SizedBox(
        width: isExpanded ? 150 : 80,
        child: isExpanded ? _buildExpandedDayCell(dayIndex) : _buildNormalDayCell(dayIndex),
      ),
    );
  }

  Widget _buildExpandedDayCell(int dayIndex) {
    return Row(
      children: [
        // Celda ID
        Expanded(
          child: EditableTableCell(
            fieldKey: 'dia_${dayIndex}_id_${empleado['id']}',
            initialValue: (empleado['dia_${dayIndex}_id'] ?? '0').toString(),
            onChanged: (value) => _handleCellChange('dia_${dayIndex}_id', value),
            isReadOnly: readOnly,
            isExpanded: isExpanded,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            margin: const EdgeInsets.only(right: 3),
          ),
        ),
        // Celda S (Salario)
        Expanded(
          child: EditableTableCell(
            fieldKey: 'dia_${dayIndex}_s_${empleado['id']}',
            initialValue: (empleado['dia_${dayIndex}_s'] ?? '0').toString(),
            onChanged: (value) => _handleCellChange('dia_${dayIndex}_s', value),
            isReadOnly: readOnly,
            isExpanded: isExpanded,
            showCurrencyPrefix: true,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            margin: const EdgeInsets.only(left: 3),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalDayCell(int dayIndex) {
    return EditableTableCell(
      fieldKey: 'dia_${dayIndex}_s_${empleado['id']}',
      initialValue: (empleado['dia_${dayIndex}_s'] ?? '0').toString(),
      onChanged: (value) => _handleCellChange('dia_${dayIndex}_s', value),
      isReadOnly: readOnly,
      isExpanded: false,
      height: 40,
      fontSize: 11,
    );
  }

  DataCell _buildEditableCell(
    String fieldKey, 
    String value, {
    required double width,
    bool showCurrency = false,
  }) {
    return DataCell(
      SizedBox(
        width: width,
        child: readOnly || !isExpanded
            ? Container(
                height: isExpanded ? 50 : 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(isExpanded ? 8 : 4),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  showCurrency ? _formatCurrency(int.tryParse(value) ?? 0) : value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isExpanded ? 15 : 13,
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : EditableTableCell(
                fieldKey: '${fieldKey}_${empleado['id']}',
                initialValue: value,
                onChanged: (newValue) => _handleCellChange(fieldKey, newValue),
                isExpanded: isExpanded,
                showCurrencyPrefix: showCurrency,
                height: 50,
                fontSize: 15,
              ),
      ),
    );
  }
}
