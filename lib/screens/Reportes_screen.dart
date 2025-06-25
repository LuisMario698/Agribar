import 'package:agribar/services/database_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import '../widgets/custom_search_bar.dart';
import '../widgets/filter_button.dart';
import '../widgets/date_selector.dart';
import 'dart:io';
import '../widgets/export_button_group.dart';


import '../widgets/reportes_table_dialog.dart';

/// Pantalla de reportes del sistema Agribar.
/// 
/// Esta pantalla implementa la visualización y generación de reportes,
/// permitiendo al usuario:
/// - Filtrar datos por empleado, cuadrilla o actividad
/// - Seleccionar rangos de fechas específicos
/// - Visualizar datos en tablas y gráficos
/// - Exportar reportes en diferentes formatos
/// 
/// La pantalla utiliza varios widgets reutilizables para:
/// - Filtrado y búsqueda (CustomSearchBar)
/// - Selección de fechas (DateSelector)
/// - Visualización de datos (DataTableWidget)
/// - Gráficos estadísticos (ChartWidget)
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

/// Estado de la pantalla de reportes que gestiona:
/// - Filtros seleccionados
/// - Fechas del reporte
/// - Datos visualizados
/// - Scroll de tablas
/// 
/// Funcionalidad principal:
/// - Actualización dinámica de datos según filtros
/// - Gestión del scroll horizontal y vertical
/// - Exportación de reportes personalizados
/// - Visualización de gráficos estadísticos
class _ReportesScreenState extends State<ReportesScreen> {
  int selectedFilter = 1; // 0: Empleado, 1: Cuadrilla, 2: Actividad
  final TextEditingController searchController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  int tipoReporteSeleccionado = 0;// 0: Empleado, 1: Cuadrilla, 2: Actividad
List<Map<String, String>> empleadosData = [];
List<Map<String, String>> reporteData = [];

  // Controladores para el scroll de la tabla
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

Future<void> exportarReporteAExcel() async {
  List<Map<String, String>> dataExportar;

  String nombreArchivo;
  List<String> headers;

  switch (selectedFilter) {
    case 0:
      dataExportar = empleadosData;
      nombreArchivo = 'reporte_empleados';
      headers = ['id_empleado', 'codigo', 'nombre', 'fecha', 'total'];
      break;
    case 1:
      dataExportar = cuadrillasData;
      nombreArchivo = 'reporte_cuadrillas';
      headers = ['id_cuadrilla', 'cuadrilla', 'total'];
      break;
    case 2:
      dataExportar = actividadesData;
      nombreArchivo = 'reporte_actividades';
      headers = ['codigo', 'nombre', 'fecha', 'responsable', 'cuadrilla'];
      break;
    default:
      return;
  }

  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];

  // Encabezados
  sheet.appendRow(headers);

  // Datos
  for (var row in dataExportar) {
    final rowData = headers.map((h) => row[h] ?? '').toList();
    sheet.appendRow(rowData);
  }

  // Guardar archivo
 final directory = Directory.current.path;
final filePath = '$directory/$nombreArchivo.xlsx';
  final fileBytes = excel.encode();

  final file = File(filePath);
  await file.writeAsBytes(fileBytes!);

  print('📁 Archivo exportado en: $filePath');
}
  // Datos de ejemplo para cada filtro

   List<Map<String, String>> cuadrillasData = [];

  final List<Map<String, String>> actividadesData = [
    {
      'codigo': 'A-01',
      'nombre': 'Cosecha',
      'fecha': '01/06/2024',
      'responsable': 'Juan Pérez',
      'cuadrilla': 'Cuadrilla Norte',
    },
    {
      'codigo': 'A-02',
      'nombre': 'Siembra',
      'fecha': '03/06/2024',
      'responsable': 'Ana López',
      'cuadrilla': 'Cuadrilla Sur',
    },
    {
      'codigo': 'A-03',
      'nombre': 'Riego',
      'fecha': '05/06/2024',
      'responsable': 'Carlos Ruiz',
      'cuadrilla': 'Cuadrilla Centro',
    },
    {
      'codigo': 'A-04',
      'nombre': 'Fertilización',
      'fecha': '07/06/2024',
      'responsable': 'Laura Torres',
      'cuadrilla': 'Cuadrilla Este',
    },
    {
      'codigo': 'A-05',
      'nombre': 'Poda',
      'fecha': '09/06/2024',
      'responsable': 'Miguel Díaz',
      'cuadrilla': 'Cuadrilla Oeste',
    },
    {
      'codigo': 'A-06',
      'nombre': 'Cosecha',
      'fecha': '11/06/2024',
      'responsable': 'Sofía Jiménez',
      'cuadrilla': 'Cuadrilla Altiplano',
    },
   
    {
      'codigo': 'A-14',
      'nombre': 'Siembra',
      'fecha': '27/06/2024',
      'responsable': 'Rosa Jiménez',
      'cuadrilla': 'Cuadrilla Sierra',
    },
    {
      'codigo': 'A-15',
      'nombre': 'Riego',
      'fecha': '29/06/2024',
      'responsable': 'Pedro Romero',
      'cuadrilla': 'Cuadrilla Bosque',
    },
   
   
    {
      'codigo': 'A-20',
      'nombre': 'Riego',
      'fecha': '09/07/2024',
      'responsable': 'Héctor Ruiz',
      'cuadrilla': 'Cuadrilla Desierto',
    },
  ];

  List<Map<String, String>> get filteredData {
    String query = searchController.text.trim().toLowerCase();
    if (selectedFilter == 0) {
      // Empleados
      if (query.isEmpty) return empleadosData;
      return empleadosData
          .where(
            (row) => row.values.any((v) => v.toLowerCase().contains(query)),
          )
          .toList();
    } else if (selectedFilter == 1) {
      // Cuadrillas
      if (query.isEmpty) return cuadrillasData;
      return cuadrillasData
          .where(
            (row) => row.values.any((v) => v.toLowerCase().contains(query)),
          )
          .toList();
    } else {
      // Actividades
      if (query.isEmpty) return actividadesData;
      return actividadesData
          .where(
            (row) => row.values.any((v) => v.toLowerCase().contains(query)),
          )
          .toList();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }


  void showFullScreenDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        List<Map<String, String>> tableData = [];
        final dialogHorizontalController = ScrollController();
        final dialogVerticalController = ScrollController();
        
        switch (selectedFilter) {
          case 0:
            tableData = empleadosData;
            break;
          case 1:
            tableData = cuadrillasData;
            break;
          case 2:
            tableData = actividadesData;
            break;
        }

        return ReportesTableDialog(
          selectedFilter: selectedFilter,
          data: tableData,
          onClose: () {
            dialogHorizontalController.dispose();
            dialogVerticalController.dispose();
            Navigator.of(dialogContext).pop();
          },
          horizontalController: dialogHorizontalController,
          verticalController: dialogVerticalController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  return Center(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth < 800 ? constraints.maxWidth * 0.9 : 1400).toDouble();

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Container(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de búsqueda y botones
                    CustomSearchBar(
                      controller: searchController,
                      onSearchChanged: (_) => setState(() {}),
                      onSearchTap: () => setState(() {}),
                      onInfoTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Filtros y fechas centrados
                    Center(
                      child: Column(
                        children: [                          
                          FilterBar(
                            filters: const ['Empleados', 'Cuadrilla', 'Actividad'],
                            selectedIndex: selectedFilter,
                          onFilterChanged: (index) async {
  setState(() {
    selectedFilter = index;
      tipoReporteSeleccionado = index;
  });
  if (index == 0) {
    // Solo si aún no se ha cargado
    if (empleadosData.isEmpty) {
      final data = await obtenerReportePorEmpleado();
      setState(() {
        empleadosData = data;
      });
    }
  }
  if (index == 1) {
    // Solo si aún no se ha cargado
    if (cuadrillasData.isEmpty) {
      final data = await obtenerReportePorCuadrilla();
      setState(() {
        cuadrillasData = data;
      });
    }
  }
}



                          ),
                          const SizedBox(height: 10),                          DateRangeSelector(
                            startDate: startDate,
                            endDate: endDate,
                            onDateSelect: (isStart) => _selectDate(context, isStart),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Botones superiores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.fullscreen, color: Color(0xFF0B7A2F), size: 28),
                          tooltip: 'Expandir tabla',
                          onPressed: () {                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.2),
                              builder: (context) {
                                // Crear controladores separados para el diálogo
                                final dialogHorizontalController = ScrollController();
                                final dialogVerticalController = ScrollController();
                                
                                List<Map<String, String>> tableData = [];
                                
                                switch (selectedFilter) {
                                  case 0:
                                    tableData = empleadosData;
                                    break;
                                  case 1:
                                    tableData = cuadrillasData;
                                    break;
                                  case 2:
                                    tableData = actividadesData;
                                    break;
                                }
                                
                                return ReportesTableDialog(
                                  selectedFilter: selectedFilter,
                                  data: tableData,
                                  onClose: () {
                                    // Asegurarse de liberar los controladores
                                    dialogHorizontalController.dispose();
                                    dialogVerticalController.dispose();
                                    Navigator.of(context).pop();
                                  },
                                  horizontalController: dialogHorizontalController,
                                  verticalController: dialogVerticalController,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.bar_chart, color: Colors.blue, size: 28),
                          tooltip: 'Ver gráficas',
                          onPressed: () {
                            setState(() {
                              showCharts = !showCharts;
                            });
                          },
                        ),
                      ],
                    ),

                    // Tabla
                    Center(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(vertical: 0),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: SizedBox(
                            width: 1224,
                            height: 500,
                            child: Scrollbar(
                              controller: _horizontalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _horizontalController,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 1224),
                                  child: Scrollbar(
                                    controller: _verticalController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _verticalController,
                                      scrollDirection: Axis.vertical,
                                      child: _buildTableWithBorders(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Gráficas
                    if (showCharts)
                      Center(
                        child: SizedBox(
                          width: 1000,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('Mostrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Switch(
                                      value: showPercentages,
                                      onChanged: (val) => setState(() => showPercentages = val),
                                      activeColor: Colors.green,
                                    ),
                                    Text(
                                      showPercentages ? 'Porcentajes' : 'Datos',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        margin: const EdgeInsets.all(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: SizedBox(
                                            height: 220,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Pago por cuadrilla',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Tooltip(
                                                      message: 'Distribución del pago total semanal entre las cuadrillas.',
                                                      child: Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(child: _buildPieChartSection()),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        margin: const EdgeInsets.all(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: SizedBox(
                                            height: 220,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Pagos semanales',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Tooltip(
                                                      message: 'Distribución del pago total semanal entre las cuadrillas.',
                                                      child: Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(child: _buildBarChartSection()),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  margin: const EdgeInsets.all(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Actividades por cuadrilla',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                            const SizedBox(width: 6),
                                            Tooltip(
                                              message: 'Distribución de las actividades entre las cuadrillas.',
                                              child: Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildHorizontalBarChartSection(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Botones de exportar
                    ExportButtonGroup(
                      onPdfExport: () {
                        // TODO: Implement PDF export functionality
                      },
                      onExcelExport: () {
                exportarReporteAExcel();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}



  // Tabla con bordes en todas las celdas y tamaño de fuente reducido
  Widget _buildTableWithBorders() {
    List<String> columns;
    List<List<String>> rows;
    if (selectedFilter == 0) {
      columns = [
        'Id empleado',
        'Codigo',
        'Nombre',
        'Fecha de pago',
        'Total',
       
      ];
      rows =
          filteredData
              .map(
                (row) => [
                  row['id_empleado'] ?? '',
                  row['codigo'] ?? '',
                  row['nombre'] ?? '',
                  row['fecha'] ?? '',
                  row['total'] ?? '',
                 
                ],
              )
              .toList();
    } else if (selectedFilter == 1) {
      columns = ['ID Cuadrilla', 'Nombre', 'Total'];
      rows =
          filteredData
              .map(
                (row) => [
                  row['id_cuadrilla'] ?? '',
                  row['cuadrilla'] ?? '',
                  row['total'] ?? '',
                ],
              )
              .toList();
    } else {
      columns = ['Código', 'Nombre', 'Fecha', 'Responsable', 'Cuadrilla'];
      rows =
          filteredData
              .map(
                (row) => [
                  row['codigo'] ?? '',
                  row['nombre'] ?? '',
                  row['fecha'] ?? '',
                  row['responsable'] ?? '',
                  row['cuadrilla'] ?? '',
                ],
              )
              .toList();
    }
    return Table(
      border: TableBorder.all(color: Colors.grey.shade500, width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        for (int i = 0; i < columns.length; i++)
          i: const IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFD3D3D3)),
          children:
              columns
                  .map(
                    (col) => Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        col,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        ...rows.map(
          (row) => TableRow(
            children:
                row
                    .map(
                      (cell) => Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        child: Text(cell, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  // Al inicio del estado:
  bool showCharts = false;
  bool showPercentages = true;

  // ...

  // Reemplaza _buildChartsSection() por tres métodos separados:
  Widget _buildPieChartSection() {
    final cuadrillaRanking = [
      {'label': 'Indirectos', 'value': 52.1, 'color': Colors.black},
      {'label': 'Línea 1', 'value': 22.8, 'color': Colors.green},
      {'label': 'Línea 3', 'value': 13.9, 'color': Colors.lightGreen},
      {'label': 'Otras', 'value': 11.2, 'color': Colors.grey},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(100, 100),
          painter: _SolidPieChartPainter(cuadrillaRanking),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              cuadrillaRanking
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${e['label']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            showPercentages
                                ? '${e['value']}%'
                                : '(24${((e['value'] as double) * 1000).toStringAsFixed(0)})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildBarChartSection() {
    final pagosSemanales = [300, 600, 350, 700, 200, 400];
    final dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    final maxPago = pagosSemanales.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(pagosSemanales.length, (i) {
          final color =
              i == 2
                  ? Colors.black
                  : i == 1
                  ? Colors.green[300]
                  : i == 3
                  ? Colors.green[700]
                  : Colors.grey[400];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    showPercentages
                        ? '${((pagosSemanales[i] / maxPago) * 100).toStringAsFixed(0)}%'
                        : '24${pagosSemanales[i]}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 120 * (pagosSemanales[i] / maxPago),
                    width: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dias[i], style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHorizontalBarChartSection() {
    final actividadesPorCuadrilla = [
      {'label': 'Cosecha', 'cuadrillas': 4},
      {'label': 'Siembra', 'cuadrillas': 3},
      {'label': 'Riego', 'cuadrillas': 2},
      {'label': 'Poda', 'cuadrillas': 1},
    ];
    final max = 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actividadesPorCuadrilla
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e['label'] as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 220 * ((e['cuadrillas'] as int) / max),
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showPercentages
                            ? '${((e['cuadrillas'] as int) / max * 100).toStringAsFixed(0)}%'
                            : '${e['cuadrillas']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _SolidPieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _SolidPieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.fold(0, (sum, e) => sum + (e['value'] as double));
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    double startRadian = -3.14 / 2;
    const double gapRadian = 0.06; // Separación entre segmentos
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24;
    for (var e in data) {
      final sweepRadian =
          (e['value'] as double) / total * (2 * 3.141592653589793) - gapRadian;
      paint.color = e['color'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 12),
        startRadian,
        sweepRadian,
        false,
        paint,
      );
      startRadian += sweepRadian + gapRadian;
    }
    // Círculo blanco central
    final innerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 24, innerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
