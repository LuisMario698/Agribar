import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GenericDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final String? hintText;
  final double? width;
  final double height;
  final Color? fillColor;
  final double borderRadius;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TextStyle? textStyle;
  final Color? iconColor;
  final bool enabled;
  final String? labelText;

  const GenericDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText,
    this.width,
    this.height = 48,
    this.fillColor,
    this.borderRadius = 8.0,
    this.firstDate,
    this.lastDate,
    this.textStyle,
    this.iconColor,
    this.enabled = true,
    this.labelText,
  });

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF0B7A2F),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Container(
      width: width,
      height: height,
      child: InkWell(
        onTap: enabled ? () => _selectDate(context) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                enabled
                    ? (fillColor ?? const Color.fromARGB(59, 139, 139, 139))
                    : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (labelText != null) ...[
                      Text(
                        labelText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      selectedDate != null
                          ? dateFormatter.format(selectedDate!)
                          : (hintText ?? 'Seleccionar fecha'),
                      style:
                          textStyle ??
                          TextStyle(
                            fontSize: 14,
                            color:
                                selectedDate != null
                                    ? (enabled
                                        ? Colors.black87
                                        : Colors.grey.shade600)
                                    : Colors.grey.shade500,
                            fontWeight:
                                selectedDate != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: 20,
                color:
                    enabled
                        ? (iconColor ?? const Color(0xFF0B7A2F))
                        : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget específico para rangos de fechas
class GenericDateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartDateSelected;
  final Function(DateTime?) onEndDateSelected;
  final String? startHintText;
  final String? endHintText;
  final double? width;
  final double height;
  final Color? fillColor;
  final double borderRadius;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TextStyle? textStyle;
  final Color? iconColor;
  final bool enabled;

  const GenericDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    this.startHintText,
    this.endHintText,
    this.width,
    this.height = 48,
    this.fillColor,
    this.borderRadius = 8.0,
    this.firstDate,
    this.lastDate,
    this.textStyle,
    this.iconColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GenericDatePicker(
          selectedDate: startDate,
          onDateSelected: onStartDateSelected,
          hintText: startHintText ?? 'Fecha inicio',
          width: width,
          height: height,
          fillColor: fillColor,
          borderRadius: borderRadius,
          firstDate: firstDate,
          lastDate: lastDate,
          textStyle: textStyle,
          iconColor: iconColor,
          enabled: enabled,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ),
        GenericDatePicker(
          selectedDate: endDate,
          onDateSelected: onEndDateSelected,
          hintText: endHintText ?? 'Fecha fin',
          width: width,
          height: height,
          fillColor: fillColor,
          borderRadius: borderRadius,
          firstDate: firstDate,
          lastDate: lastDate,
          textStyle: textStyle,
          iconColor: iconColor,
          enabled: enabled,
        ),
      ],
    );
  }
}
