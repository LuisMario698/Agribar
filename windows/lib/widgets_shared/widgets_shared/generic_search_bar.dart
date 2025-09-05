import 'package:flutter/material.dart';
import 'index.dart';

/// Widget genérico de barra de búsqueda
///
/// Este widget proporciona una barra de búsqueda reutilizable que puede ser
/// utilizada en cualquier parte de la aplicación.
///
/// Ejemplo de uso:
/// ```dart
/// GenericSearchBar(
///   controller: _searchController,
///   hintText: 'Buscar empleados...',
///   onSearchPressed: () => _performSearch(),
///   onClearPressed: () => _clearSearch(),
/// )
/// ```
class GenericSearchBar extends StatelessWidget {
  /// Controlador del campo de texto
  final TextEditingController controller;

  /// Texto de ayuda que se muestra cuando el campo está vacío
  final String hintText;

  /// Callback que se ejecuta cuando se presiona el botón de búsqueda
  final VoidCallback? onSearchPressed;

  /// Callback que se ejecuta cuando se presiona el botón de limpiar
  final VoidCallback? onClearPressed;

  /// Callback que se ejecuta cuando cambia el texto
  final ValueChanged<String>? onChanged;

  /// Icono de búsqueda (por defecto Icons.search)
  final IconData searchIcon;

  /// Icono de limpiar (por defecto Icons.clear)
  final IconData clearIcon;

  /// Color de fondo del campo de texto
  final Color? fillColor;

  /// Si se debe mostrar el botón de limpiar
  final bool showClearButton;

  /// Si se debe mostrar el botón de búsqueda
  final bool showSearchButton;

  /// Altura del widget
  final double? height;

  /// Radio del borde
  final double borderRadius;

  /// Tipo de entrada de teclado
  final TextInputType keyboardType;

  const GenericSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onSearchPressed,
    this.onClearPressed,
    this.onChanged,
    this.searchIcon = Icons.search,
    this.clearIcon = Icons.clear,
    this.fillColor,
    this.showClearButton = true,
    this.showSearchButton = false,
    this.height,
    this.borderRadius = 8.0,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return GenericCard(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: GenericTextField(
                controller: controller,
                label: '',
                hintText: hintText,
                prefix: Icon(searchIcon, color: Colors.grey[700]),
                suffix: _buildSuffixWidget(),
                fillColor: fillColor ?? const Color.fromARGB(59, 139, 139, 139),
                onChanged: onChanged,
                keyboardType: keyboardType,
              ),
            ),
            if (showSearchButton && onSearchPressed != null) ...[
              const SizedBox(width: 8),
              _buildSearchButton(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye el widget de sufijo (botón de limpiar)
  Widget? _buildSuffixWidget() {
    if (!showClearButton) return null;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();

        return IconButton(
          icon: Icon(clearIcon, color: Colors.grey[600]),
          onPressed: () {
            controller.clear();
            onClearPressed?.call();
          },
          tooltip: 'Limpiar búsqueda',
        );
      },
    );
  }

  /// Construye el botón de búsqueda
  Widget _buildSearchButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: IconButton(
        icon: Icon(searchIcon, color: Colors.white),
        onPressed: onSearchPressed,
        tooltip: 'Buscar',
      ),
    );
  }
}

/// Widget simplificado de barra de búsqueda
///
/// Una versión más simple del GenericSearchBar con configuración mínima
class SimpleSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SimpleSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GenericSearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClearPressed: onClear,
      showSearchButton: false,
      showClearButton: true,
    );
  }
}

/// Métodos estáticos para crear diferentes tipos de barra de búsqueda
class SearchBarBuilder {
  /// Crea una barra de búsqueda básica
  static Widget basic({
    required TextEditingController controller,
    String hintText = 'Buscar...',
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return SimpleSearchBar(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClear: onClear,
    );
  }

  /// Crea una barra de búsqueda con botón de búsqueda
  static Widget withButton({
    required TextEditingController controller,
    required VoidCallback onSearchPressed,
    String hintText = 'Buscar...',
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return GenericSearchBar(
      controller: controller,
      hintText: hintText,
      onSearchPressed: onSearchPressed,
      onChanged: onChanged,
      onClearPressed: onClear,
      showSearchButton: true,
      showClearButton: true,
    );
  }

  /// Crea una barra de búsqueda para empleados
  static Widget forEmpleados({
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar empleados...',
      onChanged: onChanged,
      onClearPressed: onClear,
      searchIcon: Icons.person_search,
    );
  }

  /// Crea una barra de búsqueda para cuadrillas
  static Widget forCuadrillas({
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar cuadrillas...',
      onChanged: onChanged,
      onClearPressed: onClear,
      searchIcon: Icons.group_work,
    );
  }

  /// Crea una barra de búsqueda para actividades
  static Widget forActividades({
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
  }) {
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar actividades...',
      onChanged: onChanged,
      onClearPressed: onClear,
      searchIcon: Icons.assignment,
    );
  }
}
