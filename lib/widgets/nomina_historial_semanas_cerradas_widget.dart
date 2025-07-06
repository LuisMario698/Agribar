import 'package:flutter/material.dart';
import 'historial_semanas_widget.dart';

/// Widget modular para manejar el historial de semanas cerradas
/// Encapsula toda la funcionalidad relacionada con las semanas cerradas
/// manteniendo el mismo diseño y comportamiento original
class NominaHistorialSemanasCerradasWidget extends StatefulWidget {
  final List<Map<String, dynamic>> semanasCerradas;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSemanaCerradaUpdated;

  const NominaHistorialSemanasCerradasWidget({
    Key? key,
    required this.semanasCerradas,
    required this.onClose,
    required this.onSemanaCerradaUpdated,
  }) : super(key: key);
  @override
  State<NominaHistorialSemanasCerradasWidget> createState() => _NominaHistorialSemanasCerradasWidgetState();
}

class _NominaHistorialSemanasCerradasWidgetState extends State<NominaHistorialSemanasCerradasWidget> {
  
  // Función para cambiar la cuadrilla seleccionada dentro de una semana cerrada
  void _cambiarCuadrillaSeleccionada(int semanaIndex, int cuadrillaIndex) {
    setState(() {
      widget.semanasCerradas[semanaIndex]['cuadrillaSeleccionada'] = cuadrillaIndex;
    });
    // Notificar al widget padre sobre el cambio
    widget.onSemanaCerradaUpdated(widget.semanasCerradas[semanaIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return HistorialSemanasWidget(
      semanasCerradas: widget.semanasCerradas,
      onCuadrillaSelected: _cambiarCuadrillaSeleccionada,
      onClose: widget.onClose,
    );
  }
}
