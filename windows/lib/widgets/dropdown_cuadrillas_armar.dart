import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget dropdown específico para seleccionar cuadrillas dentro del diálogo "Armar Cuadrilla"
/// Este dropdown es independiente del dropdown principal de la pantalla de nómina
/// y maneja su propia lista de cuadrillas disponibles para armar/editar
class DropdownCuadrillasArmar extends StatefulWidget {
  /// Lista de opciones de cuadrillas disponibles para armar
  final List<Map<String, dynamic>> opcionesCuadrillas;
  
  /// Cuadrilla actualmente seleccionada
  final Map<String, dynamic>? cuadrillaSeleccionada;
  
  /// Callback que se ejecuta cuando se selecciona una cuadrilla
  final Function(Map<String, dynamic>?) alSeleccionarCuadrilla;
  
  /// Texto que se muestra cuando no hay selección
  final String textoPlaceholder;
  
  /// Si permite deseleccionar la opción actual
  final bool permitirDeseleccion;
  
  /// Texto de búsqueda en el dropdown
  final String? textoBusqueda;
  
  /// Si el dropdown está deshabilitado
  final bool deshabilitado;

  const DropdownCuadrillasArmar({
    Key? key,
    required this.opcionesCuadrillas,
    required this.cuadrillaSeleccionada,
    required this.alSeleccionarCuadrilla,
    this.textoPlaceholder = 'Seleccionar cuadrilla',
    this.permitirDeseleccion = true,
    this.textoBusqueda,
    this.deshabilitado = false,
  }) : super(key: key);

  @override
  State<DropdownCuadrillasArmar> createState() => _DropdownCuadrillasArmarState();
}

class _DropdownCuadrillasArmarState extends State<DropdownCuadrillasArmar> {
  /// Controlador para el campo de búsqueda
  final TextEditingController _controladorBusqueda = TextEditingController();
  
  /// Lista filtrada de cuadrillas basada en la búsqueda
  List<Map<String, dynamic>> _opcionesFiltradas = [];
  
  /// Nodo de enfoque para el campo de búsqueda
  final FocusNode _nodoEnfoqueBusqueda = FocusNode();
  
  /// LayerLink para posicionar el overlay del dropdown
  final LayerLink _layerLink = LayerLink();
  
  /// Entrada del overlay del dropdown
  OverlayEntry? _entradaOverlay;
  
  /// Si el dropdown está actualmente abierto
  bool _estaAbierto = false;

  @override
  void initState() {
    super.initState();
    _opcionesFiltradas = List.from(widget.opcionesCuadrillas);
  }

  @override
  void didUpdateWidget(DropdownCuadrillasArmar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Comparar si las opciones han cambiado por contenido, no solo por referencia
    bool opcionesCambiaron = false;
    
    // Verificar si cambió el número de cuadrillas
    if (oldWidget.opcionesCuadrillas.length != widget.opcionesCuadrillas.length) {
      opcionesCambiaron = true;
    } else {
      // Verificar si cambió el contenido de alguna cuadrilla
      for (int i = 0; i < widget.opcionesCuadrillas.length; i++) {
        final cuadrillaAnterior = oldWidget.opcionesCuadrillas[i];
        final cuadrillaNueva = widget.opcionesCuadrillas[i];
        
        // Comparar nombre y número de empleados
        if (cuadrillaAnterior['nombre'] != cuadrillaNueva['nombre'] ||
            (cuadrillaAnterior['empleados'] as List?)?.length != 
            (cuadrillaNueva['empleados'] as List?)?.length) {
          opcionesCambiaron = true;
          break;
        }
      }
    }
    
    // Si las opciones han cambiado, actualizar la lista filtrada
    if (opcionesCambiaron) {
      setState(() {
        _opcionesFiltradas = List.from(widget.opcionesCuadrillas);
        // Si hay un texto de búsqueda activo, volver a filtrar
        if (_controladorBusqueda.text.isNotEmpty) {
          _filtrarOpciones(_controladorBusqueda.text);
        }
      });
    }
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    _nodoEnfoqueBusqueda.dispose();
    _cerrarDropdown();
    super.dispose();
  }

  /// Filtra las opciones de cuadrillas basado en el texto de búsqueda
  void _filtrarOpciones(String textoBusqueda) {
    setState(() {
      if (textoBusqueda.isEmpty) {
        _opcionesFiltradas = List.from(widget.opcionesCuadrillas);
      } else {
        _opcionesFiltradas = widget.opcionesCuadrillas.where((cuadrilla) {
          final nombreCuadrilla = cuadrilla['nombre']?.toString().toLowerCase() ?? '';
          final claveCuadrilla = cuadrilla['clave']?.toString().toLowerCase() ?? '';
          final busqueda = textoBusqueda.toLowerCase();
          // Buscar por nombre o por clave (código)
          return nombreCuadrilla.contains(busqueda) || claveCuadrilla.contains(busqueda);
        }).toList();
      }
    });
    
    // Actualizar el overlay si está abierto
    if (_estaAbierto) {
      _actualizarOverlay();
    }
  }

  /// Abre el dropdown mostrando el overlay
  void _abrirDropdown() {
    if (_estaAbierto || widget.deshabilitado) return;
    
    _estaAbierto = true;
    _entradaOverlay = _crearEntradaOverlay();
    Overlay.of(context).insert(_entradaOverlay!);
  }

  /// Cierra el dropdown removiendo el overlay
  void _cerrarDropdown() {
    if (!_estaAbierto) return;
    
    _estaAbierto = false;
    _entradaOverlay?.remove();
    _entradaOverlay = null;
    _controladorBusqueda.clear();
    _opcionesFiltradas = List.from(widget.opcionesCuadrillas);
  }

  /// Actualiza el contenido del overlay cuando cambian los datos
  void _actualizarOverlay() {
    _entradaOverlay?.markNeedsBuild();
  }

  /// Maneja la selección de una cuadrilla del dropdown
  void _seleccionarCuadrilla(Map<String, dynamic>? cuadrilla) {
    widget.alSeleccionarCuadrilla(cuadrilla);
    _cerrarDropdown();
  }

  /// Crea la entrada del overlay con la lista de opciones
  OverlayEntry _crearEntradaOverlay() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _cerrarDropdown,
        child: Stack(
          children: [
            // Área invisible que cubre toda la pantalla para detectar clics fuera
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // El dropdown real
            Positioned(
              width: _obtenerAnchoWidget(),
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: GestureDetector(
                  onTap: () {}, // Previene que se cierre cuando se hace clic dentro del dropdown
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Campo de búsqueda dentro del dropdown
                          if (widget.textoBusqueda != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _controladorBusqueda,
                                focusNode: _nodoEnfoqueBusqueda,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por código o nombre...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: _filtrarOpciones,
                              ),
                            ),
                          
                          // Lista de opciones de cuadrillas
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: [
                                // Opción para deseleccionar (si está permitido)
                                if (widget.permitirDeseleccion && widget.cuadrillaSeleccionada != null)
                                  ListTile(
                                    dense: true,
                                    leading: Icon(Icons.clear, color: Colors.grey.shade600),
                                    title: Text(
                                      'Ninguna cuadrilla',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    onTap: () => _seleccionarCuadrilla(null),
                                  ),
                                
                                // Opciones de cuadrillas filtradas
                                ..._opcionesFiltradas.map((cuadrilla) {
                                  final estaSeleccionada = widget.cuadrillaSeleccionada?['nombre'] == cuadrilla['nombre'];
                                  final cantidadEmpleados = (cuadrilla['empleados'] as List?)?.length ?? 0;
                                  
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.groups,
                                      color: estaSeleccionada ? AppColors.greenDark : Colors.grey.shade600,
                                    ),
                                    title: Text(
                                      cuadrilla['nombre'] ?? '',
                                      style: TextStyle(
                                        fontWeight: estaSeleccionada ? FontWeight.bold : FontWeight.normal,
                                        color: estaSeleccionada ? AppColors.greenDark : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '$cantidadEmpleados empleado${cantidadEmpleados != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: estaSeleccionada 
                                        ? Icon(Icons.check, color: AppColors.greenDark, size: 20)
                                        : null,
                                    selected: estaSeleccionada,
                                    selectedTileColor: AppColors.green.withOpacity(0.1),
                                    onTap: () => _seleccionarCuadrilla(cuadrilla),
                                  );
                                }).toList(),
                                
                                // Mensaje cuando no hay resultados
                                if (_opcionesFiltradas.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No se encontraron cuadrillas',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene el ancho del widget para el overlay
  double _obtenerAnchoWidget() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.deshabilitado ? null : _abrirDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.deshabilitado ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            border: Border.all(
              color: _estaAbierto 
                  ? AppColors.greenDark 
                  : widget.deshabilitado 
                      ? Colors.grey.shade300
                      : Colors.grey.shade400,
              width: _estaAbierto ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icono de cuadrilla
              Icon(
                Icons.groups,
                size: 20,
                color: widget.deshabilitado 
                    ? Colors.grey.shade400
                    : widget.cuadrillaSeleccionada != null 
                        ? AppColors.greenDark 
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              
              // Texto de la cuadrilla seleccionada o placeholder
              Expanded(
                child: Text(
                  widget.cuadrillaSeleccionada?['nombre']?.toString() ?? widget.textoPlaceholder,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.deshabilitado
                        ? Colors.grey.shade400
                        : widget.cuadrillaSeleccionada != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                    fontWeight: widget.cuadrillaSeleccionada != null 
                        ? FontWeight.w500 
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Icono de flecha hacia abajo
              Icon(
                _estaAbierto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: widget.deshabilitado 
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
