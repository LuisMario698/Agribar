import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart' as ExcelLib;
import 'package:path_provider/path_provider.dart';

class ResumenCuadrillasDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cuadrillasInfo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final VoidCallback onConfirmarCierre;
  final VoidCallback onCancelar;
  final Map<String, List<Map<String, dynamic>>>? empleadosNominaTemp; // Datos temporales actualizados

  const ResumenCuadrillasDialog({
    Key? key,
    required this.cuadrillasInfo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onConfirmarCierre,
    required this.onCancelar,
    this.empleadosNominaTemp,
  }) : super(key: key);

  @override
  State<ResumenCuadrillasDialog> createState() => _ResumenCuadrillasDialogState();
}

class _ResumenCuadrillasDialogState extends State<ResumenCuadrillasDialog> {
  bool _generandoExcel = false;
  String _tipoExcel = 'separado'; // 'separado' o 'junto'
  bool _excelGenerado = false; // 🆕 Variable para rastrear si se ha exportado Excel

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
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                          decoration: BoxDecoration(
                            color: _tipoExcel == 'separado' 
                                ? const Color(0xFF7BAE2F).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                            border: Border.all(
                              color: _tipoExcel == 'separado' 
                                  ? const Color(0xFF7BAE2F)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _tipoExcel = 'separado'),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'separado',
                                  groupValue: _tipoExcel,
                                  onChanged: (value) => setState(() => _tipoExcel = value!),
                                  activeColor: const Color(0xFF7BAE2F),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Icon(
                                  Icons.folder_open,
                                  color: Color(0xFF7BAE2F),
                                  size: 18, // Reducido de 20 a 18
                                ),
                                const SizedBox(width: 6), // Reducido de 8 a 6
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Por cuadrilla',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13, // Reducido de 14 a 13
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      Text(
                                        'Un archivo por cada cuadrilla',
                                        style: TextStyle(
                                          fontSize: 11, // Reducido de 12 a 11
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Reducido de 12 a 10
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                          decoration: BoxDecoration(
                            color: _tipoExcel == 'junto' 
                                ? const Color(0xFF7BAE2F).withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                            border: Border.all(
                              color: _tipoExcel == 'junto' 
                                  ? const Color(0xFF7BAE2F)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _tipoExcel = 'junto'),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'junto',
                                  groupValue: _tipoExcel,
                                  onChanged: (value) => setState(() => _tipoExcel = value!),
                                  activeColor: const Color(0xFF7BAE2F),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Icon(
                                  Icons.description,
                                  color: Color(0xFF7BAE2F),
                                  size: 18, // Reducido de 20 a 18
                                ),
                                const SizedBox(width: 6), // Reducido de 8 a 6
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Todo junto',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13, // Reducido de 14 a 13
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      Text(
                                        'Un archivo con todas las cuadrillas',
                                        style: TextStyle(
                                          fontSize: 11, // Reducido de 12 a 11
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Espacio para el botón
                      ElevatedButton.icon(
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
                                : const Icon(Icons.download, size: 16),
                        label: Text(
                          _generandoExcel 
                              ? 'Generando...' 
                              : _excelGenerado 
                                  ? 'Excel Generado' 
                                  : 'Generar Excel',
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

  Future<void> _generarExcel() async {
    setState(() => _generandoExcel = true);

    try {
      if (_tipoExcel == 'separado') {
        await _generarExcelSeparado();
      } else {
        await _generarExcelJunto();
      }
      
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

  /// 🚨 Función para manejar el cierre de semana con validación de Excel
  Future<void> _manejarCierreSemana() async {
    if (!_excelGenerado) {
      // Mostrar diálogo de advertencia si no se ha generado Excel
      final bool? continuar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Excel no generado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No has exportado la nómina a Excel. Te recomendamos generar el archivo antes de cerrar la semana.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Una vez cerrada la semana, no podrás generar el Excel con estos datos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Generar Excel primero',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continuar sin Excel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      if (continuar != true) {
        return; // No continuar si el usuario decide generar Excel primero
      }
    }

    // Proceder con el cierre de semana
    widget.onConfirmarCierre();
  }

  Future<void> _generarExcelSeparado() async {
    final dateFormat = DateFormat('dd-MM-yyyy');
    final fechaStr = '${dateFormat.format(widget.fechaInicio)}_${dateFormat.format(widget.fechaFin)}';

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

      final excel = ExcelLib.Excel.createExcel();
      
      // ✅ Eliminar la hoja por defecto de manera segura
      try {
        excel.delete('Sheet1');
      } catch (e) {
        print('No se pudo eliminar Sheet1: $e');
      }

      // 📊 ESTRUCTURA EXACTA DE LA TABLA PRINCIPAL
      final sheet = excel[nombreCuadrilla];
      
      // 🎯 TÍTULOS DEL ARCHIVO
      sheet.cell(ExcelLib.CellIndex.indexByString('A1')).value = 'NÓMINA - ${nombreCuadrilla.toUpperCase()}';
      sheet.cell(ExcelLib.CellIndex.indexByString('A2')).value = 'Período: ${DateFormat('dd/MM/yyyy').format(widget.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(widget.fechaFin)}';
      
      // 🏷️ ENCABEZADOS (fila 4) - RÉPLICA EXACTA DE LA TABLA PRINCIPAL
      int row = 4;
      int col = 1;
      
      // Columna 1: Clave
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Clave';
      col++;
      
      // Columna 2: Empleado
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Empleado';
      col++;
      
      // Columnas 3-9: Días de la semana (réplica exacta)
      final diasSemana = ['Jue', 'Vie', 'Sáb', 'Dom', 'Lun', 'Mar', 'Mié'];
      final fechasDias = ['3/7', '4/7', '5/7', '6/7', '7/7', '8/7', '2/7'];
      
      // Si tenemos fechas reales de la semana, usarlas
      if (widget.fechaInicio != null && widget.fechaFin != null) {
        final diasReales = <String>[];
        final fechasReales = <String>[];
        
        for (int i = 0; i < 7; i++) {
          final fecha = widget.fechaInicio.add(Duration(days: i));
          diasReales.add(DateFormat('EEE', 'es').format(fecha).toLowerCase());
          fechasReales.add(DateFormat('d/M').format(fecha));
        }
        
        for (int i = 0; i < 7; i++) {
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = '${diasReales[i]}\n${fechasReales[i]}';
          col++;
        }
      } else {
        // Usar días por defecto
        for (int i = 0; i < 7; i++) {
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = '${diasSemana[i]}\n${fechasDias[i]}';
          col++;
        }
      }
      
      // Columnas finales: Total, Debe, Subtotal, Comedor, Total Neto
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Total';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Debe';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Subtotal';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Comedor';
      col++;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = 'Total Neto';
      
      // 📊 DATOS DE EMPLEADOS (comenzando en fila 5)
      row = 5;
      for (var empleado in empleadosParaExportar) {
        col = 1;
        
        // Columna 1: Clave (código)
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = empleado['codigo']?.toString() ?? '';
        col++;
        
        // Columna 2: Nombre completo
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = empleado['nombre']?.toString() ?? '';
        col++;
        
        // Columnas 3-9: Días trabajados (dia_0_s, dia_1_s, ..., dia_6_s)
        for (int i = 0; i < 7; i++) {
          final diasTrabajados = _parseToDouble(empleado['dia_${i}_s']);
          sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = diasTrabajados;
          col++;
        }
        
        // Columna 10: Total
        final total = _parseToDouble(empleado['total']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = total;
        col++;
        
        // Columna 11: Debe
        final debe = _parseToDouble(empleado['debe']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = debe;
        col++;
        
        // Columna 12: Subtotal
        final subtotal = _parseToDouble(empleado['subtotal']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = subtotal;
        col++;
        
        // Columna 13: Comedor
        final comedor = _parseToDouble(empleado['comedor']);
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = comedor;
        col++;
        
        // Columna 14: Total Neto
        double totalNeto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          totalNeto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          final tablaData = empleado['tabla_principal'];
          totalNeto = _parseToDouble(tablaData['neto']);
        } else {
          // Calcular manualmente: Subtotal - Comedor
          totalNeto = subtotal - comedor;
        }
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalNeto;
        
        row++;
      }
      
      // 🎯 FILA DE TOTALES (separada por una fila en blanco)
      row += 2;
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row - 1)).value = 'TOTALES:';
      
      // Calcular totales por columna
      col = 3; // Empezar en los días
      for (int i = 0; i < 7; i++) {
        double totalDia = 0.0;
        for (var empleado in empleadosParaExportar) {
          totalDia += _parseToDouble(empleado['dia_${i}_s']);
        }
        sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalDia;
        col++;
      }
      
      // Total general
      double totalGeneral = 0.0;
      for (var empleado in empleadosParaExportar) {
        totalGeneral += _parseToDouble(empleado['total']);
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalGeneral;
      col++;
      
      // Total Debe
      double totalDebe = 0.0;
      for (var empleado in empleadosParaExportar) {
        totalDebe += _parseToDouble(empleado['debe']);
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalDebe;
      col++;
      
      // Total Subtotal
      double totalSubtotal = 0.0;
      for (var empleado in empleadosParaExportar) {
        totalSubtotal += _parseToDouble(empleado['subtotal']);
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalSubtotal;
      col++;
      
      // Total Comedor
      double totalComedor = 0.0;
      for (var empleado in empleadosParaExportar) {
        totalComedor += _parseToDouble(empleado['comedor']);
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalComedor;
      col++;
      
      // Total Neto Final
      double totalNetoFinal = 0.0;
      for (var empleado in empleadosParaExportar) {
        double neto = 0.0;
        if (empleado.containsKey('totalNeto')) {
          neto = _parseToDouble(empleado['totalNeto']);
        } else if (empleado['tabla_principal'] != null) {
          final tablaData = empleado['tabla_principal'];
          neto = _parseToDouble(tablaData['neto']);
        } else {
          neto = _parseToDouble(empleado['subtotal']) - _parseToDouble(empleado['comedor']);
        }
        totalNetoFinal += neto;
      }
      sheet.cell(ExcelLib.CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: row - 1)).value = totalNetoFinal;

      await _guardarExcel(excel, 'Nomina_${nombreCuadrilla}_$fechaStr.xlsx');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('${widget.cuadrillasInfo.length} archivo(s) Excel generado(s) con estructura de tabla principal'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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

    await _guardarExcel(excel, 'Nomina_General_$fechaStr.xlsx');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Archivo Excel general generado con estructura de tabla principal'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _guardarExcel(ExcelLib.Excel excel, String fileName) async {
    try {
      Directory? directory;
      
      // Obtener directorio según la plataforma
      try {
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else {
          // Para todas las demás plataformas, usar el directorio de documentos
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        // Si falla, usar el directorio de documentos como fallback
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('No se pudo obtener el directorio de almacenamiento');
      }
      
      final file = File('${directory.path}/$fileName');
      
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        
        // Mostrar mensaje con la ubicación del archivo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Archivo guardado: $fileName',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ubicación: ${file.path}',
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
}
