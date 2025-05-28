/// Widget para el formulario de datos personales de un empleado.

import 'package:flutter/material.dart';
import '../../../widgets_shared/index.dart';

class DatosPersonalesForm extends StatelessWidget {
  final TextEditingController codigoController;
  final TextEditingController nombreController;
  final TextEditingController apellidoPaternoController;
  final TextEditingController apellidoMaternoController;
  final TextEditingController rfcController;
  final TextEditingController curpController;
  final TextEditingController nssController;
  final String estadoOrigen;
  final Function(String?) onEstadoOrigenChanged;
  final List<String> estadosMexico;
  final Color grisInput;

  const DatosPersonalesForm({
    Key? key,
    required this.codigoController,
    required this.nombreController,
    required this.apellidoPaternoController,
    required this.apellidoMaternoController,
    required this.rfcController,
    required this.curpController,
    required this.nssController,
    required this.estadoOrigen,
    required this.onEstadoOrigenChanged,
    required this.estadosMexico,
    required this.grisInput,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Código (más pequeño)
        Row(
          children: [
            Flexible(
              flex: 1,
              child: GenericInput(
                controller: codigoController,
                label: 'Codigo',
                fillColor: grisInput,
              ),
            ),
            Expanded(flex: 2, child: Container()), // Espacio vacío para alinear
          ],
        ),
        SizedBox(height: 28), // Más espacio entre filas
        // Fila 2: Apellido Paterno, Apellido Materno, Nombre
        Row(
          children: [
            Expanded(
              child: GenericInput(
                controller: apellidoPaternoController,
                label: 'Apellido Paterno',
                fillColor: grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GenericInput(
                controller: apellidoMaternoController,
                label: 'Apellido Materno',
                fillColor: grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GenericInput(
                controller: nombreController,
                label: 'Nombre',
                fillColor: grisInput,
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 3: CURP, RFC
        Row(
          children: [
            Expanded(
              child: GenericInput(
                controller: curpController,
                label: 'CURP',
                fillColor: grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: GenericInput(
                controller: rfcController,
                label: 'RFC',
                fillColor: grisInput,
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 4: NSS, Estado de Origen
        Row(
          children: [
            Expanded(
              child: GenericInput(
                controller: nssController,
                label: 'NSS',
                fillColor: grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: estadoOrigen.isEmpty ? null : estadoOrigen,
                items:
                    estadosMexico
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onEstadoOrigenChanged,
                decoration: InputDecoration(
                  labelText: "Estado de Origen",
                  filled: true,
                  fillColor: grisInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
