import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../widgets/indicator_card.dart';

/// Widget modular para la fila de indicadores
/// Muestra las estadísticas de empleados, acumulado y total de semana
class IndicatorsRow extends StatelessWidget {
  final List<Map<String, dynamic>> empleadosFiltrados;
  final List<Map<String, dynamic>> optionsCuadrilla;
  final DateTime? startDate;
  final DateTime? endDate;

  const IndicatorsRow({
    super.key,
    required this.empleadosFiltrados,
    required this.optionsCuadrilla,
    this.startDate,
    this.endDate,
  });

  /// Calcula el total neto de un empleado
  double _calcularTotalEmpleado(Map<String, dynamic> emp) {
    final numDays = (endDate != null && startDate != null)
        ? endDate!.difference(startDate!).inDays + 1
        : 7;

    num _parseNum(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v;
      if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    final total = List.generate(
      numDays,
      (i) => _parseNum(emp['dia_${i}_s'] ?? emp['dia_$i']),
    ).fold<double>(0.0, (a, b) => a + b);

    final debe = _parseNum(emp['debe']);
    final comedorValue = emp['comedor'] == true
        ? 400.0
        : _parseNum(emp['comedor']);

    // Nueva regla: 'debe' (otras percepciones) se SUMA al subtotal
    final subtotal = total + debe;
    final totalNeto = subtotal - comedorValue;
    return totalNeto.toDouble();
  }

  /// Calcula el acumulado de la cuadrilla actual
  double _calcularAcumuladoCuadrilla() {
    return empleadosFiltrados.fold<double>(
      0,
      (sum, emp) => sum + _calcularTotalEmpleado(emp),
    );
  }

  /// Calcula el total de toda la semana (todas las cuadrillas)
  double _calcularTotalSemana() {
    return optionsCuadrilla.fold<double>(0, (sum, cuadrilla) {
      final empleados = List<Map<String, dynamic>>.from(
        cuadrilla['empleados'] ?? [],
      );
      final cuadrillaTotal = empleados.fold<double>(
        0,
        (empSum, emp) => empSum + _calcularTotalEmpleado(emp),
      );
      return sum + cuadrillaTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: IndicatorCard(
              title: 'Empleados',
              value: '${empleadosFiltrados.length}',
              icon: Icons.people,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: IndicatorCard(
              title: 'Acumulado',
              value: '\$${_calcularAcumuladoCuadrilla().toStringAsFixed(2)}', // punto decimal
              icon: Icons.payments,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: IndicatorCard(
              title: 'Total semana',
              value: '\$${_calcularTotalSemana().toStringAsFixed(2)}', // punto decimal
              icon: Icons.monetization_on,
            ),
          ),
        ],
      ),
    );
  }
}
