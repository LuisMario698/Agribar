import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateRangePicker({
    Key? key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _hoverDate;
  
  // 🎨 Colores del tema verde elegante
  static const Color _primaryGreen = Color(0xFF7BAE2F);
  static const Color _lightGreen = Color(0xFFE8F5E8);
  static const Color _mediumGreen = Color(0xFFB8D4B8);
  static const Color _darkGreen = Color(0xFF5A8A1F);
  static const Color _accentGreen = Color(0xFF9BC53D);

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
      _endDate = widget.initialRange!.end;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎨 Header con gradiente verde elegante
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryGreen,
                    _accentGreen,
                    _darkGreen,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.date_range_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seleccionar Período',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Elige las fechas de inicio y fin',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 🎨 Resumen del período seleccionado con diseño elegante
            if (_startDate != null || _endDate != null)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _lightGreen,
                      Colors.white,
                      _lightGreen.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _mediumGreen.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Período Seleccionado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5A8A1F),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRangeText(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5016),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 🎨 Calendario con diseño mejorado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Header del mes con navegación elegante
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _previousMonth,
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              color: _primaryGreen,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'es').format(_currentMonth),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _nextMonth,
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: _primaryGreen,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Días de la semana con mejor diseño
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
                        return Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _darkGreen,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Grid de días mejorado
                  _buildCalendarGrid(),
                ],
              ),
            ),

            // 🎨 Botones de acción con diseño premium
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryGreen,
                            _accentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _startDate != null && _endDate != null ? _confirmSelection : null,
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Confirmar Período',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstDateToShow = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    final weeks = <Widget>[];
    DateTime currentDate = firstDateToShow;
    
    for (int week = 0; week < 6; week++) {
      final days = <Widget>[];
      for (int day = 0; day < 7; day++) {
        final isCurrentMonth = currentDate.month == _currentMonth.month;
        final isSelected = _isDateSelected(currentDate);
        final isInRange = _isDateInRange(currentDate);
        final isStart = _startDate != null && _isSameDay(currentDate, _startDate!);
        final isEnd = _endDate != null && _isSameDay(currentDate, _endDate!);
        final isHovered = _hoverDate != null && _isSameDay(currentDate, _hoverDate!);
        
        days.add(
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoverDate = currentDate),
              onExit: (_) => setState(() => _hoverDate = null),
              child: GestureDetector(
                onTap: isCurrentMonth ? () => _onDateTap(currentDate) : null,
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getDateBackgroundColor(isSelected, isInRange, isStart, isEnd, isHovered, isCurrentMonth),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getDateBorderColor(isSelected, isStart, isEnd, isHovered),
                      width: isSelected || isHovered ? 2 : 0,
                    ),
                    boxShadow: (isStart || isEnd) ? [
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Text(
                      currentDate.day.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.w500,
                        color: _getDateTextColor(isSelected, isInRange, isStart, isEnd, isCurrentMonth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(Row(children: days));
      
      if (currentDate.month != _currentMonth.month && week >= 4) break;
    }
    
    return Column(children: weeks);
  }

  Color _getDateBackgroundColor(bool isSelected, bool isInRange, bool isStart, bool isEnd, bool isHovered, bool isCurrentMonth) {
    if (!isCurrentMonth) return Colors.transparent;
    if (isStart || isEnd) return _primaryGreen;
    if (isInRange) return _lightGreen;
    if (isHovered) return _mediumGreen.withOpacity(0.3);
    if (isSelected) return _primaryGreen.withOpacity(0.2);
    return Colors.transparent;
  }

  Color _getDateBorderColor(bool isSelected, bool isStart, bool isEnd, bool isHovered) {
    if (isStart || isEnd) return _darkGreen;
    if (isSelected || isHovered) return _primaryGreen;
    return Colors.transparent;
  }

  Color _getDateTextColor(bool isSelected, bool isInRange, bool isStart, bool isEnd, bool isCurrentMonth) {
    if (!isCurrentMonth) return Colors.grey.shade400;
    if (isStart || isEnd) return Colors.white;
    if (isInRange) return _darkGreen;
    if (isSelected) return _primaryGreen;
    return Colors.grey.shade800;
  }

  bool _isDateSelected(DateTime date) {
    return (_startDate != null && _isSameDay(date, _startDate!)) ||
           (_endDate != null && _isSameDay(date, _endDate!));
  }

  bool _isDateInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    return date.isAfter(_startDate!) && date.isBefore(_endDate!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Iniciar nueva selección
        _startDate = date;
        _endDate = null;
      } else if (_endDate == null) {
        // Completar el rango
        if (date.isAfter(_startDate!)) {
          _endDate = date;
        } else {
          _endDate = _startDate;
          _startDate = date;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _hoverDate = null;
    });
  }

  void _confirmSelection() {
    if (_startDate != null && _endDate != null) {
      Navigator.of(context).pop(DateTimeRange(start: _startDate!, end: _endDate!));
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  String _getRangeText() {
    if (_startDate != null && _endDate != null) {
      final formatter = DateFormat('d \'de\' MMMM', 'es');
      final days = _endDate!.difference(_startDate!).inDays + 1;
      return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}, ${_endDate!.year} ($days días)';
    } else if (_startDate != null) {
      return 'Selecciona la fecha final';
    }
    return 'Selecciona las fechas';
  }
}
