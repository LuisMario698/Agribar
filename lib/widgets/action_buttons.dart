import 'package:flutter/material.dart';
import 'package:agribar/widgets/export_button_group.dart';
import 'package:agribar/widgets/app_button.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onHistoryPress;
  final VoidCallback onPdfExport;
  final VoidCallback onExcelExport;
  final VoidCallback onExpandTable;
  final VoidCallback onViewDaysWorked;

  const ActionButtons({
    Key? key,
    required this.onHistoryPress,
    required this.onPdfExport,
    required this.onExcelExport,
    required this.onExpandTable,
    required this.onViewDaysWorked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - History button
        AppButton(
          label: 'Historial semanas cerradas',
          icon: Icons.history,
          onPressed: onHistoryPress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        // Center - Export buttons
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExportButtonGroup(
                onPdfExport: onPdfExport,
                onExcelExport: onExcelExport,
              ),
            ],
          ),
        ),
        // Right side - Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Expandir tabla',
              icon: Icons.open_in_full,
              onPressed: onExpandTable,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Ver días trabajados',
              icon: Icons.calendar_today,
              onPressed: onViewDaysWorked,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
