import 'package:flutter/material.dart';
import 'dart:ui';
import 'dropdown_cuadrillas_armar.dart';
import 'package:agribar/services/semana_service.dart';

/// Widget modular mejorado para manejar el diálogo de "Armar Cuadrilla"
/// Versión optimizada con mejor gestión de estado y flujo de trabajo
///
/// Este widget permite:
/// - Seleccionar una cuadrilla para asignar empleados
/// - Buscar y filtrar empleados disponibles
/// - Agregar o quitar empleados de una cuadrilla
/// - Guardar los cambios en la base de datos
///
/// Al guardar, se notifica mediante callbacks para actualizar las vistas relacionadas
class NominaArmarCuadrillaWidget extends StatefulWidget {
  final List<Map<String, dynamic>> optionsCuadrilla;
  final Map<String, dynamic> selectedCuadrilla;
  final List<Map<String, dynamic>> todosLosEmpleados;
  final List<Map<String, dynamic>> empleadosEnCuadrilla;
  final Function(Map<String, dynamic>, List<Map<String, dynamic>>) onCuadrillaSaved;
  final VoidCallback onClose;
  final Function(BuildContext, Map<String, dynamic>) onMostrarDetallesEmpleado;
  /// Callback opcional que se ejecuta después de guardar para actualizar las tablas principal y expandida
  /// Se llama justo después de onCuadrillaSaved y antes de cerrar el diálogo
  final VoidCallback? onActualizarTablas;

  const NominaArmarCuadrillaWidget({
    Key? key,
    required this.optionsCuadrilla,
    required this.selectedCuadrilla,
    required this.todosLosEmpleados,
    required this.empleadosEnCuadrilla,
    required this.onCuadrillaSaved,
    required this.onClose,
    required this.onMostrarDetallesEmpleado,
    this.onActualizarTablas, // Nuevo parámetro opcional
  }) : super(key: key);
  
  @override
  State<NominaArmarCuadrillaWidget> createState() => _NominaArmarCuadrillaWidgetState();
}

class _NominaArmarCuadrillaWidgetState extends State<NominaArmarCuadrillaWidget> {
  // Variables para manejar empleados y filtros
  List<Map<String, dynamic>> empleadosDisponiblesFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaLocal = [];
  Map<String, dynamic> selectedCuadrillaLocal = {};
  
  // Estado de modificación para controlar el botón de guardar
  bool _isDisposed = false;
  bool cuadrillaModificada = false;
  bool guardando = false;
  String? mensajeError;
  
  // Controladores para búsqueda
  final TextEditingController _buscarDisponiblesController = TextEditingController();
  final TextEditingController _buscarEnCuadrillaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  @override
  void didUpdateWidget(NominaArmarCuadrillaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCuadrilla != widget.selectedCuadrilla ||
        oldWidget.empleadosEnCuadrilla != widget.empleadosEnCuadrilla ||
        oldWidget.todosLosEmpleados != widget.todosLosEmpleados) {
      _inicializarDatos();
    }
  }

  /// Inicializa los datos del widget
  void _inicializarDatos() {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      // 🎯 Si no hay cuadrilla seleccionada, seleccionar automáticamente la primera
      if ((widget.selectedCuadrilla['nombre'] == null || 
           widget.selectedCuadrilla['nombre'] == '') && 
          widget.optionsCuadrilla.isNotEmpty) {
        // Seleccionar la primera cuadrilla automáticamente
        selectedCuadrillaLocal = Map<String, dynamic>.from(widget.optionsCuadrilla.first);
        // Cargar empleados de la primera cuadrilla
        empleadosEnCuadrillaLocal = List<Map<String, dynamic>>.from(
          widget.optionsCuadrilla.first['empleados'] ?? []
        );
      } else {
        // Inicializar la cuadrilla seleccionada
        selectedCuadrillaLocal = Map<String, dynamic>.from(widget.selectedCuadrilla);
        // Inicializar empleados en la cuadrilla
        empleadosEnCuadrillaLocal = List<Map<String, dynamic>>.from(widget.empleadosEnCuadrilla);
      }
      
      // Inicializar empleados disponibles (todos los empleados)
      empleadosDisponiblesFiltrados = List.from(widget.todosLosEmpleados);
      
      // Asegurar que cada empleado tenga el campo 'puesto'
      for (var empleado in empleadosEnCuadrillaLocal) {
        empleado['puesto'] = empleado['puesto'] ?? 'Jornalero';
      }
      
      // Resetear estado
      cuadrillaModificada = false;
      mensajeError = null;
      
      // Limpiar controladores de búsqueda
      _buscarDisponiblesController.clear();
      _buscarEnCuadrillaController.clear();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _buscarDisponiblesController.dispose();
    _buscarEnCuadrillaController.dispose();
    super.dispose();
  }

  /// Maneja la adición o eliminación de un empleado de la cuadrilla
  void _toggleSeleccionEmpleado(Map<String, dynamic> empleado) {
    // No permitir agregar empleados si no hay cuadrilla seleccionada
    if (selectedCuadrillaLocal['nombre'] == null || 
        selectedCuadrillaLocal['nombre'] == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Selecciona una cuadrilla primero'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_isDisposed || !mounted) return;
    
    setState(() {
      // Si el empleado ya está en la cuadrilla, quitarlo manteniendo el orden del resto
      if (empleadosEnCuadrillaLocal.any((e) => e['id'] == empleado['id'])) {
        empleadosEnCuadrillaLocal.removeWhere((e) => e['id'] == empleado['id']);
      } else {
        // Si no está en la cuadrilla, agregar una copia al final de la lista
        final empleadoCopia = Map<String, dynamic>.from(empleado);
        empleadoCopia['seleccionado'] = false; // Resetear estado de selección
        empleadosEnCuadrillaLocal.add(empleadoCopia); // Se agrega al final, preservando el orden
      }
      
      // Marcar la cuadrilla como modificada
      cuadrillaModificada = true;
    });
  }

  /// Guarda los empleados de la cuadrilla en la base de datos
  /// 
  /// Flujo de ejecución:
  /// 1. Valida si hay una cuadrilla seleccionada
  /// 2. Obtiene la semana activa
  /// 3. Guarda los empleados en la BD (borrando registros previos)
  /// 4. Notifica con onCuadrillaSaved
  /// 5. Actualiza las tablas con onActualizarTablas
  /// 6. Cierra el diálogo
  Future<void> _guardarCuadrilla() async {
    // Verificar si hay una cuadrilla seleccionada
    if (selectedCuadrillaLocal['id'] == null) {
      if (_isDisposed || !mounted) return;
      setState(() => mensajeError = 'No hay cuadrilla seleccionada');
      return;
    }
    
    // Iniciar proceso de guardado
    if (_isDisposed || !mounted) return;
    setState(() {
      guardando = true;
      mensajeError = null;
    });
    
    try {
      // Obtener la semana activa
      final semanaId = await obtenerSemanaAbierta();
      
      if (semanaId == null || semanaId['id'] == null) {
        if (_isDisposed || !mounted) return;
        setState(() {
          mensajeError = 'No hay semana activa disponible';
          guardando = false;
        });
        return;
      }
      
      // Guardar los empleados en la base de datos
      await guardarEmpleadosCuadrillaSemana(
        semanaId: semanaId['id'],
        cuadrillaId: selectedCuadrillaLocal['id'],
        empleados: empleadosEnCuadrillaLocal,
      );
      
      // Actualizar UI después de guardar
      if (_isDisposed || !mounted) return;
      setState(() {
        guardando = false;
        cuadrillaModificada = false;
      });
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Cuadrilla guardada correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Notificar que se guardó la cuadrilla
      widget.onCuadrillaSaved(selectedCuadrillaLocal, empleadosEnCuadrillaLocal);
      
      // Llamar al callback para actualizar tablas, si está definido
      if (widget.onActualizarTablas != null) {
        widget.onActualizarTablas!();
      }
      
      // Cerrar el diálogo
      widget.onClose();
      
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        mensajeError = 'Error al guardar: $e';
        guardando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la cuadrilla: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Muestra un diálogo de confirmación para cerrar sin guardar
  void _confirmarCerrarSinGuardar() {
    // Si no hay modificaciones, cerrar directamente
    if (!cuadrillaModificada) {
      widget.onClose();
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cerrar sin guardar'),
            ],
          ),
          content: Text(
            'Si cierras la ventana sin guardar, se perderán todos los cambios realizados en esta cuadrilla.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Cerrar sin guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Obtiene la semana actualmente abierta
  Future<Map<String, dynamic>?> obtenerSemanaAbierta() async {
    try {
      final service = SemanaService();
      return await service.obtenerSemanaAbierta();
    } catch (e) {
      print('Error al obtener semana abierta: $e');
      return null;
    }
  }

  /// Guarda los empleados asignados a una cuadrilla para una semana específica
  Future<void> guardarEmpleadosCuadrillaSemana({
    required int semanaId,
    required int cuadrillaId,
    required List<Map<String, dynamic>> empleados,
  }) async {
    try {
      final service = SemanaService();
      await service.guardarEmpleadosCuadrillaSemana(
        semanaId: semanaId,
        cuadrillaId: cuadrillaId,
        empleados: empleados,
      );
    } catch (e) {
      print('Error al guardar empleados en cuadrilla: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar empleados disponibles (excluir los que ya están en la cuadrilla)
    final empleadosDisponibles = empleadosDisponiblesFiltrados
        .where((e) => !empleadosEnCuadrillaLocal.any((ec) => ec['id'] == e['id']))
        .toList();
    
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Header con gradiente
                _buildHeader(),
                
                // Contenido principal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Selector de cuadrilla
                        _buildCuadrillaSelector(),
                        
                        // Mensajes de error
                        if (mensajeError != null) _buildErrorMessage(),
                        
                        const SizedBox(height: 24),
                        
                        // Listas de empleados
                        Expanded(
                          child: Row(
                            children: [
                              // Lista de empleados disponibles
                              Expanded(
                                child: _buildEmpleadosDisponibles(empleadosDisponibles),
                              ),
                              
                              // Separador con indicadores
                              SizedBox(width: 20),
                              _buildSeparador(),
                              SizedBox(width: 20),
                              
                              // Lista de empleados en cuadrilla
                              Expanded(
                                child: _buildEmpleadosEnCuadrilla(),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botones de acción
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para el encabezado
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Armar Cuadrilla',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organiza y gestiona tu equipo de trabajo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _confirmarCerrarSinGuardar,
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                padding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para el selector de cuadrilla
  Widget _buildCuadrillaSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuadrilla Activa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selecciona la cuadrilla a gestionar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownCuadrillasArmar(
                opcionesCuadrillas: widget.optionsCuadrilla,
                cuadrillaSeleccionada:
                    selectedCuadrillaLocal['nombre'] == ''
                        ? null
                        : selectedCuadrillaLocal,
                alSeleccionarCuadrilla: (Map<String, dynamic>? opcion) {
                  // Preguntar si quiere guardar cambios antes de cambiar de cuadrilla
                  if (cuadrillaModificada) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Cambiar de cuadrilla'),
                        content: Text('Hay cambios sin guardar. ¿Deseas cambiar de cuadrilla sin guardar?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _cambiarCuadrilla(opcion);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text('Cambiar'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _cambiarCuadrilla(opcion);
                  }
                },
                textoPlaceholder: 'Seleccionar cuadrilla',
                permitirDeseleccion: true,
                textoBusqueda: 'Buscar cuadrilla...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cambia la cuadrilla seleccionada
  void _cambiarCuadrilla(Map<String, dynamic>? opcion) {
    if (_isDisposed || !mounted) return;
    setState(() {
      if (opcion == null) {
        selectedCuadrillaLocal = {'nombre': '', 'id': null};
        empleadosEnCuadrillaLocal = [];
      } else {
        selectedCuadrillaLocal = opcion;
        // Cargar los empleados de esta cuadrilla
        empleadosEnCuadrillaLocal = widget.optionsCuadrilla
            .firstWhere(
                (c) => c['nombre'] == opcion['nombre'], 
                orElse: () => {'empleados': []})['empleados'] ?? [];
      }
      
      cuadrillaModificada = false;
      _buscarDisponiblesController.clear();
      _buscarEnCuadrillaController.clear();
    });
  }

  // Widget para mensajes de error
  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                mensajeError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget separador con iconos de dirección
  Widget _buildSeparador() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.green.shade700,
            size: 24,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Toca para\nagregar/quitar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // Widget para lista de empleados disponibles
  Widget _buildEmpleadosDisponibles(List<Map<String, dynamic>> empleadosDisponibles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_search_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empleados Disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        '${empleadosDisponibles.length} empleados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _buscarDisponiblesController,
              decoration: InputDecoration(
                hintText: 'Buscar empleado.....',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (_isDisposed || !mounted) return;
                setState(() {
                  if (value.isEmpty) {
                    empleadosDisponiblesFiltrados = List.from(widget.todosLosEmpleados);
                  } else {
                    final query = value.toLowerCase();
                    empleadosDisponiblesFiltrados = widget.todosLosEmpleados.where((emp) {
                      final nombre = emp['nombre']?.toString().toLowerCase() ?? '';
                      final codigo = emp['codigo']?.toString().toLowerCase() ?? '';
                      return nombre.contains(query) || codigo.contains(query);
                    }).toList();
                  }
                });
              },
            ),
          ),
          
          // Lista de empleados
          Expanded(
            child: empleadosDisponibles.isEmpty
                ? _buildEmptyState(
                    'No hay empleados disponibles', 
                    Icons.person_off_rounded
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: empleadosDisponibles.length,
                    itemBuilder: (context, index) {
                      final empleado = empleadosDisponibles[index];
                      return _buildEmpleadoCard(empleado, false);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para lista de empleados en cuadrilla
  Widget _buildEmpleadosEnCuadrilla() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCuadrillaLocal['nombre'] != null && selectedCuadrillaLocal['nombre'] != ''
                          ? 'Cuadrilla: ${selectedCuadrillaLocal['nombre']}'
                          : 'Cuadrilla no seleccionada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        '${empleadosEnCuadrillaLocal.length} empleados en la cuadrilla',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _buscarEnCuadrillaController,
              decoration: InputDecoration(
                hintText: 'Buscar en cuadrillas...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (_isDisposed || !mounted) return;
                setState(() {
                  // La búsqueda se aplica directamente al renderizar la lista
                });
              },
            ),
          ),
          
          // Lista de empleados en cuadrilla
          Expanded(
            child: empleadosEnCuadrillaLocal.isEmpty
                ? _buildEmptyState(
                    selectedCuadrillaLocal['nombre'] != null && selectedCuadrillaLocal['nombre'] != ''
                      ? 'No hay empleados en esta cuadrilla'
                      : 'Selecciona una cuadrilla primero', 
                    Icons.group_off_rounded
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: empleadosEnCuadrillaLocal.length,
                    itemBuilder: (context, index) {
                      final empleado = empleadosEnCuadrillaLocal[index];
                      
                      // Filtrar por búsqueda si hay texto
                      if (_buscarEnCuadrillaController.text.isNotEmpty) {
                        final query = _buscarEnCuadrillaController.text.toLowerCase();
                        final nombre = empleado['nombre']?.toString().toLowerCase() ?? '';
                        final codigo = empleado['codigo']?.toString().toLowerCase() ?? '';
                        final puesto = empleado['puesto']?.toString().toLowerCase() ?? '';
                        
                        if (!nombre.contains(query) && 
                            !codigo.contains(query) &&
                            !puesto.contains(query)) {
                          return SizedBox.shrink();
                        }
                      }
                      
                      return _buildEmpleadoCard(empleado, true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget estado vacío
  Widget _buildEmptyState(String mensaje, IconData icono) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            mensaje,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget para cada tarjeta de empleado
  Widget _buildEmpleadoCard(Map<String, dynamic> empleado, bool enCuadrilla) {
    // Verificar si hay cuadrilla seleccionada para habilitar interacciones
    final bool cuadrillaSeleccionada = selectedCuadrillaLocal['nombre'] != null && 
                                      selectedCuadrillaLocal['nombre'] != '';
    final bool isEnabled = enCuadrilla || cuadrillaSeleccionada;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: !isEnabled 
            ? Colors.grey.shade100 
            : (enCuadrilla ? Colors.green.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !isEnabled 
              ? Colors.grey.shade300
              : (enCuadrilla ? Colors.green.shade200 : Colors.blue.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? () => _toggleSeleccionEmpleado(empleado) : null,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: enCuadrilla 
                      ? Colors.green.shade200 
                      : Colors.blue.shade200,
                  radius: 20,
                  child: Text(
                    empleado['nombre'].toString().substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: enCuadrilla 
                          ? Colors.green.shade800 
                          : Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empleado['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isEnabled 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            empleado['puesto'] ?? 'Jornalero',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (empleado['codigo'] != null && empleado['codigo'].toString().isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              'Código: ${empleado['codigo']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón para ver detalles del empleado
                IconButton(
                  onPressed: () => widget.onMostrarDetallesEmpleado(context, empleado),
                  icon: Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 22,
                  ),
                  tooltip: 'Ver detalles',
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.all(4),
                ),
                SizedBox(width: 4),
                if (enCuadrilla)
                  Icon(
                    Icons.remove_circle,
                    color: Colors.red.shade300,
                    size: 20,
                  )
                else if (isEnabled)
                  Icon(
                    Icons.add_circle,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget botones de acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _confirmarCerrarSinGuardar,
            icon: Icon(Icons.cancel_outlined),
            label: Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              foregroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: (cuadrillaModificada && !guardando && selectedCuadrillaLocal['id'] != null) 
                ? _guardarCuadrilla 
                : null,
            icon: guardando 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save_rounded),
            label: Text(guardando 
                ? 'Guardando...' 
                : 'Guardar Cuadrilla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cuadrillaModificada 
                  ? Colors.green.shade600 
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}