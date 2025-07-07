import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

class ReportesScreen extends StatefulWidget {
  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Variables para el historial
  bool _isModoSemana = true; // true: por semana, false: por día
  DateTime? _diaSeleccionado;
  String? _semanaSeleccionada;
  final TextEditingController _semanaController = TextEditingController();
  int? _numSemanaSeleccionada;
  int _selectedYear = DateTime.now().year; // Año seleccionado por defecto
  
  // Lista de años disponibles (puedes ajustar según tus necesidades)
  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index); // Últimos 5 años
  }
  
  // Datos de ejemplo para la tabla
  List<Map<String, dynamic>> _reportData = [
    // Semana 27 (Semana actual)
    {
      'fecha': '01/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Cosecha',
      'total': '\$1,240.00'
    },
    {
      'fecha': '02/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Siembra',
      'total': '\$980.00'
    },
    {
      'fecha': '03/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Centro',
      'actividad': 'Riego',
      'total': '\$750.00'
    },
    {
      'fecha': '04/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Este',
      'actividad': 'Fertilización',
      'total': '\$1,100.00'
    },
    {
      'fecha': '05/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Oeste',
      'actividad': 'Poda',
      'total': '\$650.00'
    },
    {
      'fecha': '06/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Control de plagas',
      'total': '\$820.00'
    },
    {
      'fecha': '07/07/2025',
      'semana': 'Semana 27',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Cosecha',
      'total': '\$1,350.00'
    },
    
    // Semana 26
    {
      'fecha': '24/06/2025',
      'semana': 'Semana 26',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Cosecha',
      'total': '\$1,180.00'
    },
    {
      'fecha': '25/06/2025',
      'semana': 'Semana 26',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Siembra',
      'total': '\$890.00'
    },
    {
      'fecha': '26/06/2025',
      'semana': 'Semana 26',
      'cuadrilla': 'Cuadrilla Centro',
      'actividad': 'Riego',
      'total': '\$720.00'
    },
    {
      'fecha': '27/06/2025',
      'semana': 'Semana 26',
      'cuadrilla': 'Cuadrilla Este',
      'actividad': 'Fertilización',
      'total': '\$950.00'
    },
    {
      'fecha': '28/06/2025',
      'semana': 'Semana 26',
      'cuadrilla': 'Cuadrilla Oeste',
      'actividad': 'Poda',
      'total': '\$680.00'
    },
    
    // Semana 25
    {
      'fecha': '17/06/2025',
      'semana': 'Semana 25',
      'cuadrilla': 'Cuadrilla Centro',
      'actividad': 'Riego',
      'total': '\$720.00'
    },
    {
      'fecha': '18/06/2025',
      'semana': 'Semana 25',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Cosecha',
      'total': '\$1,100.00'
    },
    {
      'fecha': '19/06/2025',
      'semana': 'Semana 25',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Siembra',
      'total': '\$780.00'
    },
    {
      'fecha': '20/06/2025',
      'semana': 'Semana 25',
      'cuadrilla': 'Cuadrilla Este',
      'actividad': 'Control de plagas',
      'total': '\$620.00'
    },
    {
      'fecha': '21/06/2025',
      'semana': 'Semana 25',
      'cuadrilla': 'Cuadrilla Oeste',
      'actividad': 'Fertilización',
      'total': '\$880.00'
    },
    
    // Datos de 2024
    {
      'fecha': '15/12/2024',
      'semana': 'Semana 50',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Cosecha',
      'total': '\$1,500.00'
    },
    {
      'fecha': '16/12/2024',
      'semana': 'Semana 50',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Poda',
      'total': '\$900.00'
    },
    {
      'fecha': '20/11/2024',
      'semana': 'Semana 47',
      'cuadrilla': 'Cuadrilla Centro',
      'actividad': 'Siembra',
      'total': '\$1,200.00'
    },
    {
      'fecha': '25/10/2024',
      'semana': 'Semana 43',
      'cuadrilla': 'Cuadrilla Este',
      'actividad': 'Riego',
      'total': '\$800.00'
    },
    
    // Datos de 2023
    {
      'fecha': '10/12/2023',
      'semana': 'Semana 49',
      'cuadrilla': 'Cuadrilla Norte',
      'actividad': 'Cosecha',
      'total': '\$1,300.00'
    },
    {
      'fecha': '15/11/2023',
      'semana': 'Semana 46',
      'cuadrilla': 'Cuadrilla Sur',
      'actividad': 'Fertilización',
      'total': '\$950.00'
    },
    {
      'fecha': '20/09/2023',
      'semana': 'Semana 38',
      'cuadrilla': 'Cuadrilla Centro',
      'actividad': 'Control de plagas',
      'total': '\$700.00'
    },
  ];

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
}

@override
void dispose() {
  _tabController.dispose();
  _searchController.dispose();
  _semanaController.dispose();
  super.dispose();
}

/// Calcular número de semana del año
int _getNumSemana(DateTime date) {
  final primerDiaAno = DateTime(date.year, 1, 1);
  final diaAno = date.difference(primerDiaAno).inDays + 1;
  return ((diaAno - date.weekday + 10) / 7).floor();
}

/// Obtener string de semana basado en una fecha
String _getWeekString(DateTime date) {
  final numSemana = _getNumSemana(date);
  return 'Semana $numSemana';
}

/// Seleccionar fecha y calcular semana
Future<void> _selectDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _diaSeleccionado ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
  );
  
  if (picked != null) {
    setState(() {
      _diaSeleccionado = picked;
      _semanaSeleccionada = _getWeekString(picked);
    });
  }
}

/// Ir a una semana específica
void _irASemana() {
  final semanaText = _semanaController.text.trim();
  if (semanaText.isNotEmpty) {
    final semanaNum = int.tryParse(semanaText);
    if (semanaNum != null && semanaNum >= 1 && semanaNum <= 52) {
      setState(() {
        _numSemanaSeleccionada = semanaNum;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa un número de semana válido (1-52)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Limpiar selección de semana
void _clearSemanaSeleccionada() {
  setState(() {
    _numSemanaSeleccionada = null;
    _semanaController.clear();
  });
}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800;
          final cardWidth = (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();

          return Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Container(
              constraints: BoxConstraints(maxWidth: cardWidth),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              height: MediaQuery.of(context).size.height - 100, // Altura fija
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Text(
                        'Reportes',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // TabBar simplificado
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.greenDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[700],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'Semana'),
                        Tab(text: 'Historial'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por cuadrilla o actividad...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[500]),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Tabla modular
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab de Semana - Datos actuales
                        _buildReportTable(isCurrentWeek: true),
                        // Tab de Historial - Con controles adicionales
                        _buildHistorialTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// Widget para el tab de historial con controles adicionales
  Widget _buildHistorialTab() {
    return Column(
      children: [
        // Controles del historial
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de controles
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: AppColors.greenDark,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros de Historial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filtros en una sola fila
                Row(
                  children: [
                    // Sección de Año
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Año:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availableYears.length,
                              itemBuilder: (context, index) {
                                final year = _availableYears[index];
                                final isSelected = year == _selectedYear;
                                
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedYear = year;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.greenDark : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppColors.greenDark : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        year.toString(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Sección de Toggle Ver por
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ver por:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildModeButton('Semana', true)),
                                Expanded(child: _buildModeButton('Día', false)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Sección de controles específicos (Semana/Día)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isModoSemana ? 'Semana específica:' : 'Fecha específica:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 40,
                            child: Row(
                              children: [
                                if (_isModoSemana) ...[
                                  // Campo de texto para número de semana
                                  Expanded(
                                    child: TextField(
                                      controller: _semanaController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Semana #',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: AppColors.greenDark),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                      onSubmitted: (value) => _irASemana(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Botón para ir a la semana
                                  ElevatedButton(
                                    onPressed: _irASemana,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.greenDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Ir',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  // Botón para limpiar selección de semana
                                  if (_numSemanaSeleccionada != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _clearSemanaSeleccionada,
                                      icon: const Icon(Icons.clear, size: 18),
                                      tooltip: 'Limpiar filtro',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.1),
                                        foregroundColor: Colors.red[700],
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  // Selector de fecha
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _selectDate,
                                      icon: const Icon(Icons.calendar_today, size: 16),
                                      label: Text(
                                        _diaSeleccionado != null
                                            ? '${_diaSeleccionado!.day}/${_diaSeleccionado!.month}/${_diaSeleccionado!.year}'
                                            : 'Seleccionar fecha',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.greenDark,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón para limpiar selección de fecha
                                  if (_diaSeleccionado != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _diaSeleccionado = null;
                                          _semanaSeleccionada = null;
                                        });
                                      },
                                      icon: const Icon(Icons.clear, size: 18),
                                      tooltip: 'Limpiar selección',
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.1),
                                        foregroundColor: Colors.red[700],
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Información de filtros aplicados
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros: Año $_selectedYear',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isModoSemana && _numSemanaSeleccionada != null) ...[
                        Text(
                          ' • Semana $_numSemanaSeleccionada',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (!_isModoSemana && _diaSeleccionado != null) ...[
                        Text(
                          ' • Fecha: ${_diaSeleccionado!.day}/${_diaSeleccionado!.month}/${_diaSeleccionado!.year} ($_semanaSeleccionada)',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Tabla de historial
        Expanded(
          child: _buildReportTable(isCurrentWeek: false),
        ),
      ],
    );
  }
  
  /// Widget para botones de modo (Semana/Día)
  Widget _buildModeButton(String text, bool isWeekButton) {
    final isSelected = _isModoSemana == isWeekButton;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isModoSemana = isWeekButton;
          if (isWeekButton) {
            // Limpiar selección de día
            _diaSeleccionado = null;
            _semanaSeleccionada = null;
          } else {
            // Limpiar selección de semana
            _numSemanaSeleccionada = null;
            _semanaController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenDark : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  /// Widget modular para construir la tabla de reportes
  Widget _buildReportTable({bool isCurrentWeek = true}) {
    // Filtrar datos según la búsqueda y el contexto
    List<Map<String, dynamic>> filteredData = _reportData.where((item) {
      final searchTerm = _searchController.text.toLowerCase();
      bool matchesSearch = item['cuadrilla'].toString().toLowerCase().contains(searchTerm) ||
                          item['actividad'].toString().toLowerCase().contains(searchTerm) ||
                          item['fecha'].toString().toLowerCase().contains(searchTerm) ||
                          item['semana'].toString().toLowerCase().contains(searchTerm);
      
      if (!matchesSearch) return false;
      
      // Filtros específicos para historial
      if (!isCurrentWeek) {
        // Filtrar por año seleccionado
        final itemDate = item['fecha'].toString().split('/');
        if (itemDate.length == 3) {
          final itemYear = int.tryParse(itemDate[2]);
          if (itemYear != _selectedYear) {
            return false;
          }
        }
        
        if (_isModoSemana) {
          // En modo semana, filtrar por número de semana específico si está seleccionado
          if (_numSemanaSeleccionada != null) {
            return item['semana'] == 'Semana $_numSemanaSeleccionada';
          }
          // Si no hay semana seleccionada, mostrar todas las semanas del año
          return true;
        } else {
          // En modo día, filtrar por fecha específica o semana de la fecha seleccionada
          if (_diaSeleccionado != null) {
            final selectedDateStr = '${_diaSeleccionado!.day.toString().padLeft(2, '0')}/${_diaSeleccionado!.month.toString().padLeft(2, '0')}/${_diaSeleccionado!.year}';
            final selectedWeek = _getWeekString(_diaSeleccionado!);
            // Mostrar datos del día seleccionado o de toda la semana a la que pertenece
            return item['fecha'] == selectedDateStr || item['semana'] == selectedWeek;
          }
          return true;
        }
      } else {
        // Solo semana actual para el tab "Semana"
        return item['semana'] == 'Semana 27';
      }
    }).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tableHeader,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: AppColors.greenDark,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCurrentWeek ? 'Datos de la Semana Actual' : 'Datos del Historial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredData.length} registros',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido de la tabla
          Expanded(
            child: filteredData.isEmpty
                ? _buildEmpty()
                : SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      child: DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        headingRowHeight: 56,
                        dataRowHeight: 56,
                        border: TableBorder.all(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                        columns: [
                          DataColumn(
                            label: Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Fecha',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Semana',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Cuadrilla',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Actividad',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: filteredData.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text(
                                    item['fecha'],
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['semana'],
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['cuadrilla'],
                                      style: TextStyle(
                                        color: AppColors.greenDark,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text(
                                    item['actividad'],
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Text(
                                    item['total'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greenDark,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  /// Widget para mostrar cuando no hay datos
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron registros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}