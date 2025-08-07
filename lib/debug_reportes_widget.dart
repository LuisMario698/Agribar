import 'package:flutter/material.dart';
import 'package:agribar/services/reportes_service.dart';

/// Widget simple para debug del servicio de reportes
class DebugReportesWidget extends StatefulWidget {
  @override
  _DebugReportesWidgetState createState() => _DebugReportesWidgetState();
}

class _DebugReportesWidgetState extends State<DebugReportesWidget> {
  final ReportesService _reportesService = ReportesService();
  List<Map<String, dynamic>> _datos = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _datos = [];
    });

    try {
      print('🔍 Iniciando carga de datos de reportes...');
      final datos = await _reportesService.obtenerReporteGeneral();
      print('✅ Datos obtenidos: ${datos.length} registros');
      
      setState(() {
        _datos = datos;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Reportes Service'),
        backgroundColor: Color(0xFF23611C),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _cargarDatos,
              child: Text('Recargar Datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF23611C),
              ),
            ),
            SizedBox(height: 16),
            
            if (_isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando datos...'),
            ],
            
            if (_error.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            if (_datos.isNotEmpty) ...[
              Text(
                'Datos Obtenidos (${_datos.length} registros):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              
              Expanded(
                child: ListView.builder(
                  itemCount: _datos.length,
                  itemBuilder: (context, index) {
                    final dato = _datos[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏡 Rancho: ${dato['rancho'] ?? 'N/A'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('🔧 Actividad: ${dato['actividad'] ?? 'N/A'}'),
                            Text('📅 Días: ${dato['dias_trabajados'] ?? 0}'),
                            Text('👷 Empleados: ${dato['empleados_involucrados'] ?? 0}'),
                            Text(
                              '💰 Total: \$${dato['gasto_total']?.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_isLoading && _error.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('No se encontraron datos de reportes.'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
