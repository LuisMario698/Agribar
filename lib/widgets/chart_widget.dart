import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A generic chart widget that can render different types of charts.
class ChartWidget extends StatelessWidget {
  final List<BarChartGroupData>? barData;
  final List<PieChartSectionData>? pieData;
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
