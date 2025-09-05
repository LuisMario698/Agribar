import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para la selección y gestión de semanas
/// Maneja la creación, selección y cierre de semanas
class NominaWeekSelectionCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isWeekClosed;
  final bool haySemanaActiva;
  final bool semanaActiva;
  final VoidCallback? onSeleccionarSemana;
  final VoidCallback? onCerrarSemana;
  final bool mostrarEstadoFlujo; // 🎯 Propiedad para mostrar estado del flujo

  const NominaWeekSelectionCard({
    super.key,
    this.startDate,
    this.endDate,
    this.isWeekClosed = false,
    this.haySemanaActiva = false,
    this.semanaActiva = false,
    this.onSeleccionarSemana,
    this.onCerrarSemana,
    this.mostrarEstadoFlujo = true,
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
                      // 🎯 Mostrar estado del flujo
                      if (mostrarEstadoFlujo && startDate != null && endDate != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Activa',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                  // 🎯 Mensaje guía cuando no hay semana seleccionada
                  if (mostrarEstadoFlujo && startDate == null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selecciona una semana para empezar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (startDate != null && endDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
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
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}