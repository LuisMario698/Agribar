import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para el diálogo de reiniciar semana
/// 
/// Este widget maneja las opciones para reiniciar una semana,
/// permitiendo mantener o limpiar las cuadrillas armadas.
class NominaReiniciarSemanaWidget extends StatelessWidget {
  /// Callback para reiniciar manteniendo cuadrillas
  final VoidCallback onMantenerCuadrillas;
  /// Callback para reiniciar limpiando cuadrillas
  final VoidCallback onLimpiarCuadrillas;
  /// Callback para cerrar el diálogo
  final VoidCallback onClose;

  const NominaReiniciarSemanaWidget({
    Key? key,
    required this.onMantenerCuadrillas,
    required this.onLimpiarCuadrillas,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 28,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reiniciar Semana',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione una opción para reiniciar la semana',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                onMantenerCuadrillas();
                onClose();
              },
              icon: const Icon(Icons.people),
              label: const Text('Mantener cuadrillas armadas'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                onLimpiarCuadrillas();
                onClose();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Deshacer cuadrillas armadas'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}