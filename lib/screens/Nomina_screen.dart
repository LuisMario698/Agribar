/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/editable_data_table.dart';
import '../widgets/indicator_card.dart'; 
import '../widgets/export_button_group.dart';
import '../widgets/dias_trabajados_table.dart';
import '../widgets/historial_semanas_widget.dart';
import '../theme/app_styles.dart';
import '../widgets/fullscreen_table_dialog.dart';

/// Widget principal de la pantalla de nómina.
/// Gestiona el proceso completo de nómina semanal incluyendo:
/// - Selección de cuadrilla y periodo
/// - Captura de días trabajados
/// - Cálculo de percepciones y deducciones
/// - Vista normal y expandida de la información
class NominaScreen extends StatefulWidget {
  const NominaScreen({
    super.key,
    this.showFullTable = false, // Control de vista expandida
    this.onCloseFullTable, // Callback al cerrar vista completa
    this.onOpenFullTable, // Callback al abrir vista completa
  });

  final bool showFullTable;
  final VoidCallback? onCloseFullTable;
  final VoidCallback? onOpenFullTable;

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> {
  bool showTablaPrincipal = true; // true for tabla principal, false for dias trabajados
  List<Map<String, dynamic>> empleadosFiltrados = [];
  bool isTableExpanded = false;
  final List<Map<String, dynamic>> _optionsCuadrilla = [
    {'nombre': 'Indirectos', 'empleados': []},
    {'nombre': 'Linea 1', 'empleados': []},
    {'nombre': 'Linea 3', 'empleados': []},
    {'nombre': 'Maquinaria', 'empleados': []},
    {'nombre': 'Empaque', 'empleados': []},
    {'nombre': 'Invernadero', 'empleados': []},
    {'nombre': 'Campo Abierto', 'empleados': []}
  ];  Map<String, dynamic> _selectedCuadrilla = {'nombre': '', 'empleados': []};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isWeekClosed = false;
  
  // Variables para manejo de semanas cerradas
  List<Map<String, dynamic>> semanasCerradas = [];
  bool showSemanasCerradas = false;
  int? semanaCerradaSeleccionada;
  bool showDiasTrabajados = false;
    // Variables para diálogo de supervisor
  final TextEditingController supervisorUserController = TextEditingController();
  final TextEditingController supervisorPassController = TextEditingController();
  String? supervisorLoginError;

  // Variables para manejo de empleados y cuadrillas
  bool showArmarCuadrilla = false;
  List<Map<String, dynamic>> todosLosEmpleados = [
    {'id': '1', 'nombre': 'Juan Pérez López', 'puesto': 'Jornalero', 'seleccionado': false},
    {'id': '2', 'nombre': 'María González Ruiz', 'puesto': 'Jornalero', 'seleccionado': false},
    {'id': '3', 'nombre': 'Roberto Sánchez Vega', 'puesto': 'Operador', 'seleccionado': false},
    {'id': '4', 'nombre': 'Ana Torres Mendoza', 'puesto': 'Jornalero', 'seleccionado': false},
    {'id': '5', 'nombre': 'Carlos Ramírez Ortiz', 'puesto': 'Operador', 'seleccionado': false},
    {'id': '6', 'nombre': 'Laura Flores Castro', 'puesto': 'Jornalero', 'seleccionado': false},
    {'id': '7', 'nombre': 'Miguel Ángel Díaz', 'puesto': 'Operador', 'seleccionado': false},
  ];
  List<Map<String, dynamic>> empleadosEnCuadrilla = [];  @override
  void initState() {
    super.initState();
    _selectedCuadrilla = {'nombre': '', 'empleados': []};
    _startDate = null;
    _endDate = null;
    empleadosFiltrados = [];
    empleadosEnCuadrilla = [];
    _loadInitialData();
  }
  Future<void> _loadInitialData() async {
    setState(() {
      empleadosFiltrados = [];  // Iniciar con lista vacía
    });
  }

  Future<void> _seleccionarSemana() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null 
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
      locale: const Locale('es'),
      builder: (context, child) {
        return Center(child: SizedBox(width: 500, height: 420, child: child));
      },
    );
    if (picked != null) {      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isWeekClosed = false; // Reiniciar el estado al seleccionar nueva semana
      });
    }
  }
  void _onCerrarSemana() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una semana antes de cerrar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    supervisorLoginError = null;
    supervisorUserController.clear();
    supervisorPassController.clear();
    _showSupervisorLoginDialog();
  }  void _cerrarSemanaActual() {
    if (_startDate == null || _endDate == null) return;
    
    // Crear una lista de todas las cuadrillas con sus empleados y datos completos
    List<Map<String, dynamic>> cuadrillasInfo = [];
    
    // Primero procesamos todas las cuadrillas de _optionsCuadrilla
    for (var cuadrilla in _optionsCuadrilla) {
      List<Map<String, dynamic>> empleadosConTablas = [];
      
      // Si es la cuadrilla actual, usamos empleadosFiltrados
      if (cuadrilla['nombre'] == _selectedCuadrilla['nombre']) {
        empleadosConTablas = empleadosFiltrados.map((emp) {
          return _procesarEmpleado(emp);
        }).toList();
      } else {
        // Para otras cuadrillas, procesamos sus empleados si tienen
        final empleadosCuadrilla = List<Map<String, dynamic>>.from(cuadrilla['empleados'] ?? []);
        empleadosConTablas = empleadosCuadrilla.map((emp) {
          return _procesarEmpleado(emp);
        }).toList();
      }
        // Calculamos el total de la cuadrilla (será 0 si no tiene empleados)
      final totalCuadrilla = empleadosConTablas.fold<double>(
        0.0,
        (sum, emp) => sum + (emp['tabla_principal']?['neto'] as num? ?? 0).toDouble(),
      );
      
      // Agregamos la cuadrilla siempre, tenga o no empleados
      cuadrillasInfo.add({
        'nombre': cuadrilla['nombre'],
        'empleados': empleadosConTablas,
        'total': totalCuadrilla,
      });
    }
    
    // Calcular el total de todas las cuadrillas
    final totalSemana = cuadrillasInfo.fold<double>(
      0.0,
      (sum, cuadrilla) => sum + (cuadrilla['total'] as double),
    );
    
    final semanaCerrada = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'fechaInicio': _startDate,
      'fechaFin': _endDate,
      'cuadrillas': cuadrillasInfo,
      'totalSemana': totalSemana,
      'cuadrillaSeleccionada': 0,
    };
    
    setState(() {
      semanasCerradas.add(semanaCerrada);
      _isWeekClosed = true;
      
      // Reiniciar completamente el estado
      _startDate = null;
      _endDate = null;
      empleadosFiltrados = [];
      empleadosEnCuadrilla = [];
      showDiasTrabajados = false;
      showArmarCuadrilla = false;
      _selectedCuadrilla = Map<String, dynamic>.from(_optionsCuadrilla[0]);
      
      // Limpiar las cuadrillas
      for (var cuadrilla in _optionsCuadrilla) {
        cuadrilla['empleados'] = [];
      }
      
      // Reiniciar el estado del supervisor
      supervisorUserController.clear();
      supervisorPassController.clear();
      supervisorLoginError = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semana cerrada correctamente. Los datos se han guardado y las tablas se han reiniciado.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }
  // Función auxiliar para procesar los datos de un empleado
  Map<String, dynamic> _procesarEmpleado(Map<String, dynamic> emp) {
    final numDays = _endDate!.difference(_startDate!).inDays + 1;
    
    // Tabla Principal: días normales y total
    final diasNormales = List.generate(
      numDays,
      (i) => double.tryParse(emp['dia_$i']?.toString() ?? '0') ?? 0.0
    );
    
    // Tabla Días Trabajados: días trabajados y horas extra
    final diasTrabajados = List.generate(
      numDays,
      (i) => double.tryParse(emp['dt_dia_$i']?.toString() ?? '0') ?? 0.0
    );
    
    final horasExtra = List.generate(
      numDays,
      (i) => double.tryParse(emp['dt_horasExtra_$i']?.toString() ?? '0') ?? 0.0
    );
    
    // Calcular totales
    final totalDiasNormales = diasNormales.fold<double>(0, (sum, dia) => sum + dia);
    final totalDiasTrabajados = diasTrabajados.fold<double>(0, (sum, dia) => sum + dia);
    final totalHorasExtra = horasExtra.fold<double>(0, (sum, horas) => sum + horas);
    
    // Calcular deducciones
    final debe = double.tryParse(emp['debe']?.toString() ?? '0') ?? 0.0;
    final comedorValue = (emp['comedor'] == true) ? 400.0 : 0.0;
    
    // Calcular total neto
    final subtotal = totalDiasNormales;
    final totalNeto = subtotal - debe - comedorValue;
    
    // Crear objeto con todos los datos
    return {
      ...emp, // Mantener datos básicos del empleado
      'tabla_principal': {
        'dias': diasNormales,
        'total': totalDiasNormales,
        'debe': debe,
        'comedor': comedorValue,
        'neto': totalNeto
      },
      'dias_trabajados': {
        'dias': diasTrabajados,
        'horas_extra': horasExtra,
        'total_dias': totalDiasTrabajados,
        'total_horas': totalHorasExtra
      }
    };
  }
  
  void _mostrarSemanasCerradas() {
    setState(() {
      showSemanasCerradas = true;
      semanaCerradaSeleccionada = null;
    });
  }
  
  // Muestra el detalle de una semana cerrada específica
  void _mostrarDetalleSemana(int index) {
    setState(() {
      semanaCerradaSeleccionada = index;
    });
  }
  
  // Cambia la cuadrilla seleccionada dentro de una semana cerrada
  void _cambiarCuadrillaSeleccionada(int semanaIndex, int cuadrillaIndex) {
    setState(() {
      semanasCerradas[semanaIndex]['cuadrillaSeleccionada'] = cuadrillaIndex;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  void _showSupervisorLoginDialog() {    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 28,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Autorización de Supervisor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: supervisorUserController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: TextStyle(color: AppColors.greenDark),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.greenDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    borderSide: BorderSide(color: AppColors.greenDark, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supervisorPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: AppColors.greenDark),
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.greenDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius), 
                    borderSide: BorderSide(color: AppColors.greenDark, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (supervisorLoginError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            supervisorLoginError!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.greenDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.verified_user),
                    onPressed: () {
                      if (supervisorUserController.text == 'supervisor' &&
                          supervisorPassController.text == '1234') {
                        Navigator.of(context).pop();
                        _cerrarSemanaActual();
                      } else {
                        setState(() {
                          supervisorLoginError = 'Usuario o contraseña incorrectos';
                        });
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    label: const Text('Autorizar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _toggleDiasTrabajados() {
    setState(() {
      showDiasTrabajados = !showDiasTrabajados;
      if (showDiasTrabajados) {
        // Al abrir la tabla, solo asegurarse que tengamos acceso a los empleados
        if (empleadosFiltrados.isEmpty) {
          empleadosFiltrados = List<Map<String, dynamic>>.from(_selectedCuadrilla['empleados'] ?? []);
        }
      }
      // Ya no actualizamos la cuadrilla al cerrar la tabla
      // Los datos se actualizan mediante el callback onChanged de DiasTrabajadosTable
    });
  }  void _toggleArmarCuadrilla() {
    if (showArmarCuadrilla) {
      // Al cerrar el diálogo, mostrar opción de mantener datos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Actualizar Cuadrilla',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seleccione cómo desea manejar los datos existentes de la cuadrilla',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Mantener los datos existentes
                      setState(() {
                        // Crear un mapa de los empleados existentes para mantener sus datos
                        final empleadosExistentes = Map.fromEntries(
                          empleadosFiltrados.map((e) => MapEntry(e['id'], e))
                        );
                        
                        // Actualizar la cuadrilla manteniendo los datos existentes
                        _selectedCuadrilla['empleados'] = empleadosEnCuadrilla.map((empleado) {
                          if (empleadosExistentes.containsKey(empleado['id'])) {
                            // Si el empleado ya existía, mantener sus datos
                            return empleadosExistentes[empleado['id']]!;
                          } else {
                            // Si es nuevo empleado, inicializar con valores por defecto
                            return {
                              'id': empleado['id'],
                              'clave': empleado['id'],
                              'nombre': empleado['nombre'],
                              'puesto': empleado['puesto'] ?? 'Jornalero',
                              'dias': 0,
                              'total': 0.0,
                              'sueldoDiario': 200.0,
                            };
                          }
                        }).toList();
                        
                        empleadosFiltrados = List<Map<String, dynamic>>.from(_selectedCuadrilla['empleados']);
                        showArmarCuadrilla = false;
                      });
                      Navigator.of(context).pop(); // Cerrar el diálogo de confirmación
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Mantener datos existentes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      // Reiniciar con datos nuevos
                      setState(() {
                        _selectedCuadrilla['empleados'] = empleadosEnCuadrilla.map((empleado) {
                          return {
                            'id': empleado['id'],
                            'clave': empleado['id'],
                            'nombre': empleado['nombre'],
                            'puesto': empleado['puesto'] ?? 'Jornalero',
                            'dias': 0,
                            'total': 0.0,
                            'sueldoDiario': 200.0,
                          };
                        }).toList();
                        
                        empleadosFiltrados = List<Map<String, dynamic>>.from(_selectedCuadrilla['empleados']);
                        showArmarCuadrilla = false;
                      });
                      Navigator.of(context).pop(); // Cerrar el diálogo de confirmación
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Empezar de cero'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Al abrir el diálogo, resetear selecciones y cargar empleados actuales
      setState(() {
        showArmarCuadrilla = true;
        empleadosEnCuadrilla = List<Map<String, dynamic>>.from(_selectedCuadrilla['empleados'] ?? []);
        
        // Asegurarnos de que cada empleado en la cuadrilla tenga el campo 'puesto'
        for (var empleado in empleadosEnCuadrilla) {
          empleado['puesto'] = empleado['puesto'] ?? 'Jornalero';
        }
      });
    }
  }
  void _toggleSeleccionEmpleado(Map<String, dynamic> empleado) {
    setState(() {
      // Crear una copia del empleado para la cuadrilla
      final empleadoCopia = Map<String, dynamic>.from(empleado);
      empleadoCopia['seleccionado'] = false; // Resetear estado de selección
      
      // Si el empleado ya está en la cuadrilla, quitarlo
      if (empleadosEnCuadrilla.any((e) => e['id'] == empleado['id'])) {
        empleadosEnCuadrilla.removeWhere((e) => e['id'] == empleado['id']);
      } else {
        // Si no está en la cuadrilla, agregarlo
        empleadosEnCuadrilla.add(empleadoCopia);
      }
    });
  }
  void _onTableChange(int index, String key, dynamic value) {
    setState(() {
      if (key == 'comedor') {
        // Para checkbox de comedor, asegurar que sea booleano
        empleadosFiltrados[index][key] = value as bool;
      } else if (key.startsWith('dia_') || key == 'debe') {
        // Para días trabajados y debe, convertir a número
        empleadosFiltrados[index][key] = int.tryParse(value.toString()) ?? 0;
      } else {
        // Para otros campos, usar el valor como viene
        empleadosFiltrados[index][key] = value;
      }
    });
  }

  // Mostrar diálogo para reiniciar semana con opciones
  void _mostrarDialogoReiniciarSemana() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 28,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Reiniciar Semana',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Seleccione una opción para reiniciar la semana',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // Reiniciar manteniendo las cuadrillas armadas
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _isWeekClosed = false;
                      // Mantener empleados en la cuadrilla actual
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Mantener cuadrillas armadas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    // Reiniciar y limpiar la cuadrilla también
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _isWeekClosed = false;
                      // Limpiar empleados de la cuadrilla actual
                      _selectedCuadrilla['empleados'] = [];
                      empleadosFiltrados = [];
                      empleadosEnCuadrilla = [];
                    });
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Deshacer cuadrillas armadas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nóminas',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Filter row with improved design
                    Row(
                      children: [
                        // Semana Card with better visual hierarchy
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 0,
                            color: AppColors.tableHeader,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, 
                                              size: 20,
                                              color: AppColors.greenDark,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Semana',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.greenDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        InkWell(
                                          onTap: _seleccionarSemana,
                                          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _startDate != null && _endDate != null
                                                      ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                      : 'Seleccionar semana',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                const Icon(Icons.arrow_drop_down, size: 24),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_startDate != null && _endDate != null) ...[
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: _isWeekClosed ? null : _onCerrarSemana,
                                            icon: const Icon(Icons.lock_outline),
                                            label: const Text('Cerrar semana'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _isWeekClosed ? Colors.grey : AppColors.greenDark,
                                              side: BorderSide(
                                                color: _isWeekClosed ? Colors.grey : AppColors.greenDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),                                  if (_startDate != null && _endDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _mostrarDialogoReiniciarSemana,
                                      style: IconButton.styleFrom(
                                        foregroundColor: Colors.grey.shade600,
                                        backgroundColor: Colors.grey.shade100,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Cuadrilla Card con mejor diseño visual
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 0,
                            color: AppColors.tableHeader,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.groups,
                                            size: 20,
                                            color: AppColors.greenDark,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cuadrilla',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.greenDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _selectedCuadrilla['nombre'] == '' ? null : _toggleArmarCuadrilla,
                                        icon: const Icon(Icons.group_add),
                                        label: Text(empleadosEnCuadrilla.isNotEmpty ? 'Editar cuadrilla' : 'Armar cuadrilla'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _selectedCuadrilla['nombre'] == '' ? Colors.grey : Colors.blue,
                                          side: BorderSide(color: _selectedCuadrilla['nombre'] == '' ? Colors.grey : Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),                                    child: DropdownButton<String?>(
                                      value: _selectedCuadrilla['nombre'] == '' ? null : _selectedCuadrilla['nombre'] as String?,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down),
                                      hint: Text(
                                        'Seleccionar cuadrilla',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      items: [
                                        // Add null item to allow deselection
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text(
                                            'Sin cuadrilla',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        ..._optionsCuadrilla.map((Map<String, dynamic> cuadrilla) {
                                          return DropdownMenuItem<String?>(
                                            value: cuadrilla['nombre'] as String,
                                            child: Text(
                                              cuadrilla['nombre'] as String,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (String? nombreCuadrilla) {
                                        setState(() {                                          if (nombreCuadrilla == null) {
                                            // Handle deselection by setting an empty cuadrilla
                                            _selectedCuadrilla = {'nombre': '', 'empleados': []};
                                            empleadosFiltrados = [];
                                            empleadosEnCuadrilla = [];
                                          } else {
                                            // Handle selection
                                            final cuadrillaSeleccionada = _optionsCuadrilla.firstWhere(
                                              (cuadrilla) => cuadrilla['nombre'] == nombreCuadrilla,
                                              orElse: () => {'nombre': '', 'empleados': []},
                                            );
                                            _selectedCuadrilla = cuadrillaSeleccionada;
                                            empleadosFiltrados = List<Map<String, dynamic>>.from(cuadrillaSeleccionada['empleados'] ?? []);
                                            empleadosEnCuadrilla = List<Map<String, dynamic>>.from(cuadrillaSeleccionada['empleados'] ?? []);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Indicators con diseño mejorado
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: IndicatorCard(
                                    title: 'Empleados',
                                    value: '${empleadosFiltrados.length}',
                                    icon: Icons.people,
                                  ),
                                ),
                                const SizedBox(width: 16),                                Expanded(
                                  child: IndicatorCard(
                                    title: 'Acumulado',
                                    value: '\$${empleadosFiltrados.fold<double>(
                                      0,
                                      (sum, emp) {
                                        final total = List.generate((_endDate != null && _startDate != null ? _endDate!.difference(_startDate!).inDays : 6) + 1, (i) => 
                                          int.tryParse(emp['dia_$i']?.toString() ?? '0') ?? 0
                                        ).reduce((a, b) => a + b);
                                        final debe = int.tryParse(emp['debe']?.toString() ?? '0') ?? 0;
                                        final subtotal = total - debe;
                                        final comedorValue = (emp['comedor'] == true) ? 400 : 0;
                                        final totalNeto = subtotal - comedorValue;
                                        return sum + totalNeto;
                                      }
                                    ).toStringAsFixed(2)}',
                                    icon: Icons.payments,
                                  ),
                                ),
                                const SizedBox(width: 16),                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      // Obtener el total sumando los acumulados de cada cuadrilla
                                      double totalSemana = _optionsCuadrilla.fold<double>(0, (sum, cuadrilla) {
                                        final empleados = List<Map<String, dynamic>>.from(cuadrilla['empleados'] ?? []);
                                        final cuadrillaTotal = empleados.fold<double>(0, (empSum, emp) {
                                          final total = List.generate((_endDate != null && _startDate != null ? _endDate!.difference(_startDate!).inDays : 6) + 1, (i) => 
                                            int.tryParse(emp['dia_$i']?.toString() ?? '0') ?? 0
                                          ).reduce((a, b) => a + b);
                                          final debe = int.tryParse(emp['debe']?.toString() ?? '0') ?? 0;
                                          final subtotal = total - debe;
                                          final comedorValue = (emp['comedor'] == true) ? 400 : 0;
                                          final totalNeto = subtotal - comedorValue;
                                          return empSum + totalNeto;
                                        });
                                        return sum + cuadrillaTotal;
                                      });
                                      
                                      return IndicatorCard(
                                        title: 'Total semana',
                                        value: '\$${totalSemana.toStringAsFixed(2)}',
                                        icon: Icons.monetization_on,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Table section con diseño mejorado
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header con acciones
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.list_alt,
                                        size: 24,
                                        color: AppColors.greenDark,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Nómina semanal',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.greenDark,
                                        ),
                                      ),
                                    ],
                                  ),                                  Row(
                                    children: [
                                      FilledButton.icon(
                                        onPressed: (_startDate != null && _endDate != null) 
                                          ? _toggleDiasTrabajados 
                                          : null,
                                        icon: const Icon(Icons.calendar_today),
                                        label: const Text('Ver días trabajados'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: (_startDate != null && _endDate != null)
                                            ? Colors.orange.shade600
                                            : Colors.grey.shade400,
                                          foregroundColor: (_startDate != null && _endDate != null)
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),IconButton(
                                        icon: const Icon(Icons.fullscreen),
                                        onPressed: () {
                                          final _modalHorizontal = ScrollController();
                                          final _modalVertical = ScrollController();
                                          showDialog(
                                            context: context,
                                            barrierColor: Colors.black.withOpacity(0.2),                                            builder: (context) {                                              // Usar una referencia directa a empleadosFiltrados
                                              return FullscreenTableDialog(
                                                empleados: empleadosFiltrados,
                                                semanaSeleccionada: _startDate != null && _endDate != null
                                                  ? DateTimeRange(start: _startDate!, end: _endDate!)
                                                  : null,
                                                onChanged: (index, key, value) {
                                                  // Llamar a setState aquí para asegurar que la UI principal se actualice
                                                  setState(() {
                                                    _onTableChange(index, key, value);
                                                  });
                                                },
                                                onClose: () => Navigator.of(context).pop(),
                                                horizontalController: _modalHorizontal,
                                                verticalController: _modalVertical,
                                              );
                                            },
                                          );
                                        },
                                        tooltip: 'Ver en pantalla completa',
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.grey.shade100,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.history),
                                        onPressed: _mostrarSemanasCerradas,
                                        tooltip: 'Historial de semanas cerradas',
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.grey.shade100,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),                                // Tabla centrada y alineada arriba con scroll
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.95, 
                                    height: MediaQuery.of(context).size.height * 0.75,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: EditableDataTableWidget(
                                      empleados: empleadosFiltrados,
                                      semanaSeleccionada: _startDate != null && _endDate != null 
                                        ? DateTimeRange(start: _startDate!, end: _endDate!) 
                                        : null,
                                      onChanged: _onTableChange,
                                      isExpanded: false,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),                    // Bottom buttons
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'EXPORTAR A', 
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 16),
                              ExportButton(
                                label: 'PDF',
                                color: Colors.blue,
                                onPressed: () {
                                  // TODO: Export to PDF
                                },
                              ),
                              const SizedBox(width: 8),
                              ExportButton(
                                label: 'EXCEL',
                                color: Colors.green,
                                onPressed: () {
                                  // TODO: Export to Excel
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlay dialogs
          if (showSemanasCerradas)
            HistorialSemanasWidget(
              semanasCerradas: semanasCerradas,
              onCuadrillaSelected: _cambiarCuadrillaSeleccionada,
              onClose: () => setState(() => showSemanasCerradas = false),
            ),
          if (showDiasTrabajados && _startDate != null && _endDate != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.tableHeader,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppDimens.cardRadius),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: AppColors.greenDark,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Días Trabajados',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => showDiasTrabajados = false),
                                      icon: const Icon(Icons.close),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Barra de búsqueda
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Buscar empleado...',
                                            hintStyle: TextStyle(color: Colors.grey.shade500),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: const TextStyle(fontSize: 14),                                          onChanged: (value) {
                                            setState(() {
                                              if (value.isEmpty) {
                                                empleadosFiltrados = List.from(_selectedCuadrilla['empleados'] ?? []);
                                              } else {
                                                final query = value.toLowerCase();
                                                empleadosFiltrados = (_selectedCuadrilla['empleados'] as List<Map<String, dynamic>>).where((emp) {
                                                  final nombre = emp['nombre']?.toString().toLowerCase() ?? '';
                                                  final clave = emp['clave']?.toString().toLowerCase() ?? '';
                                                  return nombre.contains(query) || clave.contains(query);
                                                }).toList();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(                            child: DiasTrabajadosTable(
                              empleados: empleadosFiltrados,
                              selectedWeek: DateTimeRange(start: _startDate!, end: _endDate!),
                              readOnly: _isWeekClosed,                              diasH: empleadosFiltrados.map((empleado) => 
                                List.generate(
                                  _endDate!.difference(_startDate!).inDays + 1,
                                  (i) => empleado['dt_horasExtra_$i'] as int? ?? 0
                                )
                              ).toList(),
                              diasTT: empleadosFiltrados.map((empleado) => 
                                List.generate(
                                  _endDate!.difference(_startDate!).inDays + 1,
                                  (i) => empleado['dt_dia_$i'] as int? ?? 0
                                )
                              ).toList(),onChanged: (horasExtra, diasTrabajados) {
                                // Update the filtered employee data with new values
                                setState(() {
                                  for (var i = 0; i < empleadosFiltrados.length; i++) {
                                    var empleado = empleadosFiltrados[i];
                                    for (var d = 0; d < diasTrabajados[i].length; d++) {
                                      // Usar campos diferentes para la tabla de días trabajados
                                      empleado['dt_horasExtra_$d'] = horasExtra[i][d];
                                      empleado['dt_dia_$d'] = diasTrabajados[i][d];
                                    }
                                    // Actualizar totales específicos para la tabla de días trabajados
                                    var totalDiasDT = diasTrabajados[i].reduce((a, b) => a + b);
                                    var totalHorasDT = horasExtra[i].reduce((a, b) => a + b);
                                    empleado['dt_total'] = totalDiasDT + totalHorasDT;
                                  }
                                });
                                // Actualizar cuadrilla
                                _selectedCuadrilla['empleados'] = empleadosFiltrados;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),          // Diálogo de armar cuadrilla con diseño mejorado
          if (showArmarCuadrilla)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.groups,
                                    size: 28,
                                    color: AppColors.green,
                                  ),
                                  const SizedBox(width: 12),                                Text(
                                    'Armar Cuadrilla: ${_selectedCuadrilla['nombre']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: _toggleArmarCuadrilla,
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 500,
                            child: Row(
                              children: [
                                // Lista de empleados disponibles con diseño mejorado
                                Expanded(
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.tableHeader,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(AppDimens.cardRadius),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                color: AppColors.greenDark,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Empleados Disponibles',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: empleadosEnCuadrilla.isEmpty && todosLosEmpleados.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.person_add_disabled,
                                                        size: 48,
                                                        color: Colors.grey.shade400,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        'No hay empleados disponibles',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount: todosLosEmpleados
                                                      .where((e) =>
                                                          !empleadosEnCuadrilla.any((ec) =>
                                                              ec['id'] == e['id']))
                                                      .length,
                                                  itemBuilder: (context, index) {
                                                    final empleadosDisponibles = todosLosEmpleados
                                                        .where((e) =>
                                                            !empleadosEnCuadrilla.any((ec) =>
                                                                ec['id'] == e['id']))
                                                        .toList();
                                                    final empleado = empleadosDisponibles[index];
                                                    return Card(
                                                      margin: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      child: ListTile(
                                                        leading: CircleAvatar(
                                                          backgroundColor:
                                                              AppColors.green.withOpacity(0.1),
                                                          child: Text(
                                                            empleado['nombre']
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color: AppColors.green,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          empleado['nombre'],
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          empleado['puesto'],
                                                          style:
                                                              TextStyle(color: Colors.grey.shade600),
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(Icons.add_circle_outline),
                                                          color: AppColors.green,
                                                          onPressed: () =>
                                                              _toggleSeleccionEmpleado(empleado),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Lista de empleados en cuadrilla con diseño mejorado
                                Expanded(
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.tableHeader,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(AppDimens.cardRadius),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.groups,
                                                color: AppColors.greenDark,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Empleados en Cuadrilla',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${empleadosEnCuadrilla.length}',
                                                  style: TextStyle(
                                                    color: AppColors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: empleadosEnCuadrilla.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.group_add,
                                                        size: 48,
                                                        color: Colors.grey.shade400,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        'Añade empleados a la cuadrilla',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount: empleadosEnCuadrilla.length,
                                                  itemBuilder: (context, index) {
                                                    final empleado = empleadosEnCuadrilla[index];
                                                    return Card(
                                                      margin: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      child: ListTile(
                                                        leading: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.green.withOpacity(0.1),
                                                          child: Text(
                                                            empleado['nombre']
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color: AppColors.green,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          empleado['nombre'],
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),                                                      subtitle: Text(
                                                          empleado['puesto'] ?? 'Jornalero',
                                                          style:
                                                              TextStyle(color: Colors.grey.shade600),
                                                        ),
                                                        trailing: IconButton(
                                                          icon: const Icon(Icons.remove_circle_outline),
                                                          color: Colors.red,
                                                          onPressed: () =>
                                                              _toggleSeleccionEmpleado(empleado),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FilledButton.icon(
                                onPressed: _toggleArmarCuadrilla,
                                icon: const Icon(Icons.check),
                                label: const Text('Completar Cuadrilla'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
