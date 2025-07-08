import 'package:flutter/material.dart';
import 'dart:ui';
import 'dropdown_cuadrillas_armar.dart';

/// Widget modular mejorado para manejar el diálogo de "Armar Cuadrilla"
/// Rediseñado con una interfaz moderna manteniendo toda la funcionalidad original
class NominaArmarCuadrillaWidget extends StatefulWidget {
  final List<Map<String, dynamic>> optionsCuadrilla;
  final Map<String, dynamic> selectedCuadrilla;
  final List<Map<String, dynamic>> todosLosEmpleados;
  final List<Map<String, dynamic>> empleadosEnCuadrilla;
  final Function(Map<String, dynamic>, List<Map<String, dynamic>>)
  onCuadrillaSaved;
  final VoidCallback onClose;
  final Function(BuildContext, Map<String, dynamic>) onMostrarDetallesEmpleado;

  const NominaArmarCuadrillaWidget({
    Key? key,
    required this.optionsCuadrilla,
    required this.selectedCuadrilla,
    required this.todosLosEmpleados,
    required this.empleadosEnCuadrilla,
    required this.onCuadrillaSaved,
    required this.onClose,
    required this.onMostrarDetallesEmpleado,
  }) : super(key: key);
  
  @override
  State<NominaArmarCuadrillaWidget> createState() =>
      _NominaArmarCuadrillaWidgetState();
}

class _NominaArmarCuadrillaWidgetState
    extends State<NominaArmarCuadrillaWidget> {
  // Variables locales para el manejo del widget
  List<Map<String, dynamic>> empleadosDisponiblesFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaLocal = [];
  Map<String, dynamic> selectedCuadrillaLocal = {};

  // 🆕 NUEVO: Mapa para mantener empleados de todas las cuadrillas
  Map<String, List<Map<String, dynamic>>> empleadosPorCuadrilla = {};
  
  // 🆕 NUEVO: Set para rastrear qué cuadrillas han sido modificadas
  Set<String> cuadrillasModificadas = {};

  final TextEditingController _buscarDisponiblesController =
      TextEditingController();
  final TextEditingController _buscarEnCuadrillaController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarDatos(desdeInitState: true);
  }

  @override
  void didUpdateWidget(NominaArmarCuadrillaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los datos del widget han cambiado, actualizar las variables locales
    if (oldWidget.selectedCuadrilla != widget.selectedCuadrilla ||
        oldWidget.empleadosEnCuadrilla != widget.empleadosEnCuadrilla ||
        oldWidget.todosLosEmpleados != widget.todosLosEmpleados) {
      _inicializarDatos();
    }
  }

  /// Inicializa o actualiza los datos locales del widget
  void _inicializarDatos({bool desdeInitState = false}) {
    if (desdeInitState) {
      // Durante initState, no usar setState
      _actualizarDatosInternos();
    } else {
      // Fuera de initState, usar setState para refrescar la UI
      setState(() {
        _actualizarDatosInternos();
      });
    }
  }

  /// Actualiza los datos internos sin setState
  void _actualizarDatosInternos() {
    // Inicializar estados locales
    selectedCuadrillaLocal = Map<String, dynamic>.from(
      widget.selectedCuadrilla,
    );
    empleadosEnCuadrillaLocal = List<Map<String, dynamic>>.from(
      widget.empleadosEnCuadrilla,
    );

    // 🆕 NUEVO: Inicializar mapa de empleados por cuadrilla si está vacío
    if (empleadosPorCuadrilla.isEmpty) {
      // Inicializar con los empleados actuales si hay una cuadrilla seleccionada
      if (selectedCuadrillaLocal['nombre'] != null && selectedCuadrillaLocal['nombre'] != '') {
        final nombreCuadrilla = selectedCuadrillaLocal['nombre'] as String;
        empleadosPorCuadrilla[nombreCuadrilla] = List<Map<String, dynamic>>.from(empleadosEnCuadrillaLocal);
      }
      
      // Inicializar todas las cuadrillas disponibles con listas vacías si no existen
      for (var cuadrilla in widget.optionsCuadrilla) {
        final nombre = cuadrilla['nombre'] as String;
        if (!empleadosPorCuadrilla.containsKey(nombre)) {
          empleadosPorCuadrilla[nombre] = [];
        }
      }
    }

    // 🆕 NUEVO: Cargar empleados de la cuadrilla seleccionada desde el mapa
    if (selectedCuadrillaLocal['nombre'] != null && selectedCuadrillaLocal['nombre'] != '') {
      final nombreCuadrilla = selectedCuadrillaLocal['nombre'] as String;
      empleadosEnCuadrillaLocal = List<Map<String, dynamic>>.from(
        empleadosPorCuadrilla[nombreCuadrilla] ?? []
      );
    }

    // Inicializar listas filtradas
    empleadosDisponiblesFiltrados = List.from(widget.todosLosEmpleados);
    empleadosEnCuadrillaFiltrados = List.from(empleadosEnCuadrillaLocal);

    // Asegurar que cada empleado en la cuadrilla tenga el campo 'puesto'
    for (var empleado in empleadosEnCuadrillaLocal) {
      empleado['puesto'] = empleado['puesto'] ?? 'Jornalero';
    }

    // Limpiar los controladores de búsqueda
    _buscarDisponiblesController.clear();
    _buscarEnCuadrillaController.clear();
  }

  @override
  void dispose() {
    _buscarDisponiblesController.dispose();
    _buscarEnCuadrillaController.dispose();
    super.dispose();
  }

  void _toggleSeleccionEmpleado(Map<String, dynamic> empleado) {
    // 🚫 No permitir agregar empleados si no hay cuadrilla seleccionada
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
    
    setState(() {
      // Crear una copia del empleado para la cuadrilla
      final empleadoCopia = Map<String, dynamic>.from(empleado);
      empleadoCopia['seleccionado'] = false; // Resetear estado de selección

      // Si el empleado ya está en la cuadrilla, quitarlo
      if (empleadosEnCuadrillaLocal.any((e) => e['id'] == empleado['id'])) {
        // Primero eliminamos de la lista original
        empleadosEnCuadrillaLocal.removeWhere((e) => e['id'] == empleado['id']);

        // Después actualizamos la lista filtrada
        empleadosEnCuadrillaFiltrados.removeWhere(
          (e) => e['id'] == empleado['id'],
        );
      } else {
        // Si no está en la cuadrilla, agregarlo a la lista original
        empleadosEnCuadrillaLocal.add(empleadoCopia);

        // Luego decidir si debe ser visible en la lista filtrada según el filtro activo
        if (_buscarEnCuadrillaController.text.isEmpty) {
          // Si no hay filtro activo, el nuevo empleado se ve en la lista filtrada
          empleadosEnCuadrillaFiltrados.add(empleadoCopia);
        } else {
          // Si hay filtro activo, verificamos si el empleado cumple con el criterio
          final query = _buscarEnCuadrillaController.text.toLowerCase();
          final nombre =
              empleadoCopia['nombre']?.toString().toLowerCase() ?? '';
          final puesto =
              empleadoCopia['puesto']?.toString().toLowerCase() ?? '';
          if (nombre.contains(query) || puesto.contains(query)) {
            empleadosEnCuadrillaFiltrados.add(empleadoCopia);
          }
          // Si no cumple el criterio, no se agrega a la lista filtrada pero sí a la original
        }
      }
      
      // 🆕 NUEVO: Actualizar el mapa de empleados por cuadrilla y marcar como modificada
      if (selectedCuadrillaLocal['nombre'] != null && selectedCuadrillaLocal['nombre'] != '') {
        final nombreCuadrilla = selectedCuadrillaLocal['nombre'] as String;
        empleadosPorCuadrilla[nombreCuadrilla] = List<Map<String, dynamic>>.from(empleadosEnCuadrillaLocal);
        cuadrillasModificadas.add(nombreCuadrilla);
      }
    });
  }

  /// 🆕 NUEVO: Guarda todas las cuadrillas que han sido modificadas
  void _guardarTodasLasCuadrillas() async {
    if (cuadrillasModificadas.isEmpty) {
      // Si no hay cuadrillas modificadas, usar el callback original
      widget.onCuadrillaSaved(
        selectedCuadrillaLocal,
        empleadosEnCuadrillaLocal,
      );
      widget.onClose();
      return;
    }

    // Mostrar diálogo de confirmación con resumen
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.save_rounded, color: Colors.green.shade600),
              SizedBox(width: 8),
              Text('Guardar Cuadrillas'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Se guardarán ${cuadrillasModificadas.length} cuadrilla(s) modificada(s):'),
              SizedBox(height: 12),
              ...cuadrillasModificadas.map((nombre) {
                final empleados = empleadosPorCuadrilla[nombre] ?? [];
                return Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.group, size: 16, color: Colors.green.shade600),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('$nombre (${empleados.length} empleados)'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Guardar Todo'),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      // Procesar cada cuadrilla modificada
      for (String nombreCuadrilla in cuadrillasModificadas) {
        final empleados = empleadosPorCuadrilla[nombreCuadrilla] ?? [];
        final cuadrilla = widget.optionsCuadrilla.firstWhere(
          (c) => c['nombre'] == nombreCuadrilla,
          orElse: () => {'nombre': nombreCuadrilla, 'id': null},
        );
        
        // Llamar al callback para cada cuadrilla
        widget.onCuadrillaSaved(cuadrilla, empleados);
      }
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${cuadrillasModificadas.length} cuadrilla(s) guardada(s) exitosamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      widget.onClose();
    }
  }

  void _confirmarCerrarSinGuardar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cerrar sin guardar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Si cierras la ventana sin guardar, se perderán todos los cambios realizados en esta cuadrilla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onClose();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cerrar sin guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white, // 🎨 Fondo completamente blanco
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // ✨ Header moderno con gradiente
                Container(
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
                ),
                
                // ✨ Contenido principal con padding mejorado
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ✨ Selector de cuadrilla rediseñado
                        Container(
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
                                      setState(() {
                                        // 🆕 NUEVO: Guardar empleados de la cuadrilla anterior antes de cambiar
                                        if (selectedCuadrillaLocal['nombre'] != null && 
                                            selectedCuadrillaLocal['nombre'] != '') {
                                          final nombreAnterior = selectedCuadrillaLocal['nombre'] as String;
                                          empleadosPorCuadrilla[nombreAnterior] = List<Map<String, dynamic>>.from(empleadosEnCuadrillaLocal);
                                          cuadrillasModificadas.add(nombreAnterior);
                                        }
                                        
                                        if (opcion == null) {
                                          selectedCuadrillaLocal = {
                                            'nombre': '',
                                            'empleados': [],
                                          };
                                          empleadosEnCuadrillaLocal = [];
                                          empleadosDisponiblesFiltrados = List.from(
                                            widget.todosLosEmpleados,
                                          );
                                          empleadosEnCuadrillaFiltrados = [];
                                        } else {
                                          selectedCuadrillaLocal = opcion;
                                          
                                          // 🆕 NUEVO: Cargar empleados de la nueva cuadrilla desde el mapa
                                          final nombreNuevo = opcion['nombre'] as String;
                                          empleadosEnCuadrillaLocal = List<Map<String, dynamic>>.from(
                                            empleadosPorCuadrilla[nombreNuevo] ?? [],
                                          );
                                          
                                          empleadosDisponiblesFiltrados = List.from(
                                            widget.todosLosEmpleados,
                                          );
                                          empleadosEnCuadrillaFiltrados = List.from(
                                            empleadosEnCuadrillaLocal,
                                          );
                                        }
                                        _buscarDisponiblesController.clear();
                                        _buscarEnCuadrillaController.clear();
                                      });
                                    },
                                    textoPlaceholder: 'Seleccionar cuadrilla',
                                    permitirDeseleccion: true,
                                    textoBusqueda: 'Buscar cuadrilla...',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 🆕 NUEVO: Indicador de cuadrillas modificadas
                        if (cuadrillasModificadas.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16, color: Colors.blue.shade700),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${cuadrillasModificadas.length} cuadrilla(s) modificada(s): ${cuadrillasModificadas.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // ✨ Sección principal con listas de empleados
                        Expanded(
                          child: Row(
                            children: [
                              // ✨ Lista de empleados disponibles
                              Expanded(
                                child: _buildEmpleadosDisponibles(),
                              ),
                              
                              // ✨ Espacio entre columnas
                              SizedBox(width: 20),
                              
                              // ✨ Botones de transferencia en el centro
                              Column(
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
                                    'Arrastra o\ntoca para\nagregar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.red.shade700,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // ✨ Espacio entre columnas
                              SizedBox(width: 20),
                              
                              // ✨ Lista de empleados en cuadrilla
                              Expanded(
                                child: _buildEmpleadosEnCuadrilla(),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // ✨ Botones de acción modernos
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => widget.onClose(),
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
                                onPressed: empleadosEnCuadrillaLocal.isNotEmpty
                                    ? () {
                                        // 🆕 NUEVO: Guardar la cuadrilla actual antes de proceder
                                        if (selectedCuadrillaLocal['nombre'] != null && 
                                            selectedCuadrillaLocal['nombre'] != '') {
                                          final nombreActual = selectedCuadrillaLocal['nombre'] as String;
                                          empleadosPorCuadrilla[nombreActual] = List<Map<String, dynamic>>.from(empleadosEnCuadrillaLocal);
                                          cuadrillasModificadas.add(nombreActual);
                                        }
                                        
                                        // 🆕 NUEVO: Guardar todas las cuadrillas modificadas
                                        _guardarTodasLasCuadrillas();
                                      }
                                    : null,
                                icon: Icon(Icons.save_rounded),
                                label: Text(
                                  cuadrillasModificadas.isEmpty 
                                    ? 'Guardar Cuadrilla (${empleadosEnCuadrillaLocal.length})' 
                                    : 'Guardar ${cuadrillasModificadas.length} Cuadrilla(s)',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  // ✨ Widget para la lista de empleados disponibles
  Widget _buildEmpleadosDisponibles() {
    // 🔧 REVERTIDO: Filtrar empleados que ya están en la cuadrilla (comportamiento original)
    final empleadosDisponibles = empleadosDisponiblesFiltrados
        .where((e) => !empleadosEnCuadrillaLocal.any((ec) => ec['id'] == e['id']))
        .toList();

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
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        '${empleadosDisponibles.length} empleados',
                        style: TextStyle(
                          fontSize: 12,
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
                hintText: 'Buscar empleado...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay empleados disponibles',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 🚫 Mensaje cuando no hay cuadrilla seleccionada
                      if (selectedCuadrillaLocal['nombre'] == null || 
                          selectedCuadrillaLocal['nombre'] == '') ...[
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selecciona una cuadrilla para agregar empleados',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Lista de empleados
                      Expanded(
                        child: ListView.builder(
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
          ),
        ],
      ),
    );
  }

  // ✨ Widget para la lista de empleados en cuadrilla
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
                    Icons.groups_rounded,
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
                        'Cuadrilla Actual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        '${empleadosEnCuadrillaLocal.length} empleados',
                        style: TextStyle(
                          fontSize: 12,
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
                hintText: 'Buscar en cuadrilla...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    empleadosEnCuadrillaFiltrados = List.from(empleadosEnCuadrillaLocal);
                  } else {
                    final query = value.toLowerCase();
                    empleadosEnCuadrillaFiltrados = empleadosEnCuadrillaLocal.where((emp) {
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
            child: empleadosEnCuadrillaLocal.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_add_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cuadrilla vacía',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Agrega empleados desde la lista',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: empleadosEnCuadrillaFiltrados.length,
                    itemBuilder: (context, index) {
                      final empleado = empleadosEnCuadrillaFiltrados[index];
                      return _buildEmpleadoCard(empleado, true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✨ Widget para cada tarjeta de empleado
  Widget _buildEmpleadoCard(Map<String, dynamic> empleado, bool enCuadrilla) {
    // 🚫 Verificar si hay cuadrilla seleccionada para habilitar interacciones
    final bool cuadrillaSeleccionada = selectedCuadrillaLocal['nombre'] != null && 
                                      selectedCuadrillaLocal['nombre'] != '';
    final bool isEnabled = enCuadrilla || cuadrillaSeleccionada;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: !isEnabled 
            ? Colors.grey.shade400 
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
                  radius: 20,
                  backgroundColor: !isEnabled 
                      ? Colors.grey.shade400
                      : (enCuadrilla ? Colors.green.shade600 : Colors.blue.shade600),
                  child: Text(
                    empleado['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                    style: TextStyle(
                      color: Colors.white,
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
                          fontSize: 14,
                          color: !isEnabled 
                              ? Colors.grey.shade500 
                              : Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Código: ${empleado['codigo'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: !isEnabled 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // ✨ Botón para ver detalles del empleado
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    onPressed: () => widget.onMostrarDetallesEmpleado(context, empleado),
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: Colors.blue.shade700, // 🎨 Azul fuerte para el ícono
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50, // 🎨 Fondo azul claro
                      padding: EdgeInsets.all(6),
                      minimumSize: Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    tooltip: 'Ver detalles del empleado',
                  ),
                ),
                Icon(
                  enCuadrilla ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: !isEnabled 
                      ? Colors.grey.shade400
                      : (enCuadrilla ? Colors.red.shade600 : Colors.green.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
