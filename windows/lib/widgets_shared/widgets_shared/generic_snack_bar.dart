import 'package:flutter/material.dart';

/// Widget genérico para mostrar SnackBars con estilos consistentes
/// Proporciona diferentes tipos de notificaciones con personalización avanzada
class GenericSnackBar {
  /// Muestra un SnackBar de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.green[600]!,
      textColor: textColor ?? Colors.white,
      icon: icon ?? Icons.check_circle,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un SnackBar de error
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.red[600]!,
      textColor: textColor ?? Colors.white,
      icon: icon ?? Icons.error,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.orange[600]!,
      textColor: textColor ?? Colors.white,
      icon: icon ?? Icons.warning,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un SnackBar de información
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.blue[600]!,
      textColor: textColor ?? Colors.white,
      icon: icon ?? Icons.info,
      duration: duration,
      action: action,
    );
  }

  /// Muestra un SnackBar personalizado
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Color textColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
      action: action,
    );
  }

  /// Método privado para mostrar el SnackBar con la configuración especificada
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    // Limpia cualquier SnackBar anterior
    ScaffoldMessenger.of(context).clearSnackBars();

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 6,
      action: action,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Widget personalizable para SnackBar como componente
class GenericSnackBarWidget extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onClose;
  final Widget? action;

  const GenericSnackBarWidget({
    Key? key,
    required this.message,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.icon,
    this.onClose,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
          if (onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                color: textColor.withOpacity(0.8),
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
