import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Nueva implementación de tabla editable desde cero
/// Versión limpia y eficiente para manejar nóminas
class NuevaTablaEditable extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int index, String key, dynamic value)? onChanged;
  final bool isExpanded;
  final bool readOnly;

  const NuevaTablaEditable({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onChanged,
    this.isExpanded = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<NuevaTablaEditable> createState() => _NuevaTablaEditableState();
}

class _NuevaTablaEditableState extends State<NuevaTablaEditable> {
  // Map para mantener el estado calculado de cada empleado
  final Map<int, Map<String, dynamic>> _empleadosCalculados = {};
  
  @override
  void initState() {
    super.initState();
    print('🏁 DEBUG - initState llamado: isExpanded=${widget.isExpanded}, empleados=${widget.empleados.length}');
    
    // Usar WidgetsBinding para asegurar que se ejecute después del build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calcularTodosLosTotales();
      }
    });
  }

  @override
  void didUpdateWidget(NuevaTablaEditable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    print('🔄 DEBUG - didUpdateWidget llamado: isExpanded=${widget.isExpanded}');
    print('  Empleados anterior: ${oldWidget.empleados.length}');
    print('  Empleados nuevo: ${widget.empleados.length}');
    print('  Hash anterior: ${oldWidget.empleados.hashCode}');
    print('  Hash nuevo: ${widget.empleados.hashCode}');
    
    // Recalcular si cambiaron los empleados o si hay cambios significativos
    bool debeRecalcular = false;
    
    if (widget.empleados.length != oldWidget.empleados.length) {
      print('  🔄 Recalculando: cambió número de empleados');
      debeRecalcular = true;
    } else if (widget.empleados.hashCode != oldWidget.empleados.hashCode) {
      print('  🔄 Recalculando: cambió hash de empleados');
      debeRecalcular = true;
    } else {
      // Verificar si cambió algún dato importante de empleados
      for (int i = 0; i < widget.empleados.length; i++) {
        final empleadoAnterior = oldWidget.empleados[i];
        final empleadoNuevo = widget.empleados[i];
        
        // Verificar campos clave que afectan totales
        final camposClave = ['total', 'debe', 'comedor'];
        for (int j = 0; j <= 6; j++) {
          camposClave.add('dia_${j}_s');
        }
        
        for (String campo in camposClave) {
          if (empleadoAnterior[campo] != empleadoNuevo[campo]) {
            print('  🔄 Recalculando: cambió $campo de ${empleadoNuevo['nombre']}');
            debeRecalcular = true;
            break;
          }
        }
        
        if (debeRecalcular) break;
      }
    }
    
    if (debeRecalcular) {
      // Usar Future.microtask para evitar conflictos de setState
      Future.microtask(() {
        if (mounted) {
          _calcularTodosLosTotales();
        }
      });
    } else {
      print('  ✅ No necesita recalcular');
    }
  }

  /// Calcula totales para todos los empleados
  void _calcularTodosLosTotales() {
    print('📊 Calculando totales para ${widget.empleados.length} empleados (isExpanded: ${widget.isExpanded})');
    
    if (widget.empleados.isEmpty) {
      print('⚠️ No hay empleados para calcular');
      return;
    }
    
    bool huboCambios = false;
    
    for (int i = 0; i < widget.empleados.length; i++) {
      final empleado = widget.empleados[i];
      final nombre = empleado['nombre'] ?? 'Sin nombre';
      
      print('📋 Procesando empleado $i: $nombre');
      
      // Calcular totales
      final totales = _calcularTotalesEmpleado(empleado);
      
      // Verificar si hubo cambios en los totales
      if (empleado['total'] != totales['total'] ||
          empleado['subtotal'] != totales['subtotal'] ||
          empleado['totalNeto'] != totales['totalNeto']) {
        
        print('  📈 Actualizando totales de $nombre:');
        print('    total: ${empleado['total']} -> ${totales['total']}');
        print('    subtotal: ${empleado['subtotal']} -> ${totales['subtotal']}');
        print('    totalNeto: ${empleado['totalNeto']} -> ${totales['totalNeto']}');
        
        huboCambios = true;
        
        // Actualizar el empleado original con los totales calculados
        empleado['total'] = totales['total'];
        empleado['subtotal'] = totales['subtotal'];
        empleado['totalNeto'] = totales['totalNeto'];
      } else {
        print('  ✅ Totales de $nombre ya están correctos');
      }
      
      // Guardar en cache para referencia rápida
      _empleadosCalculados[i] = {
        ...empleado,
        ...totales,
      };
    }
    
    // Solo forzar actualización de UI si hubo cambios
    if (huboCambios && mounted) {
      print('🔄 Forzando actualización de UI');
      setState(() {});
    } else {
      print('✅ No se requiere actualización de UI');
    }
    
    print('✅ Totales calculados completamente para vista ${widget.isExpanded ? 'expandida' : 'principal'}');
    print('═══════════════════════════════════════════════════════════════');
  }

  /// Calcula los totales de un empleado específico
  Map<String, int> _calcularTotalesEmpleado(Map<String, dynamic> empleado) {
    final diasCount = widget.semanaSeleccionada?.duration.inDays ?? 6;
    int total = 0;
    
    print('🔍 DEBUG - Calculando totales para: ${empleado['nombre']} (isExpanded: ${widget.isExpanded})');
    
    // ESTRATEGIA 1: Sumar días trabajados (dia_0_s, dia_1_s, etc.)
    List<String> diasEncontrados = [];
    for (int i = 0; i <= diasCount; i++) {
      final key = 'dia_${i}_s';
      if (empleado.containsKey(key) && empleado[key] != null) {
        final valorOriginal = empleado[key];
        final valor = _convertirAEntero(valorOriginal);
        if (valor > 0) {
          diasEncontrados.add('$key=$valor');
          total += valor;
        }
        print('  $key: $valorOriginal (${valorOriginal.runtimeType}) -> $valor');
      }
    }
    
    print('  Días encontrados (${diasEncontrados.length}): ${diasEncontrados.join(', ')}');
    print('  Total de días: $total');
    
    // ESTRATEGIA 2: Si no hay suficientes días individuales o total es 0, 
    // buscar también en formato alternativo de BD
    if (total == 0 || diasEncontrados.length < 3) {
      print('  🔄 Buscando formatos alternativos...');
      final formatosAlternativos = [
        'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo',
        'day_0', 'day_1', 'day_2', 'day_3', 'day_4', 'day_5', 'day_6',
      ];
      
      int totalAlternativo = 0;
      List<String> alternativosEncontrados = [];
      
      for (String formato in formatosAlternativos) {
        if (empleado.containsKey(formato) && empleado[formato] != null) {
          final valorOriginal = empleado[formato];
          final valor = _convertirAEntero(valorOriginal);
          if (valor > 0) {
            alternativosEncontrados.add('$formato=$valor');
            totalAlternativo += valor;
          }
          print('  $formato (alternativo): $valorOriginal -> $valor');
        }
      }
      
      if (totalAlternativo > total) {
        total = totalAlternativo;
        print('  ✅ Usando total alternativo: $total (formatos: ${alternativosEncontrados.join(', ')})');
      }
    }
    
    // ESTRATEGIA 3: ÚLTIMO RECURSO - Si aún no hay datos de días, usar total existente de BD
    if (total == 0 && empleado.containsKey('total') && empleado['total'] != null) {
      final totalOriginal = empleado['total'];
      final totalBD = _convertirAEntero(totalOriginal);
      if (totalBD > 0) {
        total = totalBD;
        print('  ⚠️ Usando total desde BD (último recurso): $totalOriginal (${totalOriginal.runtimeType}) -> $total');
      }
    }
    
    final debeOriginal = empleado['debe'];
    final comedorOriginal = empleado['comedor'];
    final debe = _convertirAEntero(debeOriginal);
    final comedor = _convertirAEntero(comedorOriginal);
    
    print('  debe: $debeOriginal (${debeOriginal.runtimeType}) -> $debe');
    print('  comedor: $comedorOriginal (${comedorOriginal.runtimeType}) -> $comedor');
    
    final subtotal = total - debe;
    final totalNeto = subtotal - comedor;
    
    print('  🎯 RESULTADO FINAL: total=$total, subtotal=$subtotal, totalNeto=$totalNeto');
    print('  ═══════════════════════════════════════════════════════════════');
    
    return {
      'total': total,
      'subtotal': subtotal,
      'totalNeto': totalNeto,
    };
  }

  /// Convierte cualquier valor a entero de forma segura
  int _convertirAEntero(dynamic valor) {
    if (valor == null) return 0;
    if (valor is int) return valor;
    if (valor is double) return valor.round(); // Usar round() en lugar de toInt() para manejar decimales correctamente
    if (valor is bool) return valor ? 400 : 0; // Para comedor
    if (valor is String) {
      // Primero intentar parsearlo como double y luego convertir a entero
      final doubleValue = double.tryParse(valor);
      if (doubleValue != null) {
        return doubleValue.round();
      }
      // Si no es un decimal válido, limpiar solo los dígitos
      final cleaned = valor.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  /// Maneja cambios en los campos editables
  void _manejarCambio(int index, String campo, String valor) {
    if (widget.readOnly || index >= widget.empleados.length) return;
    
    final empleado = widget.empleados[index];
    
    print('🔄 DEBUG - Cambio detectado: ${empleado['nombre']}, campo: $campo, valor: $valor');
    
    // Actualizar el valor en el empleado
    if (campo == 'comedor') {
      final valorEntero = _convertirAEntero(valor);
      empleado[campo] = valorEntero;
      print('  Comedor actualizado: $valorEntero');
    } else if (campo.contains('dia_') && campo.endsWith('_s')) {
      // Para campos de días trabajados, asegurar que se guarde como entero
      final valorLimpio = valor.replaceAll(RegExp(r'[^\d]'), '');
      final valorEntero = int.tryParse(valorLimpio) ?? 0;
      empleado[campo] = valorEntero; // Guardar como entero, no como string
      print('  Campo $campo actualizado: $valorLimpio -> $valorEntero');
    } else if (campo == 'debe') {
      // Para debe, también guardar como entero
      final valorLimpio = valor.replaceAll(RegExp(r'[^\d]'), '');
      final valorEntero = int.tryParse(valorLimpio) ?? 0;
      empleado[campo] = valorEntero;
      print('  Debe actualizado: $valorLimpio -> $valorEntero');
    } else {
      // Para otros campos, usar string limpio
      final valorLimpio = valor.replaceAll(RegExp(r'[^\d]'), '');
      empleado[campo] = valorLimpio.isEmpty ? '0' : valorLimpio;
      print('  Campo $campo actualizado: ${empleado[campo]}');
    }
    
    // Mostrar estado actual del empleado antes de recalcular
    print('  Estado actual del empleado:');
    for (int i = 0; i <= 6; i++) {
      final key = 'dia_${i}_s';
      if (empleado.containsKey(key)) {
        print('    $key: ${empleado[key]} (${empleado[key].runtimeType})');
      }
    }
    
    // Recalcular totales solo para este empleado
    final totales = _calcularTotalesEmpleado(empleado);
    empleado['total'] = totales['total'];
    empleado['subtotal'] = totales['subtotal'];
    empleado['totalNeto'] = totales['totalNeto'];
    
    // Actualizar cache
    _empleadosCalculados[index] = {
      ...empleado,
      ...totales,
    };
    
    // Actualizar UI
    setState(() {});
    
    // Notificar cambio hacia arriba
    widget.onChanged?.call(index, campo, empleado[campo]);
    
    // Notificar totales actualizados
    widget.onChanged?.call(index, 'total', totales['total']);
    widget.onChanged?.call(index, 'subtotal', totales['subtotal']);
    widget.onChanged?.call(index, 'totalNeto', totales['totalNeto']);
    
    print('✅ Cambio procesado completamente');
  }

  /// Obtiene el número de días a mostrar
  int get _numeroDias {
    return (widget.semanaSeleccionada?.duration.inDays ?? 6) + 1;
  }

  /// Formatea un valor como moneda
  String _formatearMoneda(dynamic valor) {
    final entero = _convertirAEntero(valor);
    // Formatear como entero sin decimales
    return '\$${NumberFormat('#,##0', 'es_ES').format(entero)}';
  }

  /// Construye las columnas de la tabla
  List<DataColumn> _construirColumnas() {
    final anchoExpandido = widget.isExpanded;
    
    return [
      // Columna Clave
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 80 : 70,
          child: const Text('Clave', 
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      
      // Columna Nombre
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 200 : 170,
          child: const Text('Nombre',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
        ),
      ),
      
      // Columnas de días
      ...List.generate(_numeroDias, (i) {
        if (widget.semanaSeleccionada != null) {
          final fecha = widget.semanaSeleccionada!.start.add(Duration(days: i));
          final formato = DateFormat('EEE\nd/M', 'es');
          return DataColumn(
            label: SizedBox(
              width: anchoExpandido ? 150 : 80,
              child: Text(
                formato.format(fecha).toLowerCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          final dias = ['jue', 'vie', 'sab', 'dom', 'lun', 'mar', 'mie'];
          return DataColumn(
            label: SizedBox(
              width: anchoExpandido ? 120 : 80,
              child: Text(
                dias[i],
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      }),
      
      // Columnas de totales
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 100 : 85,
          child: const Text('Total',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 90 : 75,
          child: const Text('Debe',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 100 : 85,
          child: const Text('Subtotal',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 90 : 75,
          child: const Text('Comedor',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: anchoExpandido ? 100 : 85,
          child: const Text('Total\nNeto',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];
  }

  /// Construye las filas de la tabla
  List<DataRow> _construirFilas() {
    return widget.empleados.asMap().entries.map((entry) {
      final index = entry.key;
      final empleado = entry.value;
      
      return DataRow(
        cells: [
          // Celda Clave
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 80 : 70,
              child: Text(
                empleado['codigo']?.toString() ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Celda Nombre
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 200 : 170,
              child: Text(
                empleado['nombre']?.toString() ?? '',
                textAlign: TextAlign.left,
              ),
            ),
          ),
          
          // Celdas de días
          ...List.generate(_numeroDias, (i) => _construirCeldaDia(index, i)),
          
          // Celda Total (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 100 : 85,
              child: Text(
                _formatearMoneda(empleado['total']),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          // Celda Debe (editable)
          _construirCeldaEditable(index, 'debe', empleado['debe']),
          
          // Celda Subtotal (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 100 : 85,
              child: Text(
                _formatearMoneda(empleado['subtotal']),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          // Celda Comedor (editable)
          _construirCeldaEditable(index, 'comedor', empleado['comedor']),
          
          // Celda Total Neto (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 100 : 85,
              child: Text(
                _formatearMoneda(empleado['totalNeto']),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _convertirAEntero(empleado['totalNeto']) < 0 
                    ? Colors.red 
                    : null,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Construye una celda para un día específico
  DataCell _construirCeldaDia(int empleadoIndex, int diaIndex) {
    final empleado = widget.empleados[empleadoIndex];
    
    if (widget.isExpanded) {
      // Modo expandido: ID y Salario lado a lado
      return DataCell(
        SizedBox(
          width: 150,
          child: Row(
            children: [
              // Celda ID
              Expanded(
                child: _construirWidgetEditable(
                  empleadoIndex, 
                  'dia_${diaIndex}_id', 
                  empleado['dia_${diaIndex}_id'],
                  esPequena: true,
                ),
              ),
              const SizedBox(width: 2),
              // Celda Salario
              Expanded(
                child: _construirWidgetEditable(
                  empleadoIndex, 
                  'dia_${diaIndex}_s', 
                  empleado['dia_${diaIndex}_s'],
                  esPequena: true,
                  mostrarMoneda: true,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Modo normal: solo Salario
      return _construirCeldaEditable(
        empleadoIndex, 
        'dia_${diaIndex}_s', 
        empleado['dia_${diaIndex}_s'],
        ancho: 80,
      );
    }
  }

  /// Construye widget editable para usar dentro de Row/Column
  Widget _construirWidgetEditable(
    int empleadoIndex, 
    String campo, 
    dynamic valor, {
    bool esPequena = false,
    bool mostrarMoneda = false,
  }) {
    if (widget.readOnly) {
      return Container(
        height: widget.isExpanded ? 50 : 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          mostrarMoneda ? _formatearMoneda(valor) : (_convertirAEntero(valor).toString()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.isExpanded ? 14 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // CORREGIDO: Convertir el valor a entero y luego a string para mostrar correctamente
    final valorMostrar = _convertirAEntero(valor).toString();

    return _CeldaEditableSimple(
      valorInicial: valorMostrar,
      alCambiar: (nuevoValor) => _manejarCambio(empleadoIndex, campo, nuevoValor),
      esExpandida: widget.isExpanded,
      esPequena: esPequena,
      mostrarMoneda: mostrarMoneda,
    );
  }

  /// Construye una celda editable
  DataCell _construirCeldaEditable(
    int empleadoIndex, 
    String campo, 
    dynamic valor, {
    double? ancho,
    bool esPequena = false,
    bool mostrarMoneda = false,
  }) {
    if (widget.readOnly) {
      return DataCell(
        Container(
          width: ancho,
          height: widget.isExpanded ? 50 : 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            mostrarMoneda ? _formatearMoneda(valor) : (_convertirAEntero(valor).toString()),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.isExpanded ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // CORREGIDO: Convertir el valor a entero y luego a string para mostrar correctamente
    final valorMostrar = _convertirAEntero(valor).toString();

    return DataCell(
      SizedBox(
        width: ancho,
        child: _CeldaEditableSimple(
          valorInicial: valorMostrar,
          alCambiar: (nuevoValor) => _manejarCambio(empleadoIndex, campo, nuevoValor),
          esExpandida: widget.isExpanded,
          esPequena: esPequena,
          mostrarMoneda: mostrarMoneda,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              columns: _construirColumnas(),
              rows: _construirFilas(),
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
    );
  }
}

/// Widget simple para celdas editables
class _CeldaEditableSimple extends StatefulWidget {
  final String valorInicial;
  final Function(String) alCambiar;
  final bool esExpandida;
  final bool esPequena;
  final bool mostrarMoneda;

  const _CeldaEditableSimple({
    required this.valorInicial,
    required this.alCambiar,
    this.esExpandida = false,
    this.esPequena = false,
    this.mostrarMoneda = false,
  });

  @override
  State<_CeldaEditableSimple> createState() => _CeldaEditableSimpleState();
}

class _CeldaEditableSimpleState extends State<_CeldaEditableSimple> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text == '0') {
        _controller.clear();
      } else if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        _controller.text = '0';
        widget.alCambiar('0');
      }
    });
  }

  @override
  void didUpdateWidget(_CeldaEditableSimple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorInicial != widget.valorInicial && !_focusNode.hasFocus) {
      _controller.text = widget.valorInicial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.esExpandida ? 50 : 40,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: TextStyle(
          fontSize: widget.esPequena ? 12 : (widget.esExpandida ? 14 : 12),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: widget.esExpandida ? 12 : 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          prefix: widget.mostrarMoneda && _controller.text.isNotEmpty 
            ? const Text('\$', style: TextStyle(color: Colors.grey))
            : null,
        ),
        onChanged: (valor) {
          // Limpiar y validar
          final limpio = valor.replaceAll(RegExp(r'[^\d]'), '');
          widget.alCambiar(limpio.isEmpty ? '0' : limpio);
        },
      ),
    );
  }
}
