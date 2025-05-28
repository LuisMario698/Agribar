/// Widget para el formulario de datos de nómina de un empleado.

import 'package:flutter/material.dart';
import 'NominaTarjeta.dart';
import 'CustomInput.dart';

class DatosNominaForm extends StatelessWidget {
  final TextEditingController sueldoController;
  final TextEditingController domingoLaboralMontoController;
  final TextEditingController descuentoComedorController;
  final TextEditingController descuentoInfonavitController;
  final bool domingoLaboral;
  final bool descuentoComedor;
  final String tipoDescuentoInfonavit;
  final List<String> tiposDescuentoInfonavit;
  final Function(bool) onDomingoLaboralChanged;
  final Function(bool) onDescuentoComedorChanged;
  final Function(String?) onTipoDescuentoInfonavitChanged;
  final Color grisInput;
  final Color verde;

  const DatosNominaForm({
    Key? key,
    required this.sueldoController,
    required this.domingoLaboralMontoController,
    required this.descuentoComedorController,
    required this.descuentoInfonavitController,
    required this.domingoLaboral,
    required this.descuentoComedor,
    required this.tipoDescuentoInfonavit,
    required this.tiposDescuentoInfonavit,
    required this.onDomingoLaboralChanged,
    required this.onDescuentoComedorChanged,
    required this.onTipoDescuentoInfonavitChanged,
    required this.grisInput,
    required this.verde,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 32,
        children: [
          // Sueldo
          NominaTarjeta(
            titulo: 'Sueldo',
            children: [
              CustomInput(
                controller: sueldoController,
                label: '',
                fillColor: grisInput,
              ),
            ],
          ),

          // Domingo Laboral
          NominaTarjeta(
            titulo: '',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Domingo Laboral',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: domingoLaboral,
                    onChanged: onDomingoLaboralChanged,
                    activeColor: verde,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomInput(
                      controller: domingoLaboralMontoController,
                      label: '',
                      fillColor: grisInput,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '/ hr',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),

          // Descuento Comedor
          NominaTarjeta(
            titulo: '',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descuento Comedor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: descuentoComedor,
                    onChanged: onDescuentoComedorChanged,
                    activeColor: verde,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomInput(
                      controller: descuentoComedorController,
                      label: '',
                      fillColor: grisInput,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '%',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),

          // Tipo Descuento Infonavit y % Descuento Infonavit
          NominaTarjeta(
            titulo: 'Tipo Descuento Infonavit',
            children: [
              DropdownButtonFormField<String>(
                value:
                    tipoDescuentoInfonavit.isEmpty
                        ? null
                        : tipoDescuentoInfonavit,
                items:
                    tiposDescuentoInfonavit
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: onTipoDescuentoInfonavitChanged,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  filled: true,
                  fillColor: grisInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Descuento Infonavit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomInput(
                      controller: descuentoInfonavitController,
                      label: '',
                      fillColor: grisInput,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '%',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
