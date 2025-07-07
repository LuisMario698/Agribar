import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget que muestra el estado actual del flujo de nómina
class NominaFlowIndicator extends StatelessWidget {
  final bool hasSemana;
  final bool hasCuadrilla;
  final bool hasEmpleados;
  final bool puedeCapturar;

  const NominaFlowIndicator({
    super.key,
    required this.hasSemana,
    required this.hasCuadrilla,
    required this.hasEmpleados,
    required this.puedeCapturar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline,
            size: 20,
            color: AppColors.greenDark,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                _buildStepIndicator(
                  step: 1,
                  label: 'Semana',
                  isCompleted: hasSemana,
                  isActive: !hasSemana,
                ),
                _buildConnector(hasSemana),
                _buildStepIndicator(
                  step: 2,
                  label: 'Cuadrilla',
                  isCompleted: hasCuadrilla && hasEmpleados,
                  isActive: hasSemana && !hasCuadrilla,
                ),
                _buildConnector(hasCuadrilla && hasEmpleados),
                _buildStepIndicator(
                  step: 3,
                  label: 'Captura',
                  isCompleted: puedeCapturar,
                  isActive: hasCuadrilla && hasEmpleados && !puedeCapturar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color color;
    IconData icon;
    
    if (isCompleted) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (isActive) {
      color = Colors.blue;
      icon = Icons.radio_button_unchecked;
    } else {
      color = Colors.grey.shade400;
      icon = Icons.radio_button_unchecked;
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.only(top: 12, bottom: 16),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }
}
