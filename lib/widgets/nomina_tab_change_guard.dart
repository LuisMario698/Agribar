import 'package:flutter/material.dart';

/// Widget para interceptar cambios de pestaña y verificar cambios no guardados en nómina
class NominaTabChangeGuard extends StatelessWidget {
  final bool tieneCambiosNoGuardados;
  final VoidCallback onGuardar;
  final VoidCallback onDescartarCambios;
  final VoidCallback onCambiarTab;
  final String? mensajePersonalizado;
  final Widget child;

  const NominaTabChangeGuard({
    super.key,
    required this.tieneCambiosNoGuardados,
    required this.onGuardar,
    required this.onDescartarCambios,
    required this.onCambiarTab,
    this.mensajePersonalizado,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Función modular para verificar cambios antes de cambiar de pestaña
Future<bool> verificarCambiosAntesDeChangiarTab({
  required BuildContext context,
  required bool tieneCambiosNoGuardados,
  required Future<void> Function() onGuardar,
  required VoidCallback? onDescartarCambios,
  String? mensajePersonalizado,
  String tabDestino = 'otra pestaña',
}) async {
  // Si no hay cambios sin guardar, permitir el cambio
  if (!tieneCambiosNoGuardados) {
    return true;
  }

  // Mostrar diálogo de confirmación
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cambios sin guardar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensajePersonalizado ??
                  'Tienes cambios sin guardar en la nómina. ¿Qué deseas hacer antes de cambiar a $tabDestino?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Los cambios se perderán si no los guardas.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Botón Cancelar
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
          
          // Botón Descartar cambios
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onDescartarCambios?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Descartar cambios',
              style: TextStyle(fontSize: 16),
            ),
          ),
          
          // Botón Guardar y continuar
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop(true);
              try {
                await onGuardar();
                // Si llegamos aquí, el guardado fue exitoso
              } catch (e) {
                // Si hay error en el guardado, no cambiar de pestaña
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Error al guardar: $e'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
                return;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text(
              'Guardar y continuar',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    },
  );

  return resultado ?? false;
}

/// Mixin para agregar funcionalidad de verificación de cambios en pestañas
mixin TabChangeGuardMixin {
  bool get tieneCambiosNoGuardados;
  Future<void> guardarTodosLosDatos();
  void descartarCambios();

  /// Verifica cambios antes de cambiar de pestaña
  Future<bool> verificarCambiosAntesDeTab(
    BuildContext context, {
    String tabDestino = 'otra pestaña',
    String? mensajePersonalizado,
  }) async {
    return await verificarCambiosAntesDeChangiarTab(
      context: context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: guardarTodosLosDatos,
      onDescartarCambios: descartarCambios,
      tabDestino: tabDestino,
      mensajePersonalizado: mensajePersonalizado,
    );
  }
}

/// Widget interceptor específico para cambios de pestaña en nómina
class NominaTabChangeInterceptor extends StatelessWidget {
  final bool tieneCambiosNoGuardados;
  final Future<void> Function() onGuardar;
  final VoidCallback onDescartarCambios;
  final Widget child;
  final String? mensajePersonalizado;

  const NominaTabChangeInterceptor({
    super.key,
    required this.tieneCambiosNoGuardados,
    required this.onGuardar,
    required this.onDescartarCambios,
    required this.child,
    this.mensajePersonalizado,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  /// Método para verificar cambios antes de cambiar de pestaña
  Future<bool> verificarCambiosAntesDeCambiarTab(
    BuildContext context, {
    String tabDestino = 'otra pestaña',
  }) async {
    return await verificarCambiosAntesDeChangiarTab(
      context: context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: onGuardar,
      onDescartarCambios: onDescartarCambios,
      tabDestino: tabDestino,
      mensajePersonalizado: mensajePersonalizado,
    );
  }
}

/// Clase helper con métodos estáticos para facilitar el uso
class NominaTabChangeHelper {
  /// Verifica cambios sin guardar antes de cambiar de pestaña
  static Future<bool> verificarCambios({
    required BuildContext context,
    required bool tieneCambiosNoGuardados,
    required Future<void> Function() onGuardar,
    required VoidCallback onDescartarCambios,
    String tabDestino = 'otra pestaña',
    String? mensajePersonalizado,
  }) async {
    return await verificarCambiosAntesDeChangiarTab(
      context: context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: onGuardar,
      onDescartarCambios: onDescartarCambios,
      tabDestino: tabDestino,
      mensajePersonalizado: mensajePersonalizado,
    );
  }

  /// Método simplificado para uso rápido con solo context y estado
  static Future<bool> verificarCambiosSimple({
    required BuildContext context,
    required bool tieneCambiosNoGuardados,
    required VoidCallback onGuardar,
    required VoidCallback onDescartarCambios,
    String tabDestino = 'otra pestaña',
  }) async {
    if (!tieneCambiosNoGuardados) return true;
    
    return await verificarCambiosAntesDeChangiarTab(
      context: context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: () async => onGuardar(),
      onDescartarCambios: onDescartarCambios,
      tabDestino: tabDestino,
    );
  }
}
