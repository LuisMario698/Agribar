import 'package:flutter/material.dart';
import '../../../widgets_shared/index.dart';

class EmpleadoSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchPressed;
  const EmpleadoSearchBar({
    super.key,
    required this.controller,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Usando el nuevo GenericSearchBar
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar empleados...',
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
