import 'package:flutter/material.dart';

/// Widget para botones de exportación personalizados.
///
/// Este widget implementa un botón de exportación con estilo personalizado que incluye:
/// - Color configurable
/// - Etiqueta de texto personalizable
/// - Esquinas redondeadas
/// - Padding consistente
class ExportButton extends StatelessWidget {
  /// Etiqueta de texto que se mostrará en el botón
  final String label;
  /// Color de fondo del botón
  final Color color;
  /// Función que se ejecutará al presionar el botón
  final VoidCallback onPressed;

  const ExportButton({
    Key? key,
    required this.label,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }
}

/// Grupo de botones para exportación de datos.
///
/// Este widget agrupa botones para exportar datos en diferentes formatos:
/// - Botón para exportar a PDF (rojo)
/// - Botón para exportar a Excel (verde)
///
/// Se usa comúnmente en pantallas que muestran datos tabulares o reportes
/// que necesitan ser exportados, como la pantalla de nómina y reportes.
class ExportButtonGroup extends StatelessWidget {
  /// Función que se ejecuta al presionar el botón de exportar a PDF
  final VoidCallback onPdfExport;
  /// Función que se ejecuta al presionar el botón de exportar a Excel
  final VoidCallback onExcelExport;

  const ExportButtonGroup({
    Key? key,
    required this.onPdfExport,
    required this.onExcelExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('EXPORTAR A', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExportButton(
                label: 'PDF',
                color: Colors.red.shade700,
                onPressed: onPdfExport,
              ),
              const SizedBox(width: 16),
              ExportButton(
                label: 'EXCEL',
                color: Colors.green.shade700,
                onPressed: onExcelExport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
