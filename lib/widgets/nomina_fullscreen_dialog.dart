import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/editable_data_table.dart';

class NominaFullscreenDialog extends StatelessWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int index, String key, dynamic value) onChanged;
  final VoidCallback onClose;
  final ScrollController horizontalController;
  final ScrollController verticalController;

  const NominaFullscreenDialog({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    required this.onChanged,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop con efecto blur
        Container(
          color: Colors.black.withOpacity(0.2),
        ),
        // Contenido principal
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nómina Semanal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 32),
                        onPressed: onClose,
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tabla expandida
                  Expanded(
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: SingleChildScrollView(
                          controller: verticalController,
                          child: EditableDataTableWidget(
                            empleados: empleados,
                            semanaSeleccionada: semanaSeleccionada,
                            onChanged: onChanged,
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
