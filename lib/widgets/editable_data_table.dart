import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget modular para edición en la tabla de nómina.
class EditableDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int index, String key, dynamic value)? onChanged;
  final bool isExpanded;
  final bool readOnly;

  const EditableDataTableWidget({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onChanged,
    this.isExpanded = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<EditableDataTableWidget> createState() => _EditableDataTableWidgetState();
}

class _EditableDataTableWidgetState extends State<EditableDataTableWidget> {
  String _formatCurrency(num value) {
    if (value == value.toInt()) {
      return '\$${value.toInt()}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  int get _numDays {
    return (widget.semanaSeleccionada?.duration.inDays ?? 6) + 1; // Always include an extra day to handle Saturday
  }

  void _handleValueChange(Map<String, dynamic> empleado, int index, String key, dynamic value) {
    if (widget.readOnly) return;

    setState(() {
      empleado[key] = value;

      // Recalcular totales
      final diasCount = widget.semanaSeleccionada?.duration.inDays ?? 6;
      final total = List.generate(diasCount + 1, (i) => 
        int.tryParse((empleado['dia_$i'] ?? '0').toString()) ?? 0
      ).reduce((a, b) => a + b);
      
      final debe = int.tryParse(empleado['debe']?.toString() ?? '0') ?? 0;
      final subtotal = total - debe;
      final comedorValue = empleado['comedor'] == true ? 400 : 0;
      final totalNeto = subtotal - comedorValue;

      // Actualizar los totales en el empleado
      empleado['total'] = total;
      empleado['subtotal'] = subtotal;
      empleado['totalNeto'] = totalNeto;
    });

    widget.onChanged?.call(index, key, value);
  }

  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 90 : 75,
          child: const Text('Clave',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 220 : 180,
          child: const Text('Nombre',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
      ),
      ...widget.semanaSeleccionada != null 
        ? List.generate(_numDays, (i) {
            final date = widget.semanaSeleccionada!.start.add(Duration(days: i));
            final dateFormat = DateFormat('EEE\nd/M', 'es');
            return DataColumn(
              label: SizedBox(
                width: widget.isExpanded ? 90 : 75,
                child: Text(
                  dateFormat.format(date).toLowerCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          })
        : ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'].map((dia) => 
            DataColumn(
              label: SizedBox(
                width: widget.isExpanded ? 90 : 75,
                child: Text(
                  dia,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ).toList(),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 100 : 85,
          child: const Text('Total',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 100 : 85,
          child: const Text('Debe',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 100 : 85,
          child: const Text('Subtotal',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 100 : 85,
          child: const Text('Comedor',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 100 : 85,
          child: const Text('Total\nNeto',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildRows() {
    return widget.empleados.asMap().entries.map((entry) {
      final index = entry.key;
      final empleado = entry.value;

      // Calcular valores
      final total = empleado['total'] ?? 0;
      final debe = empleado['debe'] ?? 0;
      final subtotal = empleado['subtotal'] ?? 0;
      final comedorValue = empleado['comedor'] == true ? 400 : 0;
      final totalNeto = empleado['totalNeto'] ?? subtotal - comedorValue;

      return DataRow(
        cells: [
          DataCell(SizedBox(
            width: widget.isExpanded ? 90 : 75,
            child: Text(empleado['clave']?.toString() ?? '', 
              textAlign: TextAlign.center
            ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 220 : 180,
            child: Text(empleado['nombre']?.toString() ?? '', 
              textAlign: TextAlign.left
            ),
          )),
          ...List.generate(_numDays, (i) =>
            DataCell(SizedBox(
              width: widget.isExpanded ? 90 : 75,
              child: widget.readOnly
                ? Text(
                    _formatCurrency(int.tryParse(empleado['dia_$i']?.toString() ?? '0') ?? 0),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                  )
                : TextFormField(
                    key: ValueKey('dia_${empleado['id']}_$i'),
                    controller: TextEditingController(
                      text: _formatCurrency(int.tryParse(empleado['dia_$i']?.toString() ?? '0') ?? 0)
                    )..selection = TextSelection.collapsed(
                      offset: _formatCurrency(int.tryParse(empleado['dia_$i']?.toString() ?? '0') ?? 0).length
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: widget.isExpanded ? 12 : 8
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final numStr = value.replaceAll(RegExp(r'[^\d.]'), '');
                      _handleValueChange(empleado, index, 'dia_$i', numStr);
                    },
                  ),
            ))
          ),
          DataCell(SizedBox(
            width: widget.isExpanded ? 100 : 85,
            child: Text(
              _formatCurrency(total),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: widget.isExpanded ? 15 : 13
              ),
            ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 100 : 85,
            child: widget.readOnly
              ? Text(
                  _formatCurrency(debe),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                )
              : TextFormField(
                  key: ValueKey('debe_${empleado['id']}'),
                  controller: TextEditingController(
                    text: _formatCurrency(debe)
                  )..selection = TextSelection.collapsed(
                    offset: _formatCurrency(debe).length
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: widget.isExpanded ? 15 : 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: widget.isExpanded ? 12 : 8
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final numStr = value.replaceAll(RegExp(r'[^\d.]'), '');
                    _handleValueChange(empleado, index, 'debe', numStr);
                  },
                ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 100 : 85,
            child: Text(
              _formatCurrency(subtotal),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: widget.isExpanded ? 15 : 13
              ),
            ),
          )),
          DataCell(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.readOnly
                ? Container(
                    height: widget.isExpanded ? 40 : 36,
                    width: widget.isExpanded ? 90 : 75,
                    decoration: BoxDecoration(
                      color: empleado['comedor'] == true ? const Color(0xFF8AB531) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          empleado['comedor'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                          size: widget.isExpanded ? 24 : 20,
                          color: empleado['comedor'] == true ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCurrency(400),
                          style: TextStyle(
                            fontSize: widget.isExpanded ? 15 : 13,
                            fontWeight: FontWeight.w500,
                            color: empleado['comedor'] == true ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : MaterialButton(
                    key: ValueKey('comedor_${empleado['id']}_${empleado['comedor']}'),
                    onPressed: () => _handleValueChange(empleado, index, 'comedor', !(empleado['comedor'] ?? false)),
                    height: widget.isExpanded ? 40 : 36,
                    minWidth: widget.isExpanded ? 90 : 75,
                    color: empleado['comedor'] == true ? const Color(0xFF8AB531) : Colors.grey.shade200,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          empleado['comedor'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                          size: widget.isExpanded ? 24 : 20,
                          color: empleado['comedor'] == true ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCurrency(400),
                          style: TextStyle(
                            fontSize: widget.isExpanded ? 15 : 13,
                            fontWeight: FontWeight.w500,
                            color: empleado['comedor'] == true ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
          DataCell(SizedBox(
            width: widget.isExpanded ? 100 : 85,
            child: Text(
              _formatCurrency(totalNeto),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: widget.isExpanded ? 15 : 13,
                color: totalNeto < 0 ? Colors.red : null,
              ),
            ),
          )),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: widget.isExpanded ? 12 : 8,
          headingRowHeight: widget.isExpanded ? 52 : 48,
          dataRowHeight: widget.isExpanded ? 56 : 52,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          headingTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: TextStyle(
            fontSize: widget.isExpanded ? 14 : 13,
          ),
          showBottomBorder: true,
          columns: _buildColumns(),
          rows: [
            DataRow(
              color: MaterialStateProperty.all(Colors.grey.shade50),
              cells: [
                DataCell(SizedBox(width: widget.isExpanded ? 90 : 75)),
                DataCell(SizedBox(width: widget.isExpanded ? 220 : 180)),
                ...List.generate(_numDays, (i) =>
                  DataCell(
                    Container(
                      width: widget.isExpanded ? 90 : 75,
                      alignment: Alignment.center,
                      child: const Text('TT',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ),
                ...List.generate(5, (i) => DataCell(SizedBox(width: widget.isExpanded ? 100 : 85))),
              ],
            ),
            ..._buildRows(),
          ],
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200),
            verticalInside: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}
