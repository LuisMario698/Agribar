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
    // Semana estándar fija de 7 días
    const int numDays = 7;
    double total = 0.0;
    for (int i = 0; i < numDays; i++) {
      final raw = emp['dia_${i}_s'] ?? emp['dia_$i'];
      final valor = _toDouble(raw);
      if (valor > 0) total += valor;
    }
    final debe = _toDouble(emp['debe']);
    final comedor = _toDouble(emp['comedor']);
    final subtotal = total + debe; // ✅ Nueva regla
    final totalNeto = subtotal - comedor;
    return totalNeto;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is bool) return v ? 400.0 : 0.0; // comedor booleano legacy
    return 0.0;
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
              value: '\$${_calcularAcumuladoCuadrilla().toStringAsFixed(2)}',
              icon: Icons.payments,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: IndicatorCard(
              title: 'Total semana',
              value: '\$${_calcularTotalSemana().toStringAsFixed(2)}',
              icon: Icons.monetization_on,
            ),
          ),
        ],
      ),
    );
  }
}
