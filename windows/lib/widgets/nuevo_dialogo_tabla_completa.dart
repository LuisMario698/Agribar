import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import 'nueva_tabla_editable.dart';
import 'custom_dropdown_menu.dart';

/// Nuevo diálogo de pantalla completa simplificado
class NuevoDialogoTablaCompleta extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final void Function(int, String, dynamic) onChanged;
  final VoidCallback onClose;
  final List<Map<String, dynamic>> cuadrillas;
  final Map<String, dynamic>? cuadrillaSeleccionada;
  final Function(Map<String, dynamic>?) onCuadrillaChanged;
  
  const NuevoDialogoTablaCompleta({
    Key? key,
    required this.empleados,
    required this.semanaSeleccionada,
    required this.onChanged,
    required this.onClose,
    required this.cuadrillas,
    this.cuadrillaSeleccionada,
    required this.onCuadrillaChanged,
  }) : super(key: key);

  @override
  State<NuevoDialogoTablaCompleta> createState() => _NuevoDialogoTablaCompletaState();
}

class _NuevoDialogoTablaCompletaState extends State<NuevoDialogoTablaCompleta> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _empleadosFiltrados;

  @override
  void initState() {
    super.initState();
    _empleadosFiltrados = List.from(widget.empleados);
  }

  void _filtrarEmpleados(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _empleadosFiltrados = List.from(widget.empleados);
      } else {
        final query = texto.toLowerCase();
        _empleadosFiltrados = widget.empleados.where((emp) {
          final nombre = emp['nombre']?.toString().toLowerCase() ?? '';
          final codigo = emp['codigo']?.toString().toLowerCase() ?? '';
          return nombre.contains(query) || codigo.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fondo con desenfoque
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          
          // Diálogo principal
          Center(
            child: Container(
              width: screenWidth * 0.95,
              height: screenHeight * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.greenDark.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fullscreen,
                          color: AppColors.greenDark,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vista completa de nómina',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Controles
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Dropdown de cuadrilla
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuadrilla',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 200,
                              child: CustomDropdownMenu(
                                options: widget.cuadrillas,
                                selectedOption: widget.cuadrillaSeleccionada,
                                onOptionSelected: widget.onCuadrillaChanged,
                                displayKey: 'nombre',
                                valueKey: 'nombre',
                                hint: 'Seleccionar cuadrilla',
                                icon: Icon(
                                  Icons.groups,
                                  color: AppColors.greenDark,
                                ),
                                allowDeselect: true,
                                searchHint: 'Buscar cuadrilla...',
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Campo de búsqueda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buscar empleado',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre o código...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.greenDark,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.greenDark),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: _filtrarEmpleados,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Contador de empleados
                        Column(
                          children: [
                            Text(
                              'Empleados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greenDark,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${_empleadosFiltrados.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Tabla
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1200),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: NuevaTablaEditable(
                                  key: ValueKey('fullscreen_${_empleadosFiltrados.length}_${_empleadosFiltrados.hashCode}'),
                                  empleados: _empleadosFiltrados,
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
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.greenDark,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Haz clic en las celdas para editar. Los totales se calculan automáticamente.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ESC para cerrar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
