import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget genérico para gráficos estadísticos.
///
/// Este widget puede renderizar diferentes tipos de gráficos:
/// - Gráficos de barras para comparaciones
/// - Gráficos circulares para distribuciones
///
/// Características principales:
/// - Altura configurable
/// - Soporte para múltiples tipos de gráficos
/// - Integración con fl_chart
/// - Diseño responsivo
///
/// Se utiliza en la pantalla de reportes y dashboard para visualizar:
/// - Distribución de actividades
/// - Comparativas de nómina
/// - Estadísticas de empleados
class ChartWidget extends StatelessWidget {
  /// Datos para gráfico de barras (opcional)
  final List<BarChartGroupData>? barData;
  /// Datos para gráfico circular (opcional)
  final List<PieChartSectionData>? pieData;
  /// Altura del gráfico en píxeles
  final double height;

  const ChartWidget({
    Key? key,
    this.barData,
    this.pieData,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (barData != null) {
      return SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            barGroups: barData!,
            titlesData: FlTitlesData(show: true),
          ),
        ),
      );
    } else if (pieData != null) {
      return SizedBox(
        height: height,
        child: PieChart(
          PieChartData(
            sections: pieData!,
          ),
        ),
      );
    }
    return const SizedBox();
  }
}
