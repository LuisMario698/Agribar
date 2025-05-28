import 'package:flutter/material.dart';
import '../../widgets/common/page_header.dart';

/// Widget que encapsula un formulario genérico con un título
/// Puede ser reutilizado en diferentes secciones de la aplicación
class GenericFormCard extends StatelessWidget {
  final String title;
  final Widget formContent;
  final Color textColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const GenericFormCard({
    Key? key,
    required this.title,
    required this.formContent,
    this.textColor = const Color(0xFF23611C),
    this.backgroundColor = const Color(0xFFF8F8F8),
    this.padding = const EdgeInsets.all(20),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: title,
            backgroundColor: Colors.transparent,
            textColor: textColor,
          ),
          SizedBox(height: 24),
          formContent,
        ],
      ),
    );
  }
}
