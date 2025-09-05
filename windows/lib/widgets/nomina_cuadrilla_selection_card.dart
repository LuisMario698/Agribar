import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para la selección y gestión de cuadrillas
/// Maneja la selección de cuadrilla y el botón para armar cuadrilla
class NominaCuadrillaSelectionCard extends StatefulWidget {
  final List<Map<String, dynamic>> optionsCuadrilla;
  final Map<String, dynamic> selectedCuadrilla;
  final List<Map<String, dynamic>> empleadosEnCuadrilla;
  final Function(Map<String, dynamic>?) onCuadrillaSelected;
  final Map<String, dynamic>? semanaSeleccionada;
  final VoidCallback onToggleArmarCuadrilla;
  final bool puedeArmarCuadrilla; // 🎯 Nueva propiedad para validación
  final bool bloqueadoPorFaltaSemana; // 🎯 Nueva propiedad para mostrar estado

  const NominaCuadrillaSelectionCard({
    super.key,
    required this.optionsCuadrilla,
    required this.semanaSeleccionada,
    required this.selectedCuadrilla,
    required this.empleadosEnCuadrilla, 
    required this.onCuadrillaSelected,
    required this.onToggleArmarCuadrilla,
    this.puedeArmarCuadrilla = false,
    this.bloqueadoPorFaltaSemana = true,
  });

  @override
  State<NominaCuadrillaSelectionCard> createState() => _NominaCuadrillaSelectionCardState();
}

class _NominaCuadrillaSelectionCardState extends State<NominaCuadrillaSelectionCard> {

   List<Map<String, dynamic>> empleadosNomina = [];

  /// Ordena las cuadrillas por número de empleados (mayor a menor)
  List<Map<String, dynamic>> _ordenarCuadrillasPorEmpleados(List<Map<String, dynamic>> cuadrillas) {
    // Crear una copia para no modificar la lista original
    List<Map<String, dynamic>> cuadrillasOrdenadas = List.from(cuadrillas);
    
    cuadrillasOrdenadas.sort((a, b) {
      final empleadosA = (a['empleados'] as List?)?.length ?? 0;
      final empleadosB = (b['empleados'] as List?)?.length ?? 0;
      return empleadosB.compareTo(empleadosA); // Orden descendente (mayor a menor)
    });
    
    return cuadrillasOrdenadas;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.tableHeader,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Mostrar indicador de estado arriba si está bloqueado
            if (widget.bloqueadoPorFaltaSemana) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.orange.shade600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Requiere semana activa',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 20,
                      color: widget.bloqueadoPorFaltaSemana 
                          ? Colors.grey 
                          : AppColors.greenDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cuadrilla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.bloqueadoPorFaltaSemana 
                            ? Colors.grey 
                            : AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: widget.puedeArmarCuadrilla ? widget.onToggleArmarCuadrilla : null,
                  icon: Icon(
                    Icons.group_add,
                    color: widget.puedeArmarCuadrilla 
                        ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                        : Colors.grey,
                  ),
                  label: Text(
                    widget.empleadosEnCuadrilla.isNotEmpty
                        ? 'Editar cuadrilla'
                        : 'Armar cuadrilla',
                    style: TextStyle(
                      color: widget.puedeArmarCuadrilla 
                          ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.puedeArmarCuadrilla
                          ? (widget.empleadosEnCuadrilla.isNotEmpty ? Colors.blue : Colors.green)
                          : Colors.grey,
                    ),
                    backgroundColor: widget.puedeArmarCuadrilla
                        ? (widget.empleadosEnCuadrilla.isNotEmpty 
                            ? Colors.blue.shade50 
                            : Colors.green.shade50)
                        : Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.bloqueadoPorFaltaSemana ? 8 : 12),
            
            _CuadrillaDropdownConEmpleados(
              cuadrillas: widget.bloqueadoPorFaltaSemana ? [] : _ordenarCuadrillasPorEmpleados(widget.optionsCuadrilla),
              cuadrillaSeleccionada: widget.selectedCuadrilla['nombre'] == '' ? null : widget.selectedCuadrilla,
              onCuadrillaSelected: widget.bloqueadoPorFaltaSemana 
                  ? (Map<String, dynamic>? option) {} // Función vacía cuando está bloqueado
                  : widget.onCuadrillaSelected,
              hint: widget.bloqueadoPorFaltaSemana 
                  ? 'Seleccionar una semana primero' 
                  : (widget.optionsCuadrilla.isEmpty 
                      ? 'No hay cuadrillas - Armar cuadrilla primero'
                      : 'Seleccionar cuadrilla'),
              isDisabled: widget.bloqueadoPorFaltaSemana,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget personalizado para dropdown de cuadrillas que muestra información de empleados
class _CuadrillaDropdownConEmpleados extends StatefulWidget {
  final List<Map<String, dynamic>> cuadrillas;
  final Map<String, dynamic>? cuadrillaSeleccionada;
  final Function(Map<String, dynamic>?) onCuadrillaSelected;
  final String hint;
  final bool isDisabled;

  const _CuadrillaDropdownConEmpleados({
    required this.cuadrillas,
    required this.cuadrillaSeleccionada,
    required this.onCuadrillaSelected,
    required this.hint,
    this.isDisabled = false,
  });

  @override
  State<_CuadrillaDropdownConEmpleados> createState() => _CuadrillaDropdownConEmpleadosState();
}

/// Estado del dropdown con manejo robusto de overlay y lifecycle
class _CuadrillaDropdownConEmpleadosState extends State<_CuadrillaDropdownConEmpleados> 
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredOptions = [];
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filteredOptions = List.from(widget.cuadrillas);
  }

  @override
  void didUpdateWidget(_CuadrillaDropdownConEmpleados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDisposed) return;
    
    // Si las cuadrillas cambiaron, actualizar la lista filtrada
    if (widget.cuadrillas != oldWidget.cuadrillas) {
      if (mounted) {
        setState(() {
          _filteredOptions = List.from(widget.cuadrillas);
        });
      }
    }
    
    // Si el widget se deshabilitó, cerrar el overlay
    if (widget.isDisabled && !oldWidget.isDisabled && _isOpen) {
      _forceCloseOverlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    // Si la app se pausa o se inactiva, cerrar el overlay
    if (state != AppLifecycleState.resumed && _isOpen) {
      _forceCloseOverlay();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Remover observer
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      // Ignorar errores
    }
    
    // Forzar cierre del overlay
    _forceCloseOverlay();
    
    // Dispose de recursos
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Fuerza el cierre del overlay sin usar setState
  void _forceCloseOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        // Ignorar errores
      }
      _overlayEntry = null;
    }
    _isOpen = false;
  }

  void _showOverlay() {
    if (_isDisposed || 
        widget.isDisabled || 
        widget.cuadrillas.isEmpty || 
        !mounted) return;
    
    // Si ya hay un overlay abierto, cerrarlo primero
    if (_isOpen) {
      _hideOverlay();
      return;
    }
    
    // Resetear la búsqueda
    _searchController.clear();
    if (mounted) {
      setState(() {
        _filteredOptions = List.from(widget.cuadrillas);
      });
    }
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _hideOverlay,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  width: size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0.0, size.height + 2),
                    child: GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 8.0,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Campo de búsqueda
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Buscar por código o nombre...',
                                          hintStyle: TextStyle(color: Colors.grey.shade500),
                                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                            borderSide: BorderSide(color: AppColors.greenDark),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        onChanged: _filterOptions,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_filteredOptions.length}',
                                        style: TextStyle(
                                          color: AppColors.greenDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Lista de cuadrillas con información de empleados
                              if (_filteredOptions.isNotEmpty)
                                Flexible(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _filteredOptions.length,
                                    itemBuilder: (context, index) {
                                      final cuadrilla = _filteredOptions[index];
                                      final empleados = (cuadrilla['empleados'] as List?)?.length ?? 0;
                                      final isSelected = widget.cuadrillaSeleccionada != null &&
                                          widget.cuadrillaSeleccionada!['nombre'] == cuadrilla['nombre'];
                                      
                                      return InkWell(
                                        onTap: () => _selectOption(cuadrilla),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                          color: isSelected ? AppColors.green.withOpacity(0.1) : Colors.transparent,
                                          child: Row(
                                            children: [
                                              // Icono de cuadrilla
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                      ? AppColors.green.withOpacity(0.2)
                                                      : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.groups,
                                                  color: isSelected ? AppColors.greenDark : Colors.grey.shade600,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Información de la cuadrilla
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // Mostrar solo el nombre
                                                    Text(
                                                      cuadrilla['nombre'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                        color: isSelected ? AppColors.greenDark : Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '$empleados empleado${empleados != 1 ? 's' : ''}',
                                                          style: TextStyle(
                                                            color: empleados > 0 
                                                                ? Colors.green.shade600 
                                                                : Colors.grey.shade500,
                                                            fontSize: 12,
                                                            fontWeight: empleados > 0 
                                                                ? FontWeight.w500 
                                                                : FontWeight.normal,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Icono de selección
                                              if (isSelected)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.greenDark,
                                                    size: 20,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          color: Colors.grey.shade400,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No se encontraron cuadrillas',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Insertar overlay con manejo de errores
    try {
      if (mounted && context.mounted && !_isDisposed) {
        Overlay.of(context).insert(_overlayEntry!);
        if (mounted) {
          setState(() => _isOpen = true);
        }
      }
    } catch (e) {
      // Si hay error al insertar el overlay, limpiar referencias
      _overlayEntry = null;
      return;
    }
    
    // Auto-focus en el campo de búsqueda - sin usar postFrameCallback para evitar problemas
    Future.microtask(() {
      if (mounted && !_isDisposed && _searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _hideOverlay() {
    if (_isDisposed) return;
    
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Ignorar errores al remover overlay ya removido
    }
    _overlayEntry = null;
    
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _selectOption(Map<String, dynamic> option) {
    if (_isDisposed) return;
    
    widget.onCuadrillaSelected(option);
    _hideOverlay();
  }

  void _filterOptions(String query) {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = List.from(widget.cuadrillas);
      } else {
        _filteredOptions = widget.cuadrillas.where((cuadrilla) {
          final nombre = cuadrilla['nombre']?.toString().toLowerCase() ?? '';
          final clave = cuadrilla['clave']?.toString().toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          
          // Buscar en nombre o en clave (código)
          return nombre.contains(queryLower) || clave.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Container(); // Return empty container if disposed
    }
    
    // Comentado: variable no usada después de eliminar el indicador de empleados
    // final empleadosEnSeleccionada = widget.cuadrillaSeleccionada != null 
    //     ? ((widget.cuadrillaSeleccionada!['empleados'] as List?)?.length ?? 0)
    //     : 0;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : _showOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDisabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            border: Border.all(
              color: _isOpen 
                  ? AppColors.greenDark 
                  : widget.isDisabled 
                      ? Colors.grey.shade300
                      : Colors.grey.shade400,
              width: _isOpen ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icono de cuadrilla
              Icon(
                Icons.groups,
                size: 20,
                color: widget.isDisabled 
                    ? Colors.grey.shade400
                    : widget.cuadrillaSeleccionada != null 
                        ? AppColors.greenDark 
                        : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              
              // Texto de la cuadrilla seleccionada o placeholder
              Expanded(
                child: widget.cuadrillaSeleccionada != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.cuadrillaSeleccionada!['nombre']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDisabled
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Comentado: indicador de empleados eliminado por solicitud del usuario
                          // if (empleadosEnSeleccionada > 0)
                          //   Text(
                          //     '$empleadosEnSeleccionada empleado${empleadosEnSeleccionada != 1 ? 's' : ''}',
                          //     style: TextStyle(
                          //       color: widget.isDisabled
                          //           ? Colors.grey.shade400
                          //           : Colors.green.shade600,
                          //       fontSize: 11,
                          //       fontWeight: FontWeight.w500,
                          //     ),
                          //   ),
                        ],
                      )
                    : Text(
                        widget.hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDisabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              
              // Icono de flecha hacia abajo
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: widget.isDisabled 
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
