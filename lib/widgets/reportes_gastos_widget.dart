import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ExcelPkg;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/reportes_gastos_service.dart';
import '../theme/app_styles.dart';

class ReportesGastosWidget extends StatefulWidget {
  const ReportesGastosWidget({Key? key}) : super(key: key);

  @override
  State<ReportesGastosWidget> createState() => _ReportesGastosWidgetState();
}

class _ReportesGastosWidgetState extends State<ReportesGastosWidget> {
  final ReportesGastosService _reportesService = ReportesGastosService();
  
  // Estados del widget
  List<Map<String, dynamic>> _datosReporte = [];
  List<Map<String, dynamic>> _semanas = [];
  List<Map<String, dynamic>> _ranchos = [];
  List<Map<String, dynamic>> _actividades = [];
  List<Map<String, dynamic>> _resumenRanchos = []; // Nueva variable para resumen por ranchos
  List<Map<String, dynamic>> _resumenRanchosPorActividad = []; // Resumen de ranchos filtrado por actividad
  
  // Filtros seleccionados
  int? _semanaSeleccionada;
  int? _ranchoSeleccionado;
  int? _actividadSeleccionada;
  
  // Tipo de reporte
  String _tipoReporte = 'general'; // 'general', 'rancho', 'actividad'
  
  bool _cargando = false;
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargando = true);
    
    try {
      // Cargar datos secuencialmente para evitar conflictos de conexión
      _semanas = await _reportesService.obtenerSemanasDisponibles();
      _ranchos = await _reportesService.obtenerRanchosDisponibles();
      _actividades = await _reportesService.obtenerActividadesDisponibles();
      
      setState(() {
        // Seleccionar la semana más reciente por defecto
        if (_semanas.isNotEmpty) {
          _semanaSeleccionada = _semanas.first['id'];
        }
      });
      
      // Cargar reporte inicial
      if (_semanaSeleccionada != null) {
        await _generarReporte();
      }
      
    } catch (e) {
      _mostrarError('Error al cargar datos iniciales: $e');
    } finally {
      setState(() {
        _cargando = false;
        _primeraCarga = false;
      });
    }
  }

  Future<void> _generarReporte() async {
    if (_cargando) return;
    
    setState(() => _cargando = true);
    
    try {
      List<Map<String, dynamic>> datos = [];
      List<Map<String, dynamic>> resumenRanchos = [];
      
      switch (_tipoReporte) {
        case 'general':
          if (_semanaSeleccionada != null) {
            datos = await _reportesService.obtenerReporteGeneralPorSemana(_semanaSeleccionada!);
            // Cargar también el resumen por ranchos para el reporte general
            resumenRanchos = await _reportesService.obtenerResumenPorRanchos(_semanaSeleccionada!);
          }
          break;
          
        case 'rancho':
          if (_semanaSeleccionada != null && _ranchoSeleccionado != null) {
            datos = await _reportesService.obtenerReportePorRancho(_semanaSeleccionada!, _ranchoSeleccionado!);
          }
          break;
          
        case 'actividad':
          if (_semanaSeleccionada != null && _actividadSeleccionada != null) {
            datos = await _reportesService.obtenerReportePorActividad(_semanaSeleccionada!, _actividadSeleccionada!);
            // También cargar el resumen de ranchos para esta actividad
            final resumenRanchosPorActividad = await _reportesService.obtenerResumenRanchosPorActividad(_semanaSeleccionada!, _actividadSeleccionada!);
            setState(() {
              _resumenRanchosPorActividad = resumenRanchosPorActividad;
            });
          }
          break;
      }
      
      setState(() {
        _datosReporte = datos;
        _resumenRanchos = resumenRanchos;
      });
      
    } catch (e) {
      _mostrarError('Error al generar reporte: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _refrescarSemanas() async {
    try {
      setState(() => _cargando = true);
      
      // Recargar semanas
      _semanas = await _reportesService.obtenerSemanasDisponibles();
      
      setState(() {
        // Mantener la semana seleccionada si existe, sino seleccionar la más reciente
        if (_semanaSeleccionada != null) {
          bool semanaExiste = _semanas.any((s) => s['id'] == _semanaSeleccionada);
          if (!semanaExiste && _semanas.isNotEmpty) {
            _semanaSeleccionada = _semanas.first['id'];
          }
        } else if (_semanas.isNotEmpty) {
          _semanaSeleccionada = _semanas.first['id'];
        }
      });
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semanas actualizadas. ${_semanas.length} semana(s) encontrada(s).'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Regenerar reporte si hay una semana seleccionada
      if (_semanaSeleccionada != null) {
        await _generarReporte();
      }
      
    } catch (e) {
      _mostrarError('Error al refrescar semanas: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  double get _totalGeneral {
    return _datosReporte.fold(0.0, (sum, item) => sum + (item['total_pagado'] as double));
  }

  void _exportarPDF() async {
    try {
      // Seleccionar ubicación para guardar PDF
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar reporte como PDF',
        fileName: 'reporte_gastos_${_getTipoReporteLabel()}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        // Asegurar que la extensión sea correcta
        if (!outputFile.endsWith('.pdf')) {
          outputFile += '.pdf';
        }
        
        // Crear archivo PDF profesional
        final pdf = pw.Document();
        
        // Cargar logo de la empresa
        final logoBytes = await rootBundle.load('assets/logo.jpg');
        final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
        
        // Obtener encabezados y datos
        List<String> headers = _getColumnHeaders();
        List<List<String>> tableData = _datosReporte.map((fila) => 
          _getRowValues(fila).map((value) => value.toString()).toList()
        ).toList();
        
        // Calcular total general
        double totalGeneral = 0.0;
        for (var fila in _datosReporte) {
          totalGeneral += (fila['total_pagado'] ?? 0.0);
        }
        
        // Obtener información de la semana seleccionada
        String semanaInfo = 'N/A';
        if (_semanaSeleccionada != null && _semanas.isNotEmpty) {
          try {
            final semana = _semanas.firstWhere(
              (s) => s['id'] == _semanaSeleccionada,
            );
            // Formatear las fechas para mostrar solo la fecha sin tiempo
            String fechaInicio = semana['fecha_inicio'].toString().split(' ')[0];
            String fechaFin = semana['fecha_fin'].toString().split(' ')[0];
            semanaInfo = '$fechaInicio - $fechaFin';
          } catch (e) {
            semanaInfo = 'Semana no encontrada';
          }
        }
        
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter, // Cambiar a tamaño carta
            margin: pw.EdgeInsets.all(25),
            header: (pw.Context context) {
              // Solo mostrar el header completo en la primera página
              if (context.pageNumber == 1) {
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 25),
                  child: pw.Column(
                    children: [
                      // Header principal con logo e información
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Logo de la empresa en la esquina izquierda
                          pw.Container(
                            width: 70,
                            height: 70,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(width: 20),
                          // Información de la empresa y reporte
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'AGRIBAR',
                                  style: pw.TextStyle(
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Sistema de Gestión Agrícola',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Container(
                                  padding: pw.EdgeInsets.all(8),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.green50,
                                    border: pw.Border.all(color: PdfColors.green200),
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    'REPORTE DE GASTOS - ${_getTipoReporteLabel().toUpperCase()}',
                                    style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.green800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Información del reporte en la esquina derecha
                          pw.Container(
                            width: 180,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                _buildInfoRow('Fecha de generación:', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                                _buildInfoRow('Hora:', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                                _buildInfoRow('Generado por:', 'Sistema AGRIBAR'),
                                _buildInfoRow('Semana:', semanaInfo),
                                _buildInfoRow('Tipo de reporte:', _getTipoReporteLabel()),
                                if (_tipoReporte == 'rancho' && _ranchoSeleccionado != null)
                                  _buildInfoRow('Rancho:', _getRanchoNombre(_ranchoSeleccionado!)),
                                if (_tipoReporte == 'actividad' && _actividadSeleccionada != null)
                                  _buildInfoRow('Actividad:', _getActividadNombre(_actividadSeleccionada!)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      // Línea divisoria después del header
                      pw.Container(
                        height: 2,
                        color: PdfColors.green600,
                      ),
                    ],
                  ),
                );
              } else {
                // Para páginas siguientes, solo mostrar un header simple
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 15),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'AGRIBAR - Reporte de Gastos',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                          pw.Text(
                            'Página ${context.pageNumber}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 1,
                        color: PdfColors.green400,
                      ),
                    ],
                  ),
                );
              }
            },
            build: (pw.Context context) {
              return [
                // Espacio después del header
                pw.SizedBox(height: 20),
                
                // Mostrar resumen de ranchos si es reporte general o por actividad
                if ((_tipoReporte == 'general' && _resumenRanchos.isNotEmpty) || 
                    (_tipoReporte == 'actividad' && _resumenRanchosPorActividad.isNotEmpty)) ...[
                  pw.Text(
                    'RESUMEN POR RANCHOS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    headers: ['Rancho', 'Empleados', 'Cuadrillas', 'Total Pagado'],
                    data: (_tipoReporte == 'general' ? _resumenRanchos : _resumenRanchosPorActividad).map((rancho) => [
                      rancho['rancho_nombre'] ?? 'Sin asignar',
                      (rancho['empleados_trabajaron'] ?? 0).toString(),
                      (rancho['cuadrillas_trabajaron'] ?? 0).toString(),
                      '\$${(rancho['total_ganancia'] ?? 0.0).toStringAsFixed(2)}',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.green600),
                    cellStyle: pw.TextStyle(fontSize: 10),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerRight,
                    },
                  ),
                  pw.SizedBox(height: 30),
                ],
                
                // Título de la tabla principal
                pw.Text(
                  'DETALLE DE ACTIVIDADES',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 10),
                
                // Tabla principal de datos
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: tableData,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.green600),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  cellAlignments: Map.fromIterable(
                    List.generate(headers.length, (index) => index),
                    value: (index) {
                      // Alinear números a la derecha, texto a la izquierda
                      if (headers[index].contains('Total') || 
                          headers[index].contains('Empleados') || 
                          headers[index].contains('Cuadrillas') ||
                          headers[index].contains('Promedio') ||
                          headers[index].contains('Eficiencia')) {
                        return pw.Alignment.centerRight;
                      }
                      return pw.Alignment.centerLeft;
                    },
                  ),
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
                ),
                
                pw.SizedBox(height: 30),
                
                // Línea divisoria
                pw.Container(
                  height: 2,
                  color: PdfColors.green600,
                ),
                
                pw.SizedBox(height: 15),
                
                // Total general con diseño destacado
                pw.Container(
                  padding: pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green600, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TOTAL GENERAL',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                          pw.Text(
                            'Suma total de todos los gastos reportados',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        '\$${totalGeneral.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Información adicional
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Información del Reporte:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '• Total de registros: ${_datosReporte.length}',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '• Reporte generado automáticamente por el Sistema AGRIBAR',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        '• Los montos están expresados en pesos mexicanos (MXN)',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ];
            },
            footer: (pw.Context context) {
              return pw.Container(
                margin: pw.EdgeInsets.only(top: 20),
                padding: pw.EdgeInsets.symmetric(vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'AGRIBAR - Sistema de Gestión Agrícola',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Página ${context.pageNumber} de ${context.pagesCount}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        
        // Guardar archivo
        final file = File(outputFile);
        await file.writeAsBytes(await pdf.save());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado exitosamente en: ${outputFile}'),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Abrir ubicación',
              textColor: Colors.white,
              onPressed: () {
                // Aquí podrías agregar funcionalidad para abrir la carpeta
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar PDF: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _getTipoReporteLabel() {
    switch (_tipoReporte) {
      case 'general':
        return 'General';
      case 'rancho':
        return 'Por Rancho';
      case 'actividad':
        return 'Por Actividad';
      default:
        return 'General';
    }
  }

  void _exportarExcel() async {
    try {
      // Seleccionar ubicación para guardar Excel
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar reporte como Excel',
        fileName: 'AGRIBAR_Reporte_${_getTipoReporteLabel()}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        // Asegurar que la extensión sea correcta
        if (!outputFile.endsWith('.xlsx')) {
          outputFile += '.xlsx';
        }
        
        // Crear archivo Excel profesional
        var excel = ExcelPkg.Excel.createExcel();
        
        // Eliminar la hoja por defecto
        excel.delete('Sheet1');
        
        // Crear hoja principal con nombre descriptivo
        String nombreHoja = 'Reporte ${_getTipoReporteLabel()}';
        var sheet = excel[nombreHoja];
        
        // Obtener información de la semana
        String semanaInfo = 'N/A';
        if (_semanaSeleccionada != null && _semanas.isNotEmpty) {
          try {
            final semana = _semanas.firstWhere(
              (s) => s['id'] == _semanaSeleccionada,
            );
            String fechaInicio = semana['fecha_inicio'].toString().split(' ')[0];
            String fechaFin = semana['fecha_fin'].toString().split(' ')[0];
            semanaInfo = '$fechaInicio - $fechaFin';
          } catch (e) {
            semanaInfo = 'Semana no encontrada';
          }
        }
        
        int filaActual = 0;
        
        // ===== HEADER INFORMATIVO =====
        // Título principal
        var celdaTitulo = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual));
        celdaTitulo.value = 'AGRIBAR - SISTEMA DE GESTIÓN AGRÍCOLA';
        filaActual++;
        
        // Subtítulo
        var celdaSubtitulo = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual));
        celdaSubtitulo.value = 'REPORTE DE GASTOS - ${_getTipoReporteLabel().toUpperCase()}';
        filaActual += 2;
        
        // Información del reporte
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Fecha de generación:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
        filaActual++;
        
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Semana:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = semanaInfo;
        filaActual++;
        
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Tipo de reporte:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = _getTipoReporteLabel();
        filaActual++;
        
        if (_tipoReporte == 'rancho' && _ranchoSeleccionado != null) {
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Rancho:';
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = _getRanchoNombre(_ranchoSeleccionado!);
          filaActual++;
        }
        
        if (_tipoReporte == 'actividad' && _actividadSeleccionada != null) {
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Actividad:';
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = _getActividadNombre(_actividadSeleccionada!);
          filaActual++;
        }
        
        filaActual += 2;
        
        // ===== RESUMEN DE RANCHOS (para reporte general y por actividad) =====
        if ((_tipoReporte == 'general' && _resumenRanchos.isNotEmpty) || 
            (_tipoReporte == 'actividad' && _resumenRanchosPorActividad.isNotEmpty)) {
          // Título del resumen
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'RESUMEN POR RANCHOS';
          filaActual += 2;
          
          // Headers del resumen
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Rancho';
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = 'Empleados';
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: filaActual)).value = 'Cuadrillas';
          sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaActual)).value = 'Total Pagado';
          filaActual++;
          
          // Datos del resumen - usar el resumen correcto según el tipo de reporte
          List<Map<String, dynamic>> resumenAUsar = _tipoReporte == 'general' ? _resumenRanchos : _resumenRanchosPorActividad;
          for (var rancho in resumenAUsar) {
            sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = rancho['rancho_nombre'] ?? 'Sin asignar';
            sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = rancho['empleados_trabajaron'] ?? 0;
            sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: filaActual)).value = rancho['cuadrillas_trabajaron'] ?? 0;
            sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: filaActual)).value = rancho['total_ganancia'] ?? 0.0;
            filaActual++;
          }
          filaActual += 2;
        }
        
        // ===== TABLA PRINCIPAL DE DATOS =====
        // Título de la tabla
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'DETALLE DE ACTIVIDADES';
        filaActual += 2;
        
        // Headers de la tabla principal
        List<String> headers = _getColumnHeaders();
        for (int i = 0; i < headers.length; i++) {
          var cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: filaActual));
          cell.value = headers[i];
        }
        filaActual++;
        
        // Datos de la tabla principal
        for (int rowIndex = 0; rowIndex < _datosReporte.length; rowIndex++) {
          var fila = _datosReporte[rowIndex];
          List<dynamic> valores = _getRowValues(fila);
          
          for (int colIndex = 0; colIndex < valores.length; colIndex++) {
            var cellValue = valores[colIndex];
            var cell = sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(
              columnIndex: colIndex, 
              rowIndex: filaActual + rowIndex
            ));
            cell.value = cellValue;
          }
        }
        
        filaActual += _datosReporte.length + 2;
        
        // ===== TOTALES =====
        double totalGeneral = 0.0;
        for (var fila in _datosReporte) {
          totalGeneral += (fila['total_pagado'] ?? 0.0);
        }
        
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'TOTAL GENERAL:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = totalGeneral;
        filaActual++;
        
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Total de registros:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = _datosReporte.length;
        filaActual++;
        
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: filaActual)).value = 'Generado por:';
        sheet.cell(ExcelPkg.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: filaActual)).value = 'Sistema AGRIBAR';
        
        // Guardar archivo
        var fileBytes = excel.save();
        if (fileBytes != null) {
          final file = File(outputFile);
          await file.writeAsBytes(fileBytes);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Excel profesional guardado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: AppColors.green,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Ver ubicación',
                textColor: Colors.white,
                onPressed: () {
                  // Aquí podrías agregar funcionalidad para abrir la carpeta
                },
              ),
            ),
          );
        } else {
          throw Exception('No se pudieron generar los bytes del archivo Excel');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al exportar Excel: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  List<String> _getColumnHeaders() {
    switch (_tipoReporte) {
      case 'general':
        return ['Clave', 'Actividad', 'Empleados', 'Cuadrillas', 'Total Pagado'];
      case 'rancho':
        return ['Clave', 'Actividad', 'Empleados', 'Cuadrilla', 'Total'];
      case 'actividad':
        return ['Clave', 'Cuadrilla', 'Empleados', 'Total'];
      default:
        return ['Clave', 'Actividad', 'Empleados', 'Cuadrillas', 'Total Pagado'];
    }
  }

  List<dynamic> _getRowValues(Map<String, dynamic> fila) {
    switch (_tipoReporte) {
      case 'general':
        return [
          fila['actividad_clave'] ?? '',
          fila['actividad_nombre'] ?? '',
          fila['empleados_unicos'] ?? 0,
          fila['cuadrillas_unicas'] ?? 0,
          fila['total_pagado'] ?? 0.0
        ];
      case 'rancho':
        return [
          fila['actividad_clave'] ?? '',
          fila['actividad_nombre'] ?? '',
          fila['empleados_unicos'] ?? 0,
          fila['cuadrillas_unicas'] ?? 0,
          fila['total_pagado'] ?? 0.0
        ];
      case 'actividad':
        return [
          fila['cuadrilla_clave'] ?? '',
          fila['cuadrilla_nombre'] ?? '',
          fila['empleados_unicos'] ?? 0,
          fila['total_pagado'] ?? 0.0
        ];
      default:
        return [
          fila['empleado_clave'] ?? '',
          fila['empleado_nombre'] ?? '',
          fila['actividad_nombre'] ?? '',
          fila['rancho_nombre'] ?? '',
          fila['total_pagado'] ?? 0.0
        ];
    }
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFiltros(),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green, AppColors.green],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reportes de Gastos por Actividad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Análisis detallado de costos por actividad',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.greenDark),
                const SizedBox(width: 8),
                Text(
                  'Filtros de Reporte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Selector de tipo de reporte
            Row(
              children: [
                Text('Tipo de reporte:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'general',
                        label: Text('General'),
                        icon: Icon(Icons.assessment, size: 16),
                      ),
                      ButtonSegment(
                        value: 'rancho',
                        label: Text('Por Rancho'),
                        icon: Icon(Icons.landscape, size: 16),
                      ),
                      ButtonSegment(
                        value: 'actividad',
                        label: Text('Por Actividad'),
                        icon: Icon(Icons.work, size: 16),
                      ),
                    ],
                    selected: {_tipoReporte},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _tipoReporte = newSelection.first;
                        _limpiarFiltros();
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filtros dinámicos según el tipo de reporte
            _buildFiltrosDinamicos(),
            
            const SizedBox(height: 16),
            
            // Botón generar reporte
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _limpiarTodo,
                  icon: Icon(Icons.clear_all),
                  label: Text('Limpiar Filtros'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _cargando || !_puedeGenerarReporte() ? null : _generarReporte,
                  icon: _cargando 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.analytics),
                  label: Text(_cargando ? 'Generando...' : 'Generar Reporte'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _puedeGenerarReporte() {
    switch (_tipoReporte) {
      case 'general':
        return _semanaSeleccionada != null;
      case 'rancho':
        return _semanaSeleccionada != null && _ranchoSeleccionado != null;
      case 'actividad':
        return _semanaSeleccionada != null && _actividadSeleccionada != null;
      default:
        return false;
    }
  }

  Widget _buildFiltrosDinamicos() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Filtro de semana (siempre visible)
        _buildDropdownSemana(),
          
        // Filtro de rancho (visible en rancho)
        if (_tipoReporte == 'rancho')
          _buildDropdownRancho(),
          
        // Filtro de actividad (visible en actividad)
        if (_tipoReporte == 'actividad')
          _buildDropdownActividad(),
      ],
    );
  }

  Widget _buildDropdownSemana() {
    // Obtener información de la semana seleccionada para mostrar
    String semanaTexto = 'Seleccionar semana';
    if (_semanaSeleccionada != null && _semanas.isNotEmpty) {
      try {
        final semana = _semanas.firstWhere(
          (s) => s['id'] == _semanaSeleccionada,
        );
        String fechaInicio = semana['fecha_inicio'].toString().split(' ')[0];
        String fechaFin = semana['fecha_fin'].toString().split(' ')[0];
        semanaTexto = '$fechaInicio - $fechaFin';
      } catch (e) {
        semanaTexto = 'Semana no encontrada';
      }
    }
    
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: InkWell(
            onTap: () => _mostrarSelectorSemana(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Semana *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          semanaTexto,
                          style: TextStyle(
                            fontSize: 16,
                            color: _semanaSeleccionada != null ? Colors.black87 : Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Botón de refrescar semanas
        Tooltip(
          message: 'Actualizar lista de semanas',
          child: OutlinedButton.icon(
            onPressed: _cargando ? null : _refrescarSemanas,
            icon: _cargando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, size: 18),
            label: Text('${_semanas.length}'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              minimumSize: Size(60, 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRancho() {
    // Obtener información del rancho seleccionado para mostrar
    String ranchoTexto = 'Seleccionar rancho';
    if (_ranchoSeleccionado != null && _ranchos.isNotEmpty) {
      try {
        final rancho = _ranchos.firstWhere(
          (r) => r['id'] == _ranchoSeleccionado,
        );
        ranchoTexto = rancho['nombre'] ?? 'Rancho sin nombre';
      } catch (e) {
        ranchoTexto = 'Rancho no encontrado';
      }
    }
    
    return SizedBox(
      width: 250,
      child: InkWell(
        onTap: () => _mostrarSelectorRancho(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.landscape, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rancho *',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ranchoTexto,
                      style: TextStyle(
                        fontSize: 16,
                        color: _ranchoSeleccionado != null ? Colors.black87 : Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownActividad() {
    // Obtener información de la actividad seleccionada para mostrar
    String actividadTexto = 'Seleccionar actividad';
    if (_actividadSeleccionada != null && _actividades.isNotEmpty) {
      try {
        final actividad = _actividades.firstWhere(
          (a) => a['id'] == _actividadSeleccionada,
        );
        actividadTexto = actividad['nombre'] ?? 'Actividad sin nombre';
      } catch (e) {
        actividadTexto = 'Actividad no encontrada';
      }
    }
    
    return SizedBox(
      width: 250,
      child: InkWell(
        onTap: () => _mostrarSelectorActividad(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.work, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Actividad *',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actividadTexto,
                      style: TextStyle(
                        fontSize: 16,
                        color: _actividadSeleccionada != null ? Colors.black87 : Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      if (_tipoReporte != 'rancho') {
        _ranchoSeleccionado = null;
      }
      if (_tipoReporte != 'actividad') {
        _actividadSeleccionada = null;
      }
      
      // Limpiar todos los datos cuando se cambia el tipo de filtro
      _datosReporte = [];
      _resumenRanchos = [];
      _resumenRanchosPorActividad = [];
    });
  }

  void _limpiarTodo() {
    setState(() {
      _semanaSeleccionada = _semanas.isNotEmpty ? _semanas.first['id'] : null;
      _ranchoSeleccionado = null;
      _actividadSeleccionada = null;
      _datosReporte = [];
    });
  }

  Widget _buildContenido() {
    if (_primeraCarga || _cargando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.green),
            const SizedBox(height: 16),
            Text('Cargando reporte...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_datosReporte.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay datos para mostrar',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Selecciona los filtros necesarios y genera el reporte',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Mostrar resumen por ranchos solo en reporte general
        if (_tipoReporte == 'general' && _resumenRanchos.isNotEmpty)
          _buildResumenRanchos(),
        
        // Mostrar resumen de ranchos por actividad cuando el filtro es por actividad
        if (_tipoReporte == 'actividad' && _resumenRanchosPorActividad.isNotEmpty)
          _buildResumenRanchosPorActividad(),
        
        // Tabla principal
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12), // Reducir márgenes
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildHeaderTabla(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _buildTabla(),
                  ),
                ),
                _buildResumen(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTabla() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Más compacto
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppColors.green.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppColors.greenDark, size: 20),
          const SizedBox(width: 8),
          Text(
            'Resultados del Reporte',
            style: TextStyle(
              fontSize: 16, // Reducir tamaño de fuente
              fontWeight: FontWeight.bold,
              color: AppColors.greenDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_datosReporte.length} ${_datosReporte.length == 1 ? 'resultado' : 'resultados'}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabla() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header de la tabla
            
            // Contenido de la tabla
            Container(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.green.withOpacity(0.1)),
                        dataRowHeight: 56,
                        headingRowHeight: 48,
                        columnSpacing: constraints.maxWidth > 800 ? 16 : 8,
                        horizontalMargin: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        columns: _buildColumns(),
                        rows: _datosReporte.map((item) => _buildDataRow(item)).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [];
    
    if (_datosReporte.isEmpty) return columns;
    
    final firstRow = _datosReporte.first;
    
    // Columna de Clave (si existe) - PRIMERA POSICIÓN
    if (firstRow.containsKey('actividad_clave')) {
      columns.add(DataColumn(
        label: SizedBox(
          width: 80,
          child: Text(
            'Clave',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ));
    }
    
    // Columna de Actividad - SEGUNDA POSICIÓN
    columns.add(DataColumn(
      label: SizedBox(
        width: 160,
        child: Text(
          'Actividad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ));

    // Para reporte general, mostrar columnas simplificadas y profesionales
    if (_tipoReporte == 'general') {
      // Empleados Únicos
      columns.add(DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Empleados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
      
      // Cuadrillas
      columns.add(DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Cuadrillas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
      
      // Total Pagado
      columns.add(DataColumn(
        label: SizedBox(
          width: 120,
          child: Text(
            'Total Pagado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
      
      return columns;
    }
    
    // Para reporte de rancho, mostrar columnas específicas: clave, actividad, empleados, cuadrillas y total
    if (_tipoReporte == 'rancho') {
      // Columna de Empleados (si existe) - TERCERA POSICIÓN
      if (firstRow.containsKey('empleados_unicos')) {
        columns.add(DataColumn(
          label: SizedBox(
            width: 90,
            child: Text(
              'Empleados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          numeric: true,
        ));
      }
      
      // Columna de Cuadrillas (si existe) - CUARTA POSICIÓN
      if (firstRow.containsKey('cuadrillas_unicas')) {
        columns.add(DataColumn(
          label: SizedBox(
            width: 90,
            child: Text(
              'Cuadrillas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          numeric: true,
        ));
      }
      
      // Columna de Total Pagado - QUINTA POSICIÓN
      columns.add(DataColumn(
        label: SizedBox(
          width: 120,
          child: Text(
            'Total Pagado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
      
      return columns;
    }
    
    // Para reporte de actividad, mostrar columnas específicas: clave(cuadrilla), cuadrilla, empleados y total
    if (_tipoReporte == 'actividad') {
      // Para actividad, necesitamos cambiar el encabezado de clave
      // Reemplazar la columna de Clave por Clave de Cuadrilla
      columns.clear(); // Limpiar las columnas anteriores
      
      // Columna de Clave de Cuadrilla - PRIMERA POSICIÓN
      if (firstRow.containsKey('cuadrilla_clave') || firstRow.containsKey('clave_cuadrilla')) {
        columns.add(DataColumn(
          label: SizedBox(
            width: 90,
            child: Text(
              'Clave',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ));
      }
      
      // Columna de Cuadrilla - SEGUNDA POSICIÓN
      if (firstRow.containsKey('cuadrilla_nombre')) {
        columns.add(DataColumn(
          label: SizedBox(
            width: 150,
            child: Text(
              'Cuadrilla',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ));
      }
      
      // Columna de Empleados - TERCERA POSICIÓN
      if (firstRow.containsKey('empleados_unicos')) {
        columns.add(DataColumn(
          label: SizedBox(
            width: 90,
            child: Text(
              'Empleados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          numeric: true,
        ));
      }
      
      // Columna de Total Pagado - CUARTA POSICIÓN
      columns.add(DataColumn(
        label: SizedBox(
          width: 120,
          child: Text(
            'Total Pagado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
      
      return columns;
    }
    
    // Para otros reportes, mostrar columnas adicionales en orden específico
    
    // Columna de Empleados (si existe) - TERCERA POSICIÓN
    if (firstRow.containsKey('empleados_unicos')) {
      columns.add(DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Empleados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
    }
    
    // Columna de Cuadrillas (si existe) - CUARTA POSICIÓN
    if (firstRow.containsKey('cuadrillas_unicas')) {
      columns.add(DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Cuadrillas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
    }
    
    // Columna de Rancho (si existe) - QUINTA POSICIÓN
    if (firstRow.containsKey('rancho_nombre')) {
      columns.add(DataColumn(
        label: SizedBox(
          width: 110,
          child: Text(
            'Rancho',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ));
    }
    
    // Columna de Total Pagado - SEXTA POSICIÓN
    columns.add(DataColumn(
      label: SizedBox(
        width: 120,
        child: Text(
          'Total Pagado',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
      numeric: true,
    ));
    
    // Columna de Promedio (si existe)
    if (firstRow.containsKey('promedio_pago')) {
      columns.add(DataColumn(
        label: Container(
          width: 90,
          child: Text(
            'Promedio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        numeric: true,
      ));
    }
    
    // Columna de Registros (al final)
    columns.add(DataColumn(
      label: Container(
        width: 80,
        child: Text(
          'Registros',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
      numeric: true,
    ));
    
    return columns;
  }

  DataRow _buildDataRow(Map<String, dynamic> item) {
    List<DataCell> cells = [];
    
    // Clave de actividad (si existe) - PRIMERA POSICIÓN
    if (item.containsKey('actividad_clave')) {
      cells.add(DataCell(
        SizedBox(
          width: 80,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['actividad_clave'] ?? '-',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ));
    }
    
    // Actividad - SEGUNDA POSICIÓN
    cells.add(DataCell(
      SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            item['actividad_nombre'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.greenDark,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
    ));

    // Para el reporte general, mostrar columnas simplificadas y profesionales
    if (_tipoReporte == 'general') {
      // Empleados únicos
      final empleados = item['empleados_unicos'] ?? 0;
      cells.add(DataCell(
        SizedBox(
          width: 90,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: empleados > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: empleados > 0 ? Colors.blue.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                empleados.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: empleados > 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ));
      
      // Cuadrillas únicas
      final cuadrillas = item['cuadrillas_unicas'] ?? 0;
      cells.add(DataCell(
        SizedBox(
          width: 90,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cuadrillas > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cuadrillas > 0 ? Colors.orange.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                cuadrillas.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cuadrillas > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ));
      
      // Total pagado
      final totalPagado = item['total_pagado'] ?? 0.0;
      cells.add(DataCell(
        SizedBox(
          width: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green.withOpacity(0.15), AppColors.green.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Text(
                '\$${totalPagado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenDark,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ));
      
      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return AppColors.green.withOpacity(0.05);
            }
            return null;
          },
        ),
        cells: cells,
      );
    }

    // Para reporte de rancho, mostrar columnas específicas: clave, actividad, empleados, cuadrillas y total
    if (_tipoReporte == 'rancho') {
      // Empleados únicos (si existe) - TERCERA POSICIÓN
      if (item.containsKey('empleados_unicos')) {
        final empleados = item['empleados_unicos'] ?? 0;
        cells.add(DataCell(
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: empleados > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  empleados.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: empleados > 0 ? Colors.blue.shade700 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      
      // Cuadrillas únicas (si existe) - CUARTA POSICIÓN
      if (item.containsKey('cuadrillas_unicas')) {
        final cuadrillas = item['cuadrillas_unicas'] ?? 0;
        cells.add(DataCell(
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cuadrillas > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cuadrillas.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cuadrillas > 0 ? Colors.orange.shade700 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      
      // Total pagado - QUINTA POSICIÓN
      final totalPagado = item['total_pagado'] ?? 0.0;
      cells.add(DataCell(
        SizedBox(
          width: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Text(
                '\$${totalPagado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenDark,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ));
      
      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return AppColors.green.withOpacity(0.05);
            }
            return null;
          },
        ),
        cells: cells,
      );
    }

    // Para reporte de actividad, mostrar columnas específicas: clave(cuadrilla), cuadrilla, empleados y total
    if (_tipoReporte == 'actividad') {
      cells.clear(); // Limpiar las celdas anteriores ya que usamos una estructura diferente
      
      // Clave de cuadrilla - PRIMERA POSICIÓN
      if (item.containsKey('cuadrilla_clave') || item.containsKey('clave_cuadrilla')) {
        final claveCuadrilla = item['cuadrilla_clave'] ?? item['clave_cuadrilla'] ?? '-';
        cells.add(DataCell(
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  claveCuadrilla.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      
      // Cuadrilla - SEGUNDA POSICIÓN
      if (item.containsKey('cuadrilla_nombre')) {
        cells.add(DataCell(
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                item['cuadrilla_nombre'] ?? 'Sin cuadrilla',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.greenDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ));
      }
      
      // Empleados únicos - TERCERA POSICIÓN
      if (item.containsKey('empleados_unicos')) {
        final empleados = item['empleados_unicos'] ?? 0;
        cells.add(DataCell(
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: empleados > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  empleados.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: empleados > 0 ? Colors.blue.shade700 : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ));
      }
      
      // Total pagado - CUARTA POSICIÓN
      final totalPagado = item['total_pagado'] ?? 0.0;
      cells.add(DataCell(
        SizedBox(
          width: 120,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Text(
                '\$${totalPagado.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenDark,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ));
      
      return DataRow(
        color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return AppColors.green.withOpacity(0.05);
            }
            return null;
          },
        ),
        cells: cells,
      );
    }

    // Para otros tipos de reporte, mostrar todas las columnas en orden específico
    
    // Empleados únicos (si existe) - TERCERA POSICIÓN
    if (item.containsKey('empleados_unicos')) {
      final empleados = item['empleados_unicos'] ?? 0;
      cells.add(DataCell(
        Container(
          width: 80,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: empleados > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              empleados.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: empleados > 0 ? Colors.blue.shade700 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ));
    }
    
    // Cuadrillas únicas (si existe) - CUARTA POSICIÓN
    if (item.containsKey('cuadrillas_unicas')) {
      final cuadrillas = item['cuadrillas_unicas'] ?? 0;
      cells.add(DataCell(
        Container(
          width: 80,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cuadrillas > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cuadrillas.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cuadrillas > 0 ? Colors.orange.shade700 : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ));
    }
    
    // Rancho (si existe) - QUINTA POSICIÓN
    if (item.containsKey('rancho_nombre')) {
      cells.add(DataCell(
        Container(
          width: 100,
          child: Text(
            item['rancho_nombre'] ?? 'N/A',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ));
    }
    
    // Total pagado - SEXTA POSICIÓN
    final totalPagado = item['total_pagado'] ?? 0.0;
    cells.add(DataCell(
      Container(
        width: 110,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.green.withOpacity(0.3)),
          ),
          child: Text(
            '\$${totalPagado.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.greenDark,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ));
    
    // Promedio (si existe)
    if (item.containsKey('promedio_pago')) {
      final promedio = item['promedio_pago'] ?? 0.0;
      cells.add(DataCell(
        Container(
          width: 90,
          alignment: Alignment.center,
          child: Text(
            '\$${promedio.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ));
    }
    
    // Registros (al final)
    final registros = item['registros_totales'] ?? item['registros'] ?? 0;
    cells.add(DataCell(
      Container(
        width: 80,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            registros.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ));
    
    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return AppColors.green.withOpacity(0.05);
          }
          return null;
        },
      ),
      cells: cells,
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Más compacto
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green.withOpacity(0.1), AppColors.green.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: AppColors.green.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del Reporte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total de actividades: ${_datosReporte.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Botones de exportar rediseñados al lado izquierdo del total
          if (!_primeraCarga && _datosReporte.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón PDF
                      _buildExportButton(
                        icon: Icons.picture_as_pdf,
                        label: 'PDF',
                        color: Colors.red.shade600,
                        onPressed: _exportarPDF,
                      ),
                      const SizedBox(width: 8),
                      // Botón Excel
                      _buildExportButton(
                        icon: Icons.table_chart,
                        label: 'Excel',
                        color: Colors.green.shade700,
                        onPressed: _exportarExcel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Pagado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${_totalGeneral.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16, // Reducir tamaño
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRanchos() {
    if (_resumenRanchos.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: AppColors.greenDark, size: 20),
          const SizedBox(width: 8),
          Text(
            'Resumen de Ranchos',
            style: TextStyle(
              fontSize: 16, // Reducir tamaño de fuente
              fontWeight: FontWeight.bold,
              color: AppColors.greenDark,
            ),
          
          ),
        ],
      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: math.max(constraints.maxWidth, 700),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.green.withOpacity(0.1)),
                      dataRowHeight: 56,
                      headingRowHeight: 48,
                      horizontalMargin: 12,
                      columnSpacing: constraints.maxWidth > 600 ? 20 : 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                columns: [
                  DataColumn(
                    label: Container(
                      width: 120,
                      child: Text(
                        'Rancho',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 100,
                      child: Text(
                        'Total Ganado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: Text(
                        'Empleados',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: Text(
                        'Actividades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Container(
                      width: 80,
                      child: Text(
                        'Cuadrillas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    numeric: true,
                  ),
                ],
                rows: _resumenRanchos.map((rancho) {
                  final totalGanancia = rancho['total_ganancia'] as double;
                  final empleados = rancho['empleados_trabajaron'] as int;
                  final actividades = rancho['actividades_realizadas'] as int;
                  final cuadrillas = rancho['cuadrillas_trabajaron'] as int;
                  
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return AppColors.green.withOpacity(0.05);
                        }
                        return null;
                      },
                    ),
                    cells: [
                      DataCell(
                        Container(
                          width: 120,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            rancho['rancho_nombre'] ?? 'Sin rancho',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.greenDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 100,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.green.withOpacity(0.15), AppColors.green.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.green.withOpacity(0.3)),
                            ),
                            child: Text(
                              '\$${totalGanancia.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.greenDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: empleados > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: empleados > 0 ? Colors.blue.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              empleados.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: empleados > 0 ? Colors.blue.shade700 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: actividades > 0 ? Colors.purple.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: actividades > 0 ? Colors.purple.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              actividades.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: actividades > 0 ? Colors.purple.shade700 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cuadrillas > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cuadrillas > 0 ? Colors.orange.shade200 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              cuadrillas.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cuadrillas > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRanchosPorActividad() {
    if (_resumenRanchosPorActividad.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.agriculture_outlined, color: AppColors.greenDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumen de Ranchos por Actividad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: math.max(constraints.maxWidth, 600),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.green.withOpacity(0.1)),
                      dataRowHeight: 56,
                      headingRowHeight: 48,
                      horizontalMargin: 12,
                      columnSpacing: constraints.maxWidth > 600 ? 20 : 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      columns: [
                        DataColumn(
                          label: Container(
                            width: 140,
                            child: Text(
                              'Rancho',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            width: 120,
                            child: Text(
                              'Total Ganado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          numeric: true,
                        ),
                      ],
                      rows: _resumenRanchosPorActividad.map((rancho) {
                        final totalGanancia = rancho['total_ganancia'] as double;
                        
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered)) {
                                return AppColors.green.withOpacity(0.05);
                              }
                              return null;
                            },
                          ),
                          cells: [
                            DataCell(
                              Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  rancho['rancho_nombre'] ?? 'Sin rancho',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.greenDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 120,
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.green.withOpacity(0.15), AppColors.green.withOpacity(0.1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '\$${totalGanancia.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greenDark,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Métodos auxiliares para el PDF
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRanchoNombre(int ranchoId) {
    try {
      final rancho = _ranchos.firstWhere((r) => r['id'] == ranchoId);
      return rancho['nombre'] ?? 'Rancho $ranchoId';
    } catch (e) {
      return 'Rancho $ranchoId';
    }
  }
  
  String _getActividadNombre(int actividadId) {
    try {
      final actividad = _actividades.firstWhere((a) => a['id'] == actividadId);
      return actividad['nombre'] ?? 'Actividad $actividadId';
    } catch (e) {
      return 'Actividad $actividadId';
    }
  }

  // Método para mostrar el selector de semana con búsqueda
  void _mostrarSelectorSemana() async {
    final semanaSeleccionada = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return _SelectorSemanaDialog(
          semanas: _semanas,
          semanaActual: _semanaSeleccionada,
        );
      },
    );

    if (semanaSeleccionada != null) {
      setState(() {
        _semanaSeleccionada = semanaSeleccionada['id'];
      });
    }
  }

  // Método para mostrar el selector de rancho con búsqueda
  void _mostrarSelectorRancho() async {
    final ranchoSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return _SelectorRanchoDialog(
          ranchos: _ranchos,
          ranchoActual: _ranchoSeleccionado,
        );
      },
    );

    if (ranchoSeleccionado != null) {
      setState(() {
        _ranchoSeleccionado = ranchoSeleccionado['id'];
      });
    }
  }

  // Método para mostrar el selector de actividad con búsqueda
  void _mostrarSelectorActividad() async {
    final actividadSeleccionada = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return _SelectorActividadDialog(
          actividades: _actividades,
          actividadActual: _actividadSeleccionada,
        );
      },
    );

    if (actividadSeleccionada != null) {
      setState(() {
        _actividadSeleccionada = actividadSeleccionada['id'];
      });
    }
  }
}

// Dialog personalizado para seleccionar semana con búsqueda
class _SelectorSemanaDialog extends StatefulWidget {
  final List<Map<String, dynamic>> semanas;
  final int? semanaActual;

  const _SelectorSemanaDialog({
    required this.semanas,
    this.semanaActual,
  });

  @override
  State<_SelectorSemanaDialog> createState() => _SelectorSemanaDialogState();
}

class _SelectorSemanaDialogState extends State<_SelectorSemanaDialog> {
  late List<Map<String, dynamic>> semanasFiltradas;
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    semanasFiltradas = List.from(widget.semanas);
  }

  void _filtrarSemanas(String query) {
    setState(() {
      if (query.isEmpty) {
        semanasFiltradas = List.from(widget.semanas);
      } else {
        semanasFiltradas = widget.semanas.where((semana) {
          final nombre = semana['nombre']?.toString().toLowerCase() ?? '';
          final fechaInicio = semana['fecha_inicio']?.toString() ?? '';
          final fechaFin = semana['fecha_fin']?.toString() ?? '';
          
          // Búsqueda normal por nombre
          if (nombre.contains(query.toLowerCase())) {
            return true;
          }
          
          // Búsqueda por formato de fecha
          if (query.contains('/') || query.length >= 4) {
            // Extraer fechas en formato dd/mm/yyyy
            final fechaInicioFormateada = _formatearFechaParaBusqueda(fechaInicio);
            final fechaFinFormateada = _formatearFechaParaBusqueda(fechaFin);
            
            // Buscar en fecha de inicio o fin
            if (fechaInicioFormateada.contains(query) || fechaFinFormateada.contains(query)) {
              return true;
            }
            
            // Búsqueda parcial por año, mes/año, etc.
            if (_coincideFechaParcial(fechaInicioFormateada, query) || 
                _coincideFechaParcial(fechaFinFormateada, query)) {
              return true;
            }
          }
          
          return false;
        }).toList();
      }
    });
  }
  
  // Convierte fecha de "2024-09-15" a "15/09/2024"
  String _formatearFechaParaBusqueda(String fecha) {
    try {
      if (fecha.contains('-') && fecha.length >= 10) {
        final partes = fecha.substring(0, 10).split('-');
        if (partes.length == 3) {
          return '${partes[2]}/${partes[1]}/${partes[0]}';
        }
      }
      return fecha;
    } catch (e) {
      return fecha;
    }
  }
  
  // Verifica si una fecha coincide parcialmente con la búsqueda
  bool _coincideFechaParcial(String fechaCompleta, String busqueda) {
    // Ejemplos de búsqueda:
    // "2024" -> busca año 2024
    // "09/2024" -> busca septiembre 2024
    // "15/09" -> busca día 15 de septiembre
    
    final partesFecha = fechaCompleta.split('/');
    final partesBusqueda = busqueda.split('/');
    
    if (partesFecha.length != 3) return false;
    
    // Búsqueda solo por año
    if (partesBusqueda.length == 1 && busqueda.length == 4) {
      return partesFecha[2] == busqueda;
    }
    
    // Búsqueda por mes/año
    if (partesBusqueda.length == 2) {
      return partesFecha[1] == partesBusqueda[0] && partesFecha[2] == partesBusqueda[1];
    }
    
    // Búsqueda por día/mes
    if (partesBusqueda.length == 2 && partesBusqueda[1].length == 2) {
      return partesFecha[0] == partesBusqueda[0] && partesFecha[1] == partesBusqueda[1];
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Semana',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Campo de búsqueda con formato de fecha
            TextField(
              controller: _busquedaController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                hintText: 'dd/mm/yyyy - Buscar por fecha...',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.date_range, color: AppColors.green),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _busquedaController.clear();
                          _filtrarSemanas('');
                        },
                      )
                    : Icon(Icons.search, color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.green, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              onChanged: _filtrarSemanas,
              inputFormatters: [
                // Permitir solo números y barras
                FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                // Limitador de longitud
                LengthLimitingTextInputFormatter(10),
                // Formateador personalizado para agregar barras automáticamente
                _DateInputFormatter(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información
            Text(
              '${semanasFiltradas.length} semana(s) encontrada(s)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Lista de semanas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: semanasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron semanas',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: semanasFiltradas.length,
                        itemBuilder: (context, index) {
                          final semana = semanasFiltradas[index];
                          final isSelected = semana['id'] == widget.semanaActual;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.green.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected ? Border.all(color: AppColors.green, width: 2) : null,
                            ),
                            child: ListTile(
                              title: Text(
                                semana['nombre'] ?? 'Semana sin nombre',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.greenDark : Colors.black87,
                                ),
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.green : AppColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: isSelected ? Colors.white : AppColors.green,
                                  size: 20,
                                ),
                              ),
                              trailing: isSelected 
                                  ? Icon(Icons.check_circle, color: AppColors.green, size: 24)
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop(semana);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (widget.semanaActual != null) {
                      final semanaActual = widget.semanas.firstWhere(
                        (s) => s['id'] == widget.semanaActual,
                        orElse: () => {},
                      );
                      Navigator.of(context).pop(semanaActual);
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }
}

// Formateador personalizado para fechas con formato dd/mm/yyyy
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remover caracteres no numéricos excepto /
    final numericText = text.replaceAll(RegExp(r'[^0-9/]'), '');
    
    // Si se está borrando, permitir
    if (numericText.length < oldValue.text.length) {
      return newValue.copyWith(text: numericText);
    }
    
    String formattedText = '';
    int digitCount = 0;
    
    for (int i = 0; i < numericText.length; i++) {
      final char = numericText[i];
      
      if (char == '/') {
        // Solo agregar / si no es consecutiva
        if (formattedText.isNotEmpty && !formattedText.endsWith('/')) {
          formattedText += char;
        }
      } else {
        formattedText += char;
        digitCount++;
        
        // Agregar / automáticamente después del día (2 dígitos)
        if (digitCount == 2 && !formattedText.contains('/')) {
          formattedText += '/';
        }
        // Agregar / automáticamente después del mes (después de dd/mm)
        else if (digitCount == 4 && formattedText.split('/').length == 2) {
          formattedText += '/';
        }
      }
      
      // Limitar a formato dd/mm/yyyy
      if (formattedText.length >= 10) break;
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Dialog personalizado para seleccionar rancho con búsqueda
class _SelectorRanchoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> ranchos;
  final int? ranchoActual;

  const _SelectorRanchoDialog({
    required this.ranchos,
    this.ranchoActual,
  });

  @override
  State<_SelectorRanchoDialog> createState() => _SelectorRanchoDialogState();
}

class _SelectorRanchoDialogState extends State<_SelectorRanchoDialog> {
  late List<Map<String, dynamic>> ranchosFiltrados;
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ranchosFiltrados = List.from(widget.ranchos);
  }

  void _filtrarRanchos(String query) {
    setState(() {
      if (query.isEmpty) {
        ranchosFiltrados = List.from(widget.ranchos);
      } else {
        ranchosFiltrados = widget.ranchos.where((rancho) {
          final nombre = rancho['nombre']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.landscape, color: AppColors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Rancho',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Campo de búsqueda
            TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar rancho...',
                prefixIcon: Icon(Icons.search, color: AppColors.green),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _busquedaController.clear();
                          _filtrarRanchos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.green, width: 2),
                ),
              ),
              onChanged: _filtrarRanchos,
            ),
            const SizedBox(height: 16),
            
            // Información
            Text(
              '${ranchosFiltrados.length} rancho(s) encontrado(s)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Lista de ranchos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ranchosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron ranchos',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: ranchosFiltrados.length,
                        itemBuilder: (context, index) {
                          final rancho = ranchosFiltrados[index];
                          final isSelected = rancho['id'] == widget.ranchoActual;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.green.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected ? Border.all(color: AppColors.green, width: 2) : null,
                            ),
                            child: ListTile(
                              title: Text(
                                rancho['nombre'] ?? 'Rancho sin nombre',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.greenDark : Colors.black87,
                                ),
                              ),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.green : AppColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.landscape,
                                  color: isSelected ? Colors.white : AppColors.green,
                                  size: 20,
                                ),
                              ),
                              trailing: isSelected 
                                  ? Icon(Icons.check_circle, color: AppColors.green, size: 24)
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop(rancho);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (widget.ranchoActual != null) {
                      final ranchoActual = widget.ranchos.firstWhere(
                        (r) => r['id'] == widget.ranchoActual,
                        orElse: () => {},
                      );
                      Navigator.of(context).pop(ranchoActual);
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }
}

// Dialog personalizado para seleccionar actividad con búsqueda
class _SelectorActividadDialog extends StatefulWidget {
  final List<Map<String, dynamic>> actividades;
  final int? actividadActual;

  const _SelectorActividadDialog({
    required this.actividades,
    this.actividadActual,
  });

  @override
  State<_SelectorActividadDialog> createState() => _SelectorActividadDialogState();
}

class _SelectorActividadDialogState extends State<_SelectorActividadDialog> {
  late List<Map<String, dynamic>> actividadesFiltradas;
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    actividadesFiltradas = List.from(widget.actividades);
  }

  void _filtrarActividades(String query) {
    setState(() {
      if (query.isEmpty) {
        actividadesFiltradas = List.from(widget.actividades);
      } else {
        actividadesFiltradas = widget.actividades.where((actividad) {
          final nombre = actividad['nombre']?.toString().toLowerCase() ?? '';
          final clave = actividad['clave']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase()) || clave.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.work, color: AppColors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Actividad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Campo de búsqueda
            TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar actividad o clave...',
                helperText: 'Puedes buscar por nombre o clave de actividad',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: AppColors.green),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _busquedaController.clear();
                          _filtrarActividades('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.green, width: 2),
                ),
              ),
              onChanged: _filtrarActividades,
            ),
            const SizedBox(height: 16),
            
            // Información
            Text(
              '${actividadesFiltradas.length} actividad(es) encontrada(s)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Lista de actividades
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: actividadesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron actividades',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: actividadesFiltradas.length,
                        itemBuilder: (context, index) {
                          final actividad = actividadesFiltradas[index];
                          final isSelected = actividad['id'] == widget.actividadActual;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.green.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(6),
                              border: isSelected ? Border.all(color: AppColors.green, width: 2) : null,
                            ),
                            child: ListTile(
                              title: Text(
                                actividad['nombre'] ?? 'Actividad sin nombre',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.greenDark : Colors.black87,
                                ),
                              ),
                              subtitle: actividad['clave'] != null
                                  ? Text(
                                      'Clave: ${actividad['clave']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : null,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.green : AppColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.work,
                                  color: isSelected ? Colors.white : AppColors.green,
                                  size: 20,
                                ),
                              ),
                              trailing: isSelected 
                                  ? Icon(Icons.check_circle, color: AppColors.green, size: 24)
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop(actividad);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (widget.actividadActual != null) {
                      final actividadActual = widget.actividades.firstWhere(
                        (a) => a['id'] == widget.actividadActual,
                        orElse: () => {},
                      );
                      Navigator.of(context).pop(actividadActual);
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }
}
