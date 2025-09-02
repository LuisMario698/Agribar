import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  double get _totalGeneral {
    return _datosReporte.fold(0.0, (sum, item) => sum + (item['total_pagado'] as double));
  }

  void _exportarPDF() {
    // TODO: Implementar exportación a PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportación a PDF - En desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportarExcel() {
    // TODO: Implementar exportación a Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportación a Excel - En desarrollo'),
        backgroundColor: Colors.green,
      ),
    );
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
    return SizedBox(
      width: 350,
      child: DropdownButtonFormField<int>(
        value: _semanaSeleccionada,
        decoration: InputDecoration(
          labelText: 'Semana *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.green),
        ),
        isExpanded: true,
        menuMaxHeight: 250, // Altura controlada para semanas
        items: _semanas.map((semana) {
          return DropdownMenuItem<int>(
            value: semana['id'],
            child: Container(
              width: double.infinity,
              child: Text(
                semana['nombre'] ?? 'Semana sin nombre',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _semanaSeleccionada = value);
        },
      ),
    );
  }

  Widget _buildDropdownRancho() {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<int>(
        value: _ranchoSeleccionado,
        decoration: InputDecoration(
          labelText: 'Rancho *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.landscape, color: AppColors.green),
        ),
        isExpanded: true,
        menuMaxHeight: 200, // Altura menor para ranchos (son menos)
        items: _ranchos.map((rancho) {
          return DropdownMenuItem<int>(
            value: rancho['id'],
            child: Container(
              width: double.infinity,
              child: Text(
                rancho['nombre'] ?? 'Rancho sin nombre',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _ranchoSeleccionado = value);
        },
      ),
    );
  }

  Widget _buildDropdownActividad() {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<int>(
        value: _actividadSeleccionada,
        decoration: InputDecoration(
          labelText: 'Actividad *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.work, color: AppColors.green),
        ),
        isExpanded: true,
        menuMaxHeight: 300, // Limitar altura máxima del menú
        items: _actividades.map((actividad) {
          return DropdownMenuItem<int>(
            value: actividad['id'],
            child: Container(
              width: double.infinity,
              child: Text(
                actividad['nombre'] ?? 'Actividad sin nombre',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _actividadSeleccionada = value);
        },
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

    // Para reporte general, solo mostrar columnas básicas
    if (_tipoReporte == 'general') {
      // Total Pagado para reporte general
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

    // Para el reporte general, solo mostrar columnas básicas
    if (_tipoReporte == 'general') {
      // Total pagado
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
}
