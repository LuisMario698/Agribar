import 'package:flutter/material.dart';

class GenericTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color? fillColor;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final String? hintText;

  const GenericTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.fillColor,
    this.prefix,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: fillColor != null,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}
