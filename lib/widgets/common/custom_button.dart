import 'package:flutter/material.dart';

/// Widget personalizado para botones
/// Proporciona estilos consistentes para botones en toda la aplicación
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;
  final bool isLoading;
  final bool enabled;
  final ButtonType type;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.type = ButtonType.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (type) {
      case ButtonType.primary:
        bgColor = backgroundColor ?? Color(0xFF0B7A2F);
        fgColor = foregroundColor ?? Colors.white;
        break;
      case ButtonType.secondary:
        bgColor = backgroundColor ?? Colors.white;
        fgColor = foregroundColor ?? Color(0xFF0B7A2F);
        break;
      case ButtonType.danger:
        bgColor = backgroundColor ?? Color(0xFFE53935);
        fgColor = foregroundColor ?? Colors.white;
        break;
      case ButtonType.success:
        bgColor = backgroundColor ?? Colors.green;
        fgColor = foregroundColor ?? Colors.white;
        break;
    }

    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            side:
                type == ButtonType.secondary
                    ? BorderSide(color: Color(0xFF0B7A2F))
                    : BorderSide.none,
          ),
          elevation: type == ButtonType.secondary ? 0 : 2,
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, SizedBox(width: 8)],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

enum ButtonType { primary, secondary, danger, success }
