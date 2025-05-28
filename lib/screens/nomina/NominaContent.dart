/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../widgets_shared/generic_search_bar.dart';
import '../../widgets_shared/generic_card.dart';
import 'widgets/index.dart';

/// Widget principal de la pantalla de nómina.
/// Gestiona el proceso completo de nómina semanal incluyendo:
/// - Selección de cuadrilla y periodo
/// - Captura de días trabajados
/// - Cálculo de percepciones y deducciones
/// - Vista normal y expandida de la información
class NominaContent extends StatefulWidget {
  const NominaContent({
    super.key,
    this.showFullTable = false, // Control de vista expandida
    this.onCloseFullTable, // Callback al cerrar vista completa
    this.onOpenFullTable, // Callback al abrir vista completa
  });

  final bool showFullTable; // Estado de la vista de tabla
  final VoidCallback? onCloseFullTable;
  final VoidCallback? onOpenFullTable;

  @override
  State<NominaContent> createState() => _NominaContentState();
}

/// Estado del widget NominaContent que mantiene:
/// - Selección de cuadrilla y semana
/// - Datos de empleados y sus registros
/// - Cálculos de nómina
/// - Estado de la interfaz
class _NominaContentState extends State<NominaContent> {
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
  final TextEditingController searchDiasController = TextEditingController();
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
            // Verificar si coincide con la cuadrilla seleccionada
            bool matchCuadrilla =
                cuadrillaSeleccionada == null ||
                e['cuadrilla'] == cuadrillaSeleccionada;

            // Verificar si coincide con el texto de búsqueda
            bool matchNombre =
                e['nombre'].toString().toLowerCase().contains(query) ||
                e['clave'].toString().toLowerCase().contains(query);

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
          final oldDias = List<int>.from(e['dias']);
          final newDias = List<int>.filled(diasCount, 0);
          for (int i = 0; i < oldDias.length && i < diasCount; i++) {
            newDias[i] = oldDias[i];
          }
          e['dias'] = newDias;
        }
        // Ajustar tt
        if (!e.containsKey('tt') || !(e['tt'] is List)) {
          e['tt'] = List<int>.filled(diasCount, 0);
        } else if ((e['tt'] as List).length != diasCount) {
          final oldTT = List<int>.from(e['tt']);
          final newTT = List<int>.filled(diasCount, 0);
          for (int i = 0; i < oldTT.length && i < diasCount; i++) {
            newTT[i] = oldTT[i];
          }
          e['tt'] = newTT;
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

  // Método para sincronizar datos entre listas de empleados
  // Actualmente no se usa, pero se mantiene para posible uso futuro
  /*void _sincronizarDatos() {
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
  }*/

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
    // No se utiliza actualmente, pero puede ser útil para diseño responsive
    // final isSmallScreen = screenWidth < 1200;

    // Calcular el total de la semana (suma de todas las cuadrillas)
    final totalSemana = empleados.fold<int>(
      0,
      (sum, e) => sum + (e['neto'] as int? ?? 0),
    );

    return Stack(
      children: [
        // Contenido principal
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1400),
            child: GenericCard(
              elevation: 8,
              margin: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y controles superiores
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gestión de Nómina',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B7A2F),
                            ),
                          ),
                          Row(
                            children: [
                              // Botón para ver semanas cerradas
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    showSemanasCerradas = true;
                                    if (semanasCerradas.isNotEmpty) {
                                      semanaCerradaSeleccionada = 0;
                                      cuadrillaCerradaSeleccionada =
                                          cuadrillas.first['nombre'];
                                    }
                                  });
                                },
                                icon: Icon(Icons.history),
                                label: Text('Ver semanas cerradas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0B7A2F),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              // Botón para cerrar semana
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (semanaSeleccionada == null) {
                                    // Mostrar error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Debe seleccionar una semana para cerrar',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    showSupervisorLogin = true;
                                  });
                                },
                                icon: Icon(Icons.lock),
                                label: Text('Cerrar semana'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Formulario para selección de cuadrilla y semana
                      NominaForm(
                        cuadrillas: cuadrillas,
                        cuadrillaSeleccionada: cuadrillaSeleccionada,
                        semanaSeleccionada: semanaSeleccionada,
                        onCuadrillaChanged: (value) {
                          setState(() {
                            cuadrillaSeleccionada = value;
                            _filtrarEmpleados();

                            // Cargar datos de días trabajados para esta cuadrilla
                            diasTrabajadosH =
                                diasTrabajadosHPorCuadrilla[value];
                            diasTrabajadosTT =
                                diasTrabajadosTTPorCuadrilla[value];
                          });
                        },
                        onWeekSelected: (DateTimeRange? week) {
                          setState(() {
                            semanaSeleccionada = week;
                            _ajustarLongitudDiasTT();
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      // Barra de búsqueda
                      NominaSearchBar(
                        controller: searchController,
                        onSearchPressed: _filtrarEmpleados,
                      ),
                      SizedBox(height: 24),

                      // Información de total
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total acumulado: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '\$$totalSemana',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Botones para tablas
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                isFullScreen = !isFullScreen;
                                if (isFullScreen) {
                                  if (widget.onOpenFullTable != null) {
                                    widget.onOpenFullTable!();
                                  }
                                } else {
                                  if (widget.onCloseFullTable != null) {
                                    widget.onCloseFullTable!();
                                  }
                                }
                              });
                            },
                            icon: Icon(
                              isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                            ),
                            label: Text(
                              isFullScreen ? 'Vista normal' : 'Vista expandida',
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                showDiasTrabajados = true;
                              });
                            },
                            icon: Icon(Icons.calendar_today),
                            label: Text('Ver días trabajados'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Tabla de nómina
                      NominaDataTable(
                        data: empleadosFiltrados,
                        selectedWeek: semanaSeleccionada,
                        isExpanded: isFullScreen,
                        onUpdate: _updateEmpleadoData,
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
                // Fondo con desenfoque
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
                // Contenido del overlay
                Center(
                  child: GenericCard(
                    color: Colors.white,
                    elevation: 12,
                    child: Container(
                      width: 1200,
                      height: 700,
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Días Trabajados',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    showDiasTrabajados = false;
                                    // Actualizar datos en la cuadrilla actual
                                    if (cuadrillaSeleccionada != null &&
                                        diasTrabajadosH != null &&
                                        diasTrabajadosTT != null) {
                                      diasTrabajadosHPorCuadrilla[cuadrillaSeleccionada!] =
                                          diasTrabajadosH!;
                                      diasTrabajadosTTPorCuadrilla[cuadrillaSeleccionada!] =
                                          diasTrabajadosTT!;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Barra de búsqueda para días trabajados
                          GenericSearchBar(
                            controller: searchDiasController,
                            hintText: 'Buscar empleado...',
                            onSearchPressed: () {
                              setState(() {
                                searchDiasTrabajados =
                                    searchDiasController.text.toLowerCase();
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: DiasTrabajadosTable(
                              empleados:
                                  empleadosFiltrados.where((e) {
                                    return e['nombre']
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchDiasTrabajados);
                                  }).toList(),
                              selectedWeek: semanaSeleccionada,
                              diasH: diasTrabajadosH,
                              diasTT: diasTrabajadosTT,
                              onChanged: (h, tt) {
                                diasTrabajadosH = h;
                                diasTrabajadosTT = tt;
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

        // Overlay: Expandir Tabla (implementación existente)
        if (isFullScreen)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Center(
                child: GenericCard(
                  color: Colors.white,
                  elevation: 12,
                  child: Container(
                    width: 1300,
                    height: 700,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vista Expandida',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  isFullScreen = false;
                                  if (widget.onCloseFullTable != null) {
                                    widget.onCloseFullTable!();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: NominaDataTable(
                            data: empleadosFiltrados,
                            selectedWeek: semanaSeleccionada,
                            isExpanded: true,
                            onUpdate: _updateEmpleadoData,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Overlays para semanas cerradas y login de supervisor
        // (Implementación existente)
      ],
    );
  }
}
