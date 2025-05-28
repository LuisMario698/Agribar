import 'package:flutter/material.dart';
import 'EmpleadosMetricCard.dart';

class EmpleadosMetricsRow extends StatelessWidget {
  final int activos;
  final int inactivos;
  const EmpleadosMetricsRow({
    required this.activos,
    required this.inactivos,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 50,
          child: EmpleadosMetricCard(
            title: 'Empleados activos',
            value: activos.toString(),
            icon: Icons.person,
            iconColor: Color(0xFF0B7A2F),
          ),
        ),
        SizedBox(width: 32),
        Expanded(
          flex: 50,
          child: EmpleadosMetricCard(
            title: 'Empleados inactivos',
            value: inactivos.toString(),
            icon: Icons.person,
            iconColor: Color(0xFFE53935),
          ),
        ),
      ],
    );
  }
}
