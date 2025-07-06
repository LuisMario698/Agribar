import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import 'data_table_widget.dart';

/// Diálogo modal para mostrar tablas de reportes en pantalla completa.
class ReportesTableDialog extends StatefulWidget {
  /// Tipo de tabla a mostrar (0: Empleado, 1: Cuadrilla, 2: Actividad)
  final int selectedFilter;
  /// Datos a mostrar en la tabla
  final List<Map<String, String>> data;
  /// Función que se ejecuta al cerrar el diálogo
  final VoidCallback onClose;
  /// Controlador para el scroll horizontal de la tabla
  final ScrollController horizontalController;
  /// Controlador para el scroll vertical de la tabla
  final ScrollController verticalController;

  const ReportesTableDialog({
    Key? key,
    required this.selectedFilter,
    required this.data,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
  }) : super(key: key);

  @override
  State<ReportesTableDialog> createState() => _ReportesTableDialogState();
}

class _ReportesTableDialogState extends State<ReportesTableDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, String>> _filteredData;
  late List<String> _columns;
  
  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.data);
    _initializeColumns();
  }  void _initializeColumns() {
    // Definir columnas según el tipo de filtro seleccionado
    if (widget.selectedFilter == 0) { // Empleados
      _columns = ['Clave', 'Nombre', 'Apellido Paterno', 'Apellido Materno', 'Cuadrilla', 'Sueldo', 'Tipo'];
    } else if (widget.selectedFilter == 1) { // Cuadrillas
      _columns = ['Clave', 'Nombre', 'Responsable', 'Miembros', 'Actividad'];
    } else if (widget.selectedFilter == 2) { // Actividades
      _columns = ['Código', 'Nombre', 'Fecha', 'Responsable', 'Cuadrilla'];
    } else {
      _columns = [];
    }
  }

  void _filterData(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredData = List.from(widget.data);
      } else {
        final query = searchText.toLowerCase();
        _filteredData = widget.data.where((item) {
          return item.values.any((value) => 
            value.toLowerCase().contains(query)
          );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (widget.selectedFilter == 0) {
      title = 'Empleados';
    } else if (widget.selectedFilter == 1) {
      title = 'Cuadrillas';
    } else if (widget.selectedFilter == 2) {
      title = 'Actividades';
    } else {
      title = 'Reporte';
    }

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0)),
        ),
        Center(          child: ConstrainedBox(
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
                    // Header
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
                                    'Reporte de $title',
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
                                      hintText: 'Buscar ${title.toLowerCase()}...',
                                      hintStyle: TextStyle(color: Colors.grey.shade500),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onChanged: _filterData,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),                    // Contenido de la tabla con scroll
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Scrollbar(
                            controller: widget.horizontalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: widget.horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: Scrollbar(
                                controller: widget.verticalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: widget.verticalController,
                                  scrollDirection: Axis.vertical,
                                  child: DataTableWidget(
                                    columns: _columns,
                                    rows: _filteredData.map((item) {
                                      if (widget.selectedFilter == 0) {  // Empleados
                                        return [
                                          item['clave'] ?? '',
                                          item['nombre'] ?? '',
                                          item['apPaterno'] ?? '',
                                          item['apMaterno'] ?? '',
                                          item['cuadrilla'] ?? '',
                                          item['sueldo'] ?? '',
                                          item['tipo'] ?? '',
                                        ];
                                      } else if (widget.selectedFilter == 1) {  // Cuadrillas
                                        return [
                                          item['clave'] ?? '',
                                          item['nombre'] ?? '',
                                          item['responsable'] ?? '',
                                          item['miembros'] ?? '',
                                          item['actividad'] ?? '',
                                        ];
                                      } else {  // Actividades
                                        return [
                                          item['codigo'] ?? '',
                                          item['nombre'] ?? '',
                                          item['fecha'] ?? '',
                                          item['responsable'] ?? '',
                                          item['cuadrilla'] ?? '',
                                        ];                                      }
                                    }).toList(),
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
  
