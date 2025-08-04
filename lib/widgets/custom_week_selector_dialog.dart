import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Diálogo personalizado y moderno para seleccionar rangos de fechas
/// Permite selección libre de cualquier rango sin restricciones
class CustomWeekSelectorDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomWeekSelectorDialog({
    Key? key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  State<CustomWeekSelectorDialog> createState() => _CustomWeekSelectorDialogState();
}

class _CustomWeekSelectorDialogState extends State<CustomWeekSelectorDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _hoveredDate;
  bool _isSelectingEnd = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialRange?.start ?? DateTime.now();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _isSelectingEnd = _startDate != null && _endDate == null;
  }

  void _onDateTap(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Empezar nueva selección
        _startDate = date;
        _endDate = null;
        _isSelectingEnd = true;
      } else if (_isSelectingEnd) {
        // Seleccionar fecha final
        DateTime proposedStart, proposedEnd;
        
        if (date.isAfter(_startDate!) || date.isAtSameMomentAs(_startDate!)) {
          proposedStart = _startDate!;
          proposedEnd = date;
        } else {
          // Si la fecha es anterior, intercambiar
          proposedStart = date;
          proposedEnd = _startDate!;
        }
        
        // 🎯 VALIDACIÓN: Verificar que sean exactamente 7 días
        final daysDifference = proposedEnd.difference(proposedStart).inDays + 1;
        
        if (daysDifference == 7) {
          // ✅ Exactamente 7 días - permitir selección
          _startDate = proposedStart;
          _endDate = proposedEnd;
          _isSelectingEnd = false;
        } else {
          // ❌ No son 7 días - mostrar mensaje de error y no aplicar selección
          _showDayLimitError(daysDifference);
        }
      }
    });
  }

  void _onDateHover(DateTime? date) {
    setState(() {
      _hoveredDate = date;
    });
  }

  /// 🎯 Muestra un diálogo de error cuando la selección no tiene exactamente 7 días
  void _showDayLimitError(int actualDays) {
    String title;
    String message;
    IconData icon;
    Color iconColor;
    
    if (actualDays > 7) {
      title = 'Demasiados días seleccionados';
      message = 'Has seleccionado $actualDays días.\n\nSolo se permiten exactamente 7 días para crear una semana de nómina válida.';
      icon = Icons.error_outline;
      iconColor = Colors.red.shade600;
    } else {
      title = 'Muy pocos días seleccionados';
      message = 'Has seleccionado $actualDays días.\n\nDebes seleccionar exactamente 7 días para crear una semana de nómina completa.';
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange.shade600;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 450,
              minWidth: 350,
            ),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  actualDays > 7 ? Colors.red.shade50 : Colors.orange.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono principal
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Título
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                // Mensaje
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24),
                
                // Información adicional
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Una semana de nómina debe tener exactamente 7 días consecutivos.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.check, size: 20),
                    label: Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎯 Valida que el rango seleccionado tenga exactamente 7 días
  bool _isValidRange() {
    if (_startDate == null || _endDate == null) return false;
    final days = _endDate!.difference(_startDate!).inDays + 1;
    return days == 7;
  }

  bool _isDateInRange(DateTime date) {
    if (_startDate == null) return false;
    
    if (_endDate != null) {
      // Rango completo seleccionado
      return date.isAfter(_startDate!.subtract(Duration(days: 1))) &&
             date.isBefore(_endDate!.add(Duration(days: 1)));
    } else if (_isSelectingEnd && _hoveredDate != null) {
      // Mostrando preview del rango
      final start = _startDate!.isBefore(_hoveredDate!) ? _startDate! : _hoveredDate!;
      final end = _startDate!.isAfter(_hoveredDate!) ? _startDate! : _hoveredDate!;
      return date.isAfter(start.subtract(Duration(days: 1))) &&
             date.isBefore(end.add(Duration(days: 1)));
    } else {
      return false;
    }
  }

  bool _isStartDate(DateTime date) {
    return _startDate != null && 
           date.year == _startDate!.year &&
           date.month == _startDate!.month &&
           date.day == _startDate!.day;
  }

  bool _isEndDate(DateTime date) {
    return _endDate != null && 
           date.year == _endDate!.year &&
           date.month == _endDate!.month &&
           date.day == _endDate!.day;
  }

  Color _getDateColor(DateTime date) {
    if (_isStartDate(date) || _isEndDate(date)) {
      return Colors.white;
    } else if (_isDateInRange(date)) {
      return Colors.green.shade700;
    } else {
      return Colors.black87;
    }
  }

  Color _getDateBackgroundColor(DateTime date) {
    if (_isStartDate(date) || _isEndDate(date)) {
      return Colors.green.shade600;
    } else if (_isDateInRange(date)) {
      return Colors.green.shade100;
    } else {
      return Colors.transparent;
    }
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    final List<Widget> dayWidgets = [];
    
    // Días de la semana headers
    const weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    for (String weekday in weekdays) {
      dayWidgets.add(
        Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            weekday,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    // Espacios vacíos antes del primer día
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }
    
    // Días del mes
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = _isToday(date);
      
      dayWidgets.add(
        MouseRegion(
          onEnter: (_) => _onDateHover(date),
          onExit: (_) => _onDateHover(null),
          child: GestureDetector(
            onTap: () => _onDateTap(date),
            child: Container(
              height: 40,
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getDateBackgroundColor(date),
                borderRadius: BorderRadius.circular(8),
                border: isToday 
                    ? Border.all(color: Colors.green.shade600, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  color: _getDateColor(date),
                  fontWeight: _isStartDate(date) || _isEndDate(date) 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  String _getRangeText() {
    if (_startDate == null) {
      return 'Selecciona fecha de inicio';
    } else if (_endDate == null) {
      if (_isSelectingEnd) {
        return 'Selecciona fecha de fin (debe ser exactamente 7 días)';
      } else {
        return DateFormat('d \'de\' MMMM, yyyy', 'es').format(_startDate!);
      }
    } else {
      final days = _endDate!.difference(_startDate!).inDays + 1;
      final rangeText = '${DateFormat('d \'de\' MMMM', 'es').format(_startDate!)} - '
                       '${DateFormat('d \'de\' MMMM, yyyy', 'es').format(_endDate!)} '
                       '($days días)';
      
      // 🎯 Agregar advertencia si no son exactamente 7 días
      if (days != 7) {
        return '$rangeText\n⚠️ Debes seleccionar exactamente 7 días';
      }
      
      return rangeText;
    }
  }

  /// Muestra el diálogo para entrada manual de fechas
  void _showManualEntry() {
    showDialog(
      context: context,
      builder: (context) => _ManualDateEntryDialog(
        initialStart: _startDate,
        initialEnd: _endDate,
        onDatesSelected: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
            _isSelectingEnd = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.green.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar Período',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Debes seleccionar exactamente 7 días',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Información del rango seleccionado
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_startDate != null && _endDate != null && !_isValidRange())
                    ? Colors.orange.shade50  // Color de advertencia para selección inválida
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_startDate != null && _endDate != null && !_isValidRange())
                      ? Colors.orange.shade300  // Borde de advertencia
                      : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _startDate == null 
                        ? Icons.touch_app_outlined
                        : (_endDate == null 
                            ? Icons.schedule_outlined 
                            : (_isValidRange()
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded)),  // Ícono de advertencia para selección inválida
                    color: (_startDate != null && _endDate != null && !_isValidRange())
                        ? Colors.orange.shade600  // Color de advertencia
                        : Colors.green.shade600,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getRangeText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (_startDate != null && _endDate != null && !_isValidRange())
                          ? Colors.orange.shade800  // Color de texto de advertencia
                          : Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isSelectingEnd) ...[
                    SizedBox(height: 4),
                    Text(
                      'Toca una fecha para finalizar el rango',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Navegación del mes
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
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
                    icon: Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade600,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'es').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      });
                    },
                    icon: Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Calendario
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _buildCalendarGrid(),
            ),
            
            SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                // Botón de entrada manual
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showManualEntry,
                    icon: Icon(Icons.edit_calendar),
                    label: Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade600,
                      side: BorderSide(color: Colors.green.shade300),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                if (_startDate != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _isSelectingEnd = false;
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (_startDate != null && _endDate != null && _isValidRange())
                        ? () {
                            Navigator.of(context).pop(
                              DateTimeRange(start: _startDate!, end: _endDate!),
                            );
                          }
                        : (_startDate != null && _endDate != null)
                            ? () {
                                // Si hay fechas seleccionadas pero no son válidas, mostrar error
                                final days = _endDate!.difference(_startDate!).inDays + 1;
                                _showDayLimitError(days);
                              }
                            : null,
                    icon: Icon(Icons.check),
                    label: Text('Confirmar Período'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_startDate != null && _endDate != null && _isValidRange())
                          ? Colors.green.shade600
                          : (_startDate != null && _endDate != null)
                              ? Colors.orange.shade600  // Color de advertencia para fechas inválidas
                              : null,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para entrada manual de fechas
class _ManualDateEntryDialog extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final Function(DateTime start, DateTime end) onDatesSelected;

  const _ManualDateEntryDialog({
    this.initialStart,
    this.initialEnd,
    required this.onDatesSelected,
  });

  @override
  State<_ManualDateEntryDialog> createState() => _ManualDateEntryDialogState();
}

class _ManualDateEntryDialogState extends State<_ManualDateEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.initialStart != null) {
      _startController.text = DateFormat('dd/MM/yyyy').format(widget.initialStart!);
    }
    if (widget.initialEnd != null) {
      _endController.text = DateFormat('dd/MM/yyyy').format(widget.initialEnd!);
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parse(value);
    } catch (e) {
      return null;
    }
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una fecha';
    }
    final date = _parseDate(value);
    if (date == null) {
      return 'Formato inválido (dd/MM/yyyy)';
    }
    return null;
  }

  /// 🎯 Muestra un diálogo de error para entrada manual cuando no son exactamente 7 días
  void _showManualEntryDayLimitError(int actualDays) {
    String title;
    String message;
    IconData icon;
    Color iconColor;
    
    if (actualDays > 7) {
      title = 'Período muy largo';
      message = 'El período ingresado tiene $actualDays días.\n\nPara una semana de nómina válida, debes ingresar fechas que comprendan exactamente 7 días consecutivos.';
      icon = Icons.error_outline;
      iconColor = Colors.red.shade600;
    } else {
      title = 'Período muy corto';
      message = 'El período ingresado tiene $actualDays días.\n\nPara una semana de nómina completa, debes ingresar fechas que comprendan exactamente 7 días consecutivos.';
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange.shade600;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 450,
              minWidth: 350,
            ),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  actualDays > 7 ? Colors.red.shade50 : Colors.orange.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono principal
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Título
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                // Mensaje
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24),
                
                // Ejemplo de formato correcto
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ejemplo de período válido:',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inicio: 01/01/2025\nFin: 07/01/2025\n(7 días consecutivos)',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.edit_calendar, size: 20),
                    label: Text(
                      'Corregir fechas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final startDate = _parseDate(_startController.text)!;
      final endDate = _parseDate(_endController.text)!;
      
      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La fecha de fin debe ser posterior a la fecha de inicio'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 🎯 VALIDACIÓN: Verificar que sean exactamente 7 días
      final daysDifference = endDate.difference(startDate).inDays + 1;
      if (daysDifference != 7) {
        _showManualEntryDayLimitError(daysDifference);
        return;
      }
      
      widget.onDatesSelected(startDate, endDate);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.green.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_calendar,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Entrada Manual',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: CircleBorder(),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa las fechas en formato DD/MM/YYYY',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El período debe tener exactamente 7 días',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Campo fecha de inicio
              Text(
                'Fecha de Inicio',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _startController,
                validator: _validateDate,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: 'dd/mm/yyyy',
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.green.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Campo fecha de fin
              Text(
                'Fecha de Fin',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _endController,
                validator: _validateDate,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: 'dd/mm/yyyy',
                  prefixIcon: Icon(Icons.event, color: Colors.green.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(Icons.check),
                      label: Text('Aplicar Fechas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
