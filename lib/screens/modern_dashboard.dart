/// Dashboard moderno y completamente rediseñado para Agribar
/// Conectado a datos reales de PostgreSQL

import 'package:agribar/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ModernDashboard extends StatefulWidget {
  final String userName;
  final String tipoUsuario;

  const ModernDashboard({
    required this.userName,
    this.tipoUsuario = 'Usuario',
    Key? key,
  }) : super(key: key);

  @override
  State<ModernDashboard> createState() => _ModernDashboardState();
}

class _ModernDashboardState extends State<ModernDashboard> {
  bool isLoading = true;
  
  // Datos del dashboard
  int totalEmpleados = 0;
  int totalCuadrillas = 0;
  int totalActividades = 0;
  int semanaActual = 0;
  double gastoTotalSemana = 0.0;
  
  List<Map<String, dynamic>> datosGraficaCircular = [];
  List<Map<String, dynamic>> datosGraficaBarras = [];
  List<Map<String, dynamic>> cuadrillasTop = [];
  List<Map<String, dynamic>> ranchosTop = [];
  List<Map<String, dynamic>> actividadesTop = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDashboard();
  }

  Future<void> _cargarDatosDashboard() async {
    try {
      final dbService = DatabaseService();
      await dbService.connect();

      // 1. Estadísticas generales
      await _cargarEstadisticasGenerales(dbService);
      
      // 2. Datos para gráfica circular - Cuadrillas por grupo
      await _cargarDatosGraficaCircular(dbService);
      
      // 3. Datos para gráfica de barras - Top cuadrillas
      await _cargarDatosGraficaBarras(dbService);
      
      // 4. Top cuadrillas con empleados
      await _cargarCuadrillasTop(dbService);

      // 5. Top ranchos por gastos
      await _cargarRanchosTop(dbService);

      // 6. Top actividades por gastos
      await _cargarActividadesTop(dbService);

      await dbService.close();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del dashboard: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cargarEstadisticasGenerales(DatabaseService dbService) async {
    // Total empleados activos
    final empleadosResult = await dbService.connection.query(
      'SELECT COUNT(*) FROM empleados WHERE habilitado = true'
    );
    totalEmpleados = int.parse(empleadosResult.first[0].toString());

    // Total cuadrillas activas
    final cuadrillasResult = await dbService.connection.query(
      'SELECT COUNT(*) FROM cuadrillas WHERE estado = true'
    );
    totalCuadrillas = int.parse(cuadrillasResult.first[0].toString());

    // Total actividades
    final actividadesResult = await dbService.connection.query(
      'SELECT COUNT(*) FROM actividades'
    );
    totalActividades = int.parse(actividadesResult.first[0].toString());

    // Semana actual
    final semanaResult = await dbService.connection.query(
      'SELECT MAX(id_semana) FROM nomina_empleados_semanal'
    );
    semanaActual = int.parse(semanaResult.first[0].toString());

    // Gasto total de la semana actual
    final gastoResult = await dbService.connection.query('''
      SELECT COALESCE(SUM(total_neto), 0) 
      FROM nomina_empleados_semanal 
      WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
    ''');
    gastoTotalSemana = double.parse(gastoResult.first[0].toString());
  }

  Future<void> _cargarDatosGraficaCircular(DatabaseService dbService) async {
    final results = await dbService.connection.query('''
      SELECT 
        c.nombre as cuadrilla_nombre,
        COALESCE(SUM(n.total_neto), 0) as total_gastos
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true 
        AND n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre
      HAVING COALESCE(SUM(n.total_neto), 0) > 0
      ORDER BY total_gastos DESC
    ''');

    final colores = [
      Color(0xFF2E7D32), // Verde oscuro - Top 1
      Color(0xFF4CAF50), // Verde medio - Top 2  
      Color(0xFF66BB6A), // Verde claro - Top 3
      Color(0xFF9E9E9E), // Gris - Otras
    ];

    datosGraficaCircular.clear();
    
    if (results.isNotEmpty) {
      // Calcular total general para porcentajes
      final totalGeneral = results.fold<double>(0, (sum, row) => 
        sum + double.parse(row[1].toString()));
      
      // Top 3 cuadrillas
      for (int i = 0; i < results.length && i < 3; i++) {
        final row = results[i];
        final gasto = double.parse(row[1].toString());
        final porcentaje = (gasto / totalGeneral) * 100;
        
        datosGraficaCircular.add({
          'label': row[0].toString().length > 15 
            ? '${row[0].toString().substring(0, 15)}...' 
            : row[0].toString(),
          'value': porcentaje,
          'gastoReal': gasto,
          'color': colores[i],
        });
      }
      
      // Agrupar el resto como "Otras" si hay más de 3
      if (results.length > 3) {
        final gastosOtras = results.skip(3).fold<double>(0, (sum, row) => 
          sum + double.parse(row[1].toString()));
        final porcentajeOtras = (gastosOtras / totalGeneral) * 100;
        
        datosGraficaCircular.add({
          'label': 'Otras (${results.length - 3})',
          'value': porcentajeOtras,
          'gastoReal': gastosOtras,
          'color': colores[3],
        });
      }
    }
  }

  Future<void> _cargarDatosGraficaBarras(DatabaseService dbService) async {
    final results = await dbService.connection.query('''
      SELECT 
        SUBSTRING(c.nombre FROM 1 FOR 12) as nombre_corto,
        COALESCE(SUM(n.total_neto), 0) as total_gastos
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true 
        AND n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre
      HAVING COALESCE(SUM(n.total_neto), 0) > 0
      ORDER BY total_gastos DESC
      LIMIT 3
    ''');

    datosGraficaBarras.clear();
    for (final row in results) {
      final gasto = double.parse(row[1].toString());
      datosGraficaBarras.add({
        'label': row[0].toString(),
        'value': gasto,
        'formatted': '\$${gasto.toStringAsFixed(0)}',
      });
    }
  }

  Future<void> _cargarCuadrillasTop(DatabaseService dbService) async {
    final results = await dbService.connection.query('''
      SELECT 
        c.nombre,
        c.grupo,
        COALESCE(SUM(n.total_neto), 0) as total_gastos,
        COUNT(n.id_empleado) as empleados
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal n ON c.id_cuadrilla = n.id_cuadrilla
      WHERE c.estado = true 
        AND n.id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal)
      GROUP BY c.id_cuadrilla, c.nombre, c.grupo
      HAVING COALESCE(SUM(n.total_neto), 0) > 0
      ORDER BY total_gastos DESC
      LIMIT 3
    ''');

    cuadrillasTop.clear();
    for (final row in results) {
      final gastos = double.parse(row[2].toString());
      cuadrillasTop.add({
        'nombre': row[0].toString(),
        'grupo': row[1]?.toString() ?? 'Sin grupo',
        'gastos': gastos,
        'empleados': int.parse(row[3].toString()),
        'gastosFormatted': '\$${gastos.toStringAsFixed(0)}',
      });
    }
  }

  Future<void> _cargarRanchosTop(DatabaseService dbService) async {
    final results = await dbService.connection.query('''
      SELECT 
        COALESCE(r.nombre, 'Campo ' || campo_val) as nombre_rancho,
        COUNT(DISTINCT n.id_empleado) as empleados,
        COALESCE(SUM(n.total_neto), 0) as total_gastos
      FROM (
        SELECT id_empleado, total_neto, campo_1 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_1 IS NOT NULL AND campo_1 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_2 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_2 IS NOT NULL AND campo_2 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_3 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_3 IS NOT NULL AND campo_3 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_4 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_4 IS NOT NULL AND campo_4 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_5 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_5 IS NOT NULL AND campo_5 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_6 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_6 IS NOT NULL AND campo_6 <> 0
        UNION ALL
        SELECT id_empleado, total_neto, campo_7 as campo_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND campo_7 IS NOT NULL AND campo_7 <> 0
      ) n
      LEFT JOIN ranchos r ON r.id_rancho = n.campo_val
      GROUP BY COALESCE(r.nombre, 'Campo ' || campo_val)
      ORDER BY total_gastos DESC
      LIMIT 3
    ''');

    ranchosTop.clear();
    for (final row in results) {
      // Manejar diferentes tipos de datos para gastos
      final gastosRaw = row[2];
      final gastos = gastosRaw is String ? double.tryParse(gastosRaw) ?? 0.0 : (gastosRaw as num).toDouble();
      
      ranchosTop.add({
        'nombre': row[0].toString(),
        'gastos': gastos,
        'empleados': int.parse(row[1].toString()),
        'gastosFormatted': '\$${gastos.toStringAsFixed(0)}',
      });
    }
  }

  Future<void> _cargarActividadesTop(DatabaseService dbService) async {
    final results = await dbService.connection.query('''
      SELECT 
        COALESCE(a.nombre, 'Actividad ' || act_val) as nombre_actividad,
        COUNT(DISTINCT n.id_empleado) as empleados,
        COALESCE(SUM(CASE 
          WHEN act_val = n.act_1 THEN n.dia_1
          WHEN act_val = n.act_2 THEN n.dia_2
          WHEN act_val = n.act_3 THEN n.dia_3
          WHEN act_val = n.act_4 THEN n.dia_4
          WHEN act_val = n.act_5 THEN n.dia_5
          WHEN act_val = n.act_6 THEN n.dia_6
          WHEN act_val = n.act_7 THEN n.dia_7
          ELSE 0
        END), 0) as total_gastos
      FROM (
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_1 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_1 IS NOT NULL AND act_1 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_2 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_2 IS NOT NULL AND act_2 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_3 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_3 IS NOT NULL AND act_3 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_4 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_4 IS NOT NULL AND act_4 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_5 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_5 IS NOT NULL AND act_5 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_6 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_6 IS NOT NULL AND act_6 <> 0
        UNION ALL
        SELECT id_empleado, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, act_1, act_2, act_3, act_4, act_5, act_6, act_7, act_7 as act_val FROM nomina_empleados_semanal WHERE id_semana = (SELECT MAX(id_semana) FROM nomina_empleados_semanal) AND act_7 IS NOT NULL AND act_7 <> 0
      ) n
      LEFT JOIN actividades a ON a.id_actividad = n.act_val
      GROUP BY COALESCE(a.nombre, 'Actividad ' || act_val)
      ORDER BY total_gastos DESC
      LIMIT 3
    ''');

    actividadesTop.clear();
    for (final row in results) {
      // Manejar diferentes tipos de datos para gastos
      final gastosRaw = row[2];
      final gastos = gastosRaw is String ? double.tryParse(gastosRaw) ?? 0.0 : (gastosRaw as num).toDouble();
      
      actividadesTop.add({
        'nombre': row[0].toString(),
        'gastos': gastos,
        'empleados': int.parse(row[1].toString()),
        'gastosFormatted': '\$${gastos.toStringAsFixed(0)}',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BA829)),
            ),
            SizedBox(height: 16),
            Text('Cargando datos reales...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con información del usuario
          _buildHeader(isSmallScreen),
          
          SizedBox(height: 24),
          
          // Cards de métricas principales
          _buildMetricsCards(isSmallScreen),
          
          SizedBox(height: 32),
          
          // Podio de ranchos
          _buildRanchosPodium(isSmallScreen),
          
          SizedBox(height: 32),
          
          // Gráficas principales
          _buildChartsSection(isSmallScreen),
          
          SizedBox(height: 32),
          
          // Cuadrillas destacadas
          _buildTopCuadrillas(isSmallScreen),
          
          SizedBox(height: 32),
          
          // Actividades destacadas
          _buildTopActividades(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5BA829), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5BA829).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 30 : 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: isSmallScreen ? 30 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isSmallScreen ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, ${widget.userName}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.tipoUsuario.toUpperCase(),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Datos actualizados - Semana $semanaActual',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(bool isSmallScreen) {
    final cards = [
      {
        'title': 'Empleados Activos',
        'value': totalEmpleados.toString(),
        'icon': Icons.people,
        'color': Color(0xFF2196F3),
      },
      {
        'title': 'Cuadrillas Activas',
        'value': totalCuadrillas.toString(),
        'icon': Icons.groups,
        'color': Color(0xFF4CAF50),
      },
      {
        'title': 'Gasto Semana',
        'value': '\$${(gastoTotalSemana / 1000).toStringAsFixed(0)}K',
        'icon': Icons.attach_money,
        'color': Color(0xFFFF9800),
      },
      {
        'title': 'Semana Actual',
        'value': semanaActual.toString(),
        'icon': Icons.calendar_today,
        'color': Color(0xFF9C27B0),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isSmallScreen ? 1.2 : 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildMetricCard(
          title: card['title'] as String,
          value: card['value'] as String,
          icon: card['icon'] as IconData,
          color: card['color'] as Color,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 32 : 40,
            color: color,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRanchosPodium(bool isSmallScreen) {
    if (ranchosTop.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'No hay datos de ranchos disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos por Rancho',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          ...ranchosTop.map((rancho) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF5BA829).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: BorderDirectional(
                  start: BorderSide(
                    width: 4,
                    color: Color(0xFF5BA829),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Color(0xFF5BA829),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rancho['nombre'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        Text(
                          '${rancho['empleados']} empleados',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF5BA829),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rancho['gastosFormatted'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopActividades(bool isSmallScreen) {
    if (actividadesTop.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text('No hay actividades activas esta semana'),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividades Destacadas',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          ...actividadesTop.map((actividad) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: BorderDirectional(
                  start: BorderSide(
                    width: 4,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work,
                    color: Color(0xFFFF9800),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad['nombre'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${actividad['empleados']} empleados',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      actividad['gastosFormatted'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isSmallScreen) {
    return Row(
      children: [
        // Gráfica circular
        Expanded(
          flex: 1,
          child: _buildChartContainer(
            title: 'Top 3 Cuadrillas por Gastos',
            child: _buildPieChart(),
            isSmallScreen: isSmallScreen,
          ),
        ),
        
        SizedBox(width: 16),
        
        // Gráfica de barras
        Expanded(
          flex: 1,
          child: _buildChartContainer(
            title: 'Cuadrillas Destacadas (Gastos)',
            child: _buildBarChart(),
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer({
    required String title,
    required Widget child,
    required bool isSmallScreen,
  }) {
    return Container(
      height: isSmallScreen ? 350 : 450,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF5BA829),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF5BA829).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  size: 16,
                  color: Color(0xFF5BA829),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (datosGraficaCircular.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No hay gastos registrados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Aún no hay información disponible',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    final total = datosGraficaCircular.fold<double>(
      0, (sum, item) => sum + (item['gastoReal'] ?? item['value'])
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isCompact = constraints.maxWidth < 500;
        
        return Row(
          children: [
            // Gráfica de pastel mejorada
            Container(
              width: isCompact ? constraints.maxWidth * 0.55 : 220,
              height: isCompact ? constraints.maxWidth * 0.55 : 220,
              child: Stack(
                children: [
                  // Sombra suave detrás de la gráfica
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: isCompact ? 45 : 55,
                      startDegreeOffset: -90,
                      sections: datosGraficaCircular.asMap().entries.map((entry) {
                        final data = entry.value;
                        final realValue = data['gastoReal'] ?? data['value'];
                        final percentage = total > 0 ? (realValue / total * 100) : 0.0;
                        
                        return PieChartSectionData(
                          color: data['color'],
                          value: percentage,
                          title: percentage > 8 ? '${percentage.toStringAsFixed(1)}%' : '',
                          radius: isCompact ? 45 : 55,
                          titleStyle: TextStyle(
                            fontSize: isCompact ? 9 : 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Centro mejorado con información
                  Center(
                    child: Container(
                      width: isCompact ? 90 : 110,
                      height: isCompact ? 90 : 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: Color(0xFF5BA829).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            total >= 1000000 
                              ? '\$${(total / 1000000).toStringAsFixed(1)}M'
                              : total >= 1000
                              ? '\$${(total / 1000).toStringAsFixed(0)}K'
                              : '\$${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5BA829),
                            ),
                          ),
                          Text(
                            'MXN',
                            style: TextStyle(
                              fontSize: isCompact ? 8 : 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: isCompact ? 16 : 24),
            
            // Leyenda mejorada
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5BA829), Color(0xFF4A8C22)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gastos por Cuadrilla',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ...datosGraficaCircular.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final realValue = data['gastoReal'] ?? data['value'];
                    final percentage = total > 0 ? (realValue / total * 100) : 0.0;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(isCompact ? 8 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: data['color'].withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: data['color'].withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  data['color'],
                                  data['color'].withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: data['color'].withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['label'],
                                  style: TextStyle(
                                    fontSize: isCompact ? 11 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  realValue >= 1000000 
                                    ? '\$${(realValue / 1000000).toStringAsFixed(1)}M MXN'
                                    : realValue >= 1000
                                    ? '\$${(realValue / 1000).toStringAsFixed(0)}K MXN'
                                    : '\$${realValue.toStringAsFixed(0)} MXN',
                                  style: TextStyle(
                                    fontSize: isCompact ? 10 : 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: data['color'].withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 11,
                                fontWeight: FontWeight.bold,
                                color: data['color'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarChart() {
    if (datosGraficaBarras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No hay gastos registrados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Aún no hay información disponible',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = datosGraficaBarras.fold<double>(
      0, (max, item) => item['value'] > max ? item['value'] : max
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isCompact = constraints.maxWidth < 500;
        
        return Column(
          children: [
            // Header con información
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5BA829), Color(0xFF4A8C22)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Top Cuadrillas por Gastos',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Gráfica de barras mejorada
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.black87,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final data = datosGraficaBarras[groupIndex];
                          return BarTooltipItem(
                            '${data['label']}\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '\$${data['value'].toStringAsFixed(0)} MXN',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isCompact ? 50 : 60,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < datosGraficaBarras.length) {
                              final data = datosGraficaBarras[value.toInt()];
                              return Container(
                                padding: EdgeInsets.only(top: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Posición con medalla
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: value.toInt() == 0 
                                            ? [Color(0xFFFFD700), Color(0xFFFFA000)] // Oro
                                            : value.toInt() == 1
                                            ? [Color(0xFFC0C0C0), Color(0xFF9E9E9E)] // Plata  
                                            : [Color(0xFFCD7F32), Color(0xFF8D6E63)], // Bronce
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${value.toInt() + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    // Nombre de la cuadrilla
                                    Container(
                                      width: isCompact ? 60 : 80,
                                      child: Text(
                                        data['label'],
                                        style: TextStyle(
                                          fontSize: isCompact ? 8 : 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isCompact ? 45 : 55,
                          interval: maxValue / 4,
                          getTitlesWidget: (value, meta) {
                            if (value >= 1000000) {
                              return Container(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  '\$${(value / 1000000).toStringAsFixed(1)}M',
                                  style: TextStyle(
                                    fontSize: isCompact ? 8 : 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            } else if (value >= 1000) {
                              return Container(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  '\$${(value / 1000).toStringAsFixed(0)}K',
                                  style: TextStyle(
                                    fontSize: isCompact ? 8 : 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            } else if (value > 0) {
                              return Container(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  '\$${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 8 : 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxValue / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    barGroups: datosGraficaBarras.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      
                      // Gradientes para top 3
                      final gradients = [
                        [Color(0xFFFFD700), Color(0xFFFFA000)], // Oro - 1er lugar
                        [Color(0xFFC0C0C0), Color(0xFF9E9E9E)], // Plata - 2do lugar  
                        [Color(0xFFCD7F32), Color(0xFF8D6E63)], // Bronce - 3er lugar
                      ];
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['value'],
                            gradient: index < gradients.length 
                              ? LinearGradient(
                                  colors: gradients[index],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : LinearGradient(
                                  colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                            width: isCompact ? 25 : 35,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            rodStackItems: [],
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue * 1.2,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Valores y estadísticas debajo
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: datosGraficaBarras.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == 0 
                            ? Color(0xFFFFD700).withOpacity(0.3)
                            : index == 1
                            ? Color(0xFFC0C0C0).withOpacity(0.3)
                            : Color(0xFFCD7F32).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${data['value'].toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: index == 0 
                                ? Color(0xFFFF8F00)
                                : index == 1
                                ? Color(0xFF616161)
                                : Color(0xFF8D6E63),
                            ),
                          ),
                          Text(
                            'MXN',
                            style: TextStyle(
                              fontSize: isCompact ? 8 : 9,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopCuadrillas(bool isSmallScreen) {
    if (cuadrillasTop.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups, size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text(
                'No hay cuadrillas activas esta semana',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Row(
            children: [
              Icon(
                Icons.groups,
                size: isSmallScreen ? 24 : 28,
                color: Color(0xFF5BA829),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Top 3 Cuadrillas por Gastos',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              // Total acumulado
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF5BA829).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: \$${cuadrillasTop.fold<double>(0, (sum, c) => sum + c['gastos']).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5BA829),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Lista de cuadrillas
          ...cuadrillasTop.asMap().entries.map((entry) {
            final index = entry.key;
            final cuadrilla = entry.value;
            
            // Colores y medallas para top 3
            final colors = [
              Color(0xFFFFD700), // Oro - 1er lugar
              Color(0xFFC0C0C0), // Plata - 2do lugar  
              Color(0xFFCD7F32), // Bronce - 3er lugar
            ];
            
            final medals = ['🥇', '🥈', '🥉'];
            final positions = ['1°', '2°', '3°'];
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    colors[index].withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors[index].withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    // Medalla y posición
                    Container(
                      width: isSmallScreen ? 50 : 60,
                      height: isSmallScreen ? 50 : 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors[index],
                            colors[index].withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                        boxShadow: [
                          BoxShadow(
                            color: colors[index].withOpacity(0.4),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            medals[index],
                            style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
                          ),
                          Text(
                            positions[index],
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    
                    // Información de la cuadrilla
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuadrilla['nombre'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: isSmallScreen ? 12 : 14,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cuadrilla['grupo'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: isSmallScreen ? 12 : 14,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${cuadrilla['empleados']} empleados',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Gasto total con indicador
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF5BA829),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF5BA829).withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            cuadrilla['gastosFormatted'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gasto total',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 9 : 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
