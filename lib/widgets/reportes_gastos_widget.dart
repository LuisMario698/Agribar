import 'package:flutter/material.dart';
import '../services/reportes_gastos_service.dart';
import '../theme/app_styles.dart';
import 'export_button_group.dart';

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
      
      switch (_tipoReporte) {
        case 'general':
          if (_semanaSeleccionada != null) {
            datos = await _reportesService.obtenerReporteGeneralPorSemana(_semanaSeleccionada!);
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
          }
          break;
      }
      
      setState(() => _datosReporte = datos);
      
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
          colors: [AppColors.green, AppColors.greenDark],
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
          if (!_primeraCarga && _datosReporte.isNotEmpty)
            ExportButtonGroup(
              onPdfExport: _exportarPDF,
              onExcelExport: _exportarExcel,
            ),
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
                    backgroundColor: AppColors.green,
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
        items: _semanas.map((semana) {
          return DropdownMenuItem<int>(
            value: semana['id'],
            child: Text(semana['nombre'] ?? 'Semana sin nombre'),
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
        items: _ranchos.map((rancho) {
          return DropdownMenuItem<int>(
            value: rancho['id'],
            child: Text(rancho['nombre'] ?? 'Rancho sin nombre'),
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
        items: _actividades.map((actividad) {
          return DropdownMenuItem<int>(
            value: actividad['id'],
            child: Text(actividad['nombre'] ?? 'Actividad sin nombre'),
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

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        children: [
          _buildHeaderTabla(),
          Expanded(child: _buildTabla()),
          _buildResumen(),
        ],
      ),
    );
  }

  Widget _buildHeaderTabla() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(Icons.table_chart, color: AppColors.greenDark),
          const SizedBox(width: 8),
          Text(
            'Resultados del Reporte',
            style: TextStyle(
              fontSize: 18,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.green.withOpacity(0.1)),
          columns: [
            DataColumn(
              label: Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Total Pagado', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
            DataColumn(
              label: Text('Registros', style: TextStyle(fontWeight: FontWeight.bold)),
              numeric: true,
            ),
          ],
          rows: _datosReporte.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      item['actividad_nombre'],
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '\$${(item['total_pagado'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(item['registros'].toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green.withOpacity(0.1), AppColors.green.withOpacity(0.2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen del Reporte',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenDark,
                ),
              ),
              Text(
                'Total de actividades: ${_datosReporte.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Pagado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '\$${_totalGeneral.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
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
}
