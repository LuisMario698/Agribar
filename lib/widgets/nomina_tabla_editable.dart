import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Implementación de tabla editable para nóminas
/// Versión unificada y robusta para manejar datos de empleados
class NominaTablaEditable extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int index, String key, dynamic value)? onChanged;
  final bool isExpanded;
  final bool readOnly;

  const NominaTablaEditable({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onChanged,
    this.isExpanded = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<NominaTablaEditable> createState() => _NominaTablaEditableState();
}

class _NominaTablaEditableState extends State<NominaTablaEditable> {
  // Map para mantener el estado calculado de cada empleado
  final Map<int, Map<String, dynamic>> _empleadosCalculados = {};
  
  // Map para gestionar los FocusNodes de navegación
  final Map<String, FocusNode> _focusNodes = {};
  
  // Variables para rastrear la posición actual en la tabla
  // ignore: unused_field
  int _filaActual = 0;
  // ignore: unused_field
  int _columnaActual = 0;
  
  // Variable para controlar si el widget ha sido disposed
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    print('🏁 DEBUG - initState llamado: isExpanded=${widget.isExpanded}, empleados=${widget.empleados.length}');
    
    // Inicializar FocusNodes para navegación
    _inicializarFocusNodes();
    
    // Calcular totales de forma directa sin usar callbacks problemáticos
    if (mounted) {
      _calcularTodosLosTotales();
    }
  }

  @override
  void dispose() {
    // Marcar como disposed para evitar operaciones posteriores
    _isDisposed = true;
    
    // Limpiar todos los FocusNodes
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }

  /// Inicializa los FocusNodes para navegación de teclado
  void _inicializarFocusNodes() {
    _focusNodes.clear();
    
    if (!widget.isExpanded || widget.readOnly) return;
    
    final diasCount = _numeroDias;
    
    // Crear FocusNodes para todos los campos editables
    for (int empleadoIndex = 0; empleadoIndex < widget.empleados.length; empleadoIndex++) {
      // Campos de días (ID y Salario en modo expandido)
      for (int diaIndex = 0; diaIndex < diasCount; diaIndex++) {
        _focusNodes['${empleadoIndex}_dia_${diaIndex}_id'] = FocusNode();
        _focusNodes['${empleadoIndex}_dia_${diaIndex}_s'] = FocusNode();
      }
      
      // Campos editables adicionales
      _focusNodes['${empleadoIndex}_debe'] = FocusNode();
      _focusNodes['${empleadoIndex}_comedor'] = FocusNode();
    }
  }

  /// Obtiene la clave del FocusNode basada en posición
  String? _obtenerClaveFocus(int fila, int columna) {
    if (fila >= widget.empleados.length) return null;
    
    final diasCount = _numeroDias;
    
    // Mapear columnas a campos
    if (columna < diasCount * 2) {
      // Campos de días
      final diaIndex = columna ~/ 2;
      final esCampoId = columna % 2 == 0;
      
      if (diaIndex < diasCount) {
        return '${fila}_dia_${diaIndex}_${esCampoId ? 'id' : 's'}';
      }
    } else {
      // Campos adicionales (debe, comedor)
      final campoIndex = columna - (diasCount * 2);
      switch (campoIndex) {
        case 0:
          return '${fila}_debe';
        case 1:
          return '${fila}_comedor';
      }
    }
    
    return null;
  }

  /// Navega al siguiente campo editable
  void _navegarA(int nuevaFila, int nuevaColumna) {
    final claveFocus = _obtenerClaveFocus(nuevaFila, nuevaColumna);
    if (claveFocus != null && _focusNodes.containsKey(claveFocus)) {
      _filaActual = nuevaFila;
      _columnaActual = nuevaColumna;
      _focusNodes[claveFocus]?.requestFocus();
    }
  }

  /// Maneja la navegación con teclado
  void _manejarNavegacion(KeyEvent event, String campoActual) {
    if (event is! KeyDownEvent) return;
    
    // Encontrar posición actual
    final partes = campoActual.split('_');
    if (partes.length < 2) return;
    
    final filaActual = int.tryParse(partes[0]) ?? 0;
    int columnaActual = 0;
    
    // Determinar columna actual basada en el tipo de campo
    if (campoActual.contains('_dia_')) {
      final diaIndex = int.tryParse(partes[2]) ?? 0;
      final esCampoId = campoActual.endsWith('_id');
      columnaActual = (diaIndex * 2) + (esCampoId ? 0 : 1);
    } else if (campoActual.endsWith('_debe')) {
      columnaActual = (_numeroDias * 2);
    } else if (campoActual.endsWith('_comedor')) {
      columnaActual = (_numeroDias * 2) + 1;
    }
    
    final totalColumnas = (_numeroDias * 2) + 2; // Días * 2 + debe + comedor
    final totalFilas = widget.empleados.length;
    
    // Manejar teclas de navegación
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        // Flecha arriba: ir a la misma columna en la fila anterior
        if (filaActual > 0) {
          _navegarA(filaActual - 1, columnaActual);
        }
        break;
        
      case LogicalKeyboardKey.arrowDown:
        // Flecha abajo: ir a la misma columna en la fila siguiente
        if (filaActual < totalFilas - 1) {
          _navegarA(filaActual + 1, columnaActual);
        }
        break;
        
      case LogicalKeyboardKey.enter:
        // Enter: comportamiento tipo Excel - bajar a la misma columna conceptual
        // Si estoy en "Sueldo" (columna impar), ir a "actividad" (columna par) de la siguiente fila
        // Si estoy en "actividad" (columna par), ir a "Sueldo" (columna impar) de la misma fila
        if (filaActual < totalFilas - 1) {
          if (campoActual.contains('_dia_') && campoActual.endsWith('_s')) {
            // Estoy en campo de Sueldo, ir a actividad de la siguiente fila en el mismo día
            final diaIndex = int.tryParse(partes[2]) ?? 0;
            final nuevaColumna = (diaIndex * 2); // Columna de actividad (par)
            _navegarA(filaActual + 1, nuevaColumna);
          } else if (campoActual.contains('_dia_') && campoActual.endsWith('_id')) {
            // Estoy en campo de actividad, ir a Sueldo de la misma fila en el mismo día
            final diaIndex = int.tryParse(partes[2]) ?? 0;
            final nuevaColumna = (diaIndex * 2) + 1; // Columna de sueldo (impar)
            _navegarA(filaActual, nuevaColumna);
          } else {
            // Para otros campos (debe, comedor), comportamiento normal
            _navegarA(filaActual + 1, columnaActual);
          }
        } else {
          // Si estamos en la última fila, comportamiento cíclico
          if (campoActual.contains('_dia_') && campoActual.endsWith('_s')) {
            // Desde Sueldo, ir a actividad de la primera fila en el mismo día
            final diaIndex = int.tryParse(partes[2]) ?? 0;
            final nuevaColumna = (diaIndex * 2); // Columna de actividad (par)
            _navegarA(0, nuevaColumna);
          } else if (campoActual.contains('_dia_') && campoActual.endsWith('_id')) {
            // Desde actividad, ir a Sueldo de la misma fila en el mismo día
            final diaIndex = int.tryParse(partes[2]) ?? 0;
            final nuevaColumna = (diaIndex * 2) + 1; // Columna de sueldo (impar)
            _navegarA(filaActual, nuevaColumna);
          } else {
            // Para otros campos, ir al principio de la misma columna
            _navegarA(0, columnaActual);
          }
        }
        break;
        
      case LogicalKeyboardKey.arrowLeft:
        // Flecha izquierda: ir a la columna anterior en la misma fila
        if (columnaActual > 0) {
          _navegarA(filaActual, columnaActual - 1);
        } else if (filaActual > 0) {
          // Si estamos al inicio de la fila, ir al final de la fila anterior
          _navegarA(filaActual - 1, totalColumnas - 1);
        }
        break;
        
      case LogicalKeyboardKey.arrowRight:
        // Flecha derecha: ir a la siguiente columna en la misma fila
        if (columnaActual < totalColumnas - 1) {
          _navegarA(filaActual, columnaActual + 1);
        } else if (filaActual < totalFilas - 1) {
          // Si llegamos al final de la fila, ir al inicio de la siguiente fila
          _navegarA(filaActual + 1, 0);
        }
        break;
        
      case LogicalKeyboardKey.tab:
        // Tab: avanzar secuencialmente (derecha, luego siguiente fila)
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Shift+Tab: retroceder
          if (columnaActual > 0) {
            _navegarA(filaActual, columnaActual - 1);
          } else if (filaActual > 0) {
            _navegarA(filaActual - 1, totalColumnas - 1);
          }
        } else {
          // Tab normal: avanzar
          if (columnaActual < totalColumnas - 1) {
            _navegarA(filaActual, columnaActual + 1);
          } else if (filaActual < totalFilas - 1) {
            _navegarA(filaActual + 1, 0);
          }
        }
        break;
        
      case LogicalKeyboardKey.escape:
        // Escape: desenfocar el campo actual
        FocusScope.of(context).unfocus();
        break;
        
      case LogicalKeyboardKey.home:
        // Home: ir al primer campo de la fila actual
        _navegarA(filaActual, 0);
        break;
        
      case LogicalKeyboardKey.end:
        // End: ir al último campo de la fila actual
        _navegarA(filaActual, totalColumnas - 1);
        break;
    }
  }

  @override
  void didUpdateWidget(NominaTablaEditable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    print('🔄 DEBUG - didUpdateWidget llamado: isExpanded=${widget.isExpanded}');
    print('  Empleados anterior: ${oldWidget.empleados.length}');
    print('  Empleados nuevo: ${widget.empleados.length}');
    print('  Hash anterior: ${oldWidget.empleados.hashCode}');
    print('  Hash nuevo: ${widget.empleados.hashCode}');
    
    // Reinicializar FocusNodes si cambió el número de empleados o el modo expandido
    if (widget.empleados.length != oldWidget.empleados.length || 
        widget.isExpanded != oldWidget.isExpanded) {
      _inicializarFocusNodes();
    }
    
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
      // Calcular directamente si no está disposed
      if (mounted && !_isDisposed) {
        print('🔄 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Ejecutando recálculo de totales...');
        _calcularTodosLosTotales();
      }
    } else {
      // 🔧 FORZAR RECÁLCULO: Siempre recalcular para asegurar sincronización entre tablas
      print('🔄 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Forzando recálculo para sincronización...');
      if (mounted && !_isDisposed) {
        _calcularTodosLosTotales();
      }
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
      
      print('📋 Procesando empleado $i: $nombre (isExpanded: ${widget.isExpanded})');
      
      // Calcular totales
      final totales = _calcularTotalesEmpleado(empleado);
      
      // 🔧 CRÍTICO: Siempre actualizar los totales en el empleado original
      // Esto asegura que ambas vistas (principal y expandida) muestren los mismos valores
      final totalAnterior = empleado['total'];
      final subtotalAnterior = empleado['subtotal'];
      final totalNetoAnterior = empleado['totalNeto'];
      
      empleado['total'] = totales['total'];
      empleado['subtotal'] = totales['subtotal'];
      empleado['totalNeto'] = totales['totalNeto'];
      
      // Verificar si hubo cambios
      if (totalAnterior != totales['total'] ||
          subtotalAnterior != totales['subtotal'] ||
          totalNetoAnterior != totales['totalNeto']) {
        
        print('  📈 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Totales actualizados de $nombre:');
        print('    total: $totalAnterior -> ${totales['total']}');
        print('    subtotal: $subtotalAnterior -> ${totales['subtotal']}');
        print('    totalNeto: $totalNetoAnterior -> ${totales['totalNeto']}');
        
        huboCambios = true;
      } else {
        print('  ✅ [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Totales de $nombre ya están correctos');
      }
      
      // Guardar en cache para referencia rápida
      _empleadosCalculados[i] = {
        ...empleado,
        ...totales,
      };
    }
    
    // Solo forzar actualización de UI si hubo cambios
    if (huboCambios && mounted && !_isDisposed) {
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
    
    // Actualizar UI solo si no está disposed
    if (mounted && !_isDisposed) {
      setState(() {});
    }
    
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
    // 🔧 DEBUG: Mostrar conversión de valores para debug
    if (entero != 0) {
      print('💰 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] _formatearMoneda: $valor (${valor.runtimeType}) -> \$${NumberFormat('#,##0', 'es_ES').format(entero)}');
    }
    // Formatear como entero sin decimales
    return '\$${NumberFormat('#,##0', 'es_ES').format(entero)}';
  }

  /// Construye las columnas de la tabla
  List<DataColumn> _construirColumnas() {
    final anchoExpandido = widget.isExpanded;
    
    return [
      // Columna Clave
      DataColumn(
        label: Container(
          width: anchoExpandido ? 80 : 70,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.badge_rounded,
                color: Color(0xFF7BAE2F),
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Clave',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 13 : 10,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      
      // Columna Nombre
      DataColumn(
        label: Container(
          width: anchoExpandido ? 200 : 170,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: Color(0xFF7BAE2F),
                    size: anchoExpandido ? 18 : 14,
                  ),
                  SizedBox(width: anchoExpandido ? 6 : 4),
                  Text(
                    'Empleado',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: anchoExpandido ? 13 : 10,
                      color: Color(0xFF374151),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      
      // Columnas de días
      ...List.generate(_numeroDias, (i) {
        if (widget.semanaSeleccionada != null) {
          final fecha = widget.semanaSeleccionada!.start.add(Duration(days: i));
          final nombreDia = DateFormat('EEE', 'es').format(fecha);
          final fechaCorta = DateFormat('d/M', 'es').format(fecha);
          
          return DataColumn(
            label: Container(
              width: anchoExpandido ? 150 : 80,
              padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 6 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: anchoExpandido ? 8 : 6, vertical: anchoExpandido ? 4 : 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF7BAE2F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(anchoExpandido ? 8 : 6),
                    ),
                    child: Text(
                      nombreDia.toLowerCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: anchoExpandido ? 14 : 11, // Aumentado de 12 a 14 y de 9 a 11
                        color: Color(0xFF4A7C14),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: anchoExpandido ? 4 : 2),
                  Text(
                    fechaCorta,
                    style: TextStyle(
                      fontSize: anchoExpandido ? 12 : 9, // Aumentado de 11 a 12 y de 8 a 9
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final dias = ['jue', 'vie', 'sab', 'dom', 'lun', 'mar', 'mie'];
          final diasNumeros = ['3/7', '4/7', '5/7', '6/7', '7/7', '8/7', '2/7'];
          
          return DataColumn(
            label: Container(
              width: anchoExpandido ? 120 : 80,
              padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 6 : 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: anchoExpandido ? 8 : 6, vertical: anchoExpandido ? 4 : 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF7BAE2F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(anchoExpandido ? 8 : 6),
                    ),
                    child: Text(
                      dias[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: anchoExpandido ? 14 : 11, // Aumentado de 12 a 14 y de 9 a 11
                        color: Color(0xFF4A7C14),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: anchoExpandido ? 4 : 2),
                  Text(
                    diasNumeros[i],
                    style: TextStyle(
                      fontSize: anchoExpandido ? 12 : 9, // Aumentado de 11 a 12 y de 8 a 9
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }),
      
      // Columnas de totales mejoradas
      DataColumn(
        label: Container(
          width: anchoExpandido ? 100 : 85,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calculate_rounded,
                color: Colors.blue.shade600,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 13 : 10,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      DataColumn(
        label: Container(
          width: anchoExpandido ? 90 : 75,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.red.shade500,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Debe',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 13 : 10,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      DataColumn(
        label: Container(
          width: anchoExpandido ? 100 : 85,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_rounded,
                color: Colors.purple.shade600,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Subtotal',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 13 : 10,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      DataColumn(
        label: Container(
          width: anchoExpandido ? 90 : 75,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_rounded,
                color: Colors.orange.shade600,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Comedor',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 13 : 10,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      DataColumn(
        label: Container(
          width: anchoExpandido ? 100 : 85,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.paid_rounded,
                color: Colors.green.shade600,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Total\nNeto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 12 : 9,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                  height: anchoExpandido ? 1.1 : 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
              child: Builder(
                builder: (context) {
                  final totalFormateado = _formatearMoneda(empleado['total']);
                  // 🔧 DEBUG: Mostrar valores en construcción de celda
                  print('📊 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Celda Total ${empleado['nombre']}: ${empleado['total']} -> $totalFormateado');
                  return Text(
                    totalFormateado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                }
              ),
            ),
          ),
          
          // Celda Debe (editable con label)
          _construirCeldaEditable(
            index, 
            'debe', 
            empleado['debe'],
            labelTexto: 'Descuento',
            mostrarMoneda: true,
          ),
          
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
          
          // Celda Comedor (editable con label)
          _construirCeldaEditable(
            index, 
            'comedor', 
            empleado['comedor'],
            labelTexto: 'Comida',
            mostrarMoneda: true,
          ),
          
          // Celda Total Neto (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? 100 : 85,
              child: Builder(
                builder: (context) {
                  final totalNetoFormateado = _formatearMoneda(empleado['totalNeto']);
                  // 🔧 DEBUG: Mostrar valores en construcción de celda
                  print('💎 [${widget.isExpanded ? 'EXPANDIDA' : 'PRINCIPAL'}] Celda TotalNeto ${empleado['nombre']}: ${empleado['totalNeto']} -> $totalNetoFormateado');
                  return Text(
                    totalNetoFormateado,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _convertirAEntero(empleado['totalNeto']) < 0 
                        ? Colors.red 
                        : null,
                    ),
                  );
                }
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
      // Modo expandido: ID y Salario con labels
      return DataCell(
        SizedBox(
          width: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fila de labels
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200, width: 0.5),
                      ),
                      child: Text(
                        'actividad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200, width: 0.5),
                      ),
                      child: Text(
                        'Sueldo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Fila de campos editables
              Row(
                children: [
                  // Celda ID (actividad)
                  Expanded(
                    child: _construirWidgetEditable(
                      empleadoIndex, 
                      'dia_${diaIndex}_id', 
                      empleado['dia_${diaIndex}_id'],
                      esPequena: true,
                    ),
                  ),
                  const SizedBox(width: 4),
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
    // 🔒 Solo editable en tabla expandida o si readOnly está desactivado
    final esEditable = widget.isExpanded && !widget.readOnly;
    
    if (!esEditable) {
      return Container(
        height: widget.isExpanded ? 50 : 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isExpanded ? Colors.grey.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isExpanded ? Colors.grey.shade300 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          mostrarMoneda ? _formatearMoneda(valor) : (_convertirAEntero(valor).toString()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.isExpanded ? 14 : 12,
            fontWeight: widget.isExpanded ? FontWeight.w500 : FontWeight.w600,
            color: widget.isExpanded ? Colors.grey.shade700 : Colors.grey.shade800,
          ),
        ),
      );
    }

    // CORREGIDO: Convertir el valor a entero y luego a string para mostrar correctamente
    final valorMostrar = _convertirAEntero(valor).toString();
    
    // Crear clave única para el FocusNode
    final claveFocus = '${empleadoIndex}_${campo}';
    final focusNode = _focusNodes[claveFocus];

    return _CeldaEditableConNavegacion(
      valorInicial: valorMostrar,
      alCambiar: (nuevoValor) => _manejarCambio(empleadoIndex, campo, nuevoValor),
      esExpandida: widget.isExpanded,
      esPequena: esPequena,
      mostrarMoneda: mostrarMoneda,
      focusNode: focusNode,
      onNavegacion: (event) => _manejarNavegacion(event, claveFocus),
    );
  }

  /// Construye una celda editable con label opcional
  DataCell _construirCeldaEditable(
    int empleadoIndex, 
    String campo, 
    dynamic valor, {
    double? ancho,
    bool esPequena = false,
    bool mostrarMoneda = false,
    String? labelTexto,
  }) {
    // 🔒 Solo editable en tabla expandida y si readOnly está desactivado
    final esEditable = widget.isExpanded && !widget.readOnly;
    
    if (!esEditable) {
      return DataCell(
        Container(
          width: ancho,
          height: widget.isExpanded ? 52 : 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isExpanded ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(widget.isExpanded ? 10 : 8),
            border: Border.all(
              color: widget.isExpanded ? Colors.grey.shade200 : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            mostrarMoneda ? _formatearMoneda(valor) : (_convertirAEntero(valor).toString()),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: widget.isExpanded ? 15 : 13,
              fontWeight: widget.isExpanded ? FontWeight.w600 : FontWeight.w500,
              color: widget.isExpanded ? Colors.grey.shade600 : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    // CORREGIDO: Convertir el valor a entero y luego a string para mostrar correctamente
    final valorMostrar = _convertirAEntero(valor).toString();
    
    // Crear clave única para el FocusNode
    final claveFocus = '${empleadoIndex}_${campo}';
    final focusNode = _focusNodes[claveFocus];

    Widget contenido = _CeldaEditableConNavegacion(
      valorInicial: valorMostrar,
      alCambiar: (nuevoValor) => _manejarCambio(empleadoIndex, campo, nuevoValor),
      esExpandida: widget.isExpanded,
      esPequena: esPequena,
      mostrarMoneda: mostrarMoneda,
      focusNode: focusNode,
      onNavegacion: (event) => _manejarNavegacion(event, claveFocus),
    );

    // Si hay label y está en modo expandido, agregar el label encima
    if (labelTexto != null && widget.isExpanded) {
      contenido = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: mostrarMoneda ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: mostrarMoneda ? Colors.green.shade200 : Colors.orange.shade200, 
                width: 0.5
              ),
            ),
            child: Text(
              labelTexto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: mostrarMoneda ? Colors.green.shade700 : Colors.orange.shade700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          contenido,
        ],
      );
    }

    return DataCell(
      SizedBox(
        width: ancho,
        child: contenido,
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: widget.isExpanded ? 20 : 12,
            offset: Offset(0, widget.isExpanded ? 8 : 4),
            spreadRadius: 1,
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
              columnSpacing: widget.isExpanded ? 16 : 8,
              headingRowHeight: widget.isExpanded ? 72 : 56,
              dataRowHeight: widget.isExpanded ? 85 : 58,
              headingRowColor: MaterialStateProperty.all(
                widget.isExpanded 
                  ? Color(0xFF7BAE2F).withOpacity(0.1)
                  : Colors.grey.shade100
              ),
              headingTextStyle: TextStyle(
                fontSize: widget.isExpanded ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: 0.3,
              ),
              dataTextStyle: TextStyle(
                fontSize: widget.isExpanded ? 15 : 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
              showBottomBorder: true,
              columns: _construirColumnas(),
              rows: _construirFilas(),
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: widget.isExpanded 
                    ? Colors.grey.shade200 
                    : Colors.grey.shade300,
                  width: widget.isExpanded ? 1.5 : 1,
                ),
                verticalInside: BorderSide(
                  color: widget.isExpanded 
                    ? Colors.grey.shade200 
                    : Colors.grey.shade300,
                  width: widget.isExpanded ? 1.5 : 1,
                ),
                top: BorderSide(
                  color: Color(0xFF7BAE2F).withOpacity(0.3),
                  width: 2,
                ),
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget editable con navegación por teclado
class _CeldaEditableConNavegacion extends StatefulWidget {
  final String valorInicial;
  final Function(String) alCambiar;
  final bool esExpandida;
  final bool esPequena;
  final bool mostrarMoneda;
  final FocusNode? focusNode;
  final Function(KeyEvent)? onNavegacion;

  const _CeldaEditableConNavegacion({
    required this.valorInicial,
    required this.alCambiar,
    this.esExpandida = false,
    this.esPequena = false,
    this.mostrarMoneda = false,
    this.focusNode,
    this.onNavegacion,
  });

  @override
  State<_CeldaEditableConNavegacion> createState() => _CeldaEditableConNavegacionState();
}

class _CeldaEditableConNavegacionState extends State<_CeldaEditableConNavegacion> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
    _focusNode = widget.focusNode ?? FocusNode();
    
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
  void didUpdateWidget(_CeldaEditableConNavegacion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorInicial != widget.valorInicial && !_focusNode.hasFocus) {
      _controller.text = widget.valorInicial;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    // Solo dispose si creamos nosotros el FocusNode
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.esExpandida ? 52 : 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.esExpandida ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next, // Esto permite manejar Enter
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: TextStyle(
          fontSize: widget.esPequena ? 13 : (widget.esExpandida ? 16 : 13),
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.esExpandida ? 12 : 8,
            vertical: widget.esExpandida ? 14 : 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.esExpandida ? 10 : 8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.esExpandida ? 10 : 8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.esExpandida ? 10 : 8),
            borderSide: BorderSide(color: Color(0xFF7BAE2F), width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.esExpandida ? 10 : 8),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          filled: true,
          fillColor: _focusNode.hasFocus 
            ? Color(0xFF7BAE2F).withOpacity(0.08) // Más visible cuando está enfocado
            : Colors.grey.shade50,
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: widget.esPequena ? 12 : (widget.esExpandida ? 15 : 12),
            fontWeight: FontWeight.w500,
          ),
          prefix: widget.mostrarMoneda && _controller.text.isNotEmpty 
            ? Container(
                margin: EdgeInsets.only(right: 4),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Color(0xFF7BAE2F),
                    fontWeight: FontWeight.w600,
                    fontSize: widget.esPequena ? 12 : (widget.esExpandida ? 15 : 12),
                  ),
                ),
              )
            : null,
        ),
        onChanged: (valor) {
          if (mounted && !_isDisposed) {
            setState(() {}); // Para actualizar el color de fondo
          }
          // Limpiar y validar
          final limpio = valor.replaceAll(RegExp(r'[^\d]'), '');
          widget.alCambiar(limpio.isEmpty ? '0' : limpio);
        },
        onTap: () {
          if (mounted && !_isDisposed) {
            setState(() {}); // Para actualizar el color de fondo
          }
        },
        onFieldSubmitted: (value) {
          // Aquí manejamos Enter - llamar directamente a la lógica de navegación específica para Enter
          if (widget.onNavegacion != null) {
            // Crear un evento simulado para Enter
            widget.onNavegacion!(KeyDownEvent(
              timeStamp: Duration.zero,
              physicalKey: PhysicalKeyboardKey.enter,
              logicalKey: LogicalKeyboardKey.enter,
              character: null,
              synthesized: false,
            ));
          }
        },
        onEditingComplete: () {
          // Prevenir el comportamiento predeterminado de onEditingComplete
          // No hacer nada aquí para que onFieldSubmitted maneje la navegación
        },
      ),
    );
  }
}
