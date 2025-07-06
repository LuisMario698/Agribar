import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_styles.dart';

/// Widget modular para mostrar los detalles de un empleado
/// 
/// Este widget encapsula el diálogo que muestra información detallada
/// de un empleado incluyendo datos personales y laborales.
class NominaDetallesEmpleadoWidget extends StatelessWidget {
  /// Datos del empleado a mostrar
  final Map<String, dynamic> empleado;

  const NominaDetallesEmpleadoWidget({
    Key? key,
    required this.empleado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.95),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.green.withOpacity(0.1),
                        child: Text(
                          _getInitials(empleado['nombre'].toString()),
                          style: TextStyle(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empleado['nombre'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            empleado['puesto'] ?? 'Jornalero',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetalleRow(
                      'Número de Empleado:',
                      empleado['numeroEmpleado']?.toString() ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildDetalleRow(
                      'CURP:', 
                      empleado['curp']?.toString() ?? 'N/A'
                    ),
                    _buildDivider(),
                    _buildDetalleRow(
                      'RFC:', 
                      empleado['rfc']?.toString() ?? 'N/A'
                    ),
                    _buildDivider(),
                    _buildDetalleRow(
                      'NSS:', 
                      empleado['nss']?.toString() ?? 'N/A'
                    ),
                    _buildDivider(),
                    _buildDetalleRow(
                      'Lugar de Procedencia:',
                      empleado['lugarProcedencia']?.toString() ?? 'N/A',
                    ),
                    _buildDivider(),
                    _buildDetalleRow(
                      'Tipo de Empleado:',
                      empleado['tipoEmpleado']?.toString() ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String nombre) {
    return nombre
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}