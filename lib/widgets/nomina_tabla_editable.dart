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
  final Map<String, Function>? funcionesConversionActividad; // 🔑 Funciones de conversión de actividad
  // Permite activar comportamiento de columnas fijas + header sticky también en modo compacto (previsualización)
  final bool enableStickyPreview;
  // 🆕 Flag para activar verificación interna de consistencia tras cada cambio
  final bool debugVerificacion;

  const NominaTablaEditable({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onChanged,
    this.isExpanded = false,
    this.readOnly = false,
    this.funcionesConversionActividad, // 🔑 Funciones de conversión de actividad
    this.enableStickyPreview = false,
    this.debugVerificacion = false,
  }) : super(key: key);

  @override
  State<NominaTablaEditable> createState() => _NominaTablaEditableState();

  /// Método estático para validar una tabla desde un GlobalKey genérico
  static Map<String, dynamic>? validarTablaDesdeKey(GlobalKey? key) {
    if (key?.currentState != null && key!.currentState is _NominaTablaEditableState) {
      return (key.currentState as _NominaTablaEditableState).validarTabla();
    }
    return null;
  }
}

class _NominaTablaEditableState extends State<NominaTablaEditable> {
  // ====== Constantes de anchos para asegurar alineación encabezado/filas (vista expandida) ======
  static const double kAnchoClaveExpanded = 100; // antes 80 header / 100 fila -> desalineado
  static const double kAnchoClaveCompact = 85;   // antes 70 header / 85 fila
  static const double kAnchoEmpleadoExpanded = 250; // antes 200 header / 250 fila
  static const double kAnchoEmpleadoCompact = 200;  // antes 170 header / 200 fila
  static const double kAnchoDiaExpanded = 300; // aumentado para más espacio (actividad + sueldo + campo)
  static const double kAnchoDiaCompact = 80;
  static const double kAnchoTotalExpanded = 120; // antes header 100, fila 120
  static const double kAnchoTotalCompact = 100;  // header 85, fila 100
  static const double kAnchoOtrasPercepcionesExpanded = 120; // header 120, fila 120
  static const double kAnchoOtrasPercepcionesCompact = 100;  // header 100, fila 100
  static const double kAnchoSubtotalExpanded = 120; // header 100, fila 120
  static const double kAnchoSubtotalCompact = 100;  // header 85, fila 100
  static const double kAnchoComedorExpanded = 85;   // coincide
  static const double kAnchoComedorCompact = 70;    // coincide
  static const double kAnchoTotalNetoExpanded = 120; // header 100, fila 120
  static const double kAnchoTotalNetoCompact = 100;  // header 85, fila 100
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

  // Controladores para implementar columnas fijas (clave y nombre) en modo expandido
  // Scroll vertical sincronizado entre tabla fija (izquierda) y tabla desplazable (derecha)
  final ScrollController _verticalScrollLeft = ScrollController();
  final ScrollController _verticalScrollRight = ScrollController();
  bool _syncingVertical = false; // Evita bucles recursivos de sincronización

  // Controladores horizontales para sincronizar encabezado y cuerpo (sección derecha)
  final ScrollController _horizontalScrollHeader = ScrollController();
  final ScrollController _horizontalScrollBody = ScrollController();
  bool _syncingHorizontal = false;

  // Mapas para almacenar las actividades
  Map<String, String> _actividadesMap = {}; // ID -> nombre
  Map<String, String> _claveAIdMap = {}; // clave -> ID  
  Map<String, String> _idAClaveMap = {}; // ID -> clave
  Map<String, String> _idANombreMap = {}; // ID -> nombre directo
  Map<String, String> _claveANombreMap = {}; // clave -> nombre
  bool _actividadesCargadas = false; // bandera para saber si ya tenemos mapas listos

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
        // Limpiar todos los mapas
        _actividadesMap.clear();
  _claveAIdMap.clear();
  _idAClaveMap.clear();
  _claveANombreMap.clear();
  _idANombreMap.clear();
        
        for (var actividad in actividades) {
          final id = (actividad['id'] ?? actividad['id_actividad'] ?? actividad['ID'] ?? actividad['idActividad'] ?? 0).toString();
          final nombre = actividad['nombre']?.toString() ?? 'Sin nombre';
          final clave = actividad['clave']?.toString() ?? '';

          // Registrar siempre por ID
          _actividadesMap[id] = '${clave} - ${nombre}';
          _idANombreMap[id] = nombre;

          // Si hay clave, registrar también usando la clave como llave para permitir entrada por clave
          if (clave.isNotEmpty) {
            _actividadesMap.putIfAbsent(clave, () => '${clave} - ${nombre}');
            _idANombreMap.putIfAbsent(clave, () => nombre);
            _claveAIdMap[clave] = id; // clave -> id
            _idAClaveMap[id] = clave; // id -> clave
            _claveANombreMap[clave] = nombre; // clave -> nombre
          }

          print('  Mapeando actividad -> ID: $id | Clave: $clave | Nombre: $nombre');
        }
      });
      // 🔁 Tras cargar actividades, volver a normalizar claves en empleados (por si se ejecutó initState antes de tener mapas)
      _normalizarClavesEmpleados();
  _actividadesCargadas = true;
      
      print('✅ Actividades cargadas exitosamente:');
      print('  Total actividades: ${_actividadesMap.length}');
      print('  Mapeo clave->nombre: ${_claveANombreMap.length} entradas');
      print('  Contenido del mapa clave->nombre:');
      _claveANombreMap.forEach((clave, nombre) {
        print('    • Clave: "$clave" -> Nombre: "$nombre"');
      });
      print('  ═══════════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      print('❌ Error al cargar actividades: $e');
      print('Stack trace: $stackTrace');
      _actividadesCargadas = false;
    }
  }

  /// Normaliza los valores de dia_X_id: si están como ID los convierte a clave usando los mapas ya cargados
  void _normalizarClavesEmpleados() {
    if (_idAClaveMap.isEmpty) return; // Nada que hacer si no hay mapas
    int convertidos = 0;
    for (final emp in widget.empleados) {
      for (int i = 0; i <= 6; i++) {
        final key = 'dia_${i}_id';
        final raw = emp[key];
        if (raw == null) continue;
        final s = raw.toString();
        if (s.isEmpty || s == '0') continue;
        
        // Si es un ID interno y no es una clave válida, convertir a clave
        if (!_claveANombreMap.containsKey(s) && _idAClaveMap.containsKey(s)) {
          final nuevaClave = _idAClaveMap[s];
          if (nuevaClave != null && nuevaClave.isNotEmpty) {
            emp[key] = nuevaClave; // Reemplazar ID por clave
            convertidos++;
          }
        }
      }
    }
    if (convertidos > 0) {
      print('🔁 Normalización posterior: convertidos $convertidos IDs a claves.');
      if (mounted && !_isDisposed) setState(() {});
    }
  }



  // 🔑 Funciones auxiliares que usan las funciones del widget padre
  // (Funciones removidas por no estar en uso)
  


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

  // (Eliminado _obtenerNombreActividad: ya no se usa en el modelo basado en IDs directos)
  
  @override
  void initState() {
    super.initState();
    print('🏁 DEBUG - initState llamado: isExpanded=${widget.isExpanded}, empleados=${widget.empleados.length}');

    // Normalizar: asegurar que dia_X_id contenga siempre CLAVES (no IDs internos)
    for (final emp in widget.empleados) {
      for (int i = 0; i <= 6; i++) {
        final k = 'dia_${i}_id';
        if (!emp.containsKey(k)) continue;
        final raw = emp[k];
        if (raw == null) continue;
        final s = raw.toString();
        if (s.isEmpty || s == '0') continue;
        
        // Si es un ID interno (y tenemos el mapeo), convertir a clave
        if (_idAClaveMap.containsKey(s)) {
          final clave = _idAClaveMap[s];
          if (clave != null && clave.isNotEmpty) {
            emp[k] = clave;
          }
        }
        // Si ya es una clave válida, mantener como está
        // Si no es ni ID ni clave válida, se mantendrá el valor original
      }
    }

    // Listeners para sincronizar scroll vertical entre tablas (solo se usarán en modo expandido)
    _verticalScrollLeft.addListener(() {
      if (_syncingVertical) return;
      _syncingVertical = true;
      if (_verticalScrollRight.hasClients) {
        _verticalScrollRight.jumpTo(_verticalScrollLeft.position.pixels);
      }
      _syncingVertical = false;
    });
    _verticalScrollRight.addListener(() {
      if (_syncingVertical) return;
      _syncingVertical = true;
      if (_verticalScrollLeft.hasClients) {
        _verticalScrollLeft.jumpTo(_verticalScrollRight.position.pixels);
      }
      _syncingVertical = false;
    });

    // Listeners horizontal para encabezado fijo (solo se usan si isExpanded)
    _horizontalScrollHeader.addListener(() {
      if (_syncingHorizontal) return;
      _syncingHorizontal = true;
      if (_horizontalScrollBody.hasClients) {
        _horizontalScrollBody.jumpTo(_horizontalScrollHeader.position.pixels);
      }
      _syncingHorizontal = false;
    });
    _horizontalScrollBody.addListener(() {
      if (_syncingHorizontal) return;
      _syncingHorizontal = true;
      if (_horizontalScrollHeader.hasClients) {
        _horizontalScrollHeader.jumpTo(_horizontalScrollBody.position.pixels);
      }
      _syncingHorizontal = false;
    });
    
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

    // Dispose de controladores de scroll
    _verticalScrollLeft.dispose();
    _verticalScrollRight.dispose();
  _horizontalScrollHeader.dispose();
  _horizontalScrollBody.dispose();
    
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
  Map<String, double> _calcularTotalesEmpleado(Map<String, dynamic> empleado) {
    // ✅ Normalizamos a una semana estándar de 7 días (0..6)
    const int diasCount = 7;
    double total = 0.0;
    
    print('🔍 DEBUG - Calculando totales para: ${empleado['nombre']} (isExpanded: ${widget.isExpanded})');
    
    // ESTRATEGIA 1: Sumar días trabajados (dia_0_s, dia_1_s, etc.)
    List<String> diasEncontrados = [];
    for (int i = 0; i < diasCount; i++) {
      final key = 'dia_${i}_s';
      if (empleado.containsKey(key) && empleado[key] != null) {
        final valorOriginal = empleado[key];
        final valor = _convertirADouble(valorOriginal);
        if (valor > 0) {
          diasEncontrados.add('$key=${valor.toStringAsFixed(2)}');
          total += valor;
        }
        print('  $key: $valorOriginal (${valorOriginal.runtimeType}) -> ${valor.toStringAsFixed(2)}');
      }
    }
    
    print('  Días encontrados (${diasEncontrados.length}): ${diasEncontrados.join(', ')}');
    print('  Total de días: $total');
    
    // ESTRATEGIA 2 (ajustada): Solo buscar formato alternativo si NO hay ningún día capturado (>0)
    if (total == 0.0 && diasEncontrados.isEmpty) {
      print('  🔄 Buscando formatos alternativos...');
      final formatosAlternativos = [
        'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo',
        'day_0', 'day_1', 'day_2', 'day_3', 'day_4', 'day_5', 'day_6',
      ];
      
      double totalAlternativo = 0.0;
      List<String> alternativosEncontrados = [];
      
      for (String formato in formatosAlternativos) {
        if (empleado.containsKey(formato) && empleado[formato] != null) {
          final valorOriginal = empleado[formato];
            final valor = _convertirADouble(valorOriginal);
          if (valor > 0) {
            alternativosEncontrados.add('$formato=${valor.toStringAsFixed(2)}');
            totalAlternativo += valor;
          }
          print('  $formato (alternativo): $valorOriginal -> ${valor.toStringAsFixed(2)}');
        }
      }
      
      if (totalAlternativo > total) {
        total = totalAlternativo;
        print('  ✅ Usando total alternativo: $total (formatos: ${alternativosEncontrados.join(', ')})');
      }
    }
    
    // ESTRATEGIA 3: ÚLTIMO RECURSO - Si aún no hay datos de días, usar total existente de BD
    if (total == 0.0 && empleado.containsKey('total') && empleado['total'] != null) {
      final totalOriginal = empleado['total'];
      final totalBD = _convertirADouble(totalOriginal);
      if (totalBD > 0) {
        total = totalBD;
        print('  ⚠️ Usando total desde BD (último recurso): $totalOriginal (${totalOriginal.runtimeType}) -> ${total.toStringAsFixed(2)}');
      }
    }
    
    final debeOriginal = empleado['debe'];
    final comedorOriginal = empleado['comedor'];
    final debe = _convertirADouble(debeOriginal);
    final comedor = _convertirADouble(comedorOriginal);
    
    print('  debe: $debeOriginal (${debeOriginal.runtimeType}) -> ${debe.toStringAsFixed(2)}');
    print('  comedor: $comedorOriginal (${comedorOriginal.runtimeType}) -> ${comedor.toStringAsFixed(2)}');
    
    // Ajuste: 'debe' (otras percepciones) se suma al subtotal
  final subtotal = total + debe; // ✅ Nueva regla estable
    final totalNeto = subtotal - comedor; // comedor resta
    
    print('  🎯 RESULTADO FINAL: total=${total.toStringAsFixed(2)}, subtotal=${subtotal.toStringAsFixed(2)}, totalNeto=${totalNeto.toStringAsFixed(2)}');
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

  /// Convierte cualquier valor a double de forma segura (para campos con decimales)
  double _convertirADouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is bool) return valor ? 400.0 : 0.0; // Para comedor
    if (valor is String) {
      // Intentar parsearlo como double directamente
      final doubleValue = double.tryParse(valor);
      if (doubleValue != null) {
        return doubleValue;
      }
      // Heurística eliminada (antes: dividir cadenas de 4 dígitos entre 10).
      // Ahora: si el usuario ingresa "4005" debe conservarse como 4005.00.
      // Cualquier ajuste de escala sólo se aplica a 5+ dígitos en _autoCorregirEscala.
      // Si no es un decimal válido, intentar como entero
      final intValue = int.tryParse(valor);
      if (intValue != null) {
        return intValue.toDouble();
      }
      return 0.0;
    }
    return 0.0;
  }

  /// Parsea una entrada de usuario (que puede contener símbolos, comas, espacios) a double con 2 decimales
  double _parsearMoneda(String valor) {
    if (valor.isEmpty) return 0.0;
    // Reemplazar coma decimal por punto y eliminar símbolos no numéricos excepto punto y signo
    final normalizado = valor
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9\.-]'), '');
    final parsed = double.tryParse(normalizado) ?? 0.0;
    // Redondear a 2 decimales
    return double.parse(parsed.toStringAsFixed(2));
  }

  /// Corrige valores que probablemente perdieron el punto (escala x100) p.ej. 40050 -> 400.50
  double _autoCorregirEscala(double valor, String rawOriginal) {
    // Si ya trae punto, no se modifica
    if (rawOriginal.contains('.')) return valor;
    // Nuevo criterio: SOLO ajustar si hay 9+ dígitos (ej. 400000050) indicando claramente escala centavos.
    // Motivo: evitar que montos legítimos como 40050 (40,050.00) se reduzcan a 400.50.
    final soloDigitos = RegExp(r'^\d{9,}$'); // 9 o más dígitos
    if (soloDigitos.hasMatch(rawOriginal)) {
      // Evitar casos fuera de rango absurdo antes de dividir
      if (valor < 1000000000) { // Tope más amplio pero razonable
        final dividido = valor / 100.0; // Interpretar últimos dos como centavos perdidos
        // Aún así validar que el resultado no sea irrealmente grande para un día
        if (dividido < 1000000) {
          return double.parse(dividido.toStringAsFixed(2));
        }
      }
    }
    return valor; // No ajuste para <9 dígitos
  }

  /// Maneja cambios en los campos editables
  void _manejarCambio(int index, String campo, String valor) {
    if (widget.readOnly || index >= widget.empleados.length) return;
    
    final empleado = widget.empleados[index];
    
    print('🔄 DEBUG - Cambio detectado: ${empleado['nombre']}, campo: $campo, valor: $valor');
    
    // Actualizar el valor en el empleado
    if (campo == 'comedor') {
        double v = _parsearMoneda(valor); // Parsear el valor de entrada
        v = _autoCorregirEscala(v, valor); // Corregir escala si es necesario
        empleado[campo] = v; // Actualizar el campo 'comedor'
        print('  Comedor actualizado -> ${v.toStringAsFixed(2)}'); // Mostrar el nuevo valor
    } else if (campo.contains('dia_') && campo.endsWith('_s')) {
      // Día sueldo ahora double
      double v = _parsearMoneda(valor);
      v = _autoCorregirEscala(v, valor);
      empleado[campo] = v;
      print('  Campo $campo actualizado -> ${v.toStringAsFixed(2)}');
    } else if (campo.contains('dia_') && campo.endsWith('_id')) {
      // Ahora se almacena la CLAVE directamente (no el ID interno)
      final soloDigitos = valor.replaceAll(RegExp(r'[^0-9]'), '');
      final clave = soloDigitos.isEmpty ? '0' : soloDigitos;
      empleado[campo] = clave;
      
      // Obtener nombre usando la clave
      String nombre = '';
      if (clave != '0' && _claveANombreMap.containsKey(clave)) {
        nombre = _claveANombreMap[clave]!;
      } else if (clave != '0' && _actividadesCargadas) {
        nombre = 'no existe';
      }
      
      print('  Campo actividad actualizado:');
      print('    Clave almacenada: $clave');
      print('    Nombre: "$nombre"');
      if (clave != '0' && nombre.isEmpty && _actividadesCargadas) {
        print('    ⚠️ Clave no encontrada. Claves disponibles: ${_claveANombreMap.keys.take(10).join(', ')}');
      }
    } else if (campo.contains('dia_') && campo.endsWith('_campo')) {
      // Campo (rancho) como entero
      final soloDigitos = valor.replaceAll(RegExp(r'[^0-9]'), '');
      final campoInt = int.tryParse(soloDigitos.isEmpty ? '0' : soloDigitos) ?? 0;
      empleado[campo] = campoInt;
      final nombreCampo = _camposMap[campoInt.toString()] ?? '';
      print('  Campo rancho actualizado:');
      print('    ID(int): $campoInt');
      print('    Nombre encontrado: $nombreCampo');
    } else if (campo == 'debe') {
      double v = _parsearMoneda(valor);
      v = _autoCorregirEscala(v, valor);
      empleado[campo] = v;
      print('  Debe (otras percepciones) actualizado -> ${v.toStringAsFixed(2)}');
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
    // 🆕 Verificación automática si está activada
    if (widget.debugVerificacion) {
      _verificarConsistenciaEmpleado(index);
    }
  }

  /// 🆕 Verifica que los totales del empleado sean consistentes con la suma de días y reglas de negocio
  void _verificarConsistenciaEmpleado(int index) {
    if (index < 0 || index >= widget.empleados.length) return;
    final e = widget.empleados[index];
    final diasCount = widget.semanaSeleccionada?.duration.inDays ?? 6;
    double sumaDias = 0.0;
    for (int i = 0; i <= diasCount; i++) {
      final k = 'dia_${i}_s';
      if (e.containsKey(k)) {
        sumaDias += _convertirADouble(e[k]);
      }
    }
    final debe = _convertirADouble(e['debe']);
    final comedor = _convertirADouble(e['comedor']);
    final esperadoSubtotal = sumaDias + debe;
    final esperadoTotalNeto = esperadoSubtotal - comedor;
    final total = _convertirADouble(e['total']);
    final subtotal = _convertirADouble(e['subtotal']);
    final totalNeto = _convertirADouble(e['totalNeto']);

    final inconsistencias = <String>[];
    if ((total - sumaDias).abs() > 0.009) {
      inconsistencias.add('total(${total.toStringAsFixed(2)}) != sumaDias(${sumaDias.toStringAsFixed(2)})');
    }
    if ((subtotal - esperadoSubtotal).abs() > 0.009) {
      inconsistencias.add('subtotal(${subtotal.toStringAsFixed(2)}) != dias+debe(${esperadoSubtotal.toStringAsFixed(2)})');
    }
    if ((totalNeto - esperadoTotalNeto).abs() > 0.009) {
      inconsistencias.add('totalNeto(${totalNeto.toStringAsFixed(2)}) != subtotal-comedor(${esperadoTotalNeto.toStringAsFixed(2)})');
    }

    if (inconsistencias.isEmpty) {
      print('🧪 VERIFICACIÓN OK -> Empleado: ${e['nombre']}  Días=${sumaDias.toStringAsFixed(2)}  Debe=${debe.toStringAsFixed(2)}  Comedor=${comedor.toStringAsFixed(2)}  Neto=${totalNeto.toStringAsFixed(2)}');
    } else {
      print('⚠️ VERIFICACIÓN FALLÓ -> Empleado: ${e['nombre']}');
      for (final inc in inconsistencias) {
        print('   · $inc');
      }
      print('   Datos: dias=${sumaDias.toStringAsFixed(2)}, debe=${debe.toStringAsFixed(2)}, comedor=${comedor.toStringAsFixed(2)}, total=${total.toStringAsFixed(2)}, subtotal=${subtotal.toStringAsFixed(2)}, neto=${totalNeto.toStringAsFixed(2)}');
    }
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
      final sueldoAnteriorOriginal = empleado['dia_${diaAnterior}_s']; // Mantener valor original para preservar decimales
      final sueldoAnteriorCheck = _convertirADouble(sueldoAnteriorOriginal); // Solo para verificar si > 0
      final campoAnterior = empleado['dia_${diaAnterior}_campo']?.toString() ?? '';
      
      print('  🔍 Valores originales del día $diaAnterior:');
      print('    - actividad (clave): ${empleado['dia_${diaAnterior}_id']} (${empleado['dia_${diaAnterior}_id']?.runtimeType})');
      print('    - sueldo: ${empleado['dia_${diaAnterior}_s']} (${empleado['dia_${diaAnterior}_s']?.runtimeType})');
      print('    - campo: ${empleado['dia_${diaAnterior}_campo']} (${empleado['dia_${diaAnterior}_campo']?.runtimeType})');
      
      // Solo duplicar si hay datos en el día anterior
      bool hayDatosAnterior = (actividadAnterior.isNotEmpty && actividadAnterior != '0') ||
                             sueldoAnteriorCheck > 0 ||
                             (campoAnterior.isNotEmpty && campoAnterior != '0');
      
      if (hayDatosAnterior) {
        print('  📋 Duplicando datos de $nombre:');
        print('    actividad: $actividadAnterior -> dia_${diaActual}_id');
        print('    sueldo: $sueldoAnteriorOriginal -> dia_${diaActual}_s');
        print('    campo: $campoAnterior -> dia_${diaActual}_campo');
        
        // Usar _manejarCambio para asegurar el tipo correcto de datos
        _manejarCambio(empleadoIndex, 'dia_${diaActual}_id', actividadAnterior);
        _manejarCambio(empleadoIndex, 'dia_${diaActual}_s', sueldoAnteriorOriginal?.toString() ?? '0');
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
      final sueldoDia = _convertirADouble(empleado['dia_${dia}_s']);
      final campoDia = empleado['dia_${dia}_campo']?.toString() ?? '';
      
      if (actividadDia.isNotEmpty || sueldoDia > 0 || campoDia.isNotEmpty) {
        return true;
      }
    }
    
    return false;
  }

  /// Valida que todos los campos requeridos estén correctamente asignados
  /// Retorna un mapa con el resultado de la validación
  /// 
  /// REGLAS DE VALIDACIÓN:
  /// 1. Si sueldo > 0 → DEBE tener actividad Y rancho
  /// 2. Si sueldo = 0 → NO validar nada (día no trabajado)
  /// 3. Si tiene actividad → DEBE tener sueldo > 0 Y rancho
  /// 4. Si tiene rancho → DEBE tener sueldo > 0 Y actividad
  /// 5. El sueldo NO es obligatorio por sí solo
  Map<String, dynamic> validarTabla() {
    List<String> errores = [];
    int diasConDatos = 0;
    int diasValidados = 0;
    
    final numeroDias = _numeroDias;
    
    print('🔍 Iniciando validación de tabla de nóminas...');
    print('  Número de días a validar: $numeroDias');
    print('  Número de empleados: ${widget.empleados.length}');
    print('📋 REGLAS DE VALIDACIÓN:');
    print('  1. Si sueldo > 0 → DEBE tener actividad Y rancho');
    print('  2. Si sueldo = 0 → NO validar nada (día no trabajado)');
    print('  3. Si tiene actividad → DEBE tener sueldo > 0 Y rancho');
    print('  4. Si tiene rancho → DEBE tener sueldo > 0 Y actividad');
    print('  5. El sueldo NO es obligatorio por sí solo');
    
    // Iterar por cada día
    for (int dia = 0; dia < numeroDias; dia++) {
      bool hayDatosEnEsteDiv = false;
      List<String> erroresDia = [];
      
      // Revisar cada empleado en este día
      for (int empleadoIndex = 0; empleadoIndex < widget.empleados.length; empleadoIndex++) {
        final empleado = widget.empleados[empleadoIndex];
        final nombreEmpleado = empleado['nombre'] ?? 'Empleado ${empleadoIndex + 1}';
        
        // Obtener valores del día
        final actividadId = empleado['dia_${dia}_id']?.toString() ?? '';
        final sueldo = _convertirADouble(empleado['dia_${dia}_s']);
        final rancho = empleado['dia_${dia}_campo']?.toString() ?? '';
        
        // 🔍 DEBUG: Mostrar valores para depuración
        if (actividadId.isNotEmpty || sueldo != 0.0 || rancho.isNotEmpty) {
          print('🔍 DEBUG - $nombreEmpleado Día ${dia + 1}: sueldo=$sueldo (${sueldo.runtimeType}), actividad="$actividadId", rancho="$rancho"');
        }
        
        // Verificar si hay datos en este día para este empleado
        bool empleadoTieneDatos = actividadId.isNotEmpty || sueldo > 0.0 || rancho.isNotEmpty;
        
        if (empleadoTieneDatos) {
          hayDatosEnEsteDiv = true;
          
          // 📋 REGLA 1: Si sueldo > 0 → DEBE tener actividad Y rancho
          if (sueldo > 0.0) {
            print('🔍 REGLA 1 - $nombreEmpleado Día ${dia + 1}: Sueldo > 0 (\$${sueldo.toInt()}), verificando actividad y rancho...');
            if (actividadId.isEmpty) {
              erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar actividad (sueldo: \$${sueldo.toInt()})');
            }
            if (rancho.isEmpty) {
              erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar rancho (sueldo: \$${sueldo.toInt()})');
            }
          } else {
            // 📋 REGLA 2: Si sueldo = 0 → NO validar actividad ni rancho
            print('✅ REGLA 2 - $nombreEmpleado Día ${dia + 1}: Sueldo es 0 (\$${sueldo.toInt()}), NO se requiere actividad ni rancho');
          }
          
          // 📋 REGLA 3: Si tiene actividad → DEBE tener sueldo > 0 Y rancho
          if (actividadId.isNotEmpty && sueldo <= 0.0) {
            print('🔍 REGLA 3a - $nombreEmpleado Día ${dia + 1}: Tiene actividad pero sueldo es 0');
            erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar sueldo (actividad asignada: $actividadId)');
          }
          if (actividadId.isNotEmpty && rancho.isEmpty) {
            print('🔍 REGLA 3a+ - $nombreEmpleado Día ${dia + 1}: Tiene actividad pero falta rancho');
            erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar rancho (actividad asignada: $actividadId)');
          }
          
          // 📋 REGLA 3: Si tiene rancho → DEBE tener sueldo > 0 Y actividad
          if (rancho.isNotEmpty && sueldo <= 0.0) {
            print('🔍 REGLA 3b - $nombreEmpleado Día ${dia + 1}: Tiene rancho pero sueldo es 0');
            erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar sueldo (rancho asignado: $rancho)');
          }
          if (rancho.isNotEmpty && actividadId.isEmpty) {
            print('🔍 REGLA 3b+ - $nombreEmpleado Día ${dia + 1}: Tiene rancho pero falta actividad');
            erroresDia.add('⚠️ $nombreEmpleado - Día ${dia + 1}: Falta asignar actividad (rancho asignado: $rancho)');
          }
          
          // ℹ️ REGLA 4: El sueldo NO es obligatorio por sí solo
        }
      }
      
      if (hayDatosEnEsteDiv) {
        diasConDatos++;
        if (erroresDia.isEmpty) {
          diasValidados++;
          print('✅ Día ${dia + 1}: Validado correctamente');
        } else {
          print('❌ Día ${dia + 1}: Encontrados ${erroresDia.length} errores');
          errores.addAll(erroresDia);
        }
      } else {
        print('⏭️ Día ${dia + 1}: Sin datos, omitiendo validación');
      }
    }
    
    final esValido = errores.isEmpty;
    
    print('📊 Resumen de validación:');
    print('  Días con datos: $diasConDatos');
    print('  Días validados correctamente: $diasValidados');
    print('  Errores encontrados: ${errores.length}');
    print('  Estado: ${esValido ? "✅ VÁLIDO" : "❌ INVÁLIDO"}');
    
    return {
      'valido': esValido,
      'errores': errores,
      'diasConDatos': diasConDatos,
      'diasValidados': diasValidados,
      'resumen': esValido 
        ? 'Tabla validada correctamente. $diasValidados días procesados sin errores.'
        : 'Se encontraron ${errores.length} errores en $diasConDatos días con datos. Revise la tabla de nóminas.'
    };
  }

  /// Formatea un valor como moneda siempre con 2 decimales
  String _formatearMoneda(dynamic valor) {
    final decimal = _convertirADouble(valor);
    final redondeado = double.parse(decimal.toStringAsFixed(2));
  // Formato forzado a punto decimal usando locale en_US
  return '\$${NumberFormat('0.00', 'en_US').format(redondeado)}';
  }

  /// Formatea un valor numérico sin símbolo de moneda (conserva 0 o 2 decimales según corresponda)
  String _formatearNumero(dynamic valor) {
    final decimal = _convertirADouble(valor);
    return decimal.toStringAsFixed(2); // Siempre 2 decimales para consistencia
  }

  /// Formatea un valor de campo/id (actividad o campo) como entero sin decimales.
  /// Si viene como double terminado en .0 (p.ej. 1306.0) lo convierte a '1306'.
  /// Si es 0 o null retorna cadena vacía para mantener UX de celda vacía.
  String _formatearIdOCampo(dynamic valor) {
    if (valor == null) return '';
    if (valor is int) {
      if (valor == 0) return '';
      return valor.toString();
    }
    if (valor is double) {
      if (valor == 0) return '';
      if (valor % 1 == 0) {
        return valor.toInt().toString();
      }
      // Si por algún motivo trae decimales, truncar presentación a entero sin romper dato interno
      return valor.toStringAsFixed(0);
    }
    // Si es string numérica con .0 limpiarlo
    final s = valor.toString();
    if (s == '0') return '';
    if (RegExp(r'^\d+\.0$').hasMatch(s)) {
      return s.split('.').first;
    }
    return s;
  }

  /// Construye las columnas de la tabla
  List<DataColumn> _construirColumnas() {
    final anchoExpandido = widget.isExpanded;
    return [
      // Columna Clave
      DataColumn(
        label: Container(
          width: anchoExpandido ? kAnchoClaveExpanded : kAnchoClaveCompact,
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
          width: anchoExpandido ? kAnchoEmpleadoExpanded : kAnchoEmpleadoCompact,
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
        
        return DataColumn(
          label: Container(
            width: anchoExpandido ? kAnchoDiaExpanded : kAnchoDiaCompact,
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
          width: anchoExpandido ? kAnchoTotalExpanded : kAnchoTotalCompact,
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
          width: anchoExpandido ? kAnchoOtrasPercepcionesExpanded : kAnchoOtrasPercepcionesCompact,
          padding: EdgeInsets.symmetric(vertical: anchoExpandido ? 8 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.green.shade600,
                size: anchoExpandido ? 18 : 14,
              ),
              SizedBox(height: anchoExpandido ? 4 : 2),
              Text(
                'Otras\npercepciones',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: anchoExpandido ? 12 : 9,
                  color: Color(0xFF374151),
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      DataColumn(
        label: Container(
          width: anchoExpandido ? kAnchoSubtotalExpanded : kAnchoSubtotalCompact,
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
          width: anchoExpandido ? kAnchoComedorExpanded : kAnchoComedorCompact,
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
          width: anchoExpandido ? kAnchoTotalNetoExpanded : kAnchoTotalNetoCompact,
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
              width: widget.isExpanded ? kAnchoClaveExpanded : kAnchoClaveCompact,
              child: Text(
                empleado['codigo']?.toString() ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Celda Nombre
          DataCell(
            SizedBox(
              width: widget.isExpanded ? kAnchoEmpleadoExpanded : kAnchoEmpleadoCompact,
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
              width: widget.isExpanded ? kAnchoTotalExpanded : kAnchoTotalCompact,
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
          
          // Celda Debe (editable)
          _construirCeldaEditable(
            index, 
            'debe', 
            empleado['debe'],
            labelTexto: 'Otras percepciones',
            mostrarMoneda: true,
            ancho: widget.isExpanded ? kAnchoOtrasPercepcionesExpanded : kAnchoOtrasPercepcionesCompact,
          ),
          
          // Celda Subtotal (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? kAnchoSubtotalExpanded : kAnchoSubtotalCompact,
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
            ancho: widget.isExpanded ? kAnchoComedorExpanded : kAnchoComedorCompact,
          ),
          
          // Celda Total Neto (solo lectura)
          DataCell(
            SizedBox(
              width: widget.isExpanded ? kAnchoTotalNetoExpanded : kAnchoTotalNetoCompact,
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

    // Interpretar 'dia_X_id' como CLAVE de actividad (no ID interno)
    final actividadClave = empleado['dia_${diaIndex}_id'];
    String actividadNombre;
    if (actividadClave == null || actividadClave.toString() == '0' || actividadClave.toString().isEmpty) {
      actividadNombre = 'actividad';
    } else {
      // Normalizar la clave: remover decimales si existen (ej: "1301.0" -> "1301")
      final claveRaw = actividadClave.toString();
      final clave = claveRaw.contains('.') ? claveRaw.split('.')[0] : claveRaw;
      
      // Buscar por clave normalizada
      if (_claveANombreMap.containsKey(clave)) {
        actividadNombre = _claveANombreMap[clave]!;
      } else {
        // Si no existe la clave, mostrar "no existe" solo si ya cargamos las actividades
        actividadNombre = _actividadesCargadas ? 'no existe' : '...';
      }
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
  print('  Clave Actividad: ${actividadClave ?? ''} -> Nombre: $actividadNombre');
    print('  ID Campo: $campoId -> Nombre: $campoNombre');
    print('  Mapas cargados - Actividades: ${_claveANombreMap.length}, Campos: ${_camposMap.length}');

    // Modo expandido: ID, Salario y campo adicional con labels
    return DataCell(
      SizedBox(
        width: kAnchoDiaExpanded,
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
                  child: _CeldaEditableActividadConLabel(
                    empleadoIndex: empleadoIndex,
                    diaIndex: diaIndex,
                    valorInicial: _formatearIdOCampo(empleado['dia_${diaIndex}_id']),
                    focusNode: _focusNodes['${empleadoIndex}_dia_${diaIndex}_id'],
                    onCambio: (valor) => _manejarCambio(empleadoIndex, 'dia_${diaIndex}_id', valor),
                    onNavegacion: (event) => _manejarNavegacion(event, '${empleadoIndex}_dia_${diaIndex}_id'),
                    claveANombreMap: _claveANombreMap,
                    actividadesCargadas: _actividadesCargadas,
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
    
  // Determinar si es un campo simple (actividad/campo). Aunque se almacena como int, se trata sin formato monetario.
  final esCampoTexto = campo.contains('_campo') || campo.contains('_id');
    
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
            ? _formatearIdOCampo(valor)
            : (mostrarMoneda ? _formatearMoneda(valor) : _formatearNumero(valor)),
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
  final valorMostrar = esCampoTexto ? _formatearIdOCampo(valor) : ((valor?.toString() ?? '') == '0' ? '' : valor?.toString() ?? '');
    
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
            mostrarMoneda ? _formatearMoneda(valor) : _formatearNumero(valor),
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

    // Determinar si es un campo de texto (campo o actividad ID)
    final esCampoTexto = campo.contains('_campo') || campo.contains('_id');

    // Convertir el valor según el tipo de campo
    final valorMostrar = valor?.toString() ?? '';
    
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
    final todasColumnas = _construirColumnas();
    final filas = _construirFilas();

    // 1) Vista compacta normal (sin sticky)
    if (!widget.isExpanded && !widget.enableStickyPreview) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                headingRowHeight: 56,
                dataRowHeight: 58,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                headingTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
                showBottomBorder: true,
                columns: todasColumnas,
                rows: filas,
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  verticalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
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

    // 2) Vista compacta con header sticky (sin columnas fijas)
    if (!widget.isExpanded && widget.enableStickyPreview) {
      const double headingHeight = 56;
      const double dataRowHeight = 58;
      const double columnSpacing = 8;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight.isFinite
                  ? (constraints.maxHeight - headingHeight).clamp(120.0, 800.0)
                  : 320.0;

              // Header único sin scroll horizontal
              final header = DataTable(
                columnSpacing: columnSpacing,
                headingRowHeight: headingHeight,
                dataRowHeight: 0,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: todasColumnas,
                rows: const [],
                border: TableBorder(
                  horizontalInside: BorderSide.none,
                  verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                  top: BorderSide(color: Color(0xFF7BAE2F).withOpacity(0.3), width: 2),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              );

              // Cuerpo solo con scroll vertical
              final body = SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: columnSpacing,
                  headingRowHeight: 0,
                  dataRowHeight: dataRowHeight,
                  columns: todasColumnas.map((c) => DataColumn(label: const SizedBox())).toList(),
                  rows: filas,
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                    verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                ),
              );

              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: headingHeight),
                    child: SizedBox(
                      height: availableHeight,
                      child: ClipRect(child: body),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: header,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // 3) Vista expandida (columnas fijas + header sticky)
  final double headingHeight = 72;
    final double dataRowHeight = 100;
    final double columnSpacing = 16;
    const int anchoClave = 80;
    const int anchoEmpleado = 200;
    const int separador = 16;

    final columnasFijas = todasColumnas.take(2).toList();
    final columnasScroll = todasColumnas.skip(2).toList();

    List<DataRow> filasFijas = [];
    List<DataRow> filasScroll = [];
    for (final fila in filas) {
      if (fila.cells.length >= 2) {
        filasFijas.add(DataRow(cells: fila.cells.take(2).toList()));
        filasScroll.add(DataRow(cells: fila.cells.skip(2).toList()));
      } else {
        filasFijas.add(fila);
        filasScroll.add(fila);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth;
            const int fixedLeftWidth = anchoClave + anchoEmpleado + separador; // ancho fijo asignado a columnas fijas
            final rightViewportWidth = (maxWidth - fixedLeftWidth).clamp(300.0, maxWidth);
            final double fixedWidth = fixedLeftWidth.toDouble();

            // Construir header completo (una sola fila) reutilizando DataTable para estilos
            Widget header = Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header fijo izquierda
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: fixedWidth),
                  child: DataTable(
                    columnSpacing: columnSpacing,
                    headingRowHeight: headingHeight,
                    dataRowHeight: 0, // sin filas de datos
                    headingRowColor: MaterialStateProperty.all(
                      Color(0xFF7BAE2F).withOpacity(0.1),
                    ),
                    columns: columnasFijas,
                    rows: const [],
                    border: TableBorder(
                      verticalInside: BorderSide.none,
                      horizontalInside: BorderSide.none,
                      top: BorderSide(color: Color(0xFF7BAE2F).withOpacity(0.3), width: 2),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                ),
                // Header desplazable derecha
                SizedBox(
                  width: rightViewportWidth,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollHeader,
                    scrollDirection: Axis.horizontal,
                    // Envolvemos la DataTable en un Row para agregar un espacio extra al final
                    // y asegurar que la última columna (Total Neto) pueda desplazarse totalmente dentro del viewport.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DataTable(
                          columnSpacing: columnSpacing,
                          headingRowHeight: headingHeight,
                          dataRowHeight: 0,
                          headingRowColor: MaterialStateProperty.all(
                            Color(0xFF7BAE2F).withOpacity(0.1),
                          ),
                          columns: columnasScroll,
                          rows: const [],
                          border: TableBorder(
                            verticalInside: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            horizontalInside: BorderSide.none,
                            top: BorderSide(color: Color(0xFF7BAE2F).withOpacity(0.3), width: 2),
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        const SizedBox(width: 140), // espacio extra mayor para mostrar completamente la última columna
                      ],
                    ),
                  ),
                ),
              ],
            );

            // Cuerpo sin encabezados (headingRowHeight=0)
            Widget body = Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: fixedWidth),
                  child: SingleChildScrollView(
                    controller: _verticalScrollLeft,
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: columnSpacing,
                      headingRowHeight: 0, // ocultar encabezado en cuerpo
                      dataRowHeight: dataRowHeight,
                      columns: columnasFijas
                          .map((c) => DataColumn(label: const SizedBox()))
                          .toList(),
                      rows: filasFijas,
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        top: BorderSide.none,
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: rightViewportWidth,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollBody,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SingleChildScrollView(
                          controller: _verticalScrollRight,
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: columnSpacing,
                            headingRowHeight: 0,
                            dataRowHeight: dataRowHeight,
                            columns: columnasScroll
                                .map((c) => DataColumn(label: const SizedBox()))
                                .toList(),
                            rows: filasScroll,
                            border: TableBorder(
                              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              verticalInside: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              top: BorderSide.none,
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 140), // espacio extra mayor para mostrar completamente la última columna
                      ],
                    ),
                  ),
                ),
              ],
            );

            // Altura disponible: restar header para permitir scroll interno si sobrepasa
      final availableHeight = constraints.maxHeight.isFinite
        ? (constraints.maxHeight - headingHeight).clamp(150.0, 1200.0)
        : 520.0; // fallback expandido

            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: headingHeight), // altura header
                  child: SizedBox(
                    height: availableHeight,
                    child: ClipRect(
                      child: body,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: header,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget especializado para celdas de actividad que actualiza el label dinámicamente
class _CeldaEditableActividadConLabel extends StatefulWidget {
  final int empleadoIndex;
  final int diaIndex;
  final String valorInicial;
  final FocusNode? focusNode;
  final Function(String) onCambio;
  final Function(KeyEvent) onNavegacion;
  final Map<String, String> claveANombreMap;
  final bool actividadesCargadas;

  const _CeldaEditableActividadConLabel({
    required this.empleadoIndex,
    required this.diaIndex,
    required this.valorInicial,
    this.focusNode,
    required this.onCambio,
    required this.onNavegacion,
    required this.claveANombreMap,
    required this.actividadesCargadas,
  });

  @override
  State<_CeldaEditableActividadConLabel> createState() => _CeldaEditableActividadConLabelState();
}

class _CeldaEditableActividadConLabelState extends State<_CeldaEditableActividadConLabel> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isDisposed = false;

  /// Normaliza el valor de actividad para remover decimales innecesarios
  String _normalizarValorActividad(String valor) {
    if (valor.isEmpty || valor == '0') return '';
    // Si termina en .0, remover los decimales
    if (valor.endsWith('.0')) {
      return valor.substring(0, valor.length - 2);
    }
    return valor;
  }

  @override
  void initState() {
    super.initState();
    // Normalizar el valor inicial para remover decimales innecesarios (.0)
    final valorLimpio = _normalizarValorActividad(widget.valorInicial);
    _controller = TextEditingController(text: valorLimpio);
    _focusNode = widget.focusNode ?? FocusNode();
    
    _focusNode.addListener(() {
      // Limpiar cuando focus y valor es '0'
      if (_focusNode.hasFocus && _controller.text == '0') {
        _controller.clear();
      } 
      // Poner '0' si está vacío al perder focus
      else if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        _controller.text = '0';
        widget.onCambio('0');
      }
    });
  }

  @override
  void didUpdateWidget(_CeldaEditableActividadConLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valorInicial != widget.valorInicial && !_focusNode.hasFocus) {
      _controller.text = _normalizarValorActividad(widget.valorInicial);
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
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF7BAE2F), width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          filled: true,
          fillColor: _focusNode.hasFocus 
            ? Color(0xFF7BAE2F).withOpacity(0.08)
            : Colors.grey.shade50,
        ),
        onChanged: (valor) {
          if (mounted && !_isDisposed) {
            setState(() {}); // Para actualizar el color de fondo
          }
          
          // Procesar el valor y notificar el cambio
          final valorLimpio = valor.replaceAll(RegExp(r'[^0-9]'), '');
          final valorFinal = valorLimpio.isEmpty ? '0' : valorLimpio;
          widget.onCambio(valorFinal);
        },
        onTap: () {
          if (mounted && !_isDisposed) {
            setState(() {}); // Para actualizar el color de fondo
          }
        },
        onFieldSubmitted: (value) {
          widget.onNavegacion(KeyDownEvent(
            timeStamp: Duration.zero,
            physicalKey: PhysicalKeyboardKey.enter,
            logicalKey: LogicalKeyboardKey.enter,
            character: null,
            synthesized: false,
          ));
        },
        onEditingComplete: () {
          // Prevenir el comportamiento predeterminado
        },
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
        keyboardType: widget.esCampoTexto
            ? TextInputType.number // ahora claves/ids solo dígitos
            : const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next, // Esto permite manejar Enter
        inputFormatters: widget.esCampoTexto
            ? [
                // Solo dígitos para IDs (actividad y campo)
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ]
            : [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final pointCount = '.'.allMatches(newValue.text).length;
                  if (pointCount > 1) return oldValue;
                  if (pointCount == 1) {
                    final parts = newValue.text.split('.');
                    if (parts.length == 2 && parts[1].length > 2) {
                      final truncated = '${parts[0]}.${parts[1].substring(0, 2)}';
                      return TextEditingValue(
                        text: truncated,
                        selection: TextSelection.collapsed(offset: truncated.length),
                      );
                    }
                  }
                  return newValue;
                }),
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
            // Para campos numéricos: preservar el punto decimal y limitar a 2 decimales
            if (valor.isEmpty) {
              widget.alCambiar('0');
              return;
            }
            if (valor == '.') {
              widget.alCambiar('0.');
              return;
            }
            if (valor.contains('.')) {
              final parts = valor.split('.');
              final parteEntera = parts[0].isEmpty ? '0' : parts[0];
              var parteDecimal = parts.length > 1 ? parts[1] : '';
              if (parteDecimal.length > 2) parteDecimal = parteDecimal.substring(0, 2);
              final reconstruido = parteDecimal.isEmpty ? parteEntera : '$parteEntera.$parteDecimal';
              widget.alCambiar(reconstruido);
            } else {
              widget.alCambiar(valor); // Solo dígitos
            }
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

/*
  📋 EJEMPLO DE USO DE LA VALIDACIÓN DE TABLA:

  // 1. Crear un GlobalKey para la tabla
  final GlobalKey<_NominaTablaEditableState> _tablaKey = GlobalKey<_NominaTablaEditableState>();

  // 2. Asignar la key al widget NominaTablaEditable
  NominaTablaEditable(
    key: _tablaKey,
    empleados: empleados,
    // ... otros parámetros
  )

  // 3. Validar antes de guardar
  void _guardarCambios() {
    final validacion = NominaTablaEditable.validarTablaDesdeKey(_tablaKey);
    
    if (validacion != null && validacion['valido'] == true) {
      // ✅ Validación exitosa - proceder a guardar
      print('✅ ${validacion['resumen']}');
      _procederConGuardado();
    } else if (validacion != null) {
      // ❌ Hay errores - mostrar mensaje
      final errores = validacion['errores'] as List<String>;
      _mostrarDialogoErrores(validacion['resumen'], errores);
    } else {
      // ⚠️ No se pudo validar
      _mostrarError('No se pudo validar la tabla');
    }
  }

  void _mostrarDialogoErrores(String resumen, List<String> errores) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Errores en la Tabla de Nóminas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resumen),
            SizedBox(height: 16),
            Text('Errores encontrados:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: errores.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${errores[index]}', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }
*/
