import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Widget unificado para mostrar y editar datos de nómina
/// Maneja tanto la vista principal como la expandida con lógica limpia y robusta
class TablaUnificadaNomina extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final Function(int index, String campo, dynamic valor)? onCambio;
  final bool vistaExpandida;
  final bool soloLectura;

  const TablaUnificadaNomina({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onCambio,
    this.vistaExpandida = false,
    this.soloLectura = false,
  }) : super(key: key);

  @override
  State<TablaUnificadaNomina> createState() => _TablaUnificadaNominaState();
}

class _TablaUnificadaNominaState extends State<TablaUnificadaNomina> {
  final Map<String, TextEditingController> _controladores = {};
  final Map<String, FocusNode> _focusNodes = {};
  final NumberFormat _formatoMoneda = NumberFormat('#,##0', 'es_ES');

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  @override
  void didUpdateWidget(TablaUnificadaNomina oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.empleados != oldWidget.empleados) {
      _limpiarControladores();
      _inicializarDatos();
    }
  }

  @override
  void dispose() {
    _limpiarControladores();
    super.dispose();
  }

  void _limpiarControladores() {
    for (var controller in _controladores.values) {
      controller.dispose();
    }
    _controladores.clear();
    
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();
  }

  void _inicializarDatos() {
    for (int i = 0; i < widget.empleados.length; i++) {
      _calcularTotalesEmpleado(i);
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Calcula los totales para un empleado específico
  void _calcularTotalesEmpleado(int indice) {
    final empleado = widget.empleados[indice];
    
    // Calcular total de días trabajados
    int totalDias = 0;
    for (String dia in ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo']) {
      final valor = empleado[dia];
      if (valor is int) {
        totalDias += valor;
      } else if (valor is double) {
        totalDias += valor.toInt();
      } else {
        totalDias += int.tryParse(valor?.toString() ?? '0') ?? 0;
      }
    }

    // Obtener tarifa del empleado
    final tarifaData = empleado['tarifa'] ?? 0;
    int tarifa = 0;
    if (tarifaData is int) {
      tarifa = tarifaData;
    } else if (tarifaData is double) {
      tarifa = tarifaData.toInt();
    } else {
      tarifa = int.tryParse(tarifaData.toString()) ?? 0;
    }

    // Calcular total bruto
    final totalBruto = totalDias * tarifa;

    // Obtener debe
    final debeData = empleado['debe'] ?? 0;
    int debe = 0;
    if (debeData is int) {
      debe = debeData;
    } else if (debeData is double) {
      debe = debeData.toInt();
    } else {
      debe = int.tryParse(debeData.toString()) ?? 0;
    }

    // Obtener comedor
    final comedorData = empleado['comedor'] ?? 0;
    int comedor = 0;
    if (comedorData is bool) {
      comedor = comedorData ? 400 : 0;
    } else if (comedorData is int) {
      comedor = comedorData;
    } else if (comedorData is double) {
      comedor = comedorData.toInt();
    } else {
      comedor = int.tryParse(comedorData.toString()) ?? 0;
    }

    // Calcular subtotal y total neto
    final subtotal = totalBruto - debe;
    final totalNeto = subtotal - comedor;

    // Actualizar empleado
    empleado['total'] = totalBruto;
    empleado['subtotal'] = subtotal;
    empleado['totalNeto'] = totalNeto;
  }

  /// Obtiene o crea un controlador para un campo específico
  TextEditingController _obtenerControlador(int indice, String campo) {
    final clave = '${indice}_$campo';
    if (!_controladores.containsKey(clave)) {
      final empleado = widget.empleados[indice];
      final valor = empleado[campo] ?? '';
      _controladores[clave] = TextEditingController(text: valor.toString());
    }
    return _controladores[clave]!;
  }

  /// Obtiene o crea un focus node para un campo específico
  FocusNode _obtenerFocusNode(int indice, String campo) {
    final clave = '${indice}_$campo';
    if (!_focusNodes.containsKey(clave)) {
      _focusNodes[clave] = FocusNode();
    }
    return _focusNodes[clave]!;
  }

  /// Maneja el cambio de valor en un campo
  void _manejarCambio(int indice, String campo, String nuevoValor) {
    if (widget.soloLectura) return;

    dynamic valorProcesado;
    
    // Procesar según el tipo de campo
    if (['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo', 'debe', 'tarifa'].contains(campo)) {
      valorProcesado = int.tryParse(nuevoValor) ?? 0;
    } else if (campo == 'comedor') {
      // Comedor puede ser booleano o entero
      if (nuevoValor.toLowerCase() == 'true' || nuevoValor == '1') {
        valorProcesado = true;
      } else if (nuevoValor.toLowerCase() == 'false' || nuevoValor == '0') {
        valorProcesado = false;
      } else {
        valorProcesado = int.tryParse(nuevoValor) ?? 0;
      }
    } else {
      valorProcesado = nuevoValor;
    }

    // Actualizar empleado
    widget.empleados[indice][campo] = valorProcesado;
    
    // Recalcular totales
    _calcularTotalesEmpleado(indice);
    
    // Notificar cambio
    if (widget.onCambio != null) {
      widget.onCambio!(indice, campo, valorProcesado);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Construye una celda editable
  Widget _construirCeldaEditable(int indice, String campo, {double? ancho}) {
    final empleado = widget.empleados[indice];
    final valor = empleado[campo] ?? '';
    
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: widget.soloLectura
          ? Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                valor.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            )
          : TextFormField(
              controller: _obtenerControlador(indice, campo),
              focusNode: _obtenerFocusNode(indice, campo),
              textAlign: TextAlign.center,
              keyboardType: ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo', 'debe', 'tarifa'].contains(campo)
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo', 'debe', 'tarifa'].contains(campo)
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (nuevoValor) => _manejarCambio(indice, campo, nuevoValor),
            ),
    );
  }

  /// Construye una celda de solo lectura para totales
  Widget _construirCeldaTotal(dynamic valor, {double? ancho, Color? colorFondo}) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4.0),
          color: colorFondo ?? Colors.grey.shade50,
        ),
        child: Text(
          valor is int ? _formatoMoneda.format(valor) : valor.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Construye la fila de encabezados
  Widget _construirEncabezados() {
    final anchoColumna = widget.vistaExpandida ? 80.0 : 60.0;
    final anchoCampoTexto = widget.vistaExpandida ? 120.0 : 100.0;
    
    return Container(
      color: Colors.blue.shade100,
      child: Row(
        children: [
          _construirCeldaTotal('Empleado', ancho: anchoCampoTexto),
          if (widget.vistaExpandida) _construirCeldaTotal('Tarifa', ancho: anchoColumna),
          _construirCeldaTotal('L', ancho: anchoColumna),
          _construirCeldaTotal('M', ancho: anchoColumna),
          _construirCeldaTotal('X', ancho: anchoColumna),
          _construirCeldaTotal('J', ancho: anchoColumna),
          _construirCeldaTotal('V', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal('S', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal('D', ancho: anchoColumna),
          _construirCeldaTotal('Total', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal('Debe', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal('Subtotal', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal('Comedor', ancho: anchoColumna),
          _construirCeldaTotal('Total Neto', ancho: anchoColumna),
        ],
      ),
    );
  }

  /// Construye una fila de empleado
  Widget _construirFilaEmpleado(int indice) {
    final empleado = widget.empleados[indice];
    final anchoColumna = widget.vistaExpandida ? 80.0 : 60.0;
    final anchoCampoTexto = widget.vistaExpandida ? 120.0 : 100.0;
    
    return Container(
      decoration: BoxDecoration(
        color: indice % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _construirCeldaEditable(indice, 'nombre', ancho: anchoCampoTexto),
          if (widget.vistaExpandida) _construirCeldaEditable(indice, 'tarifa', ancho: anchoColumna),
          _construirCeldaEditable(indice, 'lunes', ancho: anchoColumna),
          _construirCeldaEditable(indice, 'martes', ancho: anchoColumna),
          _construirCeldaEditable(indice, 'miercoles', ancho: anchoColumna),
          _construirCeldaEditable(indice, 'jueves', ancho: anchoColumna),
          _construirCeldaEditable(indice, 'viernes', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaEditable(indice, 'sabado', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaEditable(indice, 'domingo', ancho: anchoColumna),
          _construirCeldaTotal(empleado['total'] ?? 0, ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaEditable(indice, 'debe', ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaTotal(empleado['subtotal'] ?? 0, ancho: anchoColumna),
          if (widget.vistaExpandida) _construirCeldaEditable(indice, 'comedor', ancho: anchoColumna),
          _construirCeldaTotal(empleado['totalNeto'] ?? 0, ancho: anchoColumna, colorFondo: Colors.green.shade50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.empleados.isEmpty) {
      return const Center(
        child: Text(
          'No hay empleados para mostrar',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezados
        _construirEncabezados(),
        
        // Filas de empleados
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(
                widget.empleados.length,
                (indice) => _construirFilaEmpleado(indice),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
