/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/semana_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../widgets/nomina_historial_semanas_cerradas_widget.dart';
import '../widgets/nomina_armar_cuadrilla_widget.dart';
import '../theme/app_styles.dart';
import '../widgets/nomina_supervisor_auth_widget.dart';
import '../widgets/nomina_actualizar_cuadrilla_widget.dart';
import '../widgets/nomina_reiniciar_semana_widget.dart';
import '../widgets/nomina_detalles_empleado_widget.dart';
import '../widgets/nomina_week_selection_card.dart';
import '../widgets/nomina_cuadrilla_selection_card.dart';
import '../widgets/nomina_indicators_row.dart';
import '../widgets/nomina_main_table_section.dart';
import '../widgets/nomina_export_section.dart';

/// Widget principal de la pantalla de nómina.
/// Gestiona el proceso completo de nómina semanal incluyendo:
/// - Selección de cuadrilla y periodo
/// - Captura de días trabajados
/// - Cálculo de percepciones y deducciones
/// - Vista normal y expandida de la información
///
///variables de estado en _NominaScreenState 
DateTime? _startDate;
DateTime? _endDate;
bool _isWeekClosed = false;
bool semanaActiva = false;
bool _haySemanaActiva = false;
Map<String, dynamic>? semanaSeleccionada;
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
  bool showTablaPrincipal =
      true; // true for tabla principal, false for dias trabajados
  bool isTableExpanded = false;

  // Variable principal para empleados en la cuadrilla seleccionada
  List<Map<String, dynamic>> empleadosFiltrados = [];

  // Variables para manejo de empleados y cuadrillas
  List<Map<String, dynamic>> empleadosDisponiblesFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaFiltrados = [];
  final TextEditingController _buscarDisponiblesController = TextEditingController();
  final TextEditingController _buscarEnCuadrillaController = TextEditingController();

  final List<Map<String, dynamic>> _optionsCuadrilla = [
    {'nombre': 'Indirectos', 'empleados': []},
    {'nombre': 'Linea 1', 'empleados': []},
    {'nombre': 'Linea 3', 'empleados': []},
    {'nombre': 'Maquinaria', 'empleados': []},
    {'nombre': 'Empaque', 'empleados': []},
    {'nombre': 'Invernadero', 'empleados': []},
    {'nombre': 'Campo Abierto', 'empleados': []},  ];
  Map<String, dynamic> _selectedCuadrilla = {'nombre': '', 'empleados': []};  // Variables para manejo de semanas cerradas
  List<Map<String, dynamic>> semanasCerradas = [];
  bool showSemanasCerradas = false;
  int? semanaCerradaSeleccionada;

  // Variables para manejo de empleados y cuadrillas
  bool showArmarCuadrilla = false;
  List<Map<String, dynamic>> todosLosEmpleados = [];
  List<Map<String, dynamic>> empleadosEnCuadrilla = [];

  @override
  void initState() {
    super.initState();
    // _selectedCuadrilla = {'nombre': '', 'empleados': []};
    _cargarCuadrillasHabilitadas();
    _loadInitialData();
    
    verificarSemanaActiva();
    _selectedCuadrilla = {'nombre': '', 'empleados': []};
    _startDate = null;
    _endDate = null;
    empleadosFiltrados = [];
    empleadosEnCuadrilla = [];
    empleadosDisponiblesFiltrados = List.from(todosLosEmpleados);
    empleadosEnCuadrillaFiltrados = [];
  }

 void verificarSemanaActiva() async {
  final semana = await obtenerSemanaAbierta();

  if (semana != null) {
    setState(() {
      _startDate = semana['fechaInicio'];
      _endDate = semana['fechaFin'];
      _isWeekClosed = semana['cerrada'] ?? false;
      _haySemanaActiva = true;
    });

    // 🚨 Agrega esta línea justo aquí:
    await _cargarCuadrillasSemana(semana['id']);
  } else {
    setState(() {
      _haySemanaActiva = false;
    });
  }
}
Future<void> _cargarCuadrillasSemana(int semanaId) async {
  final cuadrillasGuardadas = await obtenerCuadrillasDeSemana(semanaId);

  setState(() {
    _optionsCuadrilla.clear();
    _optionsCuadrilla.addAll(cuadrillasGuardadas);
  });
}

  // Cargar semana activa automáticamente al abrir pantalla
 

  Future<void> _cargarCuadrillasHabilitadas() async {
    final cuadrillasBD = await obtenerCuadrillasHabilitadas();
    setState(() {
      _optionsCuadrilla.clear();
      _optionsCuadrilla.addAll(cuadrillasBD);
    });
  }

  Future<void> _loadInitialData() async {
    final empleados = await obtenerEmpleadosHabilitados();

    setState(() {
      todosLosEmpleados = empleados;
      empleadosDisponiblesFiltrados = List.from(empleados);
      empleadosEnCuadrillaFiltrados = [];
    });
  }

  Future<void> _seleccionarSemana() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
      locale: const Locale('es'),
      builder: (context, child) {
        return Center(child: SizedBox(width: 500, height: 420, child: child));
      },
    );

    if (picked != null) {
      // Guardar en la base de datos
      final nuevaSemana = await SemanaService().crearNuevaSemana(
        picked.start,
        picked.end,
      );

      if (nuevaSemana != null) {
        setState(() {
          _startDate = nuevaSemana['fechaInicio'];
          _endDate = nuevaSemana['fechaFin'];
          _isWeekClosed = false;
        }
        
        );
  await _cargarCuadrillasSemana(nuevaSemana['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Semana creada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al guardar la semana en la base de datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCerrarSemana() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una semana antes de cerrar'),
          backgroundColor: Colors.red,
        ),      );
      return;
    }
    _showSupervisorLoginDialog();
  }
Future<List<Map<String, dynamic>>> obtenerNominaEmpleadosDeCuadrilla(
      int semanaId, int cuadrillaId) async {
    final db = DatabaseService();
    await db.connect();

    final result = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre,
        e.codigo,
        n.lunes,
        n.martes,
        n.miercoles,
        n.jueves,
        n.viernes,
        n.sabado,
        n.domingo,
        n.total,
        n.debe,
        n.subtotal,
        n.descuento_comedor
      FROM nomina_empleados_semanal n
      JOIN empleados e ON e.id_empleado = n.empleado_id
      WHERE n.semana_id = @semanaId AND n.cuadrilla_id = @cuadrillaId;
    ''', substitutionValues: {
      'semanaId': semanaId,
      'cuadrillaId': cuadrillaId,
    });

    await db.close();

    return result.map((row) => {
      'id': row[0],
      'nombre': row[1],
      'codigo': row[2],
      'lunes': row[3],
      'martes': row[4],
      'miercoles': row[5],
      'jueves': row[6],
      'viernes': row[7],
      'sabado': row[8],
      'domingo': row[9],
      'total': row[10],
      'debe': row[11],
      'subtotal': row[12],
      'comedor': row[13],
    }).toList();
  }
  
  void _cerrarSemanaActual() {
    if (_startDate == null || _endDate == null) return;

    // Crear una lista de todas las cuadrillas con sus empleados y datos completos
    List<Map<String, dynamic>> cuadrillasInfo = [];

    // Primero procesamos todas las cuadrillas de _optionsCuadrilla
    for (var cuadrilla in _optionsCuadrilla) {
      List<Map<String, dynamic>> empleadosConTablas = [];

      // Si es la cuadrilla actual, usamos empleadosFiltrados
      if (cuadrilla['nombre'] == _selectedCuadrilla['nombre']) {
        empleadosConTablas =
            empleadosFiltrados.map((emp) {
              return _procesarEmpleado(emp);
            }).toList();
      } else {
        // Para otras cuadrillas, procesamos sus empleados si tienen
        final empleadosCuadrilla = List<Map<String, dynamic>>.from(
          cuadrilla['empleados'] ?? [],
        );
        empleadosConTablas =
            empleadosCuadrilla.map((emp) {
              return _procesarEmpleado(emp);
            }).toList();
      }
      // Calculamos el total de la cuadrilla (será 0 si no tiene empleados)
      final totalCuadrilla = empleadosConTablas.fold<double>(
        0.0,
        (sum, emp) =>
            sum + (emp['tabla_principal']?['neto'] as num? ?? 0).toDouble(),
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
      showArmarCuadrilla = false;
      _selectedCuadrilla = Map<String, dynamic>.from(_optionsCuadrilla[0]);

      // Limpiar las cuadrillas
      for (var cuadrilla in _optionsCuadrilla) {
        cuadrilla['empleados'] = [];
      }      // Reiniciar el estado del supervisor ya no es necesario
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Semana cerrada correctamente. Los datos se han guardado y las tablas se han reiniciado.',
        ),
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
      (i) => double.tryParse(emp['dia_$i']?.toString() ?? '0') ?? 0.0,
    );

    // Calcular totales
    final totalDiasNormales = diasNormales.fold<double>(
      0,
      (sum, dia) => sum + dia,
    );

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
        'neto': totalNeto,
      },
    };
  }

  void _mostrarSemanasCerradas() {
    setState(() {
          showSemanasCerradas = true;
          semanaCerradaSeleccionada = null;
    });
  }
  void _showSupervisorLoginDialog() {    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NominaSupervisorAuthWidget(
        onAuthSuccess: () {
          Navigator.of(context).pop();
          _cerrarSemanaActual();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _toggleArmarCuadrilla() {
    if (showArmarCuadrilla) {      // Cuando ya está abierto, guardar cambios
      // Asegurarnos de actualizar la lista real de empleados en la cuadrilla
      // antes de cerrar el diálogo (guardamos lo que está en empleadosEnCuadrilla)
      setState(() {
        // Actualizamos la lista real en _selectedCuadrilla
        _selectedCuadrilla['empleados'] = List<Map<String, dynamic>>.from(
          empleadosEnCuadrilla,
        );
      });
      
      // Al cerrar el diálogo, mostrar opción de mantener datos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return NominaActualizarCuadrillaWidget(
            empleadosExistentes: empleadosFiltrados,
            empleadosCompletoCuadrilla: _selectedCuadrilla['empleados'] ?? [],
            onMantenerDatos: () {
              // Mantener los datos existentes
              setState(() {
                // Crear un mapa de los empleados existentes para mantener sus datos
                final empleadosExistentesMap = Map.fromEntries(
                  empleadosFiltrados.map((e) => MapEntry(e['id'], e)),
                );
                final listaCompleta = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'] ?? [],
                );
                _selectedCuadrilla['empleados'] =
                    listaCompleta.map((empleado) {
                      if (empleadosExistentesMap.containsKey(empleado['id'])) {
                        return empleadosExistentesMap[empleado['id']]!;
                      } else {
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

                empleadosFiltrados = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'],
                );
                showArmarCuadrilla = false;
              });
            },
            onEmpezarDeCero: () {
              // Reiniciar con datos nuevos
              setState(() {
                final listaCompleta = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'] ?? [],
                );
                _selectedCuadrilla['empleados'] =
                    listaCompleta.map((empleado) {
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

                empleadosFiltrados = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'],
                );
                showArmarCuadrilla = false;
              });
            },
            onClose: () => Navigator.of(context).pop(),
          );
        },
      );
    } else {
      // Al abrir el diálogo, resetear selecciones y cargar empleados actuales
      setState(() {
        showArmarCuadrilla = true;

        // Inicializamos las listas originales
        empleadosEnCuadrilla = List<Map<String, dynamic>>.from(
          _selectedCuadrilla['empleados'] ?? [],
        );

        // Inicializamos las listas de visualización filtrada
        empleadosDisponiblesFiltrados = List.from(todosLosEmpleados);
        empleadosEnCuadrillaFiltrados = List.from(empleadosEnCuadrilla);

        // Limpiamos los controladores de búsqueda
        if (_buscarDisponiblesController.text.isNotEmpty)
          _buscarDisponiblesController.clear();
        if (_buscarEnCuadrillaController.text.isNotEmpty)
          _buscarEnCuadrillaController.clear();

        // Asegurarnos de que cada empleado en la cuadrilla tenga el campo 'puesto'
        for (var empleado in empleadosEnCuadrilla) {
          empleado['puesto'] = empleado['puesto'] ?? 'Jornalero';
        }
      });
    }  }

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
      context: context,      builder: (BuildContext context) {
        return NominaReiniciarSemanaWidget(
          onMantenerCuadrillas: () {
            // Reiniciar manteniendo las cuadrillas armadas
            setState(() {
              _startDate = null;
              _endDate = null;
              _isWeekClosed = false;
              // Mantener empleados en la cuadrilla actual
            });
          },
          onLimpiarCuadrillas: () {
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
          },
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
  // Función para mostrar detalles del empleado
  void _mostrarDetallesEmpleado(
    BuildContext context,
    Map<String, dynamic> empleado,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return NominaDetallesEmpleadoWidget(empleado: empleado);
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
                  children: [
                    Row(
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
                    const SizedBox(height: 24),                    // Filter row with improved design using modular widgets
                    Row(
                      children: [
                        // Week Selection Card
                        Expanded(
                          flex: 2,
                          child: NominaWeekSelectionCard(
                            startDate: _startDate,
                            endDate: _endDate,
                            isWeekClosed: _isWeekClosed,
                            haySemanaActiva: _haySemanaActiva,
                            semanaActiva: semanaActiva,
                            onSeleccionarSemana: _seleccionarSemana,
                            onCerrarSemana: _onCerrarSemana,
                            onReiniciarSemana: _mostrarDialogoReiniciarSemana,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Cuadrilla Selection Card
                        Expanded(
                          flex: 2,
                          child: NominaCuadrillaSelectionCard(

                            optionsCuadrilla: _optionsCuadrilla,
                            selectedCuadrilla: _selectedCuadrilla,
                            empleadosEnCuadrilla: empleadosEnCuadrilla,
                            onCuadrillaSelected: (Map<String, dynamic>? option) {
                              setState(() {
                                if (option == null) {
                                  // Handle deselection by setting an empty cuadrilla
                                  _selectedCuadrilla = {
                                    'nombre': '',
                                    'empleados': [],
                                  };
                                  empleadosFiltrados = [];
                                  empleadosEnCuadrilla = [];
                                  // También limpiar las listas filtradas
                                  empleadosDisponiblesFiltrados =
                                      List.from(todosLosEmpleados);
                                  empleadosEnCuadrillaFiltrados = [];
                                } else {
                                  // Handle selection
                                  _selectedCuadrilla = option;
                                  empleadosFiltrados =
                                      List<Map<String, dynamic>>.from(
                                        option['empleados'] ?? [],
                                      );
                                  empleadosEnCuadrilla =
                                      List<Map<String, dynamic>>.from(
                                        option['empleados'] ?? [],
                                      );

                                  // Actualizar también las listas filtradas
                                  empleadosDisponiblesFiltrados =
                                      List.from(todosLosEmpleados);
                                  empleadosEnCuadrillaFiltrados =
                                      List.from(empleadosEnCuadrilla);

                                  // Limpiar los filtros de búsqueda
                                  _buscarDisponiblesController.clear();
                                  _buscarEnCuadrillaController.clear();
                                }
                              });
                            },
                             semanaSeleccionada: semanaSeleccionada, // ✅ <--- Agregado aquí
                            onToggleArmarCuadrilla: _toggleArmarCuadrilla,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Indicators with improved design
                        Expanded(
                          flex: 3,
                          child: NominaIndicatorsRow(
                            empleadosFiltrados: empleadosFiltrados,
                            optionsCuadrilla: _optionsCuadrilla,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),                    // Table section with modular design
                    Expanded(
                      child: NominaMainTableSection(
                        empleadosFiltrados: empleadosFiltrados,
                        startDate: _startDate,
                        endDate: _endDate,
                        onTableChange: _onTableChange,
                        onMostrarSemanasCerradas: _mostrarSemanasCerradas,
                      ),
                    ),                    // Export section
                    const SizedBox(height: 24),
                    const NominaExportSection(),
                  ],
                ),
              ),
            ),
          ),          // Overlay dialogs
          if (showSemanasCerradas)
            NominaHistorialSemanasCerradasWidget(
              semanasCerradas: semanasCerradas,
              onClose: () => setState(() => showSemanasCerradas = false),
              onSemanaCerradaUpdated: (semanaActualizada) {
                // Callback opcional para cuando se actualiza una semana cerrada
                // Por ahora no necesitamos hacer nada adicional
              },          ),// Diálogo de armar cuadrilla modularizado
          if (showArmarCuadrilla)
            NominaArmarCuadrillaWidget(
              optionsCuadrilla: _optionsCuadrilla,
              selectedCuadrilla: _selectedCuadrilla,
              todosLosEmpleados: todosLosEmpleados,
              empleadosEnCuadrilla: empleadosEnCuadrilla,              onCuadrillaSaved: (cuadrilla, empleados) {
                setState(() {
                  // Actualizar la cuadrilla seleccionada con los nuevos empleados
                  _selectedCuadrilla = cuadrilla;
                  empleadosEnCuadrilla = empleados;
                  
                  // Actualizar la lista en _optionsCuadrilla
                  _selectedCuadrilla['empleados'] = List<Map<String, dynamic>>.from(empleados);
                  
                  // Cerrar el diálogo
                  showArmarCuadrilla = false;
                  
                  // Llamar a la función existente para manejar los datos
                  _toggleArmarCuadrilla();
                });
              },
              onClose: () => setState(() => showArmarCuadrilla = false),
              onMostrarDetallesEmpleado: _mostrarDetallesEmpleado,
            ),
        ],
      ),
    );
  }
}
