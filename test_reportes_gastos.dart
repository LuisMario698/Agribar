import 'package:flutter/material.dart';
import 'lib/widgets/reportes_gastos_widget.dart';
import 'lib/theme/app_styles.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Reportes Gastos',
      theme: ThemeData(
        primaryColor: AppColors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestReportesGastos(),
    );
  }
}

class TestReportesGastos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Reportes de Gastos por Actividad'),
        backgroundColor: AppColors.green,
      ),
      body: ReportesGastosWidget(),
    );
  }
}
