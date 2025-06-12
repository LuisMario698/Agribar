import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para la selección y gestión de semanas
/// Maneja la creación, selección y cierre de semanas
class WeekSelectionCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isWeekClosed;
  final bool haySemanaActiva;
  final bool semanaActiva;
  final VoidCallback? onSeleccionarSemana;
  final VoidCallback? onCerrarSemana;
  final VoidCallback? onReiniciarSemana;

  const WeekSelectionCard({
    super.key,
    this.startDate,
    this.endDate,
    this.isWeekClosed = false,
    this.haySemanaActiva = false,
    this.semanaActiva = false,
    this.onSeleccionarSemana,
    this.onCerrarSemana,
    this.onReiniciarSemana,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.tableHeader,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.greenDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Semana',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: (!semanaActiva) ? onSeleccionarSemana : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            startDate != null && endDate != null
                                ? '${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                : 'Seleccionar semana',
                          ),
                          if (!haySemanaActiva)
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (startDate != null && endDate != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isWeekClosed ? null : onCerrarSemana,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Cerrar semana'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isWeekClosed ? Colors.grey : AppColors.greenDark,
                        side: BorderSide(
                          color: isWeekClosed ? Colors.grey : AppColors.greenDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (startDate != null && endDate != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onReiniciarSemana,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
