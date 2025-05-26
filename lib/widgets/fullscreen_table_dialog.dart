import 'package:flutter/material.dart';
import 'dart:ui';

/// Diálogo modal para mostrar tablas en pantalla completa.
///
/// Este widget implementa un diálogo modal con las siguientes características:
/// - Efecto de desenfoque en el fondo
/// - Controladores de scroll independientes (horizontal y vertical)
/// - Tamaño responsivo basado en las dimensiones de la pantalla
/// - Botón de cierre para volver a la vista normal
/// - Animación suave al abrir y cerrar
///
/// Se utiliza cuando se necesita ver una tabla grande en pantalla completa,
/// especialmente útil en las pantallas de:
/// - Reportes detallados
/// - Nóminas semanales
/// - Registros históricos
class FullscreenTableDialog extends StatelessWidget {
  /// Widget de tabla que se mostrará en pantalla completa
  final Widget table;
  /// Función que se ejecuta al cerrar el diálogo
  final VoidCallback onClose;
  /// Controlador para el scroll horizontal de la tabla
  final ScrollController horizontalController;
  /// Controlador para el scroll vertical de la tabla
  final ScrollController verticalController;

  const FullscreenTableDialog({
    Key? key,
    required this.table,
    required this.onClose,
    required this.horizontalController,
    required this.verticalController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withOpacity(0)),
        ),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.98,
              maxHeight: MediaQuery.of(context).size.height * 0.95,
            ),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: SizedBox(
                        width: 1200,
                        child: Scrollbar(
                          controller: horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 1100),
                              child: Scrollbar(
                                controller: verticalController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: verticalController,
                                  scrollDirection: Axis.vertical,
                                  child: table,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 32),
                      tooltip: 'Cerrar',
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
