import 'package:flutter/material.dart';
import '../../widgets_shared/widgets_shared/index.dart';

/// Widget que muestra las métricas de empleados activos e inactivos
class EmpleadosMetricsRow extends StatelessWidget {
  final int activos;
  final int inactivos;

  const EmpleadosMetricsRow({
    Key? key,
    required this.activos,
    required this.inactivos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GenericMetricCard(
            title: 'Empleados activos',
            value: activos.toString(),
            icon: Icons.person,
            iconColor: Color(0xFF0B7A2F), // Verde más oscuro para empleados activos
          ),
        ),
        SizedBox(width: 32),
        Expanded(
          child: GenericMetricCard(
            title: 'Empleados inactivos',
            value: inactivos.toString(),
            icon: Icons.person,
            iconColor: Color(0xFFE53935), // Rojo para empleados inactivos
          ),
        ),
      ],
    );
  }
}
