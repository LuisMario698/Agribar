import 'package:flutter/material.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets_shared/index.dart';

class ActividadForm extends StatelessWidget {
  final TextEditingController claveController;
  final TextEditingController nombreController;
  final TextEditingController importeController;
  final TextEditingController fechaController;
  final DateTime? fecha;
  final List<String> actividadesOptions;
  final List<Map<String, String>> cuadrillas;
  final String cuadrillaSeleccionada;
  final Function(DateTime?) onDateSelected;
  final Function(String?) onCuadrillaChanged;
  final VoidCallback onCrear;

  const ActividadForm({
    Key? key,
    required this.claveController,
    required this.nombreController,
    required this.importeController,
    required this.fechaController,
    required this.fecha,
    required this.actividadesOptions,
    required this.cuadrillas,
    required this.cuadrillaSeleccionada,
    required this.onDateSelected,
    required this.onCuadrillaChanged,
    required this.onCrear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clave'),
                    const SizedBox(height: 8),
                    GenericTextField(
                      controller: claveController,
                      label: '',
                      fillColor: Colors.grey[200],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fecha'),
                    const SizedBox(height: 8),
                    GenericTextField(
                      controller: fechaController,
                      label: '',
                      fillColor: Colors.grey[200],
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: fecha ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          onDateSelected(pickedDate);
                          fechaController.text =
                              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                        }
                      },
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Importe'),
                    const SizedBox(height: 8),
                    GenericTextField(
                      controller: importeController,
                      label: '',
                      fillColor: Colors.grey[200],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividad'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          nombreController.text.isEmpty
                              ? null
                              : nombreController.text,
                      items:
                          actividadesOptions
                              .map(
                                (a) =>
                                    DropdownMenuItem(value: a, child: Text(a)),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          nombreController.text = value;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.grey[200],
                        filled: true,
                        labelText: '',
                        hintText: 'Seleccione una actividad',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuadrilla'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:
                          cuadrillaSeleccionada.isEmpty
                              ? null
                              : cuadrillaSeleccionada,
                      items:
                          cuadrillas
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['nombre']!,
                                  child: Text(c['nombre']!),
                                ),
                              )
                              .toList(),
                      onChanged: onCuadrillaChanged,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.grey[200],
                        filled: true,
                        labelText: '',
                        hintText: 'Seleccione una cuadrilla',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(child: GenericButton(label: 'Crear', onPressed: onCrear)),
        ],
      ),
    );
  }
}
