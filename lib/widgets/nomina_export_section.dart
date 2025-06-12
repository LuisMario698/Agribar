import 'package:flutter/material.dart';
import '../widgets/export_button_group.dart';

/// Widget modular para la sección de exportación
/// Contiene los botones para exportar a PDF y Excel
class NominaExportSection extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;

  const NominaExportSection({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EXPORTAR A',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              ExportButton(
                label: 'PDF',
                color: Colors.blue,
                onPressed: onExportPdf ?? () {
                  // TODO: Export to PDF
                },
              ),
              const SizedBox(width: 8),
              ExportButton(
                label: 'EXCEL',
                color: Colors.green,
                onPressed: onExportExcel ?? () {
                  // TODO: Export to Excel
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
