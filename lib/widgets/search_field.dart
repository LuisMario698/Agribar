import 'package:flutter/material.dart';

/// Widget modular para un campo de búsqueda.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const SearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
