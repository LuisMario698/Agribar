import 'package:flutter/material.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets_shared/index.dart';

class CuadrillaForm extends StatelessWidget {
  final TextEditingController claveController;
  final TextEditingController nombreController;
  final TextEditingController grupoController;
  final String? actividadSeleccionada;
  final List<String> actividades;
  final void Function(String?) onActividadChanged;
  final VoidCallback onCrear;

  const CuadrillaForm({
    Key? key,
    required this.claveController,
    required this.nombreController,
    required this.grupoController,
    required this.actividadSeleccionada,
    required this.actividades,
    required this.onActividadChanged,
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
                    const Text('Nombre'),
                    const SizedBox(height: 8),
                    GenericTextField(
                      controller: nombreController,
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
                    const Text('Grupo'),
                    const SizedBox(height: 8),
                    GenericTextField(
                      controller: grupoController,
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
                      value: actividadSeleccionada,
                      items:
                          actividades
                              .map(
                                (a) =>
                                    DropdownMenuItem(value: a, child: Text(a)),
                              )
                              .toList(),
                      onChanged: onActividadChanged,
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
            ],
          ),
          const SizedBox(height: 24),
          Center(child: GenericButton(label: 'Crear', onPressed: onCrear)),
        ],
      ),
    );
  }
}
