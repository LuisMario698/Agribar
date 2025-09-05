import 'package:flutter/material.dart';
import 'custom_button.dart';

/// Widget para diálogos de confirmación estándar
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final ButtonType confirmButtonType;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
    this.confirmButtonType = ButtonType.primary,
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
              Icon(icon, size: 48, color: iconColor ?? Color(0xFF0B7A2F)),
              SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelText,
                    type: ButtonType.secondary,
                    onPressed: () {
                      if (onCancel != null) {
                        onCancel!();
                      }
                      Navigator.of(context).pop(false);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: confirmText,
                    type: confirmButtonType,
                    onPressed: () {
                      if (onConfirm != null) {
                        onConfirm!();
                      }
                      Navigator.of(context).pop(true);
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

  /// Método estático para mostrar diálogo de eliminación
  static Future<bool?> showDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            message: message,
            confirmText: 'Eliminar',
            cancelText: 'Cancelar',
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            confirmButtonType: ButtonType.danger,
          ),
    );
  }

  /// Método estático para mostrar diálogo de confirmación genérico
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    IconData? icon,
    Color? iconColor,
    ButtonType confirmButtonType = ButtonType.primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            icon: icon,
            iconColor: iconColor,
            confirmButtonType: confirmButtonType,
          ),
    );
  }
}
