import 'package:flutter/material.dart';

class GenericButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool outlined;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GenericButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF0B7A2F),
    this.foregroundColor = Colors.white,
    this.outlined = false,
    this.enabled = true,
    this.borderRadius = 24,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined ? Colors.white : backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: outlined ? BorderSide(color: backgroundColor) : BorderSide.none,
        ),
        elevation: 0,
        padding: padding,
      ),
      child: Text(
        label,
        style: TextStyle(color: outlined ? backgroundColor : foregroundColor),
      ),
    );
  }
}
