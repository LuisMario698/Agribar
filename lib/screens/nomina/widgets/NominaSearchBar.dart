/// Widget para la barra de búsqueda en la pantalla de nómina
/// Implementa un campo de búsqueda simple con botón para filtrar empleados

import 'package:flutter/material.dart';
import '../../../widgets_shared/generic_search_bar.dart';

class NominaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearchPressed;

  const NominaSearchBar({
    Key? key,
    required this.controller,
    required this.onSearchPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GenericSearchBar(
      controller: controller,
      hintText: 'Buscar por nombre o clave...',
      onSearchPressed: onSearchPressed,
    );
  }
}
