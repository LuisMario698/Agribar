import 'package:flutter/material.dart';
import 'tabla_unificada_nomina.dart';
import 'nomina_fullscreen_dialog.dart';
import 'nomina_indicators_row.dart';

/// Sección principal que contiene la tabla de nómina con controles
class SeccionPrincipalNomina extends StatefulWidget {
  final List<Map<String, dynamic>> empleados;
  final DateTimeRange? semanaSeleccionada;
  final Function(int index, String campo, dynamic valor)? onCambio;
  final bool soloLectura;
  final VoidCallback? onActualizarTotales;

  const SeccionPrincipalNomina({
    Key? key,
    required this.empleados,
    this.semanaSeleccionada,
    this.onCambio,
    this.soloLectura = false,
    this.onActualizarTotales,
  }) : super(key: key);

  @override
  State<SeccionPrincipalNomina> createState() => _SeccionPrincipalNominaState();
}

class _SeccionPrincipalNominaState extends State<SeccionPrincipalNomina> {
  bool _mostrandoTablaCompleta = false;

  /// Abre el diálogo de tabla completa
  void _abrirTablaCompleta() {
    setState(() {
      _mostrandoTablaCompleta = true;
    });

    showDialog(
      context: context,
      builder: (context) => NominaFullscreenDialog(
        empleados: widget.empleados,
        semanaSeleccionada: widget.semanaSeleccionada,
        onChanged: (index, campo, valor) {
          if (widget.onCambio != null) {
            widget.onCambio!(index, campo, valor);
          }
          // Actualizar la UI principal cuando se hagan cambios en el diálogo
          if (mounted) {
            setState(() {});
          }
        },
        onClose: () => Navigator.of(context).pop(),
        horizontalController: ScrollController(),
        verticalController: ScrollController(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _mostrandoTablaCompleta = false;
        });
        // Actualizar totales después de cerrar el diálogo
        if (widget.onActualizarTotales != null) {
          widget.onActualizarTotales!();
        }
      }
    });
  }

  /// Maneja los cambios en la tabla principal
  void _manejarCambioTabla(int index, String campo, dynamic valor) {
    if (widget.onCambio != null) {
      widget.onCambio!(index, campo, valor);
    }
    
    // Actualizar totales inmediatamente
    if (widget.onActualizarTotales != null) {
      widget.onActualizarTotales!();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicadores de totales
        NominaIndicatorsRow(
          empleadosFiltrados: widget.empleados,
          optionsCuadrilla: const [], // Lista vacía por defecto
          semanaId: null, // Se podría calcular desde semanaSeleccionada si es necesario
        ),
        
        const SizedBox(height: 16),
        
        // Encabezado con botón de tabla completa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tabla de Nómina',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${widget.empleados.length} empleados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _mostrandoTablaCompleta ? null : _abrirTablaCompleta,
                    icon: Icon(
                      _mostrandoTablaCompleta 
                          ? Icons.hourglass_empty 
                          : Icons.fullscreen,
                    ),
                    label: Text(
                      _mostrandoTablaCompleta 
                          ? 'Abriendo...' 
                          : 'Ver Tabla Completa',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Tabla principal (vista condensada)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              child: widget.empleados.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay empleados cargados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona una cuadrilla para ver los datos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TablaUnificadaNomina(
                      empleados: widget.empleados,
                      semanaSeleccionada: widget.semanaSeleccionada,
                      onCambio: _manejarCambioTabla,
                      vistaExpandida: false, // Vista condensada
                      soloLectura: widget.soloLectura,
                    ),
            ),
          ),
        ),
        
        // Información adicional en la parte inferior
        if (widget.empleados.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scroll horizontal para ver más columnas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (!widget.soloLectura)
                  Text(
                    'Los cambios se guardan automáticamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
