import 'package:flutter/material.dart';

/// Widget personalizado para barra de búsqueda
/// Proporciona funcionalidad de búsqueda consistente
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onSearchPressed;
  final Color? fillColor;
  final Color? iconColor;
  final double? height;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    this.hintText = 'Buscar',
    this.onChanged,
    this.onSearchPressed,
    this.fillColor,
    this.iconColor,
    this.height = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: fillColor ?? Color(0xFFF3F1EA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                borderSide: BorderSide(color: Color(0xFF0B7A2F), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: iconColor ?? Color(0xFF0B7A2F),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed:
                onSearchPressed ??
                () {
                  if (onChanged != null) {
                    onChanged!(controller.text);
                  }
                },
          ),
        ),
      ],
    );
  }
}
