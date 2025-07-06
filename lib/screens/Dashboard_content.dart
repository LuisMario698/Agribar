/// Contenido del panel principal (Dashboard) del sistema Agribar.
/// Muestra información relevante como métricas, gráficos y alertas.
/// Se adapta a diferentes tamaños de pantalla para una mejor experiencia de usuario.

import 'package:agribar/services/database_service.dart';
import 'package:flutter/material.dart';
import 'Dashboard_screen.dart';
import 'package:agribar/widgets/metric_card.dart';
import 'package:agribar/widgets/chart_card.dart';

/// Widget principal del contenido del Dashboard.
/// Muestra un resumen general del sistema incluyendo:
/// - Información del usuario actual
/// - Métricas clave
/// - Gráficos de rendimiento
/// - Alertas y notificaciones
class DashboardHomeContent extends StatefulWidget {
  final String userName; // Nombre del usuario actual
  final int userRole; // Rol del usuario (Admin, Supervisor, etc.)

  const DashboardHomeContent({
    required this.userName,
    required this.userRole,
    Key? key,
  }) : super(key: key);

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

/// Estado del DashboardHomeContent que gestiona:
/// - Visualización de porcentajes
/// - Layout responsivo
/// - Actualización de métricas
class _DashboardHomeContentState extends State<DashboardHomeContent> {
  bool showPercentages = true; // Toggle para mostrar/ocultar porcentajes
  double totalSemana = 0.0;
  int totalCuadrillas = 0;
int totalRegistros = 0;
int totalActividades = 0;

  @override
  void initState() {
    super.initState();
    // Cargar el total de nómina al iniciar
    cargarTotalNomina();
    cargarTotalCuadrillas();
    cargarTotalRegistros();
cargarTotalActividades();
  }
  Future<int> obtenerCantidadActividadesDiferentes() async {
  final dbService = DatabaseService();
  await dbService.connect();

  final results = await dbService.connection.query(
    '''
    SELECT COUNT(DISTINCT actividad)
    FROM (
      SELECT act_1 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_2 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_3 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_4 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_5 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_6 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      UNION ALL
      SELECT act_7 AS actividad FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ) AS todas_actividades
    WHERE actividad <> 0;
    '''
  );

  await dbService.close();

  if (results.isNotEmpty) {
    return int.parse(results.first[0].toString());
  } else {
    return 0;
  }
}
void cargarTotalActividades() async {
  final resultado = await obtenerCantidadActividadesDiferentes();
  setState(() {
    totalActividades = resultado;
  });
}
Future<int> obtenerNumeroRegistrosSemanaActual() async {
  final dbService = DatabaseService();
  await dbService.connect();

  final results = await dbService.connection.query(
    '''
    SELECT COUNT(*)
    FROM nomina_empleados_semanal
    WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    '''
  );

  await dbService.close();

  if (results.isNotEmpty) {
    return int.parse(results.first[0].toString());
  } else {
    return 0;
  }
}

void cargarTotalRegistros() async {
  final resultado = await obtenerNumeroRegistrosSemanaActual();
  setState(() {
    totalRegistros = resultado;
  });
}

  //Metodos
  Future<double> obtenerTotalNominaSemana() async {
    final dbService = DatabaseService();
    await dbService.connect();

    final results = await dbService.connection.query('''
SELECT total_semana
    FROM resumen_nomina
    WHERE id_semana = (SELECT MAX(id_semana) FROM resumen_nomina);
    ''');

    await dbService.close();

    if (results.isNotEmpty) {
      return double.parse(results.first[0].toString());
    } else {
      return 0.0;
    }
  }

  void cargarTotalNomina() async {
    final resultado = await obtenerTotalNominaSemana();
    setState(() {
      totalSemana = resultado;
    });
  }

  Future<int> obtenerTotalCuadrillasSemanaActual() async {
    final dbService = DatabaseService();
    await dbService.connect();

    final results = await dbService.connection.query('''
    SELECT COUNT(DISTINCT id_cuadrilla)
    FROM nomina_empleados_semanal
    WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');

    await dbService.close();

    if (results.isNotEmpty) {
      return int.parse(results.first[0].toString());
    } else {
      return 0;
    }
  }

  void cargarTotalCuadrillas() async {
    final resultado = await obtenerTotalCuadrillasSemanaActual();
    setState(() {
      totalCuadrillas = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Configuración de layout responsivo
            final isSmallScreen = constraints.maxWidth < 800;
            final cardWidth =
                (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();
            final metricCardWidth =
                (isSmallScreen ? constraints.maxWidth * 0.22 : 288).toDouble();
            final chartWidth =
                (isSmallScreen ? constraints.maxWidth * 0.45 : 600).toDouble();
            final chartHeight =
                (isSmallScreen ? constraints.maxWidth * 0.45 : 300).toDouble();

            // Contenedor principal con estilo de tarjeta
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
                    const SizedBox(height: 8),
                    // Sección superior: Información del usuario
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                            backgroundColor: Color(0xFF5BA829),
                            radius: 44,
                          ),
                          SizedBox(width: isSmallScreen ? 16 : 32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.userRole.toString() == '1'
                                    ? 'Administrador'
                                    : widget.userRole.toString() == '2'
                                        ? 'Supervisor'
                                        : 'Empleado',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 22,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 32),
                    // Indicadores clave
                    Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: Wrap(
                          spacing: isSmallScreen ? 16 : 24,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Empleados activos',
                                value: totalRegistros.toString(),
                                icon: Icons.person,
                                iconColor: Color(0xFF6B4F27),
                                isSmallScreen:
                                    isSmallScreen, // Pasar el estado de pantalla pequeña
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Cuadrillas activas',
                                value: totalCuadrillas.toString(),
                                icon: Icons.agriculture,
                                iconColor: Color(0xFF6B4F27),
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Nómina semanal',
                                value: '\$${totalSemana.toStringAsFixed(2)}',
                                icon: Icons.attach_money,
                                iconColor: Colors.orange,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Actividades semanales',
                                value: totalActividades.toString(),
                                icon: Icons.event_note,
                                iconColor: Colors.purple,
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Switch para porcentajes/datos centrado debajo de los indicadores
                    SizedBox(height: isSmallScreen ? 12 : 18),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mostrar: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: showPercentages,
                            onChanged:
                                (val) => setState(() => showPercentages = val),
                            activeColor: Colors.green,
                          ),
                          Text(
                            showPercentages ? 'Porcentajes' : 'Datos',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 18),
                    // Gráficas principales
                    Wrap(
                      spacing: isSmallScreen ? 16 : 24,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: ChartCard(
                            title: 'Pago por cuadrilla',
                            child: DashboardPieChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen:
                                isSmallScreen, // Pasar el estado de pantalla pequeña
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: ChartCard(
                            title: 'Pagos semanales',
                            child: DashboardBarChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: ChartCard(
                            title: 'Actividades por cuadrilla',
                            child: DashboardHorizontalBarChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: ChartCard(
                            title: 'Miembros por cuadrilla',
                            child: DashboardMembersBarChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    // Alertas rápidas
                    Center(
                      child: SizedBox(width: cardWidth, child: AlertCard()),
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
}

class AlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.error, color: Colors.red[400]),
              SizedBox(width: 8),
              Text(
                'Cuadrillas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Faltan capturas en 3 cuadrillas}'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[400]),
              SizedBox(width: 8),
              Text(
                'Empleados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Errores en 2 empleados}'),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Gráficas reutilizadas del Reportes_screen.dart ---
class DashboardPieChart extends StatelessWidget {
  final bool showPercentages;
  const DashboardPieChart({this.showPercentages = true, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    final cuadrillaRanking = [
      {'label': 'Indirectos', 'value': 52.1, 'color': Colors.black},
      {'label': 'Línea 1', 'value': 22.8, 'color': Colors.green},
      {'label': 'Línea 3', 'value': 13.9, 'color': Colors.lightGreen},
      {'label': 'Otras', 'value': 11.2, 'color': Colors.grey},
    ];
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _SolidPieChartPainter(cuadrillaRanking),
          ),
          const SizedBox(width: 32),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                cuadrillaRanking
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: e['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${e['label']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              showPercentages
                                  ? '${e['value']}%'
                                  : '(24${((e['value'] as double) * 1000).toStringAsFixed(0)})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class DashboardBarChart extends StatelessWidget {
  final bool showPercentages;
  const DashboardBarChart({this.showPercentages = true, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
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
}

class DashboardHorizontalBarChart extends StatelessWidget {
  final bool showPercentages;
  const DashboardHorizontalBarChart({this.showPercentages = true, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
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

// Nueva gráfica: Miembros por cuadrilla
class DashboardMembersBarChart extends StatelessWidget {
  final bool showPercentages;
  const DashboardMembersBarChart({this.showPercentages = true, Key? key})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    final cuadrillas = [
      {'label': 'Norte', 'miembros': 12},
      {'label': 'Sur', 'miembros': 9},
      {'label': 'Centro', 'miembros': 15},
      {'label': 'Este', 'miembros': 10},
      {'label': 'Oeste', 'miembros': 8},
    ];
    final max = cuadrillas
        .map((e) => e['miembros'] as int)
        .reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          cuadrillas
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          e['label'] as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 180 * ((e['miembros'] as int) / max),
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showPercentages
                            ? '${((e['miembros'] as int) / max * 100).toStringAsFixed(0)}%'
                            : '${e['miembros']}',
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
