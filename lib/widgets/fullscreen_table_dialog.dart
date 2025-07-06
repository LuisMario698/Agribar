import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import '../widgets/editable_data_table.dart';

/// Diálogo modal para mostrar tablas en pantalla completa.
///
/// Este widget implementa un diálogo modal con las siguientes características:
/// - Efecto de desenfoque en el fondo
/// - Controladores de scroll independientes (horizontal y vertical)
/// - Tamaño responsivo basado en las dimensiones de la pantalla
/// - Botón de cierre para volver a la vista normal
/// - Animación suave al abrir y cerrar
///
/// Se utiliza cuando se necesita ver una tabla grande en pantalla completa,
/// especialmente útil en las pantallas de:
/// - Reportes detallados
/// - Nóminas semanales
/// - Registros históricos
class FullscreenTableDialog extends StatefulWidget {
  /// Lista de empleados a mostrar en la tabla
  final List<Map<String, dynamic>> empleados;
  /// Rango de fechas seleccionado
  final DateTimeRange? semanaSeleccionada;
  /// Función que se llama cuando hay cambios en la tabla
  final void Function(int, String, dynamic) onChanged;
  /// Función que se ejecuta al cerrar el diálogo
  final VoidCallback onClose;
  /// Controlador para el scroll horizontal de la tabla
  final ScrollController horizontalController;
  /// Controlador para el scroll vertical de la tabla
  final ScrollController verticalController;
  const FullscreenTableDialog({
    Key? key,
    required this.empleados,
    required this.semanaSeleccionada,
    required this.onChanged,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
  }) : super(key: key);

  @override
  State<FullscreenTableDialog> createState() => _FullscreenTableDialogState();
}

class _FullscreenTableDialogState extends State<FullscreenTableDialog> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filteredEmpleados;

  @override
  void initState() {
    super.initState();
    _filteredEmpleados = List.from(widget.empleados);
  }

  void _filterEmpleados(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredEmpleados = List.from(widget.empleados);
      } else {
        final query = searchText.toLowerCase();
        _filteredEmpleados = widget.empleados.where((emp) {
          final nombre = emp['nombre']?.toString().toLowerCase() ?? '';
          final clave = emp['clave']?.toString().toLowerCase() ?? '';
          return nombre.contains(query) || clave.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0)),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.98,
              maxHeight: MediaQuery.of(context).size.height * 0.95,
            ),
            child: Material(
              color: Colors.transparent,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header mejorado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.tableHeader,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimens.cardRadius),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.table_chart,
                                    color: AppColors.greenDark,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Vista Detallada',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onClose,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barra de búsqueda
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar empleado...',
                                      hintStyle: TextStyle(color: Colors.grey.shade500),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 14),                                    onChanged: _filterEmpleados,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenido de la tabla con scroll
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Scrollbar(
                          controller: widget.horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: widget.horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1100),
                              child: Scrollbar(
                                controller: widget.verticalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: widget.verticalController,
                                  scrollDirection: Axis.vertical,
                                  child: EditableDataTableWidget(
                                    empleados: _filteredEmpleados,
                                    semanaSeleccionada: widget.semanaSeleccionada,
                                    onChanged: widget.onChanged,
                                    isExpanded: true,
                                  ),
                                ),
                              ),
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
