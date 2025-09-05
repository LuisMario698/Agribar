import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para el diálogo de actualización de cuadrilla
/// 
/// Este widget maneja las opciones para actualizar datos de empleados
/// cuando se modifica una cuadrilla existente.
class ActualizarCuadrillaWidget extends StatelessWidget {
  /// Empleados existentes en la cuadrilla
  final List<Map<String, dynamic>> empleadosExistentes;
  /// Lista completa de empleados de la cuadrilla seleccionada
  final List<Map<String, dynamic>> empleadosCompletoCuadrilla;
  /// Callback para mantener datos existentes
  final VoidCallback onMantenerDatos;
  /// Callback para empezar de cero
  final VoidCallback onEmpezarDeCero;
  /// Callback para cerrar el diálogo
  final VoidCallback onClose;

  const ActualizarCuadrillaWidget({
    Key? key,
    required this.empleadosExistentes,
    required this.empleadosCompletoCuadrilla,
    required this.onMantenerDatos,
    required this.onEmpezarDeCero,
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
            Text(
              'Actualizar Cuadrilla',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione cómo desea manejar los datos existentes de la cuadrilla',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                onMantenerDatos();
                onClose();
              },
              icon: const Icon(Icons.save),
              label: const Text('Mantener datos existentes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                onEmpezarDeCero();
                onClose();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Empezar de cero'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}