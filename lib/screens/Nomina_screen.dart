/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:agribar/widgets/app_button.dart';
import 'package:agribar/widgets/data_table_widget.dart';
import 'package:agribar/widgets/indicator_card.dart';
import 'package:agribar/widgets/dias_trabajados_table.dart';
import 'package:agribar/widgets/editable_data_table.dart';

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
    // Removing unused variables
    // final isSmallScreen = screenWidth < 1200;
    // final totalSemana = empleados.fold<int>(
    //   0,
    //   (sum, e) => sum + (e['neto'] as int? ?? 0),
    // );

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Title and weekly total indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nóminas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          IndicatorCard(
                            title: 'Total Semana',
                            value: '\$${empleados.fold<int>(0, (sum, e) => sum + (e['neto'] as int? ?? 0))}',
                            icon: Icons.calendar_view_week,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFilterBar(),
                      const SizedBox(height: 24),
                      _buildSearchAndIndicators(),
                      const SizedBox(height: 24),
                      // Top controls: expand and view days
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Expandir tabla',
                            icon: Icons.open_in_full,
                            onPressed: () => setState(() => isFullScreen = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'Ver días trabajados',
                            icon: Icons.calendar_today,
                            onPressed: () => setState(() => showDiasTrabajados = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Data table section
                      _buildTableSection(),
                      const SizedBox(height: 24),
                      // Bottom action buttons: close week, history, PDF, Excel
                      Row(
                        children: [
                          AppButton(
                            label: 'Cerrar semana',
                            icon: Icons.lock,
                            onPressed: _onCerrarSemana,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[900],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'Historial semanas cerradas',
                            icon: Icons.history,
                            onPressed: () => setState(() => showSemanasCerradas = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          Spacer(),
                          AppButton(
                            label: 'PDF',
                            icon: Icons.picture_as_pdf,
                            onPressed: _onExportPdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'EXCEL',
                            icon: Icons.table_chart,
                            onPressed: _onExportExcel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                          Flexible(
                            fit: FlexFit.loose,
                            child: EditableDataTableWidget(
                              empleados: empleadosFiltrados,
                              semanaSeleccionada: semanaSeleccionada,
                              onChanged: _updateEmpleadoData,
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
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

  // 1. Barra de filtros: Semana y Cuadrilla
  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green[900])),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _seleccionarSemana,
                    child: Text(
                      semanaSeleccionada != null
                          ? '${semanaSeleccionada!.start.day}/${semanaSeleccionada!.start.month} → ${semanaSeleccionada!.end.day}/${semanaSeleccionada!.end.month}'
                          : 'Inicio → Final',
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Cuadrilla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green[900])),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    value: cuadrillaSeleccionada,
                    isExpanded: true,
                    items: cuadrillas.map((c) => DropdownMenuItem(value: c['nombre'], child: Text(c['nombre']!))).toList(),
                    onChanged: (v) {
                      setState(() {
                        cuadrillaSeleccionada = v;
                        _filtrarEmpleados();
                      });
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Buscar e indicadores
  Widget _buildSearchAndIndicators() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: IndicatorCard(
            title: 'Empleados en cuadrilla',
            value: '${empleadosFiltrados.length}',
            icon: Icons.group,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: IndicatorCard(
            title: 'Total Acumulado',
            value: '\$${empleadosFiltrados.fold<int>(0, (s, e) => s + (e['neto'] as int))}',
            icon: Icons.attach_money,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: TextField(
            controller: searchController,
            onChanged: (_) => _filtrarEmpleados(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Sección central de tabla
  Widget _buildTableSection() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: EditableDataTableWidget(
          empleados: empleadosFiltrados,
          semanaSeleccionada: semanaSeleccionada,
          onChanged: _updateEmpleadoData,
          isExpanded: false,
        ),
      ),
    );
  }

  // 4. Barra de acciones
  void _onCerrarSemana() {
    if (semanaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una semana antes de cerrarla'),
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
  }

  void _onExportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad PDF no implementada'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _onExportExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad Excel no implementada'),
        backgroundColor: Colors.blue,
      ),
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
              DataTableWidget(
                columns: _buildNominaHeaders(),
                subHeaders: _buildNominaSubHeaders(),
                rows: _buildNominaRows(empleadosCuadrilla),
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

  // Helper methods for DataTableWidget
  List<String> _buildNominaHeaders() {
    final headers = <String>['Clave', 'Nombre'];
    final int diasCount = semanaSeleccionada != null
      ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
      : 7;
    DateTime date = semanaSeleccionada?.start ?? DateTime.now();
    for (int i = 0; i < diasCount; i++) {
      headers.add(semanaSeleccionada != null
        ? '${date.day}/${date.month}'
        : 'D${i+1}');
      if (semanaSeleccionada != null) date = date.add(const Duration(days:1));
    }
    headers.addAll(['Total', 'Debe', 'Subtotal', 'Comedor', 'Neto']);
    return headers;
  }

  List<List<String>> _buildNominaRows([List<Map<String, dynamic>>? sourceList]) {
    final list = sourceList ?? empleadosFiltrados;
    final rows = <List<String>>[];
    final int diasCount = semanaSeleccionada != null
      ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
      : 7;
    for (var emp in list) {
      final totalDias = (emp['dias'] as List<int>).fold(0, (a, b) => a + b);
      final debo = emp['debo'] as int? ?? 0;
      final subtotal = totalDias - debo;
      final comedor = emp['comedor'] as int? ?? 0;
      final neto = subtotal - comedor;
      final row = <String>[];
      row.add(emp['clave'] ?? '');
      row.add(emp['nombre'] ?? '');
      for (int i = 0; i < diasCount; i++) {
        row.add((emp['dias'][i] as int).toString());
      }
      // Total de días
      row.add(totalDias.toString());
      // Valores monetarios
      row.add('\$${debo}');
      row.add('\$${subtotal}');
      row.add('\$${comedor}');
      row.add('\$${neto}');
      rows.add(row);
    }
    return rows;
  }

  List<String> _buildNominaSubHeaders() {
    // Crea subencabezados: blancos para Clave y Nombre, 'TT' para cada día, y blancos para columnas monetarias
    final subHeaders = <String>['', ''];
    final int diasCount = semanaSeleccionada != null
      ? semanaSeleccionada!.end.difference(semanaSeleccionada!.start).inDays + 1
      : 7;
    for (int i = 0; i < diasCount; i++) {
      subHeaders.add('TT');
    }
    // Columnas finales: Total, Debe, Subtotal, Comedor, Neto
    subHeaders.addAll(['', '', '', '', '']);
    return subHeaders;
  }

    // Fin de _NominaScreenState
  }