import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/registrar_actividad.dart';
import '../services/registrar_campo.dart';

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
  
  // Variable para controlar si el widget ha been disposed
  bool _isDisposed = false;

  // Mapa para almacenar las actividades
  Map<String, String> _actividadesMap = {};

  // Mapa para almacenar los campos
  Map<String, String> _camposMap = {};

  // Método para cargar las actividades desde la base de datos
  Future<void> _cargarActividades() async {
    try {
      print('🔄 Iniciando carga de actividades...');
      var actividades = await obtenerActividadesDesdeBD();
      if (!mounted) return;

      print('📦 Procesando ${actividades.length} actividades...');
      setState(() {
        _actividadesMap.clear(); // Limpiar el mapa existente
        for (var actividad in actividades) {
          final id = (actividad['id'] ?? 0).toString();
          final nombre = actividad['nombre']?.toString() ?? 'Sin nombre';
          final clave = actividad['clave']?.toString() ?? '';
          _actividadesMap[id] = '${clave} - ${nombre}';
          print('  Mapeando - ID: $id -> Clave: $clave -> Nombre: $nombre');
        }
      });
      
      print('✅ Actividades cargadas exitosamente:');
      print('  Total en mapa: ${_actividadesMap.length}');
      print('  Contenido del mapa:');
      _actividadesMap.forEach((id, nombre) {
        print('    • ID: $id -> Nombre: $nombre');
      });
    } catch (e, stackTrace) {
      print('❌ Error al cargar actividades: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Método para cargar los campos desde la base de datos
  Future<void> _cargarCampos() async {
    try {
      print('🔄 Iniciando carga de campos...');
      var campos = await obtenerCamposDesdeBD();
      if (!mounted) return;

      print('📦 Procesando ${campos.length} campos...');
      setState(() {
        _camposMap.clear(); // Limpiar el mapa existente
        for (var campo in campos) {
          final id = (campo['id'] ?? 0).toString();
          final nombre = campo['nombre']?.toString() ?? 'Sin nombre';
          final clave = campo['clave']?.toString() ?? '';
          
          // Si no hay clave, usar solo el nombre, si hay clave usar formato "clave - nombre"
          if (clave.isEmpty) {
            _camposMap[id] = nombre;
          } else {
            _camposMap[id] = '${clave} - ${nombre}';
          }
          print('  Mapeando - ID: $id -> Clave: $clave -> Nombre: $nombre -> Resultado: ${_camposMap[id]}');
        }
      });
      
      print('✅ Campos cargados exitosamente:');
      print('  Total en mapa: ${_camposMap.length}');
      print('  Contenido del mapa:');
      _camposMap.forEach((id, nombre) {
        print('    • ID: $id -> Nombre: $nombre');
      });
    } catch (e, stackTrace) {
      print('❌ Error al cargar campos: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Método para obtener el nombre de la actividad
  String _obtenerNombreActividad(String? id) {
    if (id == null || id.isEmpty) return '';
    final nombre = _actividadesMap[id] ?? '';
    print('🔍 Buscando actividad - ID: $id -> Nombre: $nombre');
    print('  Actividades disponibles: ${_actividadesMap.keys.join(', ')}');
    return nombre;
  }
  
  @override
  void initState() {
    super.initState();
    print('🏁 DEBUG - initState llamado: isExpanded=${widget.isExpanded}, empleados=${widget.empleados.length}');
    
    // Inicializar FocusNodes para navegación
    _inicializarFocusNodes();

    // Cargar actividades y campos
    _cargarActividades();
    _cargarCampos();
    
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
      // Campos de días (ID, Salario y Campo en modo expandido)
      for (int diaIndex = 0; diaIndex < diasCount; diaIndex++) {
        _focusNodes['${empleadoIndex}_dia_${diaIndex}_id'] = FocusNode();
        _focusNodes['${empleadoIndex}_dia_${diaIndex}_s'] = FocusNode();
        // 🆕 Nuevo campo "campo" para cada día
        _focusNodes['${empleadoIndex}_dia_${diaIndex}_campo'] = FocusNode(); // 🚧 TODO: Conectar a base de datos
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
    
    // Mapear columnas a campos (ahora 3 campos por día: actividad, sueldo, campo/rancho)
    if (columna < diasCount * 3) {
      // Campos de días
      final diaIndex = columna ~/ 3;
      final tipoCampo = columna % 3;
      
      if (diaIndex < diasCount) {
        switch (tipoCampo) {
          case 0:
            return '${fila}_dia_${diaIndex}_id'; // actividad
          case 1:
            return '${fila}_dia_${diaIndex}_s'; // sueldo
          case 2:
            return '${fila}_dia_${diaIndex}_campo'; // campo/rancho
        }
      }
    } else {
      // Campos adicionales (debe, comedor)
      final campoIndex = columna - (diasCount * 3);
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
      if (campoActual.endsWith('_id')) {
        columnaActual = (diaIndex * 3); // actividad
      } else if (campoActual.endsWith('_s')) {
        columnaActual = (diaIndex * 3) + 1; // sueldo
      } else if (campoActual.endsWith('_campo')) {
        columnaActual = (diaIndex * 3) + 2; // campo/rancho
      }
    } else if (campoActual.endsWith('_debe')) {
      columnaActual = (_numeroDias * 3);
    } else if (campoActual.endsWith('_comedor')) {
      columnaActual = (_numeroDias * 3) + 1;
    }
    
    final totalColumnas = (_numeroDias * 3) + 2; // Días * 3 + debe + comedor
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
        // Enter: comportamiento tipo Excel - navegar entre los 3 campos del día
        // Orden: actividad -> sueldo -> campo/rancho -> actividad del siguiente día
        if (campoActual.contains('_dia_')) {
          final diaIndex = int.tryParse(partes[2]) ?? 0;
          
          if (campoActual.endsWith('_id')) {
            // Estoy en actividad, ir a sueldo de la misma fila en el mismo día
            final nuevaColumna = (diaIndex * 3) + 1; // Columna de sueldo
            _navegarA(filaActual, nuevaColumna);
          } else if (campoActual.endsWith('_s')) {
            // Estoy en sueldo, ir a campo/rancho de la misma fila en el mismo día
            final nuevaColumna = (diaIndex * 3) + 2; // Columna de campo/rancho
            _navegarA(filaActual, nuevaColumna);
          } else if (campoActual.endsWith('_campo')) {
            // Estoy en campo/rancho, ir a actividad de la siguiente fila en el mismo día
            if (filaActual < totalFilas - 1) {
              final nuevaColumna = (diaIndex * 3); // Columna de actividad
              _navegarA(filaActual + 1, nuevaColumna);
            } else {
              // Si estamos en la última fila, ir a la primera fila
              final nuevaColumna = (diaIndex * 3); // Columna de actividad
              _navegarA(0, nuevaColumna);
            }
          }
        } else {
          // Para otros campos (debe, comedor), comportamiento normal
          if (filaActual < totalFilas - 1) {
            _navegarA(filaActual + 1, columnaActual);
          } else {
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
    } else if (campo.contains('dia_') && campo.endsWith('_id')) {
      // Para campos de ID de actividad
      empleado[campo] = valor.isEmpty ? null : valor;
      final nombre = _obtenerNombreActividad(valor);
      print('  Campo actividad actualizado:');
      print('    ID: $valor');
      print('    Nombre encontrado: $nombre');
    } else if (campo.contains('dia_') && campo.endsWith('_campo')) {
      // Para el campo "campo", guardar como string
      empleado[campo] = valor.isEmpty ? null : valor; // Guardamos null si está vacío
      final nombreCampo = _camposMap[valor] ?? '';
      print('  Campo rancho actualizado:');
      print('    ID: $valor');
      print('    Nombre encontrado: $nombreCampo');
      print('    Mapa de campos disponible: ${_camposMap.keys.join(', ')}');
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

  /// Duplica los datos del día anterior en el día especificado
  void _duplicarDiaAnterior(int diaActual) {
    if (!widget.isExpanded || widget.readOnly || diaActual <= 0) {
      print('⚠️ No se puede duplicar: modo no expandido, solo lectura o primer día');
      return;
    }
    
    final diaAnterior = diaActual - 1;
    int empleadosActualizados = 0;
    
    print('🔄 Duplicando datos del día $diaAnterior al día $diaActual');
    
    for (int empleadoIndex = 0; empleadoIndex < widget.empleados.length; empleadoIndex++) {
      final empleado = widget.empleados[empleadoIndex];
      final nombre = empleado['nombre'] ?? 'Sin nombre';
      
      // Obtener valores del día anterior y asegurar que sean del tipo correcto
      final actividadAnterior = empleado['dia_${diaAnterior}_id']?.toString() ?? '';
      final sueldoAnterior = _convertirAEntero(empleado['dia_${diaAnterior}_s']);
      final campoAnterior = empleado['dia_${diaAnterior}_campo']?.toString() ?? '';
      
      print('  🔍 Valores originales del día $diaAnterior:');
      print('    - actividad: ${empleado['dia_${diaAnterior}_id']} (${empleado['dia_${diaAnterior}_id']?.runtimeType})');
      print('    - sueldo: ${empleado['dia_${diaAnterior}_s']} (${empleado['dia_${diaAnterior}_s']?.runtimeType})');
      print('    - campo: ${empleado['dia_${diaAnterior}_campo']} (${empleado['dia_${diaAnterior}_campo']?.runtimeType})');
      
      // Solo duplicar si hay datos en el día anterior
      bool hayDatosAnterior = actividadAnterior.isNotEmpty ||
                             sueldoAnterior > 0 ||
                             campoAnterior.isNotEmpty;
      
      if (hayDatosAnterior) {
        print('  📋 Duplicando datos de $nombre:');
        print('    actividad: $actividadAnterior -> dia_${diaActual}_id');
        print('    sueldo: $sueldoAnterior -> dia_${diaActual}_s');
        print('    campo: $campoAnterior -> dia_${diaActual}_campo');
        
        // Usar _manejarCambio para asegurar el tipo correcto de datos
        _manejarCambio(empleadoIndex, 'dia_${diaActual}_id', actividadAnterior);
        _manejarCambio(empleadoIndex, 'dia_${diaActual}_s', sueldoAnterior.toString());
        _manejarCambio(empleadoIndex, 'dia_${diaActual}_campo', campoAnterior);
        
        print('  ✅ Valores copiados al día $diaActual:');
        print('    - actividad: ${empleado['dia_${diaActual}_id']} (${empleado['dia_${diaActual}_id']?.runtimeType})');
        print('    - sueldo: ${empleado['dia_${diaActual}_s']} (${empleado['dia_${diaActual}_s']?.runtimeType})');
        print('    - campo: ${empleado['dia_${diaActual}_campo']} (${empleado['dia_${diaActual}_campo']?.runtimeType})');
        
        // Recalcular totales
        final totales = _calcularTotalesEmpleado(empleado);
        empleado['total'] = totales['total'];
        empleado['subtotal'] = totales['subtotal'];
        empleado['totalNeto'] = totales['totalNeto'];
        
        // Notificar totales actualizados
        widget.onChanged?.call(empleadoIndex, 'total', totales['total']);
        widget.onChanged?.call(empleadoIndex, 'subtotal', totales['subtotal']);
        widget.onChanged?.call(empleadoIndex, 'totalNeto', totales['totalNeto']);
        
        empleadosActualizados++;
      } else {
        print('  ⏭️ Saltando $nombre: no hay datos en día anterior');
      }
    }
    
    // Actualizar UI
    if (mounted && !_isDisposed) {
      setState(() {});
    }
    
    print('✅ Duplicación completada: $empleadosActualizados empleados actualizados');
    
    // Mostrar mensaje de confirmación (opcional)
    if (empleadosActualizados > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Datos duplicados: $empleadosActualizados empleados actualizados'),
          backgroundColor: Colors.green.shade600,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ℹ️ No se encontraron datos para duplicar en el día anterior'),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Obtiene el número de días a mostrar
  int get _numeroDias {
    return (widget.semanaSeleccionada?.duration.inDays ?? 6) + 1;
  }

  /// Verifica si hay datos en una columna específica
  bool _hayDatosEnDia(int dia) {
    if (dia < 0 || widget.empleados.isEmpty) return false;
    
    for (final empleado in widget.empleados) {
      final actividadDia = empleado['dia_${dia}_id']?.toString() ?? '';
      final sueldoDia = _convertirAEntero(empleado['dia_${dia}_s']);
      final campoDia = empleado['dia_${dia}_campo']?.toString() ?? '';
      
      if (actividadDia.isNotEmpty || sueldoDia > 0 || campoDia.isNotEmpty) {
        return true;
      }
    }
    
    return false;
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
        String nombreDia;
        String fechaCorta;
        
        if (widget.semanaSeleccionada != null) {
          final fecha = widget.semanaSeleccionada!.start.add(Duration(days: i));
          nombreDia = DateFormat('EEE', 'es').format(fecha).toLowerCase();
          fechaCorta = DateFormat('d/M', 'es').format(fecha);
        } else {
          final dias = ['jue', 'vie', 'sab', 'dom', 'lun', 'mar', 'mie'];
          final diasNumeros = ['3/7', '4/7', '5/7', '6/7', '7/7', '8/7', '2/7'];
          nombreDia = dias[i];
          fechaCorta = diasNumeros[i];
        }
        
        // Verificar si hay datos en el día anterior para activar el botón
        final bool hayDatosAnterior = i > 0 ? _hayDatosEnDia(i - 1) : false;
        
        return DataColumn(
          label: Container(
            width: anchoExpandido ? 240 : 80,
            padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 6 : 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: anchoExpandido ? 8 : 6, 
                    vertical: anchoExpandido ? 4 : 2
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF7BAE2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(anchoExpandido ? 8 : 6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombreDia,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: anchoExpandido ? 14 : 11,
                          color: Color(0xFF4A7C14),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (i > 0) // Mostrar el botón siempre que no sea el primer día
                        Container(
                          margin: EdgeInsets.only(left: 6),
                          child: IconButton(
                            icon: Icon(
                              Icons.content_copy,
                              size: anchoExpandido ? 14 : 12,
                              color: _hayDatosEnDia(i - 1)
                                  ? Color(0xFF4A7C14)
                                  : Colors.grey.shade300,
                            ),
                            onPressed: _hayDatosEnDia(i - 1)
                                ? () => _duplicarDiaAnterior(i)
                                : null,
                            tooltip: _hayDatosEnDia(i - 1)
                                ? 'Duplicar datos del día anterior'
                                : 'No hay datos para duplicar en el día anterior',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: anchoExpandido ? 20 : 16,
                              minHeight: anchoExpandido ? 20 : 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: anchoExpandido ? 4 : 2),
                Text(
                  fechaCorta,
                  style: TextStyle(
                    fontSize: anchoExpandido ? 12 : 9,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
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
    
    if (!widget.isExpanded) {
      // Modo normal: solo Salario
      return _construirCeldaEditable(
        empleadoIndex, 
        'dia_${diaIndex}_s', 
        empleado['dia_${diaIndex}_s'],
        ancho: 80,
      );
    }

    // Usar 'dia_X_id' para el ID de actividad y obtener solo el nombre
    final actividadId = empleado['dia_${diaIndex}_id']?.toString();
    final nombreActividad = _actividadesMap[actividadId] ?? '';
    String actividadNombre;
    
    if (actividadId == null || actividadId.isEmpty || actividadId == '0') {
      actividadNombre = 'actividad';
    } else if (nombreActividad.isEmpty) {
      // Si el ID no se encuentra en el mapa, mostrar "no existe"
      actividadNombre = 'no existe';
    } else {
      // Extraer solo el nombre sin la clave
      final partes = nombreActividad.split(' - ');
      actividadNombre = partes.length > 1 ? partes[1] : nombreActividad;
    }
    
    // Usar 'dia_X_campo' para el ID de campo y obtener solo el nombre
    final campoId = empleado['dia_${diaIndex}_campo']?.toString() ?? '0';
    final nombreCampo = _camposMap[campoId] ?? '';
    String campoNombre;
    
    if (campoId == '0' || campoId.isEmpty) {
      campoNombre = 'Rancho';
    } else if (nombreCampo.isEmpty) {
      // Si el ID no se encuentra en el mapa, mostrar "no existe"
      campoNombre = 'no existe';
    } else {
      // Extraer solo el nombre sin la clave
      final partes = nombreCampo.split(' - ');
      campoNombre = partes.length > 1 ? partes[1] : nombreCampo;
    }
    
    print('📅 Día $diaIndex - Empleado $empleadoIndex:');
    print('  ID Actividad: $actividadId -> Nombre: $actividadNombre');
    print('  ID Campo: $campoId -> Nombre: $campoNombre');
    print('  Mapas cargados - Actividades: ${_actividadesMap.length}, Campos: ${_camposMap.length}');

    // Modo expandido: ID, Salario y campo adicional con labels
    return DataCell(
      SizedBox(
        width: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fila de labels de campos
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200, width: 0.5),
                    ),
                    child: Text(
                      actividadNombre,
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
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200, width: 0.5),
                    ),
                    child: Text(
                      campoNombre,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Fila de campos editables
            Row(
              children: [
                Expanded(
                  child: _construirWidgetEditable(
                    empleadoIndex, 
                    'dia_${diaIndex}_id', 
                    empleado['dia_${diaIndex}_id'],
                    esPequena: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _construirWidgetEditable(
                    empleadoIndex, 
                    'dia_${diaIndex}_s', 
                    empleado['dia_${diaIndex}_s'],
                    esPequena: true,
                    mostrarMoneda: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _construirWidgetEditable(
                    empleadoIndex, 
                    'dia_${diaIndex}_campo',
                    empleado['dia_${diaIndex}_campo'] ?? '',
                    esPequena: true,
                    mostrarMoneda: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    
    // Determinar si es un campo de texto (campo) vs numérico
    final esCampoTexto = campo.contains('_campo');
    
    if (!esEditable) {
      return Container(
        height: widget.isExpanded ? 55 : 40, // 🔧 Aumentado de 50 a 55 para mejor acomodación
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
          esCampoTexto 
            ? (valor?.toString() ?? '') 
            : (mostrarMoneda ? _formatearMoneda(valor) : (_convertirAEntero(valor).toString())),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.isExpanded ? 14 : 12,
            fontWeight: widget.isExpanded ? FontWeight.w500 : FontWeight.w600,
            color: widget.isExpanded ? Colors.grey.shade700 : Colors.grey.shade800,
          ),
        ),
      );
    }

    // Preparar valor para mostrar según el tipo de campo
    final valorMostrar = esCampoTexto 
      ? (valor?.toString() == '0' ? '' : valor?.toString() ?? '') 
      : _convertirAEntero(valor).toString();
    
    // Crear clave única para el FocusNode
    final claveFocus = '${empleadoIndex}_${campo}';
    final focusNode = _focusNodes[claveFocus];

    return _CeldaEditableConNavegacion(
      valorInicial: valorMostrar,
      alCambiar: (nuevoValor) => _manejarCambio(empleadoIndex, campo, nuevoValor),
      esExpandida: widget.isExpanded,
      esPequena: esPequena,
      mostrarMoneda: mostrarMoneda,
      esCampoTexto: esCampoTexto, // 🆕 Pasar el tipo de campo
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

    // Determinar si es un campo de texto
    final esCampoTexto = campo.contains('_campo');

    // Convertir el valor según el tipo de campo
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
      esCampoTexto: esCampoTexto,  // Agregamos este parámetro
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
              dataRowHeight: widget.isExpanded ? 100 : 58, // 🔧 Aumentado de 85 a 100 para mejor acomodación de 3 campos
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
  final bool esCampoTexto; // 🆕 Nuevo parámetro para diferenciar texto vs números
  final FocusNode? focusNode;
  final Function(KeyEvent)? onNavegacion;

  const _CeldaEditableConNavegacion({
    required this.valorInicial,
    required this.alCambiar,
    this.esExpandida = false,
    this.esPequena = false,
    this.mostrarMoneda = false,
    this.esCampoTexto = false, // Por defecto es numérico
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
      if (!widget.esCampoTexto) {
        // Solo para campos numéricos: limpiar cuando focus y valor es '0'
        if (_focusNode.hasFocus && _controller.text == '0') {
          _controller.clear();
        } 
        // Solo para campos numéricos: poner '0' si está vacío al perder focus
        else if (!_focusNode.hasFocus && _controller.text.isEmpty) {
          _controller.text = '0';
          widget.alCambiar('0');
        }
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
      height: widget.esExpandida ? 55 : 42, // 🔧 Aumentado de 52 a 55 para mejor acomodación
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
          color: Colors.grey.shade700,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.esExpandida ? 12 : 8,
            vertical: widget.esExpandida ? 14 : 10,
          ),
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: widget.esPequena ? 13 : (widget.esExpandida ? 16 : 13),
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
          
          if (widget.esCampoTexto) {
            // Para campos de texto: pasar el valor tal como está
            widget.alCambiar(valor);
          } else {
            // Para campos numéricos: limpiar y validar
            final limpio = valor.replaceAll(RegExp(r'[^\d]'), '');
            widget.alCambiar(limpio.isEmpty ? '0' : limpio);
          }
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
