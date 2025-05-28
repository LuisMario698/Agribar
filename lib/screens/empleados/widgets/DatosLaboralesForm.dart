/// Widget para el formulario de datos laborales de un empleado.

import 'package:flutter/material.dart';

class DatosLaboralesForm extends StatelessWidget {
  final TextEditingController empresaController;
  final TextEditingController puestoController;
  final TextEditingController registroPatronalController;
  final TextEditingController fechaIngresoController;
  final String tipoEmpleado;
  final String cuadrilla;
  final bool inactivo;
  final bool deshabilitado;
  final DateTime? fechaIngreso;
  final Function(String?) onTipoEmpleadoChanged;
  final Function(String?) onCuadrillaChanged;
  final Function(bool) onInactivoChanged;
  final Function(bool) onDeshabilitadoChanged;
  final Function(DateTime?) onFechaIngresoChanged;
  final Color grisInput;

  const DatosLaboralesForm({
    Key? key,
    required this.empresaController,
    required this.puestoController,
    required this.registroPatronalController,
    required this.fechaIngresoController,
    required this.tipoEmpleado,
    required this.cuadrilla,
    required this.inactivo,
    required this.deshabilitado,
    required this.fechaIngreso,
    required this.onTipoEmpleadoChanged,
    required this.onCuadrillaChanged,
    required this.onInactivoChanged,
    required this.onDeshabilitadoChanged,
    required this.onFechaIngresoChanged,
    required this.grisInput,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Tipo, Cuadrilla, Fecha de Ingreso
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: tipoEmpleado.isEmpty ? null : tipoEmpleado,
                items:
                    ["Temporal", "Fijo"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onTipoEmpleadoChanged,
                decoration: InputDecoration(
                  labelText: "Tipo",
                  filled: true,
                  fillColor: grisInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: cuadrilla.isEmpty ? null : cuadrilla,
                items:
                    ["Cuadrilla 1", "Cuadrilla 2", "Cuadrilla 3"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onCuadrillaChanged,
                decoration: InputDecoration(
                  labelText: "Cuadrilla",
                  filled: true,
                  fillColor: grisInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: fechaIngreso ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    onFechaIngresoChanged(picked);
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: fechaIngresoController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Ingreso',
                      filled: true,
                      fillColor: grisInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 2: Empresa, Puesto, Registro Patronal
        Row(
          children: [
            Expanded(
              child: _customInput(empresaController, 'Empresa', grisInput),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(puestoController, 'Puesto', grisInput),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(
                registroPatronalController,
                'Registro Patronal',
                grisInput,
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 3: Inactivo, Deshabilitado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SwitchListTile(
                title: Text("Inactivo"),
                value: inactivo,
                onChanged: onInactivoChanged,
                activeColor: Color(0xFF8AB531),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                title: Text("Deshabilitado"),
                value: deshabilitado,
                onChanged: onDeshabilitadoChanged,
                activeColor: Color(0xFF8AB531),
              ),
            ),
            SizedBox(width: 16),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _customInput(
    TextEditingController controller,
    String label,
    Color fillColor, {
    Widget? prefix,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefix: prefix,
        suffix: suffix,
      ),
    );
  }
}
