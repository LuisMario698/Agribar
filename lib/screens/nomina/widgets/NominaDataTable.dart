/// Widget de tabla de datos para la pantalla de nómina
/// Muestra y permite editar los datos de los empleados con sus cálculos de nómina

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que implementa una tabla desplazable para mostrar datos de nómina.
/// Permite editar los valores de días trabajados, deducciones y comedor.
/// Se adapta al tamaño de la pantalla y mantiene el estado de edición.
class NominaDataTable extends StatefulWidget {
  /// Datos a mostrar en la tabla (empleados y sus registros)
  final List<Map<String, dynamic>> data;

  /// Semana seleccionada para mostrar los días correspondientes
  final DateTimeRange? selectedWeek;

  /// Indica si la tabla está en modo expandido
  final bool isExpanded;

  /// Callback para actualizar valores en la tabla
  final Function(int, String, dynamic) onUpdate;
  final bool readOnly;

  const NominaDataTable({
    super.key,
    required this.data,
    this.selectedWeek,
    this.isExpanded = false,
    required this.onUpdate,
    this.readOnly = false,
  });

  @override
  _NominaDataTableState createState() => _NominaDataTableState();
}

class _NominaDataTableState extends State<NominaDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(NominaDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar los controladores cuando los datos cambian
    for (var empleado in widget.data) {
      for (int i = 0; i < 7; i++) {
        String key = '${empleado['clave']}_dia_$i';
        if (_controllers.containsKey(key) && !_focusNodes[key]!.hasFocus) {
          _controllers[key]?.text = empleado['dias'][i].toString();
        }
      }
      String deboKey = '${empleado['clave']}_debo';
      String comedorKey = '${empleado['clave']}_comedor';
      if (_controllers.containsKey(deboKey) &&
          !_focusNodes[deboKey]!.hasFocus) {
        _controllers[deboKey]?.text = empleado['debo'].toString();
      }
      if (_controllers.containsKey(comedorKey) &&
          !_focusNodes[comedorKey]!.hasFocus) {
        _controllers[comedorKey]?.text = empleado['comedor'].toString();
      }
    }
  }

  void _initializeControllers() {
    for (var empleado in widget.data) {
      for (int i = 0; i < 7; i++) {
        String key = '${empleado['clave']}_dia_$i';
        if (!_controllers.containsKey(key)) {
          _controllers[key] = TextEditingController(
            text: empleado['dias'][i].toString(),
          );
          _focusNodes[key] = FocusNode();
        }
      }
      String deboKey = '${empleado['clave']}_debo';
      String comedorKey = '${empleado['clave']}_comedor';
      if (!_controllers.containsKey(deboKey)) {
        _controllers[deboKey] = TextEditingController(
          text: empleado['debo'].toString(),
        );
        _focusNodes[deboKey] = FocusNode();
      }
      if (!_controllers.containsKey(comedorKey)) {
        _controllers[comedorKey] = TextEditingController(
          text: empleado['comedor'].toString(),
        );
        _focusNodes[comedorKey] = FocusNode();
      }
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _buildEditableCell(
    String value,
    String key,
    Function(String) onChanged,
  ) {
    if (widget.readOnly) {
      return Text(
        value,
        style: TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      );
    }

    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: value);
      _focusNodes[key] = FocusNode();
    }

    return TextField(
      controller: _controllers[key],
      focusNode: _focusNodes[key],
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        border: InputBorder.none,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.isEmpty) {
          onChanged('0');
        } else {
          onChanged(value);
        }
      },
      onTap: () {
        _controllers[key]?.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controllers[key]!.text.length,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Color(0xFFE0E0E0)),
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.grey.shade300;
              }
              return Colors.white;
            }),
            border: TableBorder.all(
              color: Colors.grey.shade400,
              width: 1,
              style: BorderStyle.solid,
            ),
            columnSpacing: widget.isExpanded ? 69 : 40,
            columns: [
              DataColumn(
                label: Text(
                  'Clave',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Nombre',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              if (widget.selectedWeek != null)
                ...List.generate(widget.selectedWeek!.duration.inDays + 1, (
                  index,
                ) {
                  final date = widget.selectedWeek!.start.add(
                    Duration(days: index),
                  );
                  final dayNames = [
                    'dom',
                    'lun',
                    'mar',
                    'mie',
                    'jue',
                    'vie',
                    'sab',
                  ];
                  return DataColumn(
                    label: Text(
                      dayNames[date.weekday % 7],
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                })
              else
                ...List.generate(7, (index) {
                  return DataColumn(
                    label: Text('Día', style: TextStyle(fontSize: 12)),
                  );
                }),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Debo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Subtotal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Comedor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total neto',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
            rows: [
              DataRow(
                cells: [
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  if (widget.selectedWeek != null)
                    ...List.generate(widget.selectedWeek!.duration.inDays + 1, (
                      index,
                    ) {
                      return const DataCell(
                        Padding(padding: EdgeInsets.all(4)),
                        placeholder: true,
                      );
                    })
                  else
                    ...List.generate(7, (index) {
                      return const DataCell(
                        Padding(padding: EdgeInsets.all(4)),
                        placeholder: true,
                      );
                    }),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                ],
                color: MaterialStateProperty.all(Colors.grey.shade200),
              ),
              ...widget.data.asMap().entries.map((entry) {
                final index = entry.key;
                final e = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        e['clave'].toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        e['nombre'].toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (widget.selectedWeek != null)
                      ...List.generate(
                        widget.selectedWeek!.duration.inDays + 1,
                        (diaIndex) {
                          return DataCell(
                            _buildEditableCell(
                              e['dias'][diaIndex].toString(),
                              '${e['clave']}_dia_$diaIndex',
                              (value) {
                                widget.onUpdate(index, 'dia_$diaIndex', value);
                              },
                            ),
                          );
                        },
                      )
                    else
                      ...List.generate(7, (diaIndex) {
                        return DataCell(
                          _buildEditableCell(
                            diaIndex < e['dias'].length
                                ? e['dias'][diaIndex].toString()
                                : '0',
                            '${e['clave']}_dia_$diaIndex',
                            (value) {
                              widget.onUpdate(index, 'dia_$diaIndex', value);
                            },
                          ),
                        );
                      }),
                    DataCell(
                      Text(
                        '\$${e['total']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        e['debo'].toString(),
                        '${e['clave']}_debo',
                        (value) {
                          widget.onUpdate(index, 'debo', value);
                        },
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${e['subtotal']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      _buildComedorCell(index, e, '${e['clave']}_comedor'),
                    ),
                    DataCell(
                      Text(
                        '\$${e['neto']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComedorCell(int index, Map<String, dynamic> e, String key) {
    bool checked = e['comedor'] == 400;
    if (widget.readOnly) {
      return Text(
        '${e['comedor']}',
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: checked,
          onChanged: (val) {
            int newValue = val == true ? 400 : 0;
            widget.onUpdate(index, 'comedor', newValue);
          },
        ),
        Text('${e['comedor']}', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
