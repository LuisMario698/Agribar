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
  bool _isCalculating = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _calcularTotalSemana();
  }

  @override
  void dispose() {
    _isDisposed = true; // Marcar como eliminado
    super.dispose();
  }

  @override
  void didUpdateWidget(NominaIndicatorsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 🛡️ No hacer nada si el widget está siendo eliminado
    if (_isDisposed || !mounted) return;
    
    // Solo recalcular cuando cambien los empleados filtrados de manera significativa
    // Evitar recálculos constantes durante transiciones
    if (widget.empleadosFiltrados.length != oldWidget.empleadosFiltrados.length ||
        widget.semanaId != oldWidget.semanaId ||
        _shouldRecalculate(oldWidget)) {
      
      // 🕐 Recalcular inmediatamente, sin delay innecesario
      _calcularTotalSemana();
    }
  }
  
  /// Determina si debe recalcular basado en cambios significativos en los datos
  bool _shouldRecalculate(NominaIndicatorsRow oldWidget) {
    // Solo recalcular si cambió la información significativa
    return widget.startDate != oldWidget.startDate ||
           widget.endDate != oldWidget.endDate ||
           widget.empleadosFiltrados.length != oldWidget.empleadosFiltrados.length;
  }

  /// Función pública para forzar recálculo del total semana después de guardado
  void actualizarTotalSemana() {
    if (!_isDisposed && mounted && !_isCalculating) {
      _calcularTotalSemana();
    }
  }

  /// Función pública para cuando se inicia un guardado (mostrar loading)
  void iniciarCalculoGuardado() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isCalculating = true;
      });
    }
  }

  /// Función pública para cuando termina un guardado (ocultar loading y recalcular)
  void finalizarCalculoGuardado() {
    if (!_isDisposed && mounted) {
      _calcularTotalSemana(); // Esto automáticamente pondrá _isCalculating a false
    }
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
    // Si no hay empleados filtrados, retornar 0
    if (widget.empleadosFiltrados.isEmpty) return 0.0;
    
    // 🔧 Función auxiliar para convertir valores de manera segura
    num _safeParseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
      return 0;
    }

    double total = 0.0;
    
    for (var emp in widget.empleadosFiltrados) {
      // Usar el totalNeto ya calculado en el empleado si existe y es válido
      if (emp['totalNeto'] != null) {
        final totalNeto = _safeParseNum(emp['totalNeto']).toDouble();
        total += totalNeto;
      } else {
        // Si no existe totalNeto, calcularlo aquí como fallback
        final calculatedTotal = _calcularTotalEmpleado(emp);
        total += calculatedTotal;
      }
    }
    
    print('🔍 Acumulado cuadrilla calculado: $total (${widget.empleadosFiltrados.length} empleados)');
    return total;
  }

  /// Calcula el total de toda la semana obteniendo datos de la BD
  Future<void> _calcularTotalSemana() async {
    // 🛡️ Verificaciones de seguridad ANTES de cualquier operación
    if (_isDisposed || !mounted) {
      print('🚫 Cálculo cancelado: Widget desmontado');
      return;
    }

    if (widget.semanaId == null) {
      if (mounted && !_isDisposed) {
        setState(() {
          _totalSemana = 0.0;
          _isCalculating = false;
        });
      }
      return;
    }

    // 🔄 Marcar como calculando solo si el widget sigue montado
    if (mounted && !_isDisposed) {
      setState(() {
        _isCalculating = true;
      });
    }

    DatabaseService? db;
    try {
      // ⚡ Verificar otra vez antes de la operación costosa
      if (_isDisposed || !mounted) {
        print('🚫 Cálculo cancelado durante inicialización BD');
        return;
      }

      db = DatabaseService();
      await db.connect();

      // 🔍 Verificar antes de la consulta
      if (_isDisposed || !mounted) {
        print('🚫 Cálculo cancelado antes de consulta BD');
        await db.close();
        return;
      }

      // Obtener el total neto de todas las cuadrillas de la semana
      final result = await db.connection.query(
        '''
        SELECT COALESCE(SUM(total_neto), 0) as total_semana
        FROM nomina_empleados_semanal
        WHERE id_semana = @semanaId;
        ''',
        substitutionValues: {'semanaId': widget.semanaId},
      );

      // 🎯 VERIFICACIÓN CRÍTICA: Solo setState si el widget SIGUE montado
      if (!_isDisposed && mounted) {
        final totalFromDB = result.isNotEmpty
            ? double.tryParse(result.first[0].toString()) ?? 0.0
            : 0.0;

        setState(() {
          _totalSemana = totalFromDB;
          _isCalculating = false; // ✅ IMPORTANTE: Detener la animación
        });
        
        print('✅ Total semana actualizado correctamente: \$${_totalSemana.toStringAsFixed(2)}');
      } else {
        print('⚠️ Widget desmontado durante consulta - setState cancelado');
      }

    } catch (e) {
      print('❌ Error al calcular total semana: $e');
      
      // 🛡️ setState con protección incluso en errores + detener animación
      if (!_isDisposed && mounted) {
        setState(() {
          _totalSemana = 0.0;
          _isCalculating = false; // ✅ IMPORTANTE: Detener animación en errores también
        });
      }
    } finally {
      // 🧹 Siempre cerrar la conexión de BD
      if (db != null) {
        try {
          await db.close();
        } catch (e) {
          print('⚠️ Error al cerrar conexión BD: $e');
        }
      }
    }
  }

  /// Construye un indicador de carga animado para el total de semana
  Widget _buildLoadingIndicatorCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159, // Rotación completa
                child: Icon(
                  Icons.monetization_on,
                  size: 32,
                  color: AppColors.greenDark.withOpacity(0.7),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Texto del título
          Text(
            'Total semana',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Indicador de progreso con puntos animados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 200)),
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.greenDark.withOpacity(value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
          
          const SizedBox(height: 4),
          
          // Texto de cargando
          Text(
            'Calculando...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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
            child: _isCalculating 
                ? _buildLoadingIndicatorCard()
                : IndicatorCard(
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
