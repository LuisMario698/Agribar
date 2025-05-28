import 'package:flutter/material.dart';
import '../widgets/common/custom_input_field.dart';
import '../widgets/common/custom_dropdown_field.dart';
import '../widgets/common/custom_button.dart';
import '../widgets_shared/generic_search_bar.dart';
import '../widgets/common/page_header.dart';
import '../widgets/common/custom_date_picker_field.dart';
import '../widgets/common/custom_snackbar.dart';

// Archivo: Actividades_content.dart
// Pantalla para la gestión de actividades en el sistema Agribar
// Estructura profesionalizada y documentada en español
// No modificar la lógica ni la interfaz visual sin justificación técnica

/// Pantalla de gestión de actividades que mantiene el diseño original
class ActividadesContent extends StatefulWidget {
  @override
  State<ActividadesContent> createState() => _ActividadesContentState();
}

class _ActividadesContentState extends State<ActividadesContent> {
  // Controladores de texto
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController claveController = TextEditingController();
  final TextEditingController importeController = TextEditingController();
  DateTime? fecha;
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Variables para filtrado por cuadrilla
  String? cuadrillaSeleccionada;

  // Lista de cuadrillas disponibles (similar a nómina y reportes)
  final List<Map<String, String>> cuadrillas = [
    {'nombre': 'Todas las cuadrillas', 'clave': 'ALL'},
    {'nombre': 'Indirectos', 'clave': '000001+390'},
    {'nombre': 'Linea 1', 'clave': '000002+390'},
    {'nombre': 'Linea 2', 'clave': '000003+390'},
    {'nombre': 'Linea 3', 'clave': '000004+390'},
    {'nombre': 'Linea 4', 'clave': '000005+390'},
    {'nombre': 'Linea 5', 'clave': '000006+390'},
    {'nombre': 'Linea 6', 'clave': '000007+390'},
    {'nombre': 'Linea 7', 'clave': '000008+390'},
    {'nombre': 'Linea 8', 'clave': '000009+390'},
    {'nombre': 'Linea 9', 'clave': '000010+390'},
    {'nombre': 'Linea 10', 'clave': '000011+390'},
    {'nombre': 'Linea 11', 'clave': '000012+390'},
    {'nombre': 'Linea 12', 'clave': '000013+390'},
    {'nombre': 'Linea 13', 'clave': '000014+390'},
    {'nombre': 'Linea 14', 'clave': '000015+390'},
    {'nombre': 'Linea 15', 'clave': '000016+390'},
    {'nombre': 'Linea 16', 'clave': '000017+390'},
  ];

  // Lista de actividades con datos de ejemplo (ahora incluye cuadrilla)
  final List<List<String>> actividades = [
    // [Clave, Fecha, Importe, Actividad, Cuadrilla]
    ['1', '25/04/2025', '\u024300', 'Destajo', 'Indirectos'],
    ['1315', '25/04/2025', '\u024300', 'Tapadora', 'Linea 1'],
    ['1305', '25/04/2025', '\u024200', 'Limpieza', 'Linea 2'],
    ['1400', '25/04/2025', '\u024500', 'Cosecha', 'Linea 3'],
    ['1500', '25/04/2025', '\u024100', 'Riego', 'Linea 4'],
    ['1600', '25/04/2025', '\u024350', 'Fertilización', 'Linea 5'],
    ['1700', '25/04/2025', '\u024250', 'Poda', 'Linea 6'],
    ['1800', '25/04/2025', '\u024400', 'Transplante', 'Linea 7'],
    ['1900', '25/04/2025', '\u024150', 'Siembra', 'Linea 8'],
    [
      '2000',
      '25/04/2025',
      '\u024300',
      'Aplicación de Plaguicida',
      'Indirectos',
    ],
    ['2100', '25/04/2025', '\u024180', 'Deshierbe', 'Linea 9'],
    ['2200', '25/04/2025', '\u024320', 'Empaque', 'Linea 10'],
    ['2300', '25/04/2025', '\u024210', 'Carga', 'Linea 11'],
    ['2400', '25/04/2025', '\u024290', 'Selección', 'Linea 12'],
    ['2500', '25/04/2025', '\u024160', 'Supervisión', 'Indirectos'],
    ['2600', '25/04/2025', '\u024380', 'Mantenimiento', 'Linea 13'],
  ];

  // Lista de opciones para el dropdown de actividades
  final List<String> actividadesOptions = [
    'Nombre',
    'Destajo',
    'Tapadora',
    'Limpieza',
    'Cosecha',
    'Riego',
    'Fertilización',
    'Poda',
    'Transplante',
    'Siembra',
    'Aplicación de Plaguicida',
    'Deshierbe',
    'Empaque',
    'Carga',
  ];

  @override
  void initState() {
    super.initState();
    cuadrillaSeleccionada =
        cuadrillas.first['nombre']; // "Todas las cuadrillas"
  }

  /// Obtiene las actividades filtradas según el texto de búsqueda y cuadrilla seleccionada
  List<List<String>> get actividadesFiltradas {
    String query = searchController.text.toLowerCase();
    List<List<String>> resultado = actividades;

    // Filtrar por cuadrilla si no es "Todas las cuadrillas"
    if (cuadrillaSeleccionada != null &&
        cuadrillaSeleccionada != 'Todas las cuadrillas') {
      resultado =
          resultado.where((row) => row[4] == cuadrillaSeleccionada).toList();
    }

    // Filtrar por texto de búsqueda
    if (query.isNotEmpty) {
      resultado =
          resultado
              .where(
                (row) => row.any((cell) => cell.toLowerCase().contains(query)),
              )
              .toList();
    }

    return resultado;
  }

  /// Obtiene estadísticas de actividades por cuadrilla
  Map<String, int> get estadisticasPorCuadrilla {
    Map<String, int> stats = {};
    for (var actividad in actividades) {
      String cuadrilla = actividad[4];
      stats[cuadrilla] = (stats[cuadrilla] ?? 0) + 1;
    }
    return stats;
  }

  /// Obtiene el total de importes por cuadrilla
  Map<String, double> get importesPorCuadrilla {
    Map<String, double> totales = {};
    for (var actividad in actividades) {
      String cuadrilla = actividad[4];
      String importeStr = actividad[2].replaceAll('\u0243', '');
      double importe = double.tryParse(importeStr) ?? 0.0;
      totales[cuadrilla] = (totales[cuadrilla] ?? 0.0) + importe;
    }
    return totales;
  }

  /// Agrega una nueva actividad a la lista
  void agregarActividad() {
    if (claveController.text.isEmpty ||
        importeController.text.isEmpty ||
        fechaController.text.isEmpty ||
        nombreController.text.isEmpty ||
        cuadrillaSeleccionada == null ||
        cuadrillaSeleccionada == 'Todas las cuadrillas') {
      // Mostrar mensaje de error si hay campos vacíos o no se seleccionó cuadrilla específica
      CustomSnackBar.showError(
        context,
        'Por favor completa todos los campos y selecciona una cuadrilla específica',
      );
      return;
    }

    setState(() {
      actividades.add([
        claveController.text,
        fechaController.text,
        importeController.text,
        nombreController.text,
        cuadrillaSeleccionada!, // Agregar cuadrilla
      ]);
      _limpiarCampos();
    });

    // Mostrar mensaje de éxito
    CustomSnackBar.showSuccess(
      context,
      'Actividad agregada correctamente a ${cuadrillaSeleccionada}',
    );
  }

  /// Limpia todos los campos del formulario
  void _limpiarCampos() {
    claveController.clear();
    importeController.clear();
    fecha = null;
    fechaController.clear();
    nombreController.clear();
  }

  /// Construye un elemento de métrica para mostrar estadísticas
  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Color(0xFF0B7A2F), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B7A2F),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            final cardWidth =
                (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();

            return Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      'Gestión de Actividades',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Contenido específico de actividades
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creación de actividad',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 900;
                            return Column(
                              children: [
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    // Campo de Clave
                                    CustomInputField(
                                      controller: claveController,
                                      label: 'Clave',
                                      width: isSmall ? double.infinity : 250,
                                      fillColor: Color(0xFFEDEDED),
                                    ),
                                    // Campo de Fecha
                                    CustomDatePickerField(
                                      controller: fechaController,
                                      label: 'Fecha',
                                      selectedDate: fecha,
                                      onDateSelected: (selectedDate) {
                                        setState(() {
                                          fecha = selectedDate;
                                        });
                                      },
                                      width: isSmall ? double.infinity : 250,
                                      fillColor: Color(0xFFEDEDED),
                                    ),
                                    // Campo de Importe
                                    CustomInputField(
                                      controller: importeController,
                                      label: 'Importe',
                                      width: isSmall ? double.infinity : 250,
                                      fillColor: Color(0xFFEDEDED),
                                    ),
                                    // Dropdown de Actividad
                                    CustomDropdownField<String>(
                                      label: 'Actividad',
                                      value:
                                          nombreController.text.isEmpty
                                              ? 'Nombre'
                                              : nombreController.text,
                                      items: actividadesOptions,
                                      itemLabel: (item) => item,
                                      onChanged: (value) {
                                        setState(() {
                                          nombreController.text = value!;
                                        });
                                      },
                                      width: isSmall ? double.infinity : 250,
                                      fillColor: Color(0xFFEDEDED),
                                    ),
                                    // Dropdown de Cuadrilla
                                    CustomDropdownField<String>(
                                      label: 'Cuadrilla',
                                      value:
                                          cuadrillaSeleccionada ==
                                                  'Todas las cuadrillas'
                                              ? null
                                              : cuadrillaSeleccionada,
                                      items:
                                          cuadrillas
                                              .where(
                                                (c) =>
                                                    c['nombre'] !=
                                                    'Todas las cuadrillas',
                                              )
                                              .map((c) => c['nombre']!)
                                              .toList(),
                                      itemLabel: (item) => item,
                                      onChanged: (value) {
                                        setState(() {
                                          cuadrillaSeleccionada = value;
                                        });
                                      },
                                      width: isSmall ? double.infinity : 250,
                                      fillColor: Color(0xFFEDEDED),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 32),
                                Center(
                                  child: CustomButton(
                                    text: 'Crear',
                                    onPressed: agregarActividad,
                                    type: ButtonType.primary,
                                    width: 160,
                                    backgroundColor: Color(0xFF0B7A2F),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 19),

                    // Tabla de actividades
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageHeader(
                          title: 'Tabla de actividades',
                          backgroundColor: Colors.transparent,
                          textColor: Color(0xFF23611C),
                        ),
                        SizedBox(height: 24),

                        // Filtros y métricas
                        Row(
                          children: [
                            // Filtro de cuadrilla
                            Expanded(
                              flex: 2,
                              child: CustomDropdownField<String>(
                                label: 'Filtrar por cuadrilla',
                                value: cuadrillaSeleccionada,
                                items:
                                    cuadrillas
                                        .map((c) => c['nombre']!)
                                        .toList(),
                                itemLabel: (item) => item,
                                onChanged: (value) {
                                  setState(() {
                                    cuadrillaSeleccionada = value;
                                  });
                                },
                                fillColor: Color(0xFFF3F1EA),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Barra de búsqueda
                            Expanded(
                              flex: 3,
                              child: GenericSearchBar(
                                controller: searchController,
                                onChanged: (_) => setState(() {}),
                                hintText: 'Buscar actividades...',
                                fillColor: Color(0xFFF3F1EA),
                                searchIcon: Icons.search,
                                showSearchButton: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Métricas rápidas
                        if (cuadrillaSeleccionada !=
                            'Todas las cuadrillas') ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F5E8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF0B7A2F),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricItem(
                                  'Actividades',
                                  '${estadisticasPorCuadrilla[cuadrillaSeleccionada] ?? 0}',
                                  Icons.assignment,
                                ),
                                _buildMetricItem(
                                  'Total Importe',
                                  '\$${(importesPorCuadrilla[cuadrillaSeleccionada] ?? 0.0).toStringAsFixed(0)}',
                                  Icons.attach_money,
                                ),
                                _buildMetricItem(
                                  'Promedio',
                                  '\$${((importesPorCuadrilla[cuadrillaSeleccionada] ?? 0.0) / (estadisticasPorCuadrilla[cuadrillaSeleccionada] ?? 1)).toStringAsFixed(0)}',
                                  Icons.trending_up,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        SizedBox(height: 24),
                        Container(
                          height: 450,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: DataTable(
                                        columnSpacing: 24,
                                        border: TableBorder.all(
                                          color: Color(0xFFE5E5E5),
                                          width: 1.2,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              Color(0xFFF3F3F3),
                                            ),
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Clave',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Fecha',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Importe',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Actividad',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Cuadrilla',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows:
                                            actividadesFiltradas.map((
                                              actividad,
                                            ) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(actividad[0]),
                                                  ), // Clave
                                                  DataCell(
                                                    Text(actividad[1]),
                                                  ), // Fecha
                                                  DataCell(
                                                    Text(actividad[2]),
                                                  ), // Importe
                                                  DataCell(
                                                    Text(actividad[3]),
                                                  ), // Actividad
                                                  DataCell(
                                                    Text(actividad[4]),
                                                  ), // Cuadrilla
                                                ],
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Limpieza de controladores
    nombreController.dispose();
    claveController.dispose();
    importeController.dispose();
    fechaController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
