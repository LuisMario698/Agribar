import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart' as ExcelLib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';

class ResumenCuadrillasDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cuadrillasInfo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Future<void> Function(String)? onConfirmarCierre; // Callback que recibe la opción
  final VoidCallback onCancelar;
  final Map<String, List<Map<String, dynamic>>>? empleadosNominaTemp; // Datos temporales actualizados

  const ResumenCuadrillasDialog({
    Key? key,
    required this.cuadrillasInfo,
    required this.fechaInicio,
    required this.fechaFin,
    this.onConfirmarCierre,
    required this.onCancelar,
    this.empleadosNominaTemp,
  }) : super(key: key);

  @override
  State<ResumenCuadrillasDialog> createState() => _ResumenCuadrillasDialogState();
}

class _ResumenCuadrillasDialogState extends State<ResumenCuadrillasDialog> {
  bool _generandoExcel = false;
  bool _excelGenerado = false; // Variable para rastrear si se ha exportado Excel
  bool _generandoPdf = false; // Variable para rastrear si se está generando PDF de cheques

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Calcular total general usando datos temporales si están disponibles
    double totalGeneral = 0.0;
    for (var cuadrilla in widget.cuadrillasInfo) {
      final nombreCuadrilla = cuadrilla['nombre'];
      List<Map<String, dynamic>> empleadosParaCalcular;
      
      if (widget.empleadosNominaTemp != null && 
          widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
        empleadosParaCalcular = widget.empleadosNominaTemp![nombreCuadrilla]!;
      } else {
        empleadosParaCalcular = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
      }
      
      final totalCuadrilla = empleadosParaCalcular.fold<double>(
        0.0,
        (sum, empleado) {
          // 🔧 Buscar totalNeto correctamente según el formato de datos
          double totalNeto = 0.0;
          
          if (empleado.containsKey('totalNeto')) {
            // Datos directos con totalNeto
            totalNeto = _parseToDouble(empleado['totalNeto']);
          } else if (empleado['tabla_principal'] != null) {
            // Datos con estructura tabla_principal
            totalNeto = _parseToDouble(empleado['tabla_principal']['neto']);
          }
          
          return sum + totalNeto;
        },
      );
      totalGeneral += totalCuadrilla;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.85,
        constraints: const BoxConstraints(
          maxWidth: 900,
          minHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFF7BAE2F).withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7BAE2F),
                    const Color(0xFF6B9D28),
                    const Color(0xFF5A8B23),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7BAE2F).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono principal más moderno
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumen de Nómina por Cuadrillas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.date_range_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Del ${dateFormat.format(widget.fechaInicio)} al ${dateFormat.format(widget.fechaFin)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.groups_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.cuadrillasInfo.length} cuadrilla${widget.cuadrillasInfo.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón de cerrar mejorado
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: widget.onCancelar,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Cerrar',
                    ),
                  ),
                ],
              ),
            ),

            // Opciones de Excel
            Container(
              padding: const EdgeInsets.all(16), // Reducido de 20 a 16
              decoration: BoxDecoration(
                color: Colors.white,
                border: BorderDirectional(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Reducido de 8 a 6
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BAE2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.file_download,
                          color: Color(0xFF7BAE2F),
                          size: 18, // Reducido de 20 a 18
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Opciones de Exportación a Excel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15, // Reducido de 16 a 15
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Reducido de 16 a 12
                  // Botones de exportación
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generandoExcel ? null : _generarExcel,
                          icon: _generandoExcel
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : _excelGenerado
                                  ? const Icon(Icons.check_circle, size: 16, color: Colors.white)
                                  : const Icon(Icons.file_download, size: 16),
                          label: Text(
                            _generandoExcel 
                                ? 'Generando Excel...' 
                                : _excelGenerado 
                                    ? 'Excel Generado' 
                                    : 'Exportar Excel',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _excelGenerado 
                                ? Colors.green.shade600 
                                : const Color(0xFF7BAE2F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generandoPdf ? null : _generarChequesPdf,
                          icon: _generandoPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text(
                            _generandoPdf 
                                ? 'Generando PDF...' 
                                : 'Cheques PDF',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de cuadrillas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reducido padding
                itemCount: widget.cuadrillasInfo.length,
                itemBuilder: (context, index) {
                  final cuadrilla = widget.cuadrillasInfo[index];
                  return _buildCuadrillaCard(cuadrilla);
                },
              ),
            ),

            // Footer con total y botones
            Container(
              padding: const EdgeInsets.all(18), // Reducido de 24 a 18
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Total general destacado
                  Container(
                    padding: const EdgeInsets.all(16), // Reducido de 20 a 16
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7BAE2F).withOpacity(0.1),
                          const Color(0xFF7BAE2F).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                      border: Border.all(
                        color: const Color(0xFF7BAE2F).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6), // Reducido de 8 a 6
                              decoration: BoxDecoration(
                                color: const Color(0xFF7BAE2F),
                                borderRadius: BorderRadius.circular(6), // Reducido de 8 a 6
                              ),
                              child: const Icon(
                                Icons.calculate,
                                color: Colors.white,
                                size: 18, // Reducido de 20 a 18
                              ),
                            ),
                            const SizedBox(width: 10), // Reducido de 12 a 10
                            const Text(
                              'Total General Nómina:',
                              style: TextStyle(
                                fontSize: 16, // Reducido de 18 a 16
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${totalGeneral.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20, // Reducido de 24 a 20
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7BAE2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Reducido de 20 a 16
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCancelar,
                          icon: const Icon(Icons.cancel_outlined, size: 16), // Reducido de 18 a 16
                          label: const Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14), // Reducido de 16 a 14
                            side: BorderSide(color: Colors.grey.shade400, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Reducido de 16 a 12
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _manejarCierreSemana, // 🔄 Usar la nueva función con validación
                          icon: const Icon(Icons.lock_clock, size: 16), // Reducido de 18 a 16
                          label: const Text(
                            'Cerrar Semana y Guardar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13, // Reducido de 14 a 13
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7BAE2F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14), // Reducido de 16 a 14
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuadrillaCard(Map<String, dynamic> cuadrilla) {
    final empleados = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
    final nombreCuadrilla = cuadrilla['nombre'];
    
    // Usar datos temporales si están disponibles, sino usar los originales
    List<Map<String, dynamic>> empleadosActualizados = empleados;
    if (widget.empleadosNominaTemp != null && 
        widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
      empleadosActualizados = widget.empleadosNominaTemp![nombreCuadrilla]!;
    }
    
    // Calcular total actualizado
    final total = empleadosActualizados.fold<double>(
      0.0,
      (sum, empleado) {
        // 🔧 Buscar totalNeto directamente en el empleado o en tabla_principal
        double totalNeto = 0.0;
        
        if (empleado.containsKey('totalNeto')) {
          // Datos temporales o datos con totalNeto directo
          totalNeto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          // Datos con estructura tabla_principal
          totalNeto = _parseToDouble(empleado['tabla_principal']['neto']);
        }
        
        return sum + totalNeto;
      },
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF7BAE2F).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            childrenPadding: EdgeInsets.zero,
            title: Row(
              children: [
                // Icono de cuadrilla mejorado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7BAE2F).withOpacity(0.15),
                        const Color(0xFF7BAE2F).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF7BAE2F).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF7BAE2F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                // Información de cuadrilla
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreCuadrilla,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '${empleadosActualizados.length} empleado${empleadosActualizados.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11, // Reducido de 12 a 11
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total con formato mejorado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reducido padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BAE2F),
                    borderRadius: BorderRadius.circular(16), // Reducido de 20 a 16
                  ),
                  child: Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Reducido de 14 a 13
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    // Header de empleados
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reducido padding
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'CÓDIGO',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11, // Reducido de 12 a 11
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'EMPLEADO',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11, // Reducido de 12 a 11
                                color: Colors.grey.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            'TOTAL NETO',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11, // Reducido de 12 a 11
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Lista de empleados
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                      itemCount: empleadosActualizados.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6), // Reducido de 8 a 6
                      itemBuilder: (context, index) {
                        final empleado = empleadosActualizados[index];
                        
                        // 🔧 Buscar totalNeto correctamente según la estructura de datos
                        double neto = 0.0;
                        if (empleado.containsKey('totalNeto')) {
                          // Datos temporales o datos con totalNeto directo
                          neto = _parseToDouble(empleado['totalNeto']);
                        } else if (empleado['tabla_principal'] != null) {
                          // Datos con estructura tabla_principal
                          neto = _parseToDouble(empleado['tabla_principal']['neto']);
                        }
                        
                        final codigo = empleado['codigo']?.toString() ?? '';
                        final nombre = empleado['nombre']?.toString() ?? '';
                        
                        return Container(
                          padding: const EdgeInsets.all(10), // Reducido de 12 a 10
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6), // Reducido de 8 a 6
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Código del empleado
                              Container(
                                width: 55, // Reducido de 60 a 55
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reducido padding
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4), // Reducido de 6 a 4
                                ),
                                child: Text(
                                  codigo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11, // Reducido de 12 a 11
                                    color: Color(0xFF2C3E50),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 10), // Reducido de 12 a 10
                              // Nombre del empleado
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 13, // Reducido de 14 a 13
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              // Total neto
                              Text(
                                '\$${neto.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13, // Reducido de 14 a 13
                                  color: Color(0xFF7BAE2F),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Subtotal de la cuadrilla
                    if (empleadosActualizados.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Ajustado margins
                        padding: const EdgeInsets.all(10), // Reducido de 12 a 10
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BAE2F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6), // Reducido de 8 a 6
                          border: Border.all(
                            color: const Color(0xFF7BAE2F).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal ${nombreCuadrilla}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reducido de 14 a 13
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15, // Reducido de 16 a 15
                                color: Color(0xFF7BAE2F),
                              ),
                            ),
                          ],
                        ),
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

  /// Función auxiliar para convertir valores de manera segura a double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remover formatos de moneda y convertir
      final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  /// Convertir cantidad a letras en formato mexicano
  String _convertirCantidadALetras(double cantidad) {
    if (cantidad == 0) return 'SON: CERO PESOS 00/100 M.N.';
    
    final parteEntera = cantidad.floor();
    final parteFraccionaria = ((cantidad - parteEntera) * 100).round();
    
    String letras = _convertirEnteroALetras(parteEntera);
    
    return 'SON: $letras PESOS ${parteFraccionaria.toString().padLeft(2, '0')}/100 M.N.';
  }
  
  /// Convertir número entero a letras
  String _convertirEnteroALetras(int numero) {
    if (numero == 0) return 'CERO';
    
    final unidades = ['', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE'];
    final especiales = ['DIEZ', 'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE', 'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE'];
    final decenas = ['', '', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'];
    final centenas = ['', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'];
    
    if (numero < 10) return unidades[numero];
    if (numero < 20) return especiales[numero - 10];
    if (numero < 100) {
      final dec = numero ~/ 10;
      final uni = numero % 10;
      if (uni == 0) return decenas[dec];
      if (dec == 2) return 'VEINTI${unidades[uni]}';
      return '${decenas[dec]} Y ${unidades[uni]}';
    }
    if (numero < 1000) {
      final cen = numero ~/ 100;
      final resto = numero % 100;
      if (numero == 100) return 'CIEN';
      if (resto == 0) return centenas[cen];
      return '${centenas[cen]} ${_convertirEnteroALetras(resto)}';
    }
    if (numero < 1000000) {
      final miles = numero ~/ 1000;
      final resto = numero % 1000;
      String textoMiles = miles == 1 ? 'MIL' : '${_convertirEnteroALetras(miles)} MIL';
      if (resto == 0) return textoMiles;
      return '$textoMiles ${_convertirEnteroALetras(resto)}';
    }
    if (numero < 1000000000) {
      final millones = numero ~/ 1000000;
      final resto = numero % 1000000;
      String textoMillones = millones == 1 ? 'UN MILLÓN' : '${_convertirEnteroALetras(millones)} MILLONES';
      if (resto == 0) return textoMillones;
      return '$textoMillones ${_convertirEnteroALetras(resto)}';
    }
    
    return 'CANTIDAD MUY GRANDE';
  }

  /// Función auxiliar para formatear dinero de manera segura sin usar NumberFormat
  String _formatearDineroSeguro(double value) {
    try {
      // Eliminar decimales si es un número entero
      if (value == value.toInt()) {
        return '\$${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      } else {
        return '\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
    } catch (e) {
      print('❌ Error al formatear dinero: $e, valor: $value');
      return '\$${value.toInt()}'; // Fallback seguro
    }
  }

  Future<void> _generarExcel() async {
    setState(() => _generandoExcel = true);

    try {
      // Siempre generar todo junto (se eliminó la opción por cuadrillas separadas)
      await _generarExcelJunto();
      
      // ✅ Marcar que se ha generado el Excel exitosamente
      setState(() => _excelGenerado = true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _generandoExcel = false);
  }

  /// Mostrar diálogo para pedir el número de cheque inicial
  Future<int?> _mostrarDialogoNumeroChequInicial() async {
    final TextEditingController controller = TextEditingController();
    
    return await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono y título
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Número de Cheque Inicial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Contenido
                Text(
                  'Ingrese el número del primer cheque para la generación automática:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Campo de texto mejorado
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Número inicial',
                      hintText: '1001',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.numbers_rounded,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                    ),
                    autofocus: true,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Los números se generarán automáticamente incrementando de uno en uno',
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
                
                const SizedBox(height: 28),
                
                // Botones mejorados
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final numero = int.tryParse(controller.text.trim());
                          if (numero != null && numero > 0) {
                            Navigator.of(context).pop(numero);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Por favor ingrese un número válido mayor a 0'),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Función para generar PDF de cheques de nómina
  Future<void> _generarChequesPdf() async {
    // Primero pedir el número de cheque inicial
    final int? numeroInicial = await _mostrarDialogoNumeroChequInicial();
    if (numeroInicial == null) return; // Usuario canceló
    
    setState(() => _generandoPdf = true);

    try {
      // Crear el documento PDF
      final pdf = pw.Document();

      // Crear lista de todos los empleados de todas las cuadrillas
      List<Map<String, dynamic>> todosLosEmpleados = [];
      
      for (var cuadrilla in widget.cuadrillasInfo) {
        final empleados = cuadrilla['empleados'] as List<Map<String, dynamic>>? ?? [];
        for (var empleado in empleados) {
          todosLosEmpleados.add({
            ...empleado,
            'cuadrilla': cuadrilla['nombre'],
          });
        }
      }

      // Generar cheques (2 por página)
      for (int i = 0; i < todosLosEmpleados.length; i += 2) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(0), // Sin márgenes adicionales, manejamos todo internamente
            build: (context) {
              return pw.Column(
                children: [
                  // Primer cheque
                  _construirCheque(todosLosEmpleados[i], numeroInicial + i),
                  pw.SizedBox(height: 20), // Espaciado más compacto entre cheques
                  // Segundo cheque (si existe)
                  if (i + 1 < todosLosEmpleados.length)
                    _construirCheque(todosLosEmpleados[i + 1], numeroInicial + i + 1),
                ],
              );
            },
          ),
        );
      }

      // Permitir al usuario elegir dónde guardar
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar Cheques PDF',
        fileName: 'Cheques_Nomina_${DateFormat('dd-MM-yyyy').format(widget.fechaInicio)}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path != null) {
        final File file = File(path);
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF de cheques guardado en: $path'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF de cheques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _generandoPdf = false);
  }

  /// Construir un cheque individual con formato exacto de la imagen
  pw.Widget _construirCheque(Map<String, dynamic> empleado, int numeroCheque) {
    // Convertir totalNeto a double de forma segura
    double totalNeto = _parseToDouble(empleado['totalNeto']);
    
    // Formatear cantidad en números (con comas para miles)
    String cantidadNumeros = totalNeto.toStringAsFixed(2);
    cantidadNumeros = cantidadNumeros.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    );
    
    // Convertir cantidad a letras
    String cantidadLetras = _convertirCantidadALetras(totalNeto);
    
    // Formatear fecha como en la imagen (2 DE AGOSTO DEL 2025)
    final now = DateTime.now();
    final meses = [
      'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
      'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
    ];
    String fechaFormateada = '${now.day} DE ${meses[now.month - 1]} DEL ${now.year}';
    
    return pw.Container(
      height: 400, // Altura aumentada para simular hoja carta
      width: double.infinity,
      // Márgenes aumentados para centrar mejor el contenido
      padding: const pw.EdgeInsets.fromLTRB(120, 80, 80, 180), // Más márgenes en todos los lados
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Número de folio y fecha (arriba a la derecha)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    numeroCheque.toString(),
                    style: pw.TextStyle(
                      fontSize: 10, // 9-10 pts
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4), // Espaciado entre folio y fecha
                  pw.Text(
                    fechaFormateada,
                    style: pw.TextStyle(
                      fontSize: 10, // 10 pts
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          pw.SizedBox(height: 40), // Espaciado hasta el nombre
          
          // Nombre del beneficiario y monto
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Nombre del beneficiario (centro-izquierda)
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  empleado['nombre']?.toString().toUpperCase() ?? 'SIN NOMBRE',
                  style: pw.TextStyle(
                    fontSize: 11, // 11-12 pts
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(width: 30), // Más espacio entre nombre y monto
              
              // Monto en números (alineado a la derecha)
              pw.Text(
                cantidadNumeros,
                style: pw.TextStyle(
                  fontSize: 11, // 11-12 pts
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20), // Espaciado hasta el monto en letras
          
          // Monto en letras (debajo del nombre)
          pw.Text(
            cantidadLetras.toUpperCase(), // Todo en MAYÚSCULAS
            style: pw.TextStyle(
              fontSize: 10, // 10 pts
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Función para manejar el cierre de semana con validación de Excel
  Future<void> _manejarCierreSemana() async {
    if (!_excelGenerado) {
      // Mostrar diálogo de advertencia si no se ha generado Excel
      final bool? continuar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con icono de advertencia
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade50, Colors.orange.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade500,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.table_chart_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Excel No Generado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Recomendamos generar el archivo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contenido del mensaje principal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_late_outlined,
                          color: Colors.orange.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No has exportado la nómina a Excel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Te recomendamos generar el archivo antes de cerrar la semana para mantener un respaldo de la información.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Advertencia importante
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Importante:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Una vez cerrada la semana, no podrás generar el Excel con estos datos exactos.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Botones de acción mejorados
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generar Excel Primero',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.skip_next_rounded,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Continuar sin Excel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (continuar != true) {
        return; // No continuar si el usuario decide generar Excel primero
      }
    }

    // ✨ Mostrar diálogo de opciones para el cierre de semana
    await _mostrarOpcionesCierreSemana();
  }

  Future<void> _generarExcelJunto() async {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final fechaStr = '${dateFormat.format(widget.fechaInicio)}_${dateFormat.format(widget.fechaFin)}';
    
    final excel = ExcelLib.Excel.createExcel();
    
    // ✅ Eliminar la hoja por defecto de manera segura
    try {
      excel.delete('Sheet1');
    } catch (e) {
      print('No se pudo eliminar Sheet1: $e');
    }

    // 📊 HOJA GENERAL CON ESTRUCTURA DE TABLA PRINCIPAL PARA TODAS LAS CUADRILLAS
    final sheet = excel['Nómina General'];
    
    // 🎯 TÍTULOS DEL ARCHIVO
    sheet.cell(ExcelLib.CellIndex.indexByString('A1')).value = 'NÓMINA GENERAL - TODAS LAS CUADRILLAS';
    sheet.cell(ExcelLib.CellIndex.indexByString('A2')).value = 'Período: ${DateFormat('dd/MM/yyyy').format(widget.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(widget.fechaFin)}';
    
    int currentRow = 4;
    
    // 🏷️ PROCESAMIENTO POR CADA CUADRILLA
    for (var cuadrilla in widget.cuadrillasInfo) {
      final nombreCuadrilla = cuadrilla['nombre'];
      
      // Usar datos temporales si están disponibles
      List<Map<String, dynamic>> empleadosParaExportar;
      if (widget.empleadosNominaTemp != null && 
          widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
        empleadosParaExportar = widget.empleadosNominaTemp![nombreCuadrilla]!;
      } else {
        empleadosParaExportar = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
      }
      
      if (empleadosParaExportar.isEmpty) continue;
      
      // 📋 TÍTULO DE LA CUADRILLA
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow - 1)).value = 'CUADRILLA: ${nombreCuadrilla.toUpperCase()}';
      currentRow += 2;
      
      // 🏷️ ENCABEZADOS - RÉPLICA EXACTA DE LA TABLA PRINCIPAL
      int col = 1;
      
      // Columnas básicas
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Clave';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Empleado';
      col++;
      
      // Días de la semana
      final diasSemana = ['Jue', 'Vie', 'Sáb', 'Dom', 'Lun', 'Mar', 'Mié'];
      final fechasDias = ['3/7', '4/7', '5/7', '6/7', '7/7', '8/7', '2/7'];
      
      if (widget.fechaInicio != null && widget.fechaFin != null) {
        for (int i = 0; i < 7; i++) {
          final fecha = widget.fechaInicio.add(Duration(days: i));
          final diaReal = DateFormat('EEE', 'es').format(fecha).toLowerCase();
          final fechaReal = DateFormat('d/M').format(fecha);
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = '$diaReal\n$fechaReal';
          col++;
        }
      } else {
        for (int i = 0; i < 7; i++) {
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = '${diasSemana[i]}\n${fechasDias[i]}';
          col++;
        }
      }
      
      // Columnas de totales
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Total';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Debe';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Subtotal';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Comedor';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Total Neto';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Firma'; // Columna de firma
      col++;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = 'Total Neto';
      
      currentRow++;
      
      // 📊 DATOS DE EMPLEADOS DE ESTA CUADRILLA
      for (var empleado in empleadosParaExportar) {
        col = 1;
        
        // Clave y nombre
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = empleado['codigo']?.toString() ?? '';
        col++;
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = empleado['nombre']?.toString() ?? '';
        col++;
        
        // Días trabajados
        for (int i = 0; i < 7; i++) {
          final diasTrabajados = _parseToDouble(empleado['dia_${i}_s']);
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = diasTrabajados;
          col++;
        }
        
        // Totales
        final total = _parseToDouble(empleado['total']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = total;
        col++;
        
        final debe = _parseToDouble(empleado['debe']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = debe;
        col++;
        
        final subtotal = _parseToDouble(empleado['subtotal']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotal;
        col++;
        
        final comedor = _parseToDouble(empleado['comedor']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = comedor;
        col++;
        
        // Total Neto
        double totalNeto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          totalNeto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          final tablaData = empleado['tabla_principal'];
          totalNeto = _parseToDouble(tablaData['neto']);
        } else {
          totalNeto = subtotal - comedor;
        }
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = totalNeto;
        col++;
        
        // Nueva columna: Firma (vacía por defecto, para que los empleados firmen)
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = '';
        
        currentRow++;
      }
      
      // 🎯 SUBTOTALES POR CUADRILLA
      currentRow++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow - 1)).value = 'SUBTOTAL ${nombreCuadrilla}:';
      
      col = 3; // Empezar en los días
      for (int i = 0; i < 7; i++) {
        double totalDia = 0.0;
        for (var empleado in empleadosParaExportar) {
          totalDia += _parseToDouble(empleado['dia_${i}_s']);
        }
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = totalDia;
        col++;
      }
      
      // Subtotales de la cuadrilla
      double subtotalCuadrilla = 0.0;
      double subtotalDebe = 0.0;
      double subtotalSubtotal = 0.0;
      double subtotalComedor = 0.0;
      double subtotalNeto = 0.0;
      
      for (var empleado in empleadosParaExportar) {
        subtotalCuadrilla += _parseToDouble(empleado['total']);
        subtotalDebe += _parseToDouble(empleado['debe']);
        subtotalSubtotal += _parseToDouble(empleado['subtotal']);
        subtotalComedor += _parseToDouble(empleado['comedor']);
        
        double neto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          neto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          neto = _parseToDouble(empleado['tabla_principal']['neto']);
        } else {
          neto = _parseToDouble(empleado['subtotal']) - _parseToDouble(empleado['comedor']);
        }
        subtotalNeto += neto;
      }
      
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotalCuadrilla;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotalDebe;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotalSubtotal;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotalComedor;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = subtotalNeto;
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = ''; // Firma vacía en subtotales
      
      currentRow += 3; // Espacio entre cuadrillas
    }
    
    // 🎯 GRAN TOTAL FINAL
    currentRow++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow - 1)).value = '=== GRAN TOTAL FINAL ===';
    currentRow++;
    
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow - 1)).value = 'TOTALES GENERALES:';
    
    // Calcular totales generales de todas las cuadrillas
    int col = 3;
    for (int i = 0; i < 7; i++) {
      double totalGeneralDia = 0.0;
      for (var cuadrilla in widget.cuadrillasInfo) {
        final nombreCuadrilla = cuadrilla['nombre'];
        List<Map<String, dynamic>> empleados;
        if (widget.empleadosNominaTemp != null && 
            widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
          empleados = widget.empleadosNominaTemp![nombreCuadrilla]!;
        } else {
          empleados = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
        }
        
        for (var empleado in empleados) {
          totalGeneralDia += _parseToDouble(empleado['dia_${i}_s']);
        }
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = totalGeneralDia;
      col++;
    }
    
    // Totales generales finales
    double granTotal = 0.0;
    double granDebe = 0.0;
    double granSubtotal = 0.0;
    double granComedor = 0.0;
    double granNeto = 0.0;
    
    for (var cuadrilla in widget.cuadrillasInfo) {
      final nombreCuadrilla = cuadrilla['nombre'];
      List<Map<String, dynamic>> empleados;
      if (widget.empleadosNominaTemp != null && 
          widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
        empleados = widget.empleadosNominaTemp![nombreCuadrilla]!;
      } else {
        empleados = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
      }
      
      for (var empleado in empleados) {
        granTotal += _parseToDouble(empleado['total']);
        granDebe += _parseToDouble(empleado['debe']);
        granSubtotal += _parseToDouble(empleado['subtotal']);
        granComedor += _parseToDouble(empleado['comedor']);
        
        double neto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          neto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          neto = _parseToDouble(empleado['tabla_principal']['neto']);
        } else {
          neto = _parseToDouble(empleado['subtotal']) - _parseToDouble(empleado['comedor']);
        }
        granNeto += neto;
      }
    }
    
    col = 10; // Reset col to the Total column position
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = granTotal;
    col++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = granDebe;
    col++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = granSubtotal;
    col++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = granComedor;
    col++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = granNeto;
    col++;
    sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: currentRow - 1)).value = ''; // Firma vacía en totales

    // 📊 CREAR HOJAS INDIVIDUALES PARA CADA CUADRILLA
    for (var cuadrilla in widget.cuadrillasInfo) {
      final nombreCuadrilla = cuadrilla['nombre'];
      
      // Usar datos temporales si están disponibles
      List<Map<String, dynamic>> empleadosParaExportar;
      if (widget.empleadosNominaTemp != null && 
          widget.empleadosNominaTemp!.containsKey(nombreCuadrilla)) {
        empleadosParaExportar = widget.empleadosNominaTemp![nombreCuadrilla]!;
      } else {
        empleadosParaExportar = List<Map<String, dynamic>>.from(cuadrilla['empleados']);
      }
      
      if (empleadosParaExportar.isEmpty) continue;
      
      // Crear hoja individual para la cuadrilla
      final sheetCuadrilla = excel['$nombreCuadrilla'];
      
      // Título de la hoja individual
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByString('A1')).value = 'NÓMINA - CUADRILLA: ${nombreCuadrilla.toUpperCase()}';
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByString('A2')).value = 'Período: ${DateFormat('dd/MM/yyyy').format(widget.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(widget.fechaFin)}';
      
      int currentRowCuadrilla = 4;
      
      // Encabezados para la hoja individual
      int colCuadrilla = 1;
      
      // Columnas básicas
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Clave';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Empleado';
      colCuadrilla++;
      
      // Días de la semana
      if (widget.fechaInicio != null && widget.fechaFin != null) {
        for (int i = 0; i < 7; i++) {
          final fecha = widget.fechaInicio.add(Duration(days: i));
          final diaReal = DateFormat('EEE', 'es').format(fecha).toLowerCase();
          final fechaReal = DateFormat('d/M').format(fecha);
          sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = '$diaReal\n$fechaReal';
          colCuadrilla++;
        }
      } else {
        final diasSemana = ['Jue', 'Vie', 'Sáb', 'Dom', 'Lun', 'Mar', 'Mié'];
        final fechasDias = ['3/7', '4/7', '5/7', '6/7', '7/7', '8/7', '2/7'];
        for (int i = 0; i < 7; i++) {
          sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = '${diasSemana[i]}\n${fechasDias[i]}';
          colCuadrilla++;
        }
      }
      
      // Columnas de totales
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Total';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Debe';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Subtotal';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Comedor';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Total Neto';
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = 'Firma';
      colCuadrilla++;
      
      currentRowCuadrilla++;
      
      // Llenar datos de empleados en la hoja individual
      for (var empleado in empleadosParaExportar) {
        colCuadrilla = 1;
        
        // Clave y nombre
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = empleado['clave']?.toString() ?? '';
        colCuadrilla++;
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = empleado['nombre']?.toString() ?? '';
        colCuadrilla++;
        
        // Días
        for (int i = 0; i < 7; i++) {
          final valor = _parseToDouble(empleado['dia_${i}_s']);
          sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = valor;
          colCuadrilla++;
        }
        
        // Totales
        final total = _parseToDouble(empleado['total']);
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = total;
        colCuadrilla++;
        
        final debe = _parseToDouble(empleado['debe']);
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = debe;
        colCuadrilla++;
        
        final subtotal = _parseToDouble(empleado['subtotal']);
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = subtotal;
        colCuadrilla++;
        
        final comedor = _parseToDouble(empleado['comedor']);
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = comedor;
        colCuadrilla++;
        
        // Total Neto
        double totalNeto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          totalNeto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          final tablaData = empleado['tabla_principal'];
          totalNeto = _parseToDouble(tablaData['neto']);
        } else {
          totalNeto = subtotal - comedor;
        }
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = totalNeto;
        colCuadrilla++;
        
        // Firma (vacía para que el empleado firme)
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = '';
        
        currentRowCuadrilla++;
      }
      
      // Totales de la cuadrilla individual
      currentRowCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRowCuadrilla - 1)).value = 'TOTALES:';
      
      colCuadrilla = 3; // Empezar en los días
      for (int i = 0; i < 7; i++) {
        double totalDia = 0.0;
        for (var empleado in empleadosParaExportar) {
          totalDia += _parseToDouble(empleado['dia_${i}_s']);
        }
        sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = totalDia;
        colCuadrilla++;
      }
      
      // Calcular totales de la cuadrilla
      double totalCuadrilla = 0.0;
      double debeCuadrilla = 0.0;
      double subtotalCuadrilla = 0.0;
      double comedorCuadrilla = 0.0;
      double netoCuadrilla = 0.0;
      
      for (var empleado in empleadosParaExportar) {
        totalCuadrilla += _parseToDouble(empleado['total']);
        debeCuadrilla += _parseToDouble(empleado['debe']);
        subtotalCuadrilla += _parseToDouble(empleado['subtotal']);
        comedorCuadrilla += _parseToDouble(empleado['comedor']);
        
        double neto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          neto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          neto = _parseToDouble(empleado['tabla_principal']['neto']);
        } else {
          neto = _parseToDouble(empleado['subtotal']) - _parseToDouble(empleado['comedor']);
        }
        netoCuadrilla += neto;
      }
      
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = totalCuadrilla;
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = debeCuadrilla;
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = subtotalCuadrilla;
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = comedorCuadrilla;
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = netoCuadrilla;
      colCuadrilla++;
      sheetCuadrilla.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: colCuadrilla - 1, rowIndex: currentRowCuadrilla - 1)).value = ''; // Firma vacía en totales
    }

    await _guardarExcel(excel, 'Nomina_General_$fechaStr.xlsx');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Archivo Excel generado exitosamente', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('• Hoja General con todas las cuadrillas', style: TextStyle(fontSize: 12)),
            Text('• ${widget.cuadrillasInfo.length} hojas individuales por cuadrilla', style: const TextStyle(fontSize: 12)),
            const Text('• Nueva columna "Firma" añadida', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _guardarExcel(ExcelLib.Excel excel, String fileName) async {
    try {
      // Permitir al usuario elegir dónde guardar el archivo Excel
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar Nómina Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (path != null) {
        final file = File(path);
        final bytes = excel.encode();
        
        if (bytes != null) {
          await file.writeAsBytes(bytes);
          
          // Mostrar mensaje de éxito con la ubicación elegida
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Archivo Excel guardado exitosamente',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ubicación: $path',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          throw Exception('No se pudo codificar el archivo Excel');
        }
      } else {
        // Usuario canceló el diálogo de guardar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Guardado cancelado por el usuario'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al guardar archivo: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// 🔄 Nuevo diálogo para elegir entre resetear o mantener cuadrillas
  Future<void> _mostrarOpcionesCierreSemana() async {
    final String? opcionSeleccionada = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF7BAE2F).withOpacity(0.1), const Color(0xFF7BAE2F).withOpacity(0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7BAE2F).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7BAE2F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7BAE2F).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_backup_restore_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configurar Nueva Semana',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecciona la configuración deseada',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Descripción
                Text(
                  'Elige cómo deseas configurar las cuadrillas para la próxima semana:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Opciones mejoradas
                Column(
                  children: [
                    // Opción 1: Resetear cuadrillas
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade50, Colors.red.shade100.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade100.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop('resetear'),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade500,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Resetear Cuadrillas',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Empezar de cero armando cuadrillas para la nueva semana',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.red.shade400,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Opción 2: Mantener cuadrillas
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade100.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop('mantener'),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade500,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mantener Cuadrillas Actuales',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Conservar empleados asignados, solo resetear sueldos y actividades',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.green.shade400,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta acción cerrará la semana actual y preparará el sistema para la próxima semana de trabajo.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Botón de cancelar mejorado
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancelar Operación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (opcionSeleccionada != null && widget.onConfirmarCierre != null) {
      // Proceder según la opción seleccionada
      await widget.onConfirmarCierre!(opcionSeleccionada);
    }
  }
}
