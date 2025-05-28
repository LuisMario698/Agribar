import 'package:flutter/material.dart';

class generic_icon_button extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool outlined;
  final bool enabled;

  const generic_icon_button({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.outlined = false,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, color: outlined ? backgroundColor : foregroundColor),
      label: Text(
        label,
        style: TextStyle(color: outlined ? backgroundColor : foregroundColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined ? Colors.white : backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: outlined ? BorderSide(color: backgroundColor) : BorderSide.none,
        ),
        elevation: 0,
      ),
    );
  }
}
