/// Widget para la tarjeta de información en el formulario de nómina.

import 'package:flutter/material.dart';

class NominaTarjeta extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  final double width;

  const NominaTarjeta({
    Key? key,
    required this.titulo,
    required this.children,
    this.width = 320,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo.isNotEmpty)
            Text(
              titulo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          if (titulo.isNotEmpty) SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
