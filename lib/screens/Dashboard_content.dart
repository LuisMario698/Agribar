/// Contenido del panel principal (Dashboard) del sistema Agribar.
/// Muestra información relevante como métricas, gráficos y alertas.
/// Se adapta a diferentes tamaños de pantalla para una mejor experiencia de usuario.

import 'package:flutter/material.dart';
import 'Dashboard_screen.dart';
import '../widgets/common/metric_card.dart';
import '../widgets/common/custom_card.dart';

/// Widget principal del contenido del Dashboard.
/// Muestra un resumen general del sistema incluyendo:
/// - Información del usuario actual
/// - Métricas clave
/// - Gráficos de rendimiento
/// - Alertas y notificaciones
class DashboardHomeContent extends StatefulWidget {
  final String userName; // Nombre del usuario actual
  final String userRole; // Rol del usuario (Admin, Supervisor, etc.)

  const DashboardHomeContent({
    this.userName = 'Juan Pérez',
    this.userRole = 'Supervisor',
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
                                widget.userRole,
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
                                value: '87',
                                icon: Icons.person,
                                iconColor: Color(0xFF6B4F27),
                                margin: EdgeInsets.only(
                                  bottom: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 12 : 18,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Cuadrillas activas',
                                value: '7',
                                icon: Icons.agriculture,
                                iconColor: Color(0xFF6B4F27),
                                margin: EdgeInsets.only(
                                  bottom: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 12 : 18,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Nómina semanal',
                                value: '\u0024120,000',
                                icon: Icons.attach_money,
                                iconColor: Colors.orange,
                                margin: EdgeInsets.only(
                                  bottom: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 12 : 18,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: metricCardWidth,
                              child: MetricCard(
                                title: 'Actividades hoy',
                                value: '5',
                                icon: Icons.event_note,
                                iconColor: Colors.purple,
                                margin: EdgeInsets.only(
                                  bottom: isSmallScreen ? 12 : 16,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 12 : 18,
                                ),
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
                          child: _buildChartCard(
                            'Pago por cuadrilla',
                            DashboardPieChart(showPercentages: showPercentages),
                            isSmallScreen,
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: _buildChartCard(
                            'Pagos semanales',
                            DashboardBarChart(showPercentages: showPercentages),
                            isSmallScreen,
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: _buildChartCard(
                            'Actividades por cuadrilla',
                            DashboardHorizontalBarChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen,
                          ),
                        ),
                        SizedBox(
                          width: chartWidth,
                          height: chartHeight,
                          child: _buildChartCard(
                            'Miembros por cuadrilla',
                            DashboardMembersBarChart(
                              showPercentages: showPercentages,
                            ),
                            isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    // Alertas rápidas
                    Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: _buildAlertCard(),
                      ),
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

  // Helper method para construir una tarjeta de gráfico con CustomCard
  Widget _buildChartCard(String title, Widget child, bool isSmallScreen) {
    final adjustedPadding = isSmallScreen ? 16.0 : 20.0;

    return CustomCard(
      padding: EdgeInsets.all(adjustedPadding),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
      ],
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Helper method para construir la tarjeta de alertas
  Widget _buildAlertCard() {
    return CustomCard(
      padding: EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
      ],
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
          _buildAlertItem(
            'Cuadrilla Línea 7 sin actividad durante 3 días',
            Icons.warning,
            Colors.orange,
          ),
          Divider(),
          _buildAlertItem(
            'Reporte semanal pendiente de cierre',
            Icons.assignment_late,
            Colors.red,
          ),
          Divider(),
          _buildAlertItem(
            'Nuevo mensaje de Francisco Rodríguez',
            Icons.mail,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 16),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

// Clases para los diferentes gráficos de la pantalla
// Se mantienen igual para no afectar la funcionalidad
// Solo usamos widgets modularizados para los contenedores

class DashboardPieChart extends StatelessWidget {
  final bool showPercentages;

  const DashboardPieChart({required this.showPercentages});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorLabel('Línea 1', Color(0xFF66BB6A)),
                _buildColorLabel('Línea 2', Color(0xFF42A5F5)),
                _buildColorLabel('Línea 3', Color(0xFFFFB74D)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              showPercentages
                  ? 'Porcentajes de distribución'
                  : 'Valores nominales en pesos',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLabel(String text, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class DashboardBarChart extends StatelessWidget {
  final bool showPercentages;

  const DashboardBarChart({required this.showPercentages});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Gráfica de barras - ${showPercentages ? "Porcentajes" : "Valores"}',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class DashboardHorizontalBarChart extends StatelessWidget {
  final bool showPercentages;

  const DashboardHorizontalBarChart({required this.showPercentages});

  @override
  Widget build(BuildContext context) {
    final actividadesPorCuadrilla = [
      {'label': 'Línea 1', 'cuadrillas': 4},
      {'label': 'Línea 2', 'cuadrillas': 3},
      {'label': 'Línea 3', 'cuadrillas': 2},
      {'label': 'Línea 4', 'cuadrillas': 1},
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
                            ? '${((e['cuadrillas'] as int) / max * 100).round()}%'
                            : '${e['cuadrillas']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class DashboardMembersBarChart extends StatelessWidget {
  final bool showPercentages;

  const DashboardMembersBarChart({required this.showPercentages});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Gráfica de miembros - ${showPercentages ? "Porcentajes" : "Valores"}',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
