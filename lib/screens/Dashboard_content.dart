import 'package:flutter/material.dart';
import 'Dashboard_screen.dart';

class DashboardHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Top metrics
          Row(
            children: [
              MetricCard(
                title: 'Empleados activos',
                value: '87',
                icon: Icons.person,
                iconColor: Color(0xFF6B4F27),
              ),
              SizedBox(width: 24),
              MetricCard(
                title: 'Cuadrillas activas',
                value: '7',
                icon: Icons.agriculture,
                iconColor: Color(0xFF6B4F27),
              ),
              SizedBox(width: 24),
              MetricCard(
                title: 'Actividades',
                value: '35',
                icon: Icons.assignment,
                iconColor: Color(0xFF6B4F27),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Middle charts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: ChartCard(
                  title: 'Pagos Semanales',
                  child: Placeholder(fallbackHeight: 180),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: ChartCard(
                  title: 'Pago por cuadrilla',
                  child: Placeholder(fallbackHeight: 180),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bottom row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: MetricCard(
                  title: 'Nomina acumulada',
                  value: '\u00024604,000',
                  valueColor: Colors.green,
                  fontSize: 36,
                ),
              ),
              SizedBox(width: 24),
              Expanded(flex: 2, child: AlertCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final double fontSize;
  const MetricCard({
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black,
                ),
              ),
              if (icon != null) ...[
                SizedBox(width: 8),
                Icon(icon, color: iconColor ?? Colors.black, size: 32),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Abr', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.error, color: Colors.red[400]),
              SizedBox(width: 8),
              Text(
                'Cuadrillas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Faltan capturas en 3 cuadrillas}'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[400]),
              SizedBox(width: 8),
              Text(
                'Empleados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[400],
                ),
              ),
              SizedBox(width: 8),
              Text('{Errores en 2 empleados}'),
            ],
          ),
        ],
      ),
    );
  }
}
