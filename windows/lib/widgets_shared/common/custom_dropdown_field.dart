import 'package:flutter/material.dart';

/// Widget personalizado para dropdowns
/// Proporciona un estilo consistente para menús desplegables
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final double? width;
  final Color? fillColor;
  final String? hintText;
  final bool enabled;

  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.width,
    this.fillColor,
    this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
          ],
          DropdownButtonFormField<T>(
            value: value,
            items:
                items
                    .map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ),
                    )
                    .toList(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: fillColor ?? Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF0B7A2F), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
