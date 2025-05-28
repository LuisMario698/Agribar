import 'package:flutter/material.dart';
import '../../../widgets_shared/index.dart';

class ActividadSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchPressed;
  const ActividadSearchBar({
    super.key,
    required this.controller,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Usando el nuevo GenericSearchBar
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar actividades...',
      onChanged: (value) {
        // Opcional: lógica de búsqueda en tiempo real
      },
      onClearPressed: () {
        // Limpia el controlador automáticamente
      },
      searchIcon: Icons.search,
      fillColor: const Color.fromARGB(59, 139, 139, 139),
    );
  }
}
