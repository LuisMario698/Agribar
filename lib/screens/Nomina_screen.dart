/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

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

  final bool showFullTable; // Estado de la vista de tabla
  final VoidCallback? onCloseFullTable;
  final VoidCallback? onOpenFullTable;

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

/// Estado del widget NominaScreen que mantiene:
/// - Selección de cuadrilla y semana
/// - Datos de empleados y sus registros
/// - Cálculos de nómina
/// - Estado de la interfaz
class _NominaScreenState extends State<NominaScreen> {
  // Datos de ejemplo de cuadrillas
  List<Map<String, String>> cuadrillas = [
    {
      'nombre': 'Indirectos', // Nombre de la cuadrilla
      'clave': '000001+390', // Identificador único
      'grupo': 'Grupo Baranzini', // Grupo al que pertenece
      'actividad': 'Destajo', // Tipo de actividad
    },
    {
      'nombre': 'Linea 1',
      'clave': '000002+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
    },
    {
      'nombre': 'Linea 3',
      'clave': '000003+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
    },
  ];

  String? cuadrillaSeleccionada;
  DateTimeRange? semanaSeleccionada;
  final TextEditingController searchController = TextEditingController();

  // Datos de nómina (mock, pero dinámicos)
  List<Map<String, dynamic>> empleados = [
    {
      'clave': '1950',
      'nombre': 'Adela Rodríguez Ramírez',
      'dias': [0, 0, 0, 0, 0, 0, 0], // Array para los 7 días
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Indirectos',
    },
    {
      'clave': '2340',
      'nombre': 'Elizabeth Rodríguez Ramírez',
      'dias': [0, 0, 0, 0, 0, 0, 0],
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Indirectos',
    },
    {
      'clave': '2730',
      'nombre': 'Pedro Sanchez Velasco',
      'dias': [0, 0, 0, 0, 0, 0, 0],
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Linea 1',
    },
    {
      'clave': '3120',
      'nombre': 'Magdalena Bautista Ramírez',
      'dias': [0, 0, 0, 0, 0, 0, 0],
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Linea 1',
    },
    {
      'clave': '3510',
      'nombre': 'Leonides Cruz Quiroz',
      'dias': [0, 0, 0, 0, 0, 0, 0],
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Linea 3',
    },
    {
      'clave': '3900',
      'nombre': 'Fabian Cruz Quiroz',
      'dias': [0, 0, 0, 0, 0, 0, 0],
      'total': 0,
      'debo': 0,
      'subtotal': 0,
      'comedor': 0,
      'neto': 0,
      'cuadrilla': 'Linea 3',
    },
  ];

  List<Map<String, dynamic>> empleadosFiltrados = [];
  bool isFullScreen = false; // State variable to track full-screen mode
  bool showDiasTrabajados = false;
  Map<String, List<List<int>>> diasTrabajadosHPorCuadrilla = {};
  Map<String, List<List<int>>> diasTrabajadosTTPorCuadrilla = {};
  List<List<int>>? diasTrabajadosH;
  List<List<int>>? diasTrabajadosTT;
  bool showSupervisorLogin = false;
  final TextEditingController supervisorUserController =
      TextEditingController();
  final TextEditingController supervisorPassController =
      TextEditingController();
  String? supervisorLoginError;
  String searchDiasTrabajados = '';
  List<Map<String, dynamic>> semanasCerradas = [];
  bool showSemanasCerradas = false;
  int? semanaCerradaSeleccionada;
  String? cuadrillaCerradaSeleccionada;

  @override
  void initState() {
    super.initState();
    cuadrillaSeleccionada = cuadrillas.first['nombre'];
    _filtrarEmpleados();
  }

  void _filtrarEmpleados() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      empleadosFiltrados =
          empleados.where((e) {
            final matchCuadrilla = e['cuadrilla'] == cuadrillaSeleccionada;
            final matchNombre = e['nombre'].toLowerCase().contains(query);
            return matchCuadrilla && (query.isEmpty || matchNombre);
          }).toList();
      _ajustarLongitudDiasTT();
    });
  }

  void _ajustarLongitudDiasTT() {
    int diasCount =
        semanaSeleccionada != null
            ? semanaSeleccionada!.duration.inDays + 1
            : 7;
    void ajustar(List<Map<String, dynamic>> lista) {
      for (var e in lista) {
        // Ajustar dias
        if (e['dias'] is! List) {
          e['dias'] = List<int>.filled(diasCount, 0);
        } else if ((e['dias'] as List).length != diasCount) {
          List<int> oldDias = List<int>.from(e['dias']);
          e['dias'] = List<int>.filled(diasCount, 0);
          for (int i = 0; i < diasCount && i < oldDias.length; i++) {
            e['dias'][i] = oldDias[i];
          }
        }
        // Ajustar tt
        if (!e.containsKey('tt') || !(e['tt'] is List)) {
          e['tt'] = List<int>.filled(diasCount, 0);
        } else if ((e['tt'] as List).length != diasCount) {
          List<int> oldTT = List<int>.from(e['tt']);
          e['tt'] = List<int>.filled(diasCount, 0);
          for (int i = 0; i < diasCount && i < oldTT.length; i++) {
            e['tt'][i] = oldTT[i];
          }
        }
      }
    }

    ajustar(empleados);
    ajustar(empleadosFiltrados);
  }

  Future<void> _seleccionarSemana() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: semanaSeleccionada,
      locale: const Locale('es'),
      builder: (context, child) {
        return Center(child: SizedBox(width: 500, height: 420, child: child));
      },
    );
    if (picked != null) {
      setState(() {
        semanaSeleccionada = picked;
        _ajustarLongitudDiasTT();
      });
    }
  }

  void _sincronizarDatos() {
    setState(() {
      // Actualizar empleadosFiltrados con los datos más recientes
      for (var empleado in empleadosFiltrados) {
        int mainIndex = empleados.indexWhere(
          (e) => e['clave'] == empleado['clave'],
        );
        if (mainIndex != -1) {
          empleados[mainIndex] = Map<String, dynamic>.from(empleado);
        }
      }
    });
  }

  void _recalcularTotales(int index) {
    // Determinar qué lista usar
    List<Map<String, dynamic>> listaActual =
        index < empleados.length ? empleados : empleadosFiltrados;

    // Asegurarnos de que los valores sean enteros
    int total = 0;
    for (var dia in listaActual[index]['dias']) {
      total += (dia as int);
    }
    listaActual[index]['total'] = total;

    // Obtener valores como enteros
    int debo = (listaActual[index]['debo'] as int?) ?? 0;
    int comedor = (listaActual[index]['comedor'] as int?) ?? 0;

    // Calcular subtotal (total - debo)
    int subtotal = total - debo;
    listaActual[index]['subtotal'] = subtotal;

    // Calcular neto (subtotal - comedor)
    int neto = subtotal - comedor;
    listaActual[index]['neto'] = neto;
  }

  void _updateEmpleadoData(int index, String key, dynamic value) {
    // Convertir el valor a entero
    int intValue = 0;
    if (value is String) {
      intValue = int.tryParse(value) ?? 0;
    } else if (value is int) {
      intValue = value;
    }

    if (key.startsWith('dia_')) {
      int diaIndex = int.parse(key.split('_')[1]);
      empleadosFiltrados[index]['dias'][diaIndex] = intValue;
      _recalcularTotales(index);

      // Sincronizar los días con la lista principal
      int mainIndex = empleados.indexWhere(
        (e) => e['clave'] == empleadosFiltrados[index]['clave'],
      );
      if (mainIndex != -1) {
        empleados[mainIndex]['dias'] = List<int>.from(
          empleadosFiltrados[index]['dias'],
        );
        _recalcularTotales(mainIndex);
      }
    } else if (key == 'debo' || key == 'comedor') {
      empleadosFiltrados[index][key] = intValue;
      _recalcularTotales(index);

      // Sincronizar cambios con la lista principal
      int mainIndex = empleados.indexWhere(
        (e) => e['clave'] == empleadosFiltrados[index]['clave'],
      );
      if (mainIndex != -1) {
        empleados[mainIndex][key] = intValue;
        _recalcularTotales(mainIndex);
      }
    }

    // Forzar la actualización de los totales
    setState(() {
      // Solo actualizar los totales
      for (var i = 0; i < empleadosFiltrados.length; i++) {
        _recalcularTotales(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 1200;
    // Calcular el total de la semana (suma de todas las cuadrillas)
    final totalSemana = empleados.fold<int>(
      0,
      (sum, e) => sum + (e['neto'] as int? ?? 0),
    );

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Nóminas',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 30),
                      // Contenedor flex para los cards superiores
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          // Total Semana Acumulado card at top
                          Card(
                            color: Colors.white,
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Total Semana Acumulado',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$$totalSemana',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ), // Container Card for both Semana and Cuadrilla
                          Card(
                            color: Color.fromARGB(255, 219, 219, 219),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Card: Semana
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 400,
                                        minWidth: 300,
                                      ),
                                      child: Card(
                                        color: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 180,
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Semana',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[900],
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                OutlinedButton(
                                                  onPressed: _seleccionarSemana,
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                      color: Colors.black54,
                                                      width: 1.2,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            22,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    semanaSeleccionada == null
                                                        ? 'Inicio → Final'
                                                        : '${semanaSeleccionada!.start.day}/${semanaSeleccionada!.start.month}/${semanaSeleccionada!.start.year} → ${semanaSeleccionada!.end.day}/${semanaSeleccionada!.end.month}/${semanaSeleccionada!.end.year}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.green[900],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Card: Cuadrilla
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 400,
                                        minWidth: 300,
                                      ),
                                      child: Card(
                                        color: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: SizedBox(
                                          height: 180,
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Cuadrilla',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[900],
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                DropdownButton<String>(
                                                  value: cuadrillaSeleccionada,
                                                  isExpanded: true,
                                                  items:
                                                      cuadrillas
                                                          .map(
                                                            (
                                                              c,
                                                            ) => DropdownMenuItem(
                                                              value:
                                                                  c['nombre'],
                                                              child: Text(
                                                                c['nombre'] ??
                                                                    '',
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      cuadrillaSeleccionada =
                                                          value;
                                                      _filtrarEmpleados();
                                                    });
                                                  },
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
                            ),
                          ),
                        ],
                      ),
                      // <-- This closes the Row's children list
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              // Indicadores a la derecha (sin el Total Semana Acumulado de abajo)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Buscador a la izquierda
                                  Container(
                                    width: 300,
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: (value) => _filtrarEmpleados(),
                                      decoration: InputDecoration(
                                        hintText: 'Buscar',
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        suffixIcon: Icon(
                                          Icons.search,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Tarjetas a la derecha
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Card(
                                        color: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                isSmallScreen
                                                    ? double.infinity
                                                    : 220,
                                            minHeight: 100,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Empleados en cuadrilla',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green[900],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.people,
                                                      size: 32,
                                                      color: Colors.blue[700],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${empleadosFiltrados.length}',
                                                      style: TextStyle(
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Card(
                                        color: Colors.white,
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                isSmallScreen
                                                    ? double.infinity
                                                    : 220,
                                            minHeight: 100,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Total Acumulado Cuadrilla',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green[900],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '\$${empleadosFiltrados.fold<int>(0, (sum, e) => sum + (e['neto'] as int? ?? 0))}',
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botón nuevo a la izquierda
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showDiasTrabajados = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.blue,
                                    ),
                                    label: const Text(
                                      'Ver días trabajados',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white, // White background
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isFullScreen =
                                            !isFullScreen; // Toggle full-screen mode
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.green,
                                    ), // Expand icon with green color
                                    label: const Text(
                                      'Expandir Tabla',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ), // Green text
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Center(
                                child: Card(
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Container(
                                    width: 1200,
                                    height: 440,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ScrollableDataTable(
                                            key: ValueKey('expanded'),
                                            data:
                                                List<Map<String, dynamic>>.from(
                                                  empleadosFiltrados,
                                                ),
                                            selectedWeek: semanaSeleccionada,
                                            onUpdate: _updateEmpleadoData,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showSemanasCerradas = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.history,
                                      color: Colors.blue,
                                    ),
                                    label: const Text(
                                      'Semanas cerradas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF8CB800),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (semanaSeleccionada == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Debes seleccionar una semana antes de cerrarla',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      setState(() {
                                        showSupervisorLogin = true;
                                        supervisorLoginError = null;
                                        supervisorUserController.clear();
                                        supervisorPassController.clear();
                                      });
                                    },
                                    child: const Text(
                                      'Cerrar semana',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'PDF',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'EXCEL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Overlay: Ver días trabajados
        if (showDiasTrabajados)
          Positioned.fill(
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(),
                ),
                Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.95,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tabla de días trabajados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showDiasTrabajados = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barra de búsqueda
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchDiasTrabajados =
                                    value.trim().toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: DiasTrabajadosTable(
                              empleados:
                                  empleadosFiltrados
                                      .where(
                                        (e) =>
                                            searchDiasTrabajados.isEmpty ||
                                            e['nombre'].toLowerCase().contains(
                                              searchDiasTrabajados,
                                            ),
                                      )
                                      .toList(),
                              selectedWeek: semanaSeleccionada,
                              diasH: diasTrabajadosH,
                              diasTT: diasTrabajadosTT,
                              onChanged: (h, tt) {
                                setState(() {
                                  diasTrabajadosH = h;
                                  diasTrabajadosTT = tt;
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Overlay: Expandir Tabla
        if (isFullScreen)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Center(
                child: Card(
                  color: Colors.white,
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width *
                        0.95, // Cover 95% of the screen width
                    height:
                        MediaQuery.of(context).size.height *
                        0.95, // Cover 95% of the screen height
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) => _filtrarEmpleados(),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                _sincronizarDatos(); // Sincronizar datos antes de cerrar
                                setState(() {
                                  isFullScreen =
                                      false; // Close full-screen mode
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Aquí la tabla debe ocupar todo el ancho disponible
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ScrollableDataTable(
                              key: ValueKey('expanded'),
                              data: List<Map<String, dynamic>>.from(
                                empleadosFiltrados,
                              ),
                              selectedWeek: semanaSeleccionada,
                              isExpanded: true,
                              onUpdate: _updateEmpleadoData,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Overlay: Semanas cerradas
        if (showSemanasCerradas)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Center(
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    width: 1200,
                    height: 800,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Semanas cerradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showSemanasCerradas = false;
                                    semanaCerradaSeleccionada = null;
                                    cuadrillaCerradaSeleccionada = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (semanasCerradas.isEmpty)
                            const Text('No hay semanas cerradas.'),
                          if (semanasCerradas.isNotEmpty)
                            ...semanasCerradas.asMap().entries.map((entry) {
                              final i = entry.key;
                              final semana = entry.value;
                              final fechaCierre = semana['fecha'] as DateTime;
                              final DateTimeRange? rango =
                                  semana['semanaSeleccionada']
                                      as DateTimeRange?;
                              String? fechaInicio =
                                  rango != null
                                      ? '${rango.start.day}/${rango.start.month}/${rango.start.year}'
                                      : null;
                              String? fechaFin =
                                  rango != null
                                      ? '${rango.end.day}/${rango.end.month}/${rango.end.year}'
                                      : null;
                              final empleadosSemana =
                                  semana['empleados'] as List;
                              String? cuadrillaEjemplo;
                              if (empleadosSemana.isNotEmpty) {
                                cuadrillaEjemplo =
                                    empleadosSemana.first['cuadrilla'];
                              }
                              return ListTile(
                                leading: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  'Semana: ${fechaInicio ?? '-'} → ${fechaFin ?? '-'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Cerrada el ${fechaCierre.day}/${fechaCierre.month}/${fechaCierre.year} a las ${fechaCierre.hour.toString().padLeft(2, '0')}:${fechaCierre.minute.toString().padLeft(2, '0')}',
                                ),
                                onTap: () {
                                  setState(() {
                                    semanaCerradaSeleccionada = i;
                                    cuadrillaCerradaSeleccionada =
                                        cuadrillaEjemplo;
                                  });
                                },
                                selected: semanaCerradaSeleccionada == i,
                              );
                            }),
                          if (semanaCerradaSeleccionada != null)
                            _buildDetalleSemanaCerrada(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Overlay: Cerrar semana (autorización supervisor)
        if (showSupervisorLogin)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Center(
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    width: 370,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título y botón de cerrar en la misma fila
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Autorización Supervisor',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setState(() {
                                    showSupervisorLogin = false;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: supervisorUserController,
                          decoration: const InputDecoration(
                            hintText: 'Usuario o correo',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: supervisorPassController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Contraseña',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                        ),
                        if (supervisorLoginError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              supervisorLoginError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8CB800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final user = supervisorUserController.text.trim();
                              final pass = supervisorPassController.text.trim();
                              if (user == 'supervisor' && pass == '1234') {
                                setState(() {
                                  showSupervisorLogin = false;
                                  supervisorLoginError = null;
                                  // Guardar snapshot profundo de la semana
                                  semanasCerradas.add({
                                    'fecha': DateTime.now(),
                                    'semanaSeleccionada': semanaSeleccionada,
                                    'empleados':
                                        empleados
                                            .map(
                                              (e) =>
                                                  Map<String, dynamic>.from(e),
                                            )
                                            .toList(),
                                    'diasTrabajadosH':
                                        Map<String, List<List<int>>>.from(
                                          diasTrabajadosHPorCuadrilla,
                                        ),
                                    'diasTrabajadosTT':
                                        Map<String, List<List<int>>>.from(
                                          diasTrabajadosTTPorCuadrilla,
                                        ),
                                  });
                                  // Limpiar datos
                                  for (var e in empleados) {
                                    e['dias'] = List<int>.filled(
                                      e['dias'].length,
                                      0,
                                    );
                                    e['total'] = 0;
                                    e['debo'] = 0;
                                    e['subtotal'] = 0;
                                    e['comedor'] = 0;
                                    e['neto'] = 0;
                                    if (e.containsKey('tt'))
                                      e['tt'] = List<int>.filled(
                                        e['tt'].length,
                                        0,
                                      );
                                  }
                                  diasTrabajadosHPorCuadrilla.clear();
                                  diasTrabajadosTTPorCuadrilla.clear();
                                  diasTrabajadosH = null;
                                  diasTrabajadosTT = null;
                                  _filtrarEmpleados();
                                });
                                supervisorUserController.clear();
                                supervisorPassController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Semana cerrada correctamente.',
                                    ),
                                  ),
                                );
                              } else {
                                setState(() {
                                  supervisorLoginError =
                                      'Credenciales incorrectas';
                                });
                              }
                            },
                            child: const Text(
                              'Autorizar',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetalleSemanaCerrada(BuildContext context) {
    final semana = semanasCerradas[semanaCerradaSeleccionada!];
    final empleadosSemana = semana['empleados'] as List<Map<String, dynamic>>;
    final diasH = semana['diasTrabajadosH'] as Map<String, List<List<int>>>?;
    final diasTT = semana['diasTrabajadosTT'] as Map<String, List<List<int>>>?;
    final cuadrillasSemana =
        empleadosSemana.map((e) => e['cuadrilla'] as String).toSet().toList();
    final empleadosCuadrilla =
        empleadosSemana
            .where((e) => e['cuadrilla'] == cuadrillaCerradaSeleccionada)
            .toList();
    final totalSemana = empleadosSemana.fold<int>(
      0,
      (sum, e) => sum + (e['neto'] as int),
    );
    final totalCuadrilla = empleadosCuadrilla.fold<int>(
      0,
      (sum, e) => sum + (e['neto'] as int),
    );
    return Card(
      color: Colors.grey[50],
      elevation: 12,
      margin: const EdgeInsets.only(top: 24),
      child: Container(
        width: 1100,
        height: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Cuadrilla:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: cuadrillaCerradaSeleccionada,
                    items:
                        cuadrillasSemana
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        cuadrillaCerradaSeleccionada = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Total acumulado semana: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$$totalSemana',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Total acumulado cuadrilla: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$$totalCuadrilla',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Tabla de nómina guardada:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ScrollableDataTable(
                data: empleadosCuadrilla,
                selectedWeek: null,
                isExpanded: true,
                readOnly: true,
                onUpdate: (a, b, c) {}, // Solo visualización
              ),
              const SizedBox(height: 18),
              Text(
                'Tabla de días trabajados guardada:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DiasTrabajadosTable(
                empleados: empleadosCuadrilla,
                selectedWeek: null,
                readOnly: true,
                diasH:
                    diasH != null ? diasH[cuadrillaCerradaSeleccionada] : null,
                diasTT:
                    diasTT != null
                        ? diasTT[cuadrillaCerradaSeleccionada]
                        : null,
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget que implementa una tabla desplazable para mostrar datos de nómina.
/// Permite editar los valores de días trabajados, deducciones y comedor.
/// Se adapta al tamaño de la pantalla y mantiene el estado de edición.
class ScrollableDataTable extends StatefulWidget {
  /// Datos a mostrar en la tabla (empleados y sus registros)
  final List<Map<String, dynamic>> data;

  /// Semana seleccionada para mostrar los días correspondientes
  final DateTimeRange? selectedWeek;

  /// Indica si la tabla está en modo expandido
  final bool isExpanded;

  /// Callback para actualizar valores en la tabla
  final Function(int, String, dynamic) onUpdate;
  final bool readOnly;

  const ScrollableDataTable({
    super.key,
    required this.data,
    this.selectedWeek,
    this.isExpanded = false,
    required this.onUpdate,
    this.readOnly = false,
  });

  @override
  _ScrollableDataTableState createState() => _ScrollableDataTableState();
}

class _ScrollableDataTableState extends State<ScrollableDataTable> {
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
  void didUpdateWidget(ScrollableDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar los controladores cuando los datos cambian
    for (var empleado in widget.data) {
      for (int i = 0; i < 1; i++) {
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                })
              else
                ...List.generate(7, (index) {
                  return DataColumn(
                    label: Text(
                      'Día',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            'TT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        placeholder: true,
                      );
                    })
                  else
                    ...List.generate(7, (index) {
                      return const DataCell(
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            'TT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                                int? newValue = int.tryParse(value);
                                if (newValue != null) {
                                  widget.onUpdate(
                                    index,
                                    'dia_$diaIndex',
                                    newValue,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      )
                    else
                      ...List.generate(7, (diaIndex) {
                        return DataCell(
                          _buildEditableCell(
                            e['dias'][diaIndex].toString(),
                            '${e['clave']}_dia_$diaIndex',
                            (value) {
                              int? newValue = int.tryParse(value);
                              if (newValue != null) {
                                widget.onUpdate(
                                  index,
                                  'dia_$diaIndex',
                                  newValue,
                                );
                              }
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
                          int? newValue = int.tryParse(value);
                          if (newValue != null) {
                            widget.onUpdate(index, 'debo', newValue);
                          }
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

class DiasTrabajadosTable extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? selectedWeek;
  final List<List<int>>? diasH;
  final List<List<int>>? diasTT;
  final void Function(List<List<int>> h, List<List<int>> tt)? onChanged;
  final bool readOnly;
  final bool isExpanded;

  const DiasTrabajadosTable({
    required this.empleados,
    required this.selectedWeek,
    this.diasH,
    this.diasTT,
    this.onChanged,
    this.readOnly = false,
    this.isExpanded = false,
    Key? key,
  }) : super(key: key);

  @override
  State<DiasTrabajadosTable> createState() => _DiasTrabajadosTableState();
}

class _DiasTrabajadosTableState extends State<DiasTrabajadosTable> {
  late List<List<int>> hValues;
  late List<List<int>> ttValues;
  final Map<String, TextEditingController> _controllersH = {};
  final Map<String, TextEditingController> _controllersTT = {};
  final Map<String, FocusNode> _focusNodesH = {};
  final Map<String, FocusNode> _focusNodesTT = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initLocalData();
  }

  @override
  void didUpdateWidget(DiasTrabajadosTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initLocalData();
  }

  void _initLocalData() {
    final diasSemana =
        widget.selectedWeek != null
            ? List.generate(
              widget.selectedWeek!.duration.inDays + 1,
              (i) => widget.selectedWeek!.start.add(Duration(days: i)),
            )
            : List.generate(7, (i) => DateTime(2023, 1, i + 1));
    int diasCount = diasSemana.length;
    hValues =
        widget.diasH != null &&
                widget.diasH!.length == widget.empleados.length &&
                widget.diasH!.every((l) => l.length == diasCount)
            ? widget.diasH!.map((l) => List<int>.from(l)).toList()
            : List.generate(
              widget.empleados.length,
              (i) => List<int>.filled(diasCount, 0),
            );
    ttValues =
        widget.diasTT != null &&
                widget.diasTT!.length == widget.empleados.length &&
                widget.diasTT!.every((l) => l.length == diasCount)
            ? widget.diasTT!.map((l) => List<int>.from(l)).toList()
            : List.generate(
              widget.empleados.length,
              (i) => List<int>.filled(diasCount, 0),
            );
    for (int eIdx = 0; eIdx < widget.empleados.length; eIdx++) {
      for (int i = 0; i < diasCount; i++) {
        String keyH = '${eIdx}_h_$i';
        String keyTT = '${eIdx}_tt_$i';
        _controllersH[keyH] = TextEditingController(
          text: hValues[eIdx][i].toString(),
        );
        _controllersTT[keyTT] = TextEditingController(
          text: ttValues[eIdx][i].toString(),
        );
        _focusNodesH[keyH] = FocusNode();
        _focusNodesTT[keyTT] = FocusNode();
        _controllersH[keyH]?.addListener(() {
          int v = int.tryParse(_controllersH[keyH]?.text ?? '0') ?? 0;
          hValues[eIdx][i] = v;
          widget.onChanged?.call(hValues, ttValues);
          setState(() {});
        });
        _controllersTT[keyTT]?.addListener(() {
          int v = int.tryParse(_controllersTT[keyTT]?.text ?? '0') ?? 0;
          ttValues[eIdx][i] = v;
          widget.onChanged?.call(hValues, ttValues);
          setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    for (var c in _controllersH.values) {
      c.dispose();
    }
    for (var c in _controllersTT.values) {
      c.dispose();
    }
    for (var f in _focusNodesH.values) {
      f.dispose();
    }
    for (var f in _focusNodesTT.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diasSemana =
        widget.selectedWeek != null
            ? List.generate(
              widget.selectedWeek!.duration.inDays + 1,
              (i) => widget.selectedWeek!.start.add(Duration(days: i)),
            )
            : List.generate(7, (i) => DateTime(2023, 1, i + 1));
    final dayNames = ['dom', 'lun', 'mar', 'mie', 'jue', 'vie', 'sab'];
    int diasCount = diasSemana.length;
    int totalCols = 2 + diasCount * 2 + 1; // Clave, Nombre, (TT+H)*dias, Total

    // Definir los anchos personalizados
    Map<int, TableColumnWidth> columnWidths = {
      0: FixedColumnWidth(widget.isExpanded ? 99 : 60), // Clave
      1: FixedColumnWidth(widget.isExpanded ? 239 : 200), // Nombre
    };
    for (int i = 0; i < diasCount * 2; i++) {
      columnWidths[2 + i] = FixedColumnWidth(
        widget.isExpanded ? 79 : 48,
      ); // TT y H
    }
    columnWidths[totalCols - 1] = FixedColumnWidth(
      widget.isExpanded ? 99 : 60,
    ); // Total

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade500, width: 1),
            columnWidths: columnWidths,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                children: [
                  _headerCell('Clave', fontSize: widget.isExpanded ? 14 : 12),
                  _headerCell('Nombre', fontSize: widget.isExpanded ? 14 : 12),
                  ...diasSemana.expand(
                    (date) => [
                      _headerCell(
                        dayNames[date.weekday % 7].toUpperCase(),
                        fontSize: widget.isExpanded ? 14 : 12,
                      ),
                      _headerCell('', fontSize: widget.isExpanded ? 14 : 12),
                    ],
                  ),
                  _headerCell('Total', fontSize: widget.isExpanded ? 14 : 12),
                ],
              ),
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                children: [
                  const TableCell(child: SizedBox()),
                  const TableCell(child: SizedBox()),
                  ...List.generate(
                    diasCount,
                    (i) => [
                      _headerCell('TT', fontSize: widget.isExpanded ? 14 : 12),
                      _headerCell('H', fontSize: widget.isExpanded ? 14 : 12),
                    ],
                  ).expand((x) => x),
                  const TableCell(child: SizedBox()),
                ],
              ),
              ...List.generate(widget.empleados.length, (eIdx) {
                int total = 0;
                for (int i = 0; i < diasCount; i++) {
                  total += hValues[eIdx][i] + ttValues[eIdx][i];
                }
                return TableRow(
                  children: [
                    _bodyCell(
                      widget.empleados[eIdx]['clave'].toString(),
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                    _bodyCell(
                      widget.empleados[eIdx]['nombre'].toString(),
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                    ...List.generate(
                      diasCount,
                      (i) => [
                        _editableCell(
                          ttValues[eIdx][i].toString(),
                          'tt_${eIdx}_$i',
                          (val) {
                            int? newValue = int.tryParse(val);
                            if (newValue != null) {
                              ttValues[eIdx][i] = newValue;
                              widget.onChanged?.call(hValues, ttValues);
                              setState(() {});
                            }
                          },
                          _controllersTT,
                          _focusNodesTT,
                          fontSize: widget.isExpanded ? 14 : 12,
                        ),
                        _editableCell(
                          hValues[eIdx][i].toString(),
                          'h_${eIdx}_$i',
                          (val) {
                            int? newValue = int.tryParse(val);
                            if (newValue != null) {
                              hValues[eIdx][i] = newValue;
                              widget.onChanged?.call(hValues, ttValues);
                              setState(() {});
                            }
                          },
                          _controllersH,
                          _focusNodesH,
                          fontSize: widget.isExpanded ? 14 : 12,
                        ),
                      ],
                    ).expand((x) => x),
                    _bodyCell(
                      total.toString(),
                      bold: true,
                      fontSize: widget.isExpanded ? 14 : 12,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text, {double fontSize = 12}) => TableCell(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
    ),
  );

  Widget _bodyCell(String text, {bool bold = false, double fontSize = 12}) =>
      TableCell(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ),
      );

  Widget _editableCell(
    String value,
    String key,
    void Function(String) onChanged,
    Map<String, TextEditingController> controllers,
    Map<String, FocusNode> focusNodes, {
    double fontSize = 12,
  }) {
    if (widget.readOnly) {
      return Text(
        value,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      );
    }

    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(text: value);
      focusNodes[key] = FocusNode();
    }
    return TextField(
      controller: controllers[key],
      focusNode: focusNodes[key],
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: fontSize),
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
        controllers[key]?.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controllers[key]!.text.length,
        );
      },
    );
  }
}
