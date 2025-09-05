// Dropdown menu personalizado con buscador
// Utilizado para selección de elementos con funcionalidad de búsqueda
// Autor: GitHub Copilot para Agribar

import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

class CustomDropdownMenu<T> extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final Map<String, dynamic>? selectedOption;
  final void Function(Map<String, dynamic>?) onOptionSelected;
  final String displayKey;
  final String valueKey;
  final String hint;
  final Icon icon;
  final bool allowDeselect;
  final String? searchHint;
  final double? width;
  final bool disabled;
  
  const CustomDropdownMenu({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.displayKey,
    required this.valueKey,
    required this.hint,
    required this.icon,
    this.allowDeselect = true,
    this.searchHint,
    this.width,
    this.disabled = false,
  }) : super(key: key);

  @override
  State<CustomDropdownMenu<T>> createState() => _CustomDropdownMenuState<T>();
}

class _CustomDropdownMenuState<T> extends State<CustomDropdownMenu<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredOptions = [];
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (widget.disabled) return;
    
    // Resetear la búsqueda
    _searchController.clear();
    _filteredOptions = List.from(widget.options);
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _hideOverlay, // Cerrar al tocar fuera del dropdown
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Stack(
              children: [
                // El dropdown real
                Positioned(
                  width: widget.width ?? size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0.0, size.height + 2),
                    child: GestureDetector(
                      onTap: () {}, // Evitar que se propague el tap al contenedor padre
                      behavior: HitTestBehavior.opaque,
                      child: Material(
                        elevation: 8.0,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Campo de búsqueda
                              if (widget.searchHint != null)
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          decoration: InputDecoration(
                                            hintText: widget.searchHint,
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
                              
                              // Lista de opciones
                              if (_filteredOptions.isNotEmpty)
                                Flexible(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _filteredOptions.length,
                                    itemBuilder: (context, index) {
                                      final option = _filteredOptions[index];
                                      final bool isSelected = widget.selectedOption != null &&
                                          widget.selectedOption![widget.valueKey] == option[widget.valueKey];
                                      
                                      return InkWell(
                                        onTap: () => _selectOption(option),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                          color: isSelected ? AppColors.green.withOpacity(0.1) : Colors.transparent,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  option[widget.displayKey].toString(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                    color: isSelected ? AppColors.greenDark : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check,
                                                  color: AppColors.greenDark,
                                                  size: 20,
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
                                    child: Text(
                                      'No se encontraron opciones',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Opción de deseleccionar
                              if (widget.allowDeselect && widget.selectedOption != null)
                                Column(
                                  children: [
                                    Divider(color: Colors.grey.shade300, height: 1),
                                    InkWell(
                                      onTap: () => _selectOption(null),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.clear,
                                              color: Colors.red.shade400,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Deseleccionar',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.red.shade400,
                                              ),
                                            ),
                                          ],
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
                ),
              ],
            ),
          ),
        );
      },
    );
  

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
    
    // Enfocar el campo de búsqueda si existe
    if (widget.searchHint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      setState(() {
        _isOpen = false;
      });
    }
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _filterOptions(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        _filteredOptions = widget.options.where((option) {
          final String display = option[widget.displayKey].toString().toLowerCase();
          return display.contains(lowercaseQuery);
        }).toList();
      }
    });
    
    // Reconstruir el overlay para reflejar los cambios
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _selectOption(Map<String, dynamic>? option) {
    widget.onOptionSelected(option);
    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: widget.disabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
            border: Border.all(
              color: _isOpen 
                ? AppColors.greenDark 
                : (widget.disabled ? Colors.grey.shade400 : Colors.grey.shade300),
              width: _isOpen ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.icon,
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.selectedOption != null && widget.selectedOption![widget.displayKey] != null
                            ? widget.selectedOption![widget.displayKey].toString()
                            : widget.hint,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.selectedOption != null && widget.selectedOption![widget.displayKey] != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: widget.disabled ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
