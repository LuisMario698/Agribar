import 'package:flutter/material.dart';

/// Widget personalizado para selección de fechas
/// Proporciona un campo de fecha consistente
class CustomDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime?) onDateSelected;
  final double? width;
  final Color? fillColor;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const CustomDatePickerField({
    Key? key,
    required this.controller,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.width,
    this.fillColor,
    this.firstDate,
    this.lastDate,
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
          GestureDetector(
            onTap: enabled ? () => _selectDate(context) : null,
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Seleccionar fecha',
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
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: enabled ? Color(0xFF0B7A2F) : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF0B7A2F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
      controller.text =
          "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }
}
