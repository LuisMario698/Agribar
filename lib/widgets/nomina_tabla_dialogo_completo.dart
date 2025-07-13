import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import '../widgets/nomina_tabla_editable.dart';

/// Diálogo modal para mostrar tablas de nómina en pantalla completa.
/// Diseño optimizado y profesional para captura de datos.
class NominaTablaDialogoCompleto extends StatefulWidget {
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
  
  const NominaTablaDialogoCompleto({
    Key? key,
    required this.empleados,
    required this.semanaSeleccionada,
    required this.onChanged,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
  }) : super(key: key);

  @override
  State<NominaTablaDialogoCompleto> createState() => _NominaTablaDialogoCompletoState();
}

class _NominaTablaDialogoCompletoState extends State<NominaTablaDialogoCompleto> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filteredEmpleados;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _filteredEmpleados = List.from(widget.empleados);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmpleados(String searchText) {
    if (_isDisposed || !mounted) return;
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
          // Fondo con desenfoque elegante y gradiente
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: screenWidth * 0.96,
              height: screenHeight * 0.92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header mejorado con diseño premium
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8BC34A), // Verde más vibrante
                          Color(0xFF7BAE2F),
                          Color(0xFF689F38),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF7BAE2F).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                      child: Row(
                        children: [
                          // Icono mejorado con fondo elegante
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.dashboard_customize_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Captura de Nómina',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Edita y captura los datos de nómina semanal de forma eficiente',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón cerrar mejorado
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: widget.onClose,
                              icon: Icon(Icons.close_rounded, color: Colors.white, size: 26),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.all(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Barra de herramientas moderna y elegante
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Información de la semana con diseño premium
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.green.shade100],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_note_rounded,
                                    color: Colors.green.shade700,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Semana Actual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300, width: 1),
                                ),
                                child: Text(
                                  widget.semanaSeleccionada != null
                                      ? '${widget.semanaSeleccionada!.start.day}/${widget.semanaSeleccionada!.start.month} - ${widget.semanaSeleccionada!.end.day}/${widget.semanaSeleccionada!.end.month}'
                                      : 'Sin semana',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 32),
                        
                        // Campo de búsqueda rediseñado
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar empleado por nombre o código...',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.greenDark,
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: Colors.grey.shade500,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterEmpleados('');
                                        },
                                      )
                                    : Icon(
                                        Icons.keyboard_rounded,
                                        color: Colors.grey.shade400,
                                        size: 18,
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppColors.greenDark, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              onChanged: _filterEmpleados,
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 24),
                        
                        // Contador de empleados con diseño premium
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.greenDark, AppColors.greenDark.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.greenDark.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Empleados',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_filteredEmpleados.length}',
                                  style: TextStyle(
                                    color: AppColors.greenDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido de la tabla con diseño mejorado
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            // Barra superior de la tabla
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_rows_rounded,
                                    color: AppColors.greenDark,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Tabla de Captura',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenDark.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Scroll horizontal/vertical',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.greenDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Contenido de la tabla
                            Expanded(
                              child: Scrollbar(
                                controller: widget.horizontalController,
                                thumbVisibility: true,
                                thickness: 8,
                                radius: Radius.circular(4),
                                child: SingleChildScrollView(
                                  controller: widget.horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(minWidth: 1200),
                                    child: Scrollbar(
                                      controller: widget.verticalController,
                                      thumbVisibility: true,
                                      thickness: 8,
                                      radius: Radius.circular(4),
                                      child: SingleChildScrollView(
                                        controller: widget.verticalController,
                                        scrollDirection: Axis.vertical,
                                        child: NominaTablaEditable(
                                          key: ValueKey('fullscreen_table_${_filteredEmpleados.length}_${_filteredEmpleados.hashCode}'),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Footer elegante con información útil
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade50, Colors.grey.shade100],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.greenDark.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.greenDark,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Haz clic en las celdas para editar valores. Los totales se calculan automáticamente.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_rounded,
                                color: Colors.grey.shade600,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ESC para cerrar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
}
