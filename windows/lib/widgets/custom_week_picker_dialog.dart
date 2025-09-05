import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_styles.dart';

/// Diálogo personalizado para selección de semana con diseño moderno
class CustomWeekPickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomWeekPickerDialog({
    super.key,
    this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomWeekPickerDialog> createState() => _CustomWeekPickerDialogState();
}

class _CustomWeekPickerDialogState extends State<CustomWeekPickerDialog>
    with TickerProviderStateMixin {
  late DateTime _currentMonth;
  DateTimeRange? _selectedRange;
  DateTime? _hoveredDate;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialRange?.start ?? DateTime.now();
    _selectedRange = widget.initialRange;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildCalendar(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.greenDark,
            AppColors.greenDark.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRange != null
                        ? '${DateFormat('d MMM', 'es').format(_selectedRange!.start)} - ${DateFormat('d MMM', 'es').format(_selectedRange!.end)}'
                        : 'Toca para seleccionar una semana',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMonthNavigation(),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy', 'es').format(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildWeekHeader(),
          const SizedBox(height: 16),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Text(
          day,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = (firstDay.weekday - 1) % 7;
    
    final days = <Widget>[];
    
    // Espacios en blanco para días del mes anterior
    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox(width: 48, height: 48));
    }
    
    // Días del mes actual
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      days.add(_buildDayWidget(date));
    }
    
    return Wrap(
      children: days,
    );
  }

  Widget _buildDayWidget(DateTime date) {
    final isSelected = _selectedRange != null &&
        date.isAfter(_selectedRange!.start.subtract(const Duration(days: 1))) &&
        date.isBefore(_selectedRange!.end.add(const Duration(days: 1)));
    
    final isStart = _selectedRange?.start.day == date.day &&
        _selectedRange?.start.month == date.month &&
        _selectedRange?.start.year == date.year;
    
    final isEnd = _selectedRange?.end.day == date.day &&
        _selectedRange?.end.month == date.month &&
        _selectedRange?.end.year == date.year;
    
    final isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    
    final isHovered = _hoveredDate?.day == date.day &&
        _hoveredDate?.month == date.month &&
        _hoveredDate?.year == date.year;
    
    return GestureDetector(
      onTap: () => _selectWeek(date),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredDate = date),
        onExit: (_) => setState(() => _hoveredDate = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isSelected, isStart, isEnd, isToday, isHovered),
            borderRadius: BorderRadius.circular(12),
            border: _getBorder(isSelected, isStart, isEnd, isToday),
            boxShadow: (isStart || isEnd) ? [
              BoxShadow(
                color: AppColors.greenDark.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: _getFontWeight(isSelected, isStart, isEnd, isToday),
                color: _getTextColor(isSelected, isStart, isEnd, isToday),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isSelected, bool isStart, bool isEnd, bool isToday, bool isHovered) {
    if (isStart || isEnd) {
      return AppColors.greenDark;
    }
    if (isSelected) {
      return AppColors.greenDark.withOpacity(0.15);
    }
    if (isToday) {
      return Colors.blue.shade50;
    }
    if (isHovered) {
      return Colors.grey.shade100;
    }
    return Colors.transparent;
  }

  Border? _getBorder(bool isSelected, bool isStart, bool isEnd, bool isToday) {
    if (isStart || isEnd) {
      return Border.all(color: AppColors.greenDark, width: 2);
    }
    if (isToday) {
      return Border.all(color: Colors.blue.shade300, width: 2);
    }
    if (isSelected) {
      return Border.all(color: AppColors.greenDark.withOpacity(0.3), width: 1);
    }
    return null;
  }

  Color _getTextColor(bool isSelected, bool isStart, bool isEnd, bool isToday) {
    if (isStart || isEnd) {
      return Colors.white;
    }
    if (isToday) {
      return Colors.blue.shade700;
    }
    if (isSelected) {
      return AppColors.greenDark;
    }
    return Colors.grey.shade700;
  }

  FontWeight _getFontWeight(bool isSelected, bool isStart, bool isEnd, bool isToday) {
    if (isStart || isEnd || isToday) {
      return FontWeight.w700;
    }
    if (isSelected) {
      return FontWeight.w600;
    }
    return FontWeight.w500;
  }

  void _selectWeek(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    setState(() {
      _selectedRange = DateTimeRange(start: weekStart, end: weekEnd);
    });
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.greenDark,
                  AppColors.greenDark.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.greenDark.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _selectedRange != null
                  ? () => Navigator.of(context).pop(_selectedRange)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Función helper para mostrar el diálogo personalizado
Future<DateTimeRange?> showCustomWeekPicker({
  required BuildContext context,
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => CustomWeekPickerDialog(
      initialRange: initialRange,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}
