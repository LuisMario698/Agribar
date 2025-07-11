import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/semana_service.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';
import 'dropdown_cuadrillas_armar.dart';

/// Widget modular para manejar el diálogo de "Armar Cuadrilla"
/// Encapsula toda la funcionalidad relacionada con la creación y edición de cuadrillas
/// manteniendo el mismo diseño y comportamiento original
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
Future<List<Map<String, dynamic>>> obtenerNominaEmpleadosDeCuadrilla(int semanaId, int cuadrillaId) async {
  final db = DatabaseService();
  await db.connect();

  final result = await db.connection.query('''
    SELECT 
      e.id_empleado,
      e.nombre,
      e.codigo,
      n.lunes,
      n.martes,
      n.miercoles,
      n.jueves,
      n.viernes,
      n.sabado,
      n.domingo,
      n.total,
      n.debe,
      n.subtotal,
      n.descuento_comedor
    FROM nomina_empleados_semanal n
    JOIN empleados e ON e.id_empleado = n.empleado_id
    WHERE n.semana_id = @semanaId AND n.cuadrilla_id = @cuadrillaId;
  ''', substitutionValues: {
    'semanaId': semanaId,
    'cuadrillaId': cuadrillaId,
  });

  await db.close();

  return result.map((row) => {
    'id': row[0],
    'nombre': row[1],
    'codigo': row[2],
    'lunes': row[3],
    'martes': row[4],
    'miercoles': row[5],
    'jueves': row[6],
    'viernes': row[7],
    'sabado': row[8],
    'domingo': row[9],
    'total': row[10],
    'debe': row[11],
    'subtotal': row[12],
    'comedor': row[13],
  }).toList();
}

class _NominaArmarCuadrillaWidgetState
    extends State<NominaArmarCuadrillaWidget> {
  // Variables locales para el manejo del widget
  List<Map<String, dynamic>> empleadosDisponiblesFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaLocal = [];
  Map<String, dynamic> selectedCuadrillaLocal = {};

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
    });
  }

  void _confirmarCerrarSinGuardar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 28,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cerrar sin guardar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Si cierra la ventana sin guardar, se perderán todos los cambios realizados en esta cuadrilla.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.greenDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onClose();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Cerrar sin guardar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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

  void _guardarCambios() async {
    final semanaId =
        await obtenerSemanaAbierta(); //obtenerIdSemanaActiva(); // Debes tenerla
    final cuadrillaId = selectedCuadrillaLocal['id'];

    if (semanaId == null || cuadrillaId == null) return;

    await guardarEmpleadosCuadrillaSemana(
      semanaId: semanaId['id'],
      cuadrillaId: cuadrillaId,
      empleados: empleadosEnCuadrillaLocal,
    );

    widget.onCuadrillaSaved(selectedCuadrillaLocal, empleadosEnCuadrillaLocal);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups, size: 28, color: AppColors.green),
                          const SizedBox(width: 12),
                          Text(
                            'Armar Cuadrilla',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _confirmarCerrarSinGuardar,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selector de cuadrilla para cambiar dentro del diálogo
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.greenDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cambiar cuadrilla:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownCuadrillasArmar(
                              opcionesCuadrillas: widget.optionsCuadrilla,
                              cuadrillaSeleccionada:
                                  selectedCuadrillaLocal['nombre'] == ''
                                      ? null
                                      : selectedCuadrillaLocal,
                              alSeleccionarCuadrilla: (Map<String, dynamic>? opcion) {
                                setState(() {
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
                                    empleadosEnCuadrillaLocal =
                                        List<Map<String, dynamic>>.from(
                                          opcion['empleados'] ?? [],
                                        );
                                    empleadosDisponiblesFiltrados = List.from(
                                      widget.todosLosEmpleados,
                                    );
                                    empleadosEnCuadrillaFiltrados = List.from(
                                      empleadosEnCuadrillaLocal,
                                    );
                                    _buscarDisponiblesController.clear();
                                    _buscarEnCuadrillaController.clear();
                                  }
                                });
                              },
                              textoPlaceholder: 'Seleccionar cuadrilla',
                              permitirDeseleccion: true,
                              textoBusqueda: 'Buscar cuadrilla...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 650, // Aumentado de 500 a 650 para mostrar más contenido
                    child: Row(
                      children: [
                        // Lista de empleados disponibles
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.cardRadius,
                              ),
                              side: BorderSide(color: Colors.grey.shade200),
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
                                      top: Radius.circular(
                                        AppDimens.cardRadius,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: AppColors.greenDark,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Empleados Disponibles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Barra de búsqueda
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.buttonRadius,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                                          decoration: InputDecoration(
                                            hintText: 'Buscar empleado...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade500,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                          controller:
                                              _buscarDisponiblesController,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value.isEmpty) {
                                                empleadosDisponiblesFiltrados =
                                                    List.from(
                                                      widget.todosLosEmpleados,
                                                    );
                                              } else {
                                                final query =
                                                    value.toLowerCase();
                                                empleadosDisponiblesFiltrados =
                                                    widget.todosLosEmpleados.where((
                                                      emp,
                                                    ) {
                                                      final nombre =
                                                          emp['nombre']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          '';
                                                      final puesto =
                                                          emp['puesto']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          '';
                                                      return nombre.contains(
                                                            query,
                                                          ) ||
                                                          puesto.contains(
                                                            query,
                                                          );
                                                    }).toList();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Lista de empleados disponibles
                                Expanded(
                                  child:
                                      empleadosDisponiblesFiltrados
                                              .where(
                                                (e) =>
                                                    !empleadosEnCuadrillaLocal
                                                        .any(
                                                          (ec) =>
                                                              ec['id'] ==
                                                              e['id'],
                                                        ),
                                              )
                                              .isEmpty
                                          ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.person_add_disabled,
                                                  size: 48,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  widget
                                                          .todosLosEmpleados
                                                          .isEmpty
                                                      ? 'No hay empleados disponibles'
                                                      : (empleadosEnCuadrillaLocal
                                                              .length ==
                                                          widget
                                                              .todosLosEmpleados
                                                              .length)
                                                      ? 'Todos los empleados ya están en la cuadrilla'
                                                      : 'No hay resultados para esta búsqueda',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : ListView.builder(
                                            itemCount:
                                                empleadosDisponiblesFiltrados
                                                    .where(
                                                      (e) =>
                                                          !empleadosEnCuadrillaLocal
                                                              .any(
                                                                (ec) =>
                                                                    ec['id'] ==
                                                                    e['id'],
                                                              ),
                                                    )
                                                    .length,
                                            itemBuilder: (context, index) {
                                              final empleadosDisponibles =
                                                  empleadosDisponiblesFiltrados
                                                      .where(
                                                        (e) =>
                                                            !empleadosEnCuadrillaLocal
                                                                .any(
                                                                  (ec) =>
                                                                      ec['id'] ==
                                                                      e['id'],
                                                                ),
                                                      )
                                                      .toList();
                                              final empleado =
                                                  empleadosDisponibles[index];
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor: AppColors
                                                        .green
                                                        .withOpacity(0.1),
                                                    child: Text(
                                                      empleado['nombre']
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: AppColors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    empleado['nombre'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    empleado['puesto'],
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .visibility_outlined,
                                                        ),
                                                        color: Colors.blue,
                                                        onPressed:
                                                            () => widget
                                                                .onMostrarDetallesEmpleado(
                                                                  context,
                                                                  empleado,
                                                                ),
                                                        tooltip: 'Ver detalles',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .add_circle_outline,
                                                        ),
                                                        color: AppColors.green,
                                                        onPressed:
                                                            () =>
                                                                _toggleSeleccionEmpleado(
                                                                  empleado,
                                                                ),
                                                        tooltip:
                                                            'Agregar a cuadrilla',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Lista de empleados en cuadrilla
                        Expanded(
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.cardRadius,
                              ),
                              side: BorderSide(color: Colors.grey.shade200),
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
                                      top: Radius.circular(
                                        AppDimens.cardRadius,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.groups,
                                        color: AppColors.greenDark,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Empleados en Cuadrilla',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${empleadosEnCuadrillaLocal.length}',
                                          style: TextStyle(
                                            color: AppColors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Barra de búsqueda para cuadrilla
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.buttonRadius,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                                          decoration: InputDecoration(
                                            hintText: 'Buscar en cuadrilla...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade500,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                          controller:
                                              _buscarEnCuadrillaController,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value.isEmpty) {
                                                empleadosEnCuadrillaFiltrados =
                                                    List.from(
                                                      empleadosEnCuadrillaLocal,
                                                    );
                                              } else {
                                                final query =
                                                    value.toLowerCase();
                                                empleadosEnCuadrillaFiltrados =
                                                    empleadosEnCuadrillaLocal.where((
                                                      emp,
                                                    ) {
                                                      final nombre =
                                                          emp['nombre']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          '';
                                                      final puesto =
                                                          emp['puesto']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          '';
                                                      return nombre.contains(
                                                            query,
                                                          ) ||
                                                          puesto.contains(
                                                            query,
                                                          );
                                                    }).toList();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Lista de empleados en cuadrilla
                                Expanded(
                                  child:
                                      empleadosEnCuadrillaFiltrados.isEmpty
                                          ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.group_add,
                                                  size: 48,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  empleadosEnCuadrillaLocal
                                                          .isEmpty
                                                      ? 'Añade empleados a la cuadrilla'
                                                      : 'No hay resultados para esta búsqueda',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : ListView.builder(
                                            itemCount:
                                                empleadosEnCuadrillaFiltrados
                                                    .length,
                                            itemBuilder: (context, index) {
                                              final empleado =
                                                  empleadosEnCuadrillaFiltrados[index];
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor: Colors
                                                        .green
                                                        .withOpacity(0.1),
                                                    child: Text(
                                                      empleado['nombre']
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: AppColors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    empleado['nombre'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    empleado['puesto'] ??
                                                        'Jornalero',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .visibility_outlined,
                                                        ),
                                                        color: Colors.blue,
                                                        onPressed:
                                                            () => widget
                                                                .onMostrarDetallesEmpleado(
                                                                  context,
                                                                  empleado,
                                                                ),
                                                        tooltip: 'Ver detalles',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                        ),
                                                        color: Colors.red,
                                                        onPressed:
                                                            () =>
                                                                _toggleSeleccionEmpleado(
                                                                  empleado,
                                                                ),
                                                        tooltip:
                                                            'Quitar de cuadrilla',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _confirmarCerrarSinGuardar,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _guardarCambios,
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar cambios'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
