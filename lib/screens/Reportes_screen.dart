import 'package:flutter/material.dart';
import '../services/reportes_service.dart';
import '../widgets/reportes_gastos_widget.dart';

/// Pantalla de reportes con filtros de rancho y fechas
/// Incluye tres tipos de reportes: General, Por Rancho y Por Actividad
class ReportesScreen extends StatefulWidget {
  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ReportesService _reportesService = ReportesService();

  // Controladores de filtros
  String _ranchoSeleccionado = 'Todos';
  String _actividadSeleccionada = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Controladores de fecha
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  // Listas para dropdowns
  List<String> _ranchos = ['Todos'];
  List<String> _actividades = [];

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingFilters = true;

  // Datos de reportes
  List<Map<String, dynamic>> _datosReporteGeneral = [];
  List<Map<String, dynamic>> _datosReportePorRancho = [];
  List<Map<String, dynamic>> _datosReportePorActividad = [];
  Map<String, dynamic> _resumenGeneral = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _establecerFechasPorDefecto();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  void _establecerFechasPorDefecto() {
    // Establecer fecha fin como hoy
    _fechaFin = DateTime.now();
    _fechaFinController.text = "${_fechaFin!.day.toString().padLeft(2, '0')}/${_fechaFin!.month.toString().padLeft(2, '0')}/${_fechaFin!.year}";
    
    // Establecer fecha inicio como hace 30 días
    _fechaInicio = _fechaFin!.subtract(const Duration(days: 30));
    _fechaInicioController.text = "${_fechaInicio!.day.toString().padLeft(2, '0')}/${_fechaInicio!.month.toString().padLeft(2, '0')}/${_fechaInicio!.year}";
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoadingFilters = true);
    
    try {
      // Cargar opciones para filtros
      _ranchos = await _reportesService.obtenerRanchos();
      _actividades = await _reportesService.obtenerActividades();
      
      if (_actividades.isNotEmpty) {
        _actividadSeleccionada = _actividades.first;
      }
      
      // Cargar datos iniciales
      await _cargarReportes();
      
    } catch (e) {
      _mostrarError('Error al cargar datos iniciales: $e');
    } finally {
      setState(() => _isLoadingFilters = false);
    }
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    
    try {
      // Reporte General
      _datosReporteGeneral = await _reportesService.obtenerReporteGeneral(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        rancho: _ranchoSeleccionado,
      );

      // Reporte por Rancho (solo si no es "Todos")
      if (_ranchoSeleccionado != 'Todos') {
        _datosReportePorRancho = await _reportesService.obtenerReportePorRancho(
          rancho: _ranchoSeleccionado,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
        );
      } else {
        _datosReportePorRancho = [];
      }

      // Reporte por Actividad
      if (_actividadSeleccionada.isNotEmpty) {
        _datosReportePorActividad = await _reportesService.obtenerReportePorActividad(
          actividad: _actividadSeleccionada,
          fechaInicio: _fechaInicio,
          fechaFin: _fechaFin,
          rancho: _ranchoSeleccionado,
        );
      }

      // Resumen general
      _resumenGeneral = await _reportesService.obtenerResumenGeneral(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

    } catch (e) {
      _mostrarError('Error al cargar reportes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: _isLoadingFilters
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _construirTitulo(),
                    SizedBox(height: 24),
                    _construirFiltros(),
                    SizedBox(height: 32),
                    _construirResumenGeneral(),
                    SizedBox(height: 32),
                    _construirTabsReportes(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _construirTitulo() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart,
            size: 32,
            color: Color(0xFF23611C),
          ),
          SizedBox(width: 16),
          Text(
            'Reportes de Actividades y Costos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltros() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros de Búsqueda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Filtro de Rancho
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: _ranchoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Rancho',
                    filled: true,
                    fillColor: Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _ranchos
                      .map((rancho) => DropdownMenuItem(
                            value: rancho,
                            child: Text(rancho),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _ranchoSeleccionado = value!;
                    });
                    _cargarReportes();
                  },
                ),
              ),
              
              // Filtro de Actividad
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: _actividadSeleccionada.isEmpty ? null : _actividadSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Actividad',
                    filled: true,
                    fillColor: Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _actividades
                      .map((actividad) => DropdownMenuItem(
                            value: actividad,
                            child: Text(actividad),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _actividadSeleccionada = value!;
                    });
                    _cargarReportes();
                  },
                ),
              ),
              
              // Campo Fecha Inicio
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _fechaInicioController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha Inicio',
                    filled: true,
                    fillColor: Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _seleccionarFecha(true),
                ),
              ),
              
              // Campo Fecha Fin
              SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _fechaFinController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha Fin',
                    filled: true,
                    fillColor: Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _seleccionarFecha(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFecha(bool esFechaInicio) async {
    DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
          _fechaInicioController.text = "${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}";
        } else {
          _fechaFin = fechaSeleccionada;
          _fechaFinController.text = "${fechaSeleccionada.day.toString().padLeft(2, '0')}/${fechaSeleccionada.month.toString().padLeft(2, '0')}/${fechaSeleccionada.year}";
        }
      });
      _cargarReportes();
    }
  }

  Widget _construirResumenGeneral() {
    if (_resumenGeneral.isEmpty) return Container();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _construirTarjetaMetrica(
                  'Gasto Total',
                  '\$${_formatearNumero(_resumenGeneral['gasto_total'] ?? 0.0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _construirTarjetaMetrica(
                  'Ranchos Activos',
                  '${_resumenGeneral['total_ranchos'] ?? 0}',
                  Icons.location_on,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _construirTarjetaMetrica(
                  'Actividades',
                  '${_resumenGeneral['total_actividades'] ?? 0}',
                  Icons.work,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _construirTarjetaMetrica(
                  'Días Trabajados',
                  '${_resumenGeneral['dias_trabajados'] ?? 0}',
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaMetrica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTabsReportes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Color(0xFF23611C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('General'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Por Rancho'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Por Actividad'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Gastos por Actividad'),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Container(
            height: 600,
            padding: EdgeInsets.all(24),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _construirReporteGeneral(),
                      _construirReportePorRancho(),
                      _construirReportePorActividad(),
                      _construirReporteGastosPorActividad(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirReporteGeneral() {
    if (_datosReporteGeneral.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para mostrar en el rango de fechas seleccionado',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte General - Gasto por Actividad en cada Rancho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
          SizedBox(height: 16),
          
          // Botón de exportar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportarReporte('general'),
                icon: Icon(Icons.download),
                label: Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF23611C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Tabla de datos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Color(0xFFF8F8F8)),
              columns: [
                DataColumn(label: Text('Rancho', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Días', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Empleados', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Gasto Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _datosReporteGeneral.map((dato) => DataRow(
                cells: [
                  DataCell(Text(dato['rancho'] ?? '')),
                  DataCell(Text(dato['actividad'] ?? '')),
                  DataCell(Text('${dato['dias_trabajados'] ?? 0}')),
                  DataCell(Text('${dato['empleados_involucrados'] ?? 0}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_total'] ?? 0.0)}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_promedio'] ?? 0.0)}')),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirReportePorRancho() {
    if (_ranchoSeleccionado == 'Todos') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Selecciona un rancho específico para ver el reporte detallado',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_datosReportePorRancho.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para el rancho "$_ranchoSeleccionado" en el rango de fechas seleccionado',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte del Rancho "$_ranchoSeleccionado"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
          SizedBox(height: 16),
          
          // Botón de exportar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportarReporte('rancho'),
                icon: Icon(Icons.download),
                label: Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF23611C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Tabla de datos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Color(0xFFF8F8F8)),
              columns: [
                DataColumn(label: Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Días', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Empleados', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cuadrillas', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Gasto Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mín/Máx', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _datosReportePorRancho.map((dato) => DataRow(
                cells: [
                  DataCell(Text(dato['actividad'] ?? '')),
                  DataCell(Text('${dato['dias_trabajados'] ?? 0}')),
                  DataCell(Text('${dato['empleados_diferentes'] ?? 0}')),
                  DataCell(Text('${dato['cuadrillas_involucradas'] ?? 0}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_total'] ?? 0.0)}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_promedio_por_registro'] ?? 0.0)}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_minimo'] ?? 0.0)} - \$${_formatearNumero(dato['gasto_maximo'] ?? 0.0)}')),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirReportePorActividad() {
    if (_actividadSeleccionada.isEmpty || _datosReportePorActividad.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para la actividad "$_actividadSeleccionada" en el rango de fechas seleccionado',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de la Actividad "$_actividadSeleccionada"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF23611C),
            ),
          ),
          SizedBox(height: 16),
          
          // Botón de exportar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportarReporte('actividad'),
                icon: Icon(Icons.download),
                label: Text('Exportar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF23611C),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Tabla de datos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Color(0xFFF8F8F8)),
              columns: [
                DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Rancho', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cuadrilla', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Empleados', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Gasto del Día', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Promedio/Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _datosReportePorActividad.map((dato) => DataRow(
                cells: [
                  DataCell(Text(_formatearFecha(dato['fecha']))),
                  DataCell(Text(dato['rancho'] ?? '')),
                  DataCell(Text(dato['cuadrilla'] ?? '')),
                  DataCell(Text('${dato['empleados_ese_dia'] ?? 0}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_dia'] ?? 0.0)}')),
                  DataCell(Text('\$${_formatearNumero(dato['gasto_promedio_empleado'] ?? 0.0)}')),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearNumero(dynamic numero) {
    if (numero == null) return '0.00';
    return double.parse(numero.toString()).toStringAsFixed(2);
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '';
    if (fecha is DateTime) {
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
    }
    // Asumimos formato yyyy-mm-dd
    try {
      final partes = fecha.toString().split('-');
      if (partes.length == 3) {
        return "${partes[2]}/${partes[1]}/${partes[0]}";
      }
    } catch (e) {
      // Si hay error en el formateo, devolver tal como viene
    }
    return fecha.toString();
  }

  void _exportarReporte(String tipo) {
    // TODO: Implementar exportación a PDF/Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de exportación para reporte $tipo próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _construirReporteGastosPorActividad() {
    return ReportesGastosWidget();
  }
}
