import 'package:flutter/material.dart';
import '../widgets/reportes_gastos_widget.dart';

/// Pantalla de reportes que muestra únicamente los gastos por actividad
class ReportesScreen extends StatefulWidget {
  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: ReportesGastosWidget(),
    );
  }
}
