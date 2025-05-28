import 'package:flutter/material.dart';
import 'custom_button.dart';

/// Widget para diálogos de confirmación
/// Proporciona una interfaz estándar para confirmaciones de acciones importantes
class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final ButtonType confirmType;

  const CustomConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'Aceptar',
    this.cancelText = 'Cancelar',
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
    this.confirmType = ButtonType.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon!, size: 48, color: iconColor ?? Color(0xFF0B7A2F)),
              SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelText,
                    type: ButtonType.secondary,
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      onCancel?.call();
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: confirmText,
                    type: confirmType,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Método estático para mostrar diálogo de confirmación genérico
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    IconData? icon,
    Color? iconColor,
    ButtonType confirmType = ButtonType.primary,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => CustomConfirmationDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            icon: icon,
            iconColor: iconColor,
            confirmType: confirmType,
            onConfirm: onConfirm,
            onCancel: onCancel,
          ),
    );
  }

  /// Método estático para mostrar diálogo de eliminación
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: 'Eliminar',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      confirmType: ButtonType.danger,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Método estático para mostrar diálogo de logout
  static Future<bool?> showLogout({
    required BuildContext context,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro que deseas cerrar sesión?',
      confirmText: 'Cerrar sesión',
      icon: Icons.logout,
      iconColor: Colors.red,
      confirmType: ButtonType.danger,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Método estático para mostrar diálogo de guardar cambios
  static Future<bool?> showSaveChanges({
    required BuildContext context,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show(
      context: context,
      title: 'Guardar cambios',
      message: '¿Desea guardar los cambios realizados?',
      confirmText: 'Guardar',
      cancelText: 'No guardar',
      icon: Icons.save,
      iconColor: Color(0xFF0B7A2F),
      confirmType: ButtonType.success,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }
}
