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
    
    // 🔧 Función auxiliar para convertir valores de manera segura
    num _safeParseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
      return 0;
    }
    
    // Solo sumar las celdas "S", ignorar las celdas "ID"
    final total = List.generate(
      numDays,
      (i) => _safeParseNum(emp['dia_${i}_s']).toInt(),
    ).reduce((a, b) => a + b);
    
    final debe = _safeParseNum(emp['debe']).toDouble();
    final subtotal = total - debe;
    
    // Usar el valor numérico del comedor con conversión segura
    final comedorValue = _safeParseNum(emp['comedor']).toDouble();
    final totalNeto = subtotal - comedorValue;
    
    return totalNeto.toDouble();
  }

  /// Calcula el acumulado de la cuadrilla actual
  double _calcularAcumuladoCuadrilla() {
    // 🔧 Función auxiliar para convertir valores de manera segura
    num _safeParseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
      return 0;
    }

    return widget.empleadosFiltrados.fold<double>(
      0,
      (sum, emp) {
        // Usar el totalNeto ya calculado en el empleado si existe, 
        // de lo contrario calcularlo aquí
        final totalNeto = emp['totalNeto'] != null 
            ? _safeParseNum(emp['totalNeto']).toDouble()
            : _calcularTotalEmpleado(emp);
        return sum + totalNeto;
      },
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
  SELECT total_semana
    FROM resumen_nomina
    WHERE id_semana = (SELECT MAX(id_semana) FROM resumen_nomina);
        '''
       
      );

      await db.close();

     final totalFromDB = result.isNotEmpty
  ? double.tryParse(result.first[0].toString()) ?? 0.0
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
