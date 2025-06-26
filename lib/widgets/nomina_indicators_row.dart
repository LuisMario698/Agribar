import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../widgets/indicator_card.dart';
import '../services/database_service.dart';

/// Widget modular para la fila de indicadores
/// Muestra las estadísticas de empleados, acumulado y total de semana
class NominaIndicatorsRow extends StatefulWidget {
  final List<Map<String, dynamic>> empleadosFiltrados;
  final List<Map<String, dynamic>> optionsCuadrilla;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? semanaId;

  const NominaIndicatorsRow({
    super.key,
    required this.empleadosFiltrados,
    required this.optionsCuadrilla,
    this.startDate,
    this.endDate,
    this.semanaId,
  });

  @override
  State<NominaIndicatorsRow> createState() => _NominaIndicatorsRowState();
}

class _NominaIndicatorsRowState extends State<NominaIndicatorsRow> {
  double _totalSemana = 0.0;

  @override
  void initState() {
    super.initState();
    _calcularTotalSemana();
  }

  @override
  void didUpdateWidget(NominaIndicatorsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalcular cuando cambien los empleados filtrados o las cuadrillas
    if (widget.empleadosFiltrados != oldWidget.empleadosFiltrados ||
        widget.optionsCuadrilla != oldWidget.optionsCuadrilla ||
        widget.semanaId != oldWidget.semanaId) {
      _calcularTotalSemana();
    }
  }

  /// Función pública para forzar recálculo del total semana
  void actualizarTotalSemana() {
    _calcularTotalSemana();
  }

  /// Calcula el total neto de un empleado
  double _calcularTotalEmpleado(Map<String, dynamic> emp) {
    final numDays = (widget.endDate != null && widget.startDate != null)
        ? widget.endDate!.difference(widget.startDate!).inDays + 1
        : 7;
    
    final total = List.generate(
      numDays,
      (i) => int.tryParse(emp['dia_$i']?.toString() ?? '0') ?? 0,
    ).reduce((a, b) => a + b);
    
    final debe = int.tryParse(emp['debe']?.toString() ?? '0') ?? 0;
    final subtotal = total - debe;
    // Cambiar para usar el valor numérico del comedor en lugar de boolean
    final comedorValue = double.tryParse(emp['comedor']?.toString() ?? '0') ?? 0;
    final totalNeto = subtotal - comedorValue;
    
    return totalNeto.toDouble();
  }

  /// Calcula el acumulado de la cuadrilla actual
  double _calcularAcumuladoCuadrilla() {
    return widget.empleadosFiltrados.fold<double>(
      0,
      (sum, emp) => sum + _calcularTotalEmpleado(emp),
    );
  }

  /// Calcula el total de toda la semana obteniendo datos de la BD
  Future<void> _calcularTotalSemana() async {
    if (widget.semanaId == null) {
      setState(() {
        _totalSemana = 0.0;
      });
      return;
    }

    try {
      final db = DatabaseService();
      await db.connect();

      // Obtener el total neto de todas las cuadrillas de la semana
      final result = await db.connection.query(
        '''
        SELECT COALESCE(SUM(n.total_neto), 0) as total_semana
        FROM nomina_empleados_semanal n
        WHERE n.id_semana = @semanaId
        ''',
        substitutionValues: {'semanaId': widget.semanaId},
      );

      await db.close();

      final totalFromDB = result.isNotEmpty 
          ? (result.first[0] as num?)?.toDouble() ?? 0.0
          : 0.0;

      setState(() {
        _totalSemana = totalFromDB;
      });
    } catch (e) {
      print('Error al calcular total semana: $e');
      setState(() {
        _totalSemana = 0.0;
      });
    }
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
              value: '${widget.empleadosFiltrados.length}',
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
              value: '\$${_totalSemana.toStringAsFixed(2)}',
              icon: Icons.monetization_on,
            ),
          ),
        ],
      ),
    );
  }
}
