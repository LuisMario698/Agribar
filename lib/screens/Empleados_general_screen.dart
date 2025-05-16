import 'package:flutter/material.dart';
import 'Empleados_content.dart';

class EmpleadosGeneralScreen extends StatelessWidget {
  const EmpleadosGeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EmpleadosContent(),
      ),
    );
  }
}
