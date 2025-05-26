import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onInfoTap;
  final String hintText;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onInfoTap,
    this.hintText = 'Buscar',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color.fromARGB(118, 206, 206, 206),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFF0B7A2F),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onSearchTap,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.search, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Enter para buscar en uno de los tres apartados, importante, establecer el rango de fechas',
          child: Material(
            color: const Color(0xFF0B7A2F),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onInfoTap,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.info, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
