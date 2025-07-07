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
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 20,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✨ Header con gradiente sutil
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.green.withOpacity(0.08),
                      AppColors.green.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // ✨ Avatar mejorado
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
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
                    ),
                    const SizedBox(width: 16),
                    // ✨ Información del empleado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empleado['nombre'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${empleado['id']} • ${empleado['puesto'] ?? 'Jornalero'}',
                              style: TextStyle(
                                color: AppColors.greenDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✨ Botón de cerrar mejorado
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ✨ Contenido de la información
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetalleRow(
                      'Número de Empleado:',
                      empleado['numeroEmpleado']?.toString() ?? 'N/A',
                      Icons.badge_outlined,
                    ),
                    _buildDetalleRow(
                      'CURP:', 
                      empleado['curp']?.toString() ?? 'N/A',
                      Icons.fingerprint,
                    ),
                    _buildDetalleRow(
                      'RFC:', 
                      empleado['rfc']?.toString() ?? 'N/A',
                      Icons.account_balance_wallet_outlined,
                    ),
                    _buildDetalleRow(
                      'NSS:', 
                      empleado['nss']?.toString() ?? 'N/A',
                      Icons.health_and_safety_outlined,
                    ),
                    _buildDetalleRow(
                      'Lugar de Procedencia:',
                      empleado['lugarProcedencia']?.toString() ?? 'N/A',
                      Icons.location_on_outlined,
                    ),
                    _buildDetalleRow(
                      'Tipo de Empleado:',
                      empleado['tipoEmpleado']?.toString() ?? 'N/A',
                      Icons.work_outline,
                      isLast: true,
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

  Widget _buildDetalleRow(String label, String value, IconData icon, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✨ Icono temático
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.greenDark,
            ),
          ),
          const SizedBox(width: 12),
          // ✨ Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}