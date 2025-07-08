import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';



/// Widget mejorado para mostrar y editar datos tabulares de empleados con funcionalidades avanzadas
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
  // 🔧 Mapa para mantener controladores persistentes
  final Map<String, TextEditingController> _controllers = {};
  // 🔧 Mapa para rastrear el foco de los campos
  final Map<String, FocusNode> _focusNodes = {};
  // 🔧 Set para rastrear qué campos están siendo editados activamente
  final Set<String> _activelyEditing = {};
  
  @override
  void dispose() {
    // Limpiar todos los controladores al destruir el widget
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    // Limpiar todos los focus nodes
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();
    
    super.dispose();
  }

  /// Obtiene o crea un focus node para un campo específico
  FocusNode _getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() {
        if (_focusNodes[key]!.hasFocus) {
          _activelyEditing.add(key);
          
          // 🔧 Limpiar el "0" automáticamente al enfocar
          final controller = _controllers[key];
          if (controller != null && controller.text == '0') {
            controller.clear();
          }
        } else {
          _activelyEditing.remove(key);
          
          // 🔧 Si queda vacío al perder el foco, poner "0"
          final controller = _controllers[key];
          if (controller != null && controller.text.isEmpty) {
            controller.text = '0';
          }
        }
      });
    }
    return _focusNodes[key]!;
  }

  /// Obtiene o crea un controlador para un campo específico
  TextEditingController _getController(String key, String initialValue) {
    if (!_controllers.containsKey(key)) {
      // Para valores que ya vienen limpios como enteros, no aplicar limpieza adicional
      _controllers[key] = TextEditingController(text: initialValue);
    } else {
      // Solo actualizar si el campo NO está siendo editado activamente
      if (!_activelyEditing.contains(key)) {
        final controller = _controllers[key]!;
        
        // Solo actualizar si es realmente diferente
        if (controller.text != initialValue) {
          final currentSelection = controller.selection;
          controller.text = initialValue;
          
          // Mantener posición del cursor si es válida, de lo contrario ir al final
          if (currentSelection.start >= 0 && currentSelection.start <= initialValue.length) {
            controller.selection = TextSelection.collapsed(offset: currentSelection.start);
          } else {
            controller.selection = TextSelection.collapsed(offset: initialValue.length);
          }
        }
      }
    }
    return _controllers[key]!;
  }

  /// Limpia el valor numérico removiendo formatos y caracteres no válidos (solo enteros)
  String _cleanNumericValue(String value) {
    if (value.isEmpty) return '';
    
    // Remover símbolos de moneda, espacios, puntos y cualquier carácter no numérico
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si está vacío después de limpiar, retornar cadena vacía
    if (cleaned.isEmpty) return '';
    
    // Remover ceros a la izquierda, excepto si es solo "0"
    cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
    if (cleaned.isEmpty) cleaned = '0';
    
    return cleaned;
  }
  String _formatCurrency(num value) {
    if (value == value.toInt()) {
      return '\$${value.toInt()}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  int get _numDays {
    return (widget.semanaSeleccionada?.duration.inDays ?? 6) + 1;
  }

  void _handleValueChange(Map<String, dynamic> empleado, int index, String key, dynamic value) {
    if (widget.readOnly) return;

    // Procesar el valor de entrada de manera segura (solo enteros)
    String processedValue = _cleanNumericValue(value.toString());
    
    // Validar que el valor es numérico válido (entero)
    final numericValue = int.tryParse(processedValue);
    if (numericValue == null && processedValue.isNotEmpty) {
      // Si no es un número válido, mantener el valor anterior
      return;
    }

    // Variables para capturar los totales calculados
    late int total;
    late int subtotal;
    late int totalNeto;

    setState(() {
      // Almacenar el valor limpio como entero (o cadena vacía si está vacío)
      empleado[key] = processedValue.isEmpty ? '0' : processedValue;

      // Recalcular totales sumando solo las celdas "S" por día
      final diasCount = widget.semanaSeleccionada?.duration.inDays ?? 6;
    total = List.generate(diasCount + 1, (i) {
  final sValue = double.tryParse((empleado['dia_${i}_s'] ?? '0').toString()) ?? 0.0;
  return sValue;
}).reduce((a, b) => a + b).toInt();
      
      final debe = int.tryParse(empleado['debe']?.toString() ?? '0') ?? 0;
      subtotal = total - debe;
      final comedorValue = int.tryParse(empleado['comedor']?.toString() ?? '0') ?? 0;
      totalNeto = subtotal - comedorValue;

      // Actualizar los totales en el empleado
      empleado['total'] = total;
      empleado['subtotal'] = subtotal;
      empleado['totalNeto'] = totalNeto;
    });
    // Usar Future.microtask para evitar conflictos de eventos
    Future.microtask(() {
      // Notificar el cambio del campo específico
      widget.onChanged?.call(index, key, processedValue.isEmpty ? '0' : processedValue);
      
      // También notificar los cambios de totales para mantener sincronización
      widget.onChanged?.call(index, 'total', total);
      widget.onChanged?.call(index, 'subtotal', subtotal);
      widget.onChanged?.call(index, 'totalNeto', totalNeto);
    });
  }

  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 70 : 75, // 🎯 Clave un poco más ancha
          child: const Text('Clave',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 180 : 170, // 🎯 Nombre más ancho
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
                width: widget.isExpanded ? 150 : 80, // 🎯 Días más anchos para mejor visualización
                child: Text(
                  dateFormat.format(date).toLowerCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          })
        : List.generate(7, (i) {
            final dias = ['jue', 'vie', 'sab', 'dom', 'lun', 'mar', 'mie'];
            return DataColumn(
              label: SizedBox(
                width: widget.isExpanded ? 110 : 80, // 🎯 Días más anchos
                child: Text(
                  dias[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 90 : 85, // 🎯 Total más ancho
          child: const Text('Total',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 80 : 75, // 🎯 Debe más ancho
          child: const Text('Debe',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 90 : 85, // 🎯 Subtotal más ancho
          child: const Text('Subtotal',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 80 : 75, // 🎯 Comedor más ancho
          child: const Text('Comedor',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: widget.isExpanded ? 90 : 85, // 🎯 Total Neto más ancho
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

      // Calcular valores (usando enteros)
      final total = empleado['total'] ?? 0;
      final debe = int.tryParse(empleado['debe'].toString()) ?? 0;
      final subtotal = int.tryParse(empleado['subtotal'].toString()) ?? 0;
      final comedorValue = int.tryParse(empleado['comedor'].toString()) ?? 0;
      final totalNeto = empleado['totalNeto'] ?? subtotal - comedorValue;
      

      return DataRow(
        cells: [
          DataCell(SizedBox(
            width: widget.isExpanded ? 70 : 75, // 🎯 Clave más ancha - debe coincidir con header
            child: Text(empleado['codigo']?.toString() ?? '', 
              textAlign: TextAlign.center
            ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 180 : 170, // 🎯 Nombre más ancho - debe coincidir con header
            child: Text(empleado['nombre']?.toString() ?? '', 
              textAlign: TextAlign.left
            ),
          )),
          ...List.generate(_numDays, (i) {
            return DataCell(
              SizedBox(
                width: widget.isExpanded ? 150 : 80, // 🎯 Días más anchos - debe coincidir con header
                child: widget.isExpanded 
                    ? Row(
                        children: [
                          // Celda ID (solo en modo expandido)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 3),
                              child: widget.readOnly
                                  ? Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        (int.tryParse(empleado['dia_${i}_id']?.toString() ?? '0') ?? 0).toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                      child: TextFormField(
                                        key: ValueKey('dia_${i}_id_${empleado['id']}'),
                                        controller: _getController(
                                          'dia_${i}_id_${empleado['id']}',
                                          (empleado['dia_${i}_id'] ?? '0').toString()
                                        ),
                                        focusNode: _getFocusNode('dia_${i}_id_${empleado['id']}'),
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF7BAE2F),
                                              width: 2,
                                            ),
                                          ),
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          _handleValueChange(empleado, index, 'dia_${i}_id', value);
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          // Celda S
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 3),
                              child: widget.readOnly
                                  ? Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        _formatCurrency(int.tryParse(empleado['dia_${i}_s']?.toString() ?? '0') ?? 0),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 48,
                                      child: TextFormField(
                                        key: ValueKey('dia_${i}_s_${empleado['id']}'),
                                        controller: _getController(
                                          'dia_${i}_s_${empleado['id']}',
                                          (empleado['dia_${i}_s'] ?? '0').toString()
                                        ),
                                        focusNode: _getFocusNode('dia_${i}_s_${empleado['id']}'),
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF7BAE2F),
                                              width: 2,
                                            ),
                                          ),
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                          ),
                                          prefixText: '\$',
                                          prefixStyle: const TextStyle(
                                            fontSize: 14, 
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          _handleValueChange(empleado, index, 'dia_${i}_s', value);
                                        },
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      )
                    : // Solo celda S en modo normal (SOLO LECTURA)
                      Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _formatCurrency(int.tryParse(empleado['dia_${i}_s']?.toString() ?? '0') ?? 0),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            );
          }),
          DataCell(SizedBox(
            width: widget.isExpanded ? 90 : 85, // 🎯 Total más ancho - debe coincidir con header
            child: Text(
              _formatCurrency(int.tryParse(total.toString()) ?? 0),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: widget.isExpanded ? 15 : 13
              ),
            ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 80 : 75, // 🎯 Debe más ancho - debe coincidir con header
            child: widget.readOnly || !widget.isExpanded
              ? Container(
                  height: widget.isExpanded ? 50 : 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(widget.isExpanded ? 8 : 4),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatCurrency(debe),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.isExpanded ? 15 : 13,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Container(
                  height: 50,
                  child: TextFormField(
                    key: ValueKey('debe_${empleado['id']}'),
                    controller: _getController(
                      'debe_${empleado['id']}',
                      (empleado['debe'] ?? '0').toString()
                    ),
                    focusNode: _getFocusNode('debe_${empleado['id']}'),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF7BAE2F),
                          width: 2,
                        ),
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      prefixText: '\$',
                      prefixStyle: const TextStyle(
                        fontSize: 15, 
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) {
                      _handleValueChange(empleado, index, 'debe', value);
                    },
                  ),
                ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 90 : 85, // 🎯 Subtotal más ancho - debe coincidir con header
            child: Text(
              _formatCurrency(subtotal),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: widget.isExpanded ? 15 : 13
              ),
            ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 80 : 75, // 🎯 Comedor más ancho - debe coincidir con header
            child: widget.readOnly || !widget.isExpanded
              ? Container(
                  height: widget.isExpanded ? 50 : 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(widget.isExpanded ? 8 : 4),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formatCurrency(comedorValue),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.isExpanded ? 15 : 13,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Container(
                  height: 50,
                  child: TextFormField(
                    key: ValueKey('comedor_${empleado['id']}'),
                    controller: _getController(
                      'comedor_${empleado['id']}',
                      (empleado['comedor'] ?? '0').toString()
                    ),
                    focusNode: _getFocusNode('comedor_${empleado['id']}'),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF7BAE2F),
                          width: 2,
                        ),
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      prefixText: '\$',
                      prefixStyle: const TextStyle(
                        fontSize: 15, 
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) {
                      _handleValueChange(empleado, index, 'comedor', value);
                    },
                  ),
                ),
          )),
          DataCell(SizedBox(
            width: widget.isExpanded ? 90 : 85, // 🎯 Total Neto más ancho - debe coincidir con header
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
    // 🔧 Wrapper con FocusScope para mejor manejo de eventos de teclado
    return FocusScope(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: widget.isExpanded ? 16 : 8,
              offset: Offset(0, widget.isExpanded ? 6 : 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: widget.isExpanded ? 12 : 6,
                headingRowHeight: widget.isExpanded ? 60 : 48,
                dataRowHeight: widget.isExpanded ? 68 : 52,
                headingRowColor: MaterialStateProperty.all(
                  widget.isExpanded 
                    ? Colors.grey.shade50
                    : Colors.grey.shade100
                ),
                headingTextStyle: TextStyle(
                  fontSize: widget.isExpanded ? 16 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
                dataTextStyle: TextStyle(
                  fontSize: widget.isExpanded ? 15 : 13,
                  color: const Color(0xFF6B7280),
                ),
                showBottomBorder: true,
                columns: _buildColumns(),
                rows: [
                  DataRow(
                    color: MaterialStateProperty.all(
                      widget.isExpanded 
                        ? Colors.grey.shade50
                        : Colors.grey.shade50                ),
                cells: [
                  DataCell(SizedBox(width: widget.isExpanded ? 60 : 65)), // 🎯 Clave más pequeña
                  DataCell(SizedBox(width: widget.isExpanded ? 170 : 150)),
                  ...List.generate(_numDays, (i) {
                    return DataCell(
                      Container(
                        width: widget.isExpanded ? 150 : 65, // 🎯 Días más grandes en expandido
                            child: widget.isExpanded
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'ID',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: const Text(
                                            'S',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: const Text(
                                      'S',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          ),
                        );                  }),
                  ...List.generate(5, (i) => DataCell(SizedBox(
                    width: i == 1 || i == 3 // Debe y Comedor
                        ? (widget.isExpanded ? 70 : 65) // Debe: 70, Comedor: 70
                        : (widget.isExpanded ? 80 : 75) // Total, Subtotal, Total Neto: 80
                  ))),
                    ],
                  ),
                  ..._buildRows(),
                ],
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
