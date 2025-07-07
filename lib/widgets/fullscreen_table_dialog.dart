import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import '../widgets/editable_data_table.dart';
import '../widgets/custom_dropdown_menu.dart';

/// Diálogo modal para mostrar tablas en pantalla completa.
/// Diseño simple y profesional para captura de nómina.
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
  
  // 🎯 Nuevas propiedades para el dropdown de cuadrillas
  final List<Map<String, dynamic>> cuadrillas;
  final Map<String, dynamic>? cuadrillaSeleccionada;
  final Function(Map<String, dynamic>?) onCuadrillaChanged;
  
  const FullscreenTableDialog({
    Key? key,
    required this.empleados,
    required this.semanaSeleccionada,
    required this.onChanged,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
    required this.cuadrillas,
    this.cuadrillaSeleccionada,
    required this.onCuadrillaChanged,
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
          // Fondo con desenfoque sutil
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
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
                  // Header con estilo similar al menú "Armar Cuadrilla"
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7BAE2F),
                          Color(0xFF6B9E2A),
                          Color(0xFF5C8E25),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Row(
                        children: [
                          // Icono y título principal
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.table_view_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Captura de Nómina',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Edita y captura los datos de nómina semanal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón cerrar
                          IconButton(
                            onPressed: widget.onClose,
                            icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Barra unificada: búsqueda, semana e info de cuadrilla en una sola línea
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Información de la semana (compacta)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semana',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.green.shade700,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    widget.semanaSeleccionada != null
                                        ? '${widget.semanaSeleccionada!.start.day}/${widget.semanaSeleccionada!.start.month} - ${widget.semanaSeleccionada!.end.day}/${widget.semanaSeleccionada!.end.month}'
                                        : 'Sin semana',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(width: 24),
                        
                        // Dropdown de cuadrillas (con widget genérico)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cuadrilla',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
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
                        
                        SizedBox(width: 24),
                        
                        // Campo de búsqueda (más compacto)
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar empleado...',
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.search,
                                  color: AppColors.greenDark,
                                  size: 18,
                                ),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey.shade600,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterEmpleados('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: AppColors.greenDark.withOpacity(0.3), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: AppColors.greenDark, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: _filterEmpleados,
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        // Indicador de resultados con etiqueta
                        Column(
                          children: [
                            Text(
                              'Empleados',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.greenDark,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${_filteredEmpleados.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido de la tabla
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
                          child: Scrollbar(
                            controller: widget.horizontalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: widget.horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 1200),
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
                    ),
                  ),
                  
                  // Footer simple con información
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