import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import 'indicator_card.dart';
import 'dias_trabajados_table.dart';
import 'editable_data_table.dart';

class HistorialSemanasWidget extends StatefulWidget {
  final List<Map<String, dynamic>> semanasCerradas;
  final Function(int, int) onCuadrillaSelected;
  final VoidCallback onClose;

  const HistorialSemanasWidget({
    Key? key,
    required this.semanasCerradas,
    required this.onCuadrillaSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<HistorialSemanasWidget> createState() => _HistorialSemanasWidgetState();
}

class _HistorialSemanasWidgetState extends State<HistorialSemanasWidget> with SingleTickerProviderStateMixin {
  int? semanaCerradaSeleccionada;
  bool showTablaPrincipal = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Card(
            margin: const EdgeInsets.all(32),
            elevation: 16,
            shadowColor: AppColors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con título y acciones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.history,
                              color: AppColors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Historial de Semanas',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          _controller.reverse().then((_) => widget.onClose());
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.tableHeader,
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Lista de semanas y detalles
                  Expanded(
                    child: widget.semanasCerradas.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No hay semanas cerradas',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Las semanas cerradas aparecerán aquí',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.semanasCerradas.length,
                          itemBuilder: (context, index) {
                            final semana = widget.semanasCerradas[index];
                            final fechaInicio = semana['fechaInicio'] as DateTime;
                            final fechaFin = semana['fechaFin'] as DateTime;
                            final cuadrillas = List<Map<String, dynamic>>.from(semana['cuadrillas']);
                            final cuadrillaSeleccionada = semana['cuadrillaSeleccionada'] as int;
                            final isExpanded = semanaCerradaSeleccionada == index;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: isExpanded ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                side: BorderSide(
                                  color: isExpanded ? AppColors.greenDark : Colors.grey.shade200,
                                  width: isExpanded ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isExpanded ? Colors.white : Colors.grey.shade50,
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: isExpanded,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      semanaCerradaSeleccionada = expanded ? index : null;
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  collapsedBackgroundColor: Colors.transparent,
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isExpanded 
                                            ? AppColors.green.withOpacity(0.1)
                                            : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.calendar_month,
                                          color: isExpanded ? AppColors.green : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Semana del ${_formatDate(fechaInicio)} al ${_formatDate(fechaFin)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isExpanded ? AppColors.greenDark : Colors.grey.shade800,
                                            ),
                                          ),
                                          if (!isExpanded) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '${cuadrillas.length} cuadrillas | Total: ${_formatCurrency(semana['totalSemana'] as double)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Selector de cuadrilla e indicadores
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Seleccionar Cuadrilla',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    DropdownButtonFormField<int>(
                                                      value: cuadrillaSeleccionada,
                                                      decoration: InputDecoration(
                                                        prefixIcon: Icon(Icons.groups, color: AppColors.greenDark),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                                          borderSide: BorderSide(color: AppColors.greenDark, width: 2),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                                        ),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      ),
                                                      items: cuadrillas.asMap().entries.map((entry) {
                                                        return DropdownMenuItem(
                                                          value: entry.key,
                                                          child: Text(
                                                            entry.value['nombre'],
                                                            style: const TextStyle(fontSize: 15),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          widget.onCuadrillaSelected(index, value);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 24),
                                              // Indicadores
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: IndicatorCard(
                                                        title: 'Total Acumulado',
                                                        value: _formatCurrency(cuadrillas[cuadrillaSeleccionada]['total'] as double),
                                                        icon: Icons.payments,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: IndicatorCard(
                                                        title: 'Total Semana',
                                                        value: _formatCurrency(semana['totalSemana'] as double),
                                                        icon: Icons.calendar_today,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),

                                          // Switch para alternar entre tablas
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                _buildTabOption(
                                                  'Tabla Principal',
                                                  Icons.table_chart,
                                                  showTablaPrincipal,
                                                ),
                                                const SizedBox(width: 32),
                                                _buildTabOption(
                                                  'Días Trabajados',
                                                  Icons.calendar_view_week,
                                                  !showTablaPrincipal,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Contenido de tablas
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Tabla de resumen de cuadrillas (izquierda)
                                              SizedBox(
                                                width: 320,
                                                child: Card(
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                                    side: BorderSide(color: Colors.grey.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.tableHeader,
                                                          borderRadius: BorderRadius.vertical(
                                                            top: Radius.circular(AppDimens.buttonRadius),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.all(6),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.green.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Icon(
                                                                Icons.groups_outlined,
                                                                size: 16,
                                                                color: AppColors.green,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Text(
                                                              'Resumen de Cuadrillas',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.greenDark,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        child: DataTable(
                                                          headingTextStyle: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                            color: Colors.black87,
                                                          ),
                                                          dataTextStyle: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.black87,
                                                          ),
                                                          horizontalMargin: 12,
                                                          columnSpacing: 20,
                                                          columns: const [
                                                            DataColumn(label: Text('Cuadrilla')),
                                                            DataColumn(
                                                              label: Text('Emp.'),
                                                              numeric: true,
                                                            ),
                                                            DataColumn(
                                                              label: Text('Total'),
                                                              numeric: true,
                                                            ),
                                                          ],
                                                          rows: cuadrillas.map((cuadrilla) {
                                                            final empleadosCount = cuadrilla['empleados']?.length ?? 0;
                                                            final total = cuadrilla['total'] as double? ?? 0.0;
                                                            final isSelected = cuadrillas.indexOf(cuadrilla) == cuadrillaSeleccionada;

                                                            return DataRow(
                                                              color: MaterialStateProperty.resolveWith<Color?>(
                                                                (Set<MaterialState> states) {
                                                                  if (isSelected) return AppColors.tableHeader;
                                                                  if (states.contains(MaterialState.hovered)) 
                                                                    return Colors.grey.shade100;
                                                                  return null;
                                                                },
                                                              ),
                                                              cells: [
                                                                DataCell(
                                                                  Row(
                                                                    children: [
                                                                      if (isSelected)
                                                                        Container(
                                                                          width: 4,
                                                                          height: 24,
                                                                          margin: const EdgeInsets.only(right: 8),
                                                                          decoration: BoxDecoration(
                                                                            color: AppColors.green,
                                                                            borderRadius: BorderRadius.circular(2),
                                                                          ),
                                                                        ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          cuadrilla['nombre'] ?? '',
                                                                          style: TextStyle(
                                                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                            color: isSelected ? AppColors.greenDark : null,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                DataCell(Text(
                                                                  '$empleadosCount',
                                                                  style: TextStyle(
                                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                  ),
                                                                )),
                                                                DataCell(Text(
                                                                  _formatCurrency(total),
                                                                  style: TextStyle(
                                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                  ),
                                                                )),
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),

                                              // Tabla dinámica (derecha)
                                              Expanded(
                                                child: Card(
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                                                    side: BorderSide(color: Colors.grey.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.tableHeader,
                                                          borderRadius: BorderRadius.vertical(
                                                            top: Radius.circular(AppDimens.buttonRadius),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.all(6),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.green.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Icon(
                                                                showTablaPrincipal ? Icons.table_chart : Icons.calendar_view_week,
                                                                size: 16,
                                                                color: AppColors.green,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Text(
                                                              showTablaPrincipal ? 'Tabla Principal' : 'Días Trabajados',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.greenDark,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),                                                  Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: showTablaPrincipal
                                                      ? EditableDataTableWidget(
                                          empleados: cuadrillas[cuadrillaSeleccionada]['empleados'],
                                          readOnly: true,
                                          semanaSeleccionada: DateTimeRange(
                                            start: fechaInicio,
                                            end: fechaFin
                                          ),
                                        )
                                                      : DiasTrabajadosTable(
                                                              empleados: _getDiasTrabajadosData(cuadrillas[cuadrillaSeleccionada]['empleados']),
                                                              selectedWeek: DateTimeRange(
                                                                start: fechaInicio,
                                                                end: fechaFin,
                                                              ),
                                                              diasH: (cuadrillas[cuadrillaSeleccionada]['empleados'] as List)
                                                                  .map((emp) {
                                                                    final horasExtra = emp['dias_trabajados']?['horas_extra'] as List?;
                                                                    return horasExtra?.map((h) => (h as num).toInt()).toList() ??
                                                                      List.filled(fechaFin.difference(fechaInicio).inDays + 1, 0);
                                                                  })
                                                                  .toList(),
                                                              diasTT: (cuadrillas[cuadrillaSeleccionada]['empleados'] as List)
                                                                  .map((emp) {
                                                                    final dias = emp['dias_trabajados']?['dias'] as List?;
                                                                    return dias?.map((d) => (d as num).toInt()).toList() ??
                                                                      List.filled(fechaFin.difference(fechaInicio).inDays + 1, 0);
                                                                  })
                                                                  .toList(),
                                                              readOnly: true,
                                                              isExpanded: false,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabOption(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          showTablaPrincipal = title == 'Tabla Principal';
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.green : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.green : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.green : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
// Eliminado método _getTablaPrincipalData ya que no se necesita

  List<Map<String, dynamic>> _getDiasTrabajadosData(List<dynamic> empleados) {
    return empleados.map((emp) {
      final diasTrabajados = emp['dias_trabajados'] ?? {};
      return {
        'id': emp['id'] ?? '',
        'nombre': emp['nombre'] ?? '',
        'dias': diasTrabajados['dias'] ?? [],
        'horas_extra': diasTrabajados['horas_extra'] ?? [],
        'total_dias': diasTrabajados['total_dias'] ?? 0,
        'total_horas': diasTrabajados['total_horas'] ?? 0,
      };
    }).toList();
  }
  Widget _buildTablaPrincipal(List<Map<String, dynamic>> empleados) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        headingRowHeight: 48,
        dataRowHeight: 52,
        headingRowColor: MaterialStateProperty.all(AppColors.tableHeader),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87,
        ),
        dataTextStyle: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        showBottomBorder: true,
        columns: [
          DataColumn(
            label: SizedBox(
              width: 75,
              child: Text('Clave'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              width: 180,
              child: Text('Nombre'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              width: 85,
              child: Text('Días'),
            ),
            numeric: true,
          ),
          DataColumn(
            label: SizedBox(
              width: 85,
              child: Text('Total'),
            ),
            numeric: true,
          ),
          DataColumn(
            label: SizedBox(
              width: 85,
              child: Text('Debe'),
            ),
            numeric: true,
          ),
          DataColumn(
            label: SizedBox(
              width: 85,
              child: Text('Comedor'),
            ),
          ),
          DataColumn(
            label: SizedBox(
              width: 85,
              child: Text('Neto'),
            ),
            numeric: true,
          ),
        ],
        rows: empleados.map((empleado) {
          final tablaPrincipal = empleado['tabla_principal'] ?? {};
          final dias = tablaPrincipal['dias'] as List? ?? [];
          final totalDias = dias.fold<double>(0.0, (sum, dia) => sum + (dia as num).toDouble());
          final total = (tablaPrincipal['total'] as num?)?.toDouble() ?? 0.0;
          final debe = (tablaPrincipal['debe'] as num?)?.toDouble() ?? 0.0;
          final comedor = tablaPrincipal['comedor'] == true;
          final neto = (tablaPrincipal['neto'] as num?)?.toDouble() ?? 0.0;

          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 75,
                  alignment: Alignment.center,
                  child: Text(empleado['clave']?.toString() ?? ''),
                ),
              ),
              DataCell(
                Container(
                  width: 180,
                  alignment: Alignment.centerLeft,
                  child: Text(empleado['nombre']?.toString() ?? ''),
                ),
              ),
              DataCell(
                Container(
                  width: 85,
                  alignment: Alignment.centerRight,
                  child: Text(totalDias.toStringAsFixed(1)),
                ),
              ),
              DataCell(
                Container(
                  width: 85,
                  alignment: Alignment.centerRight,
                  child: Text(_formatCurrency(total)),
                ),
              ),
              DataCell(
                Container(
                  width: 85,
                  alignment: Alignment.centerRight,
                  child: Text(_formatCurrency(debe)),
                ),
              ),
              DataCell(
                Container(
                  width: 85,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: comedor,
                          onChanged: null,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCurrency(comedor ? 400 : 0),
                        style: TextStyle(
                          color: comedor ? Colors.black87 : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Container(
                  width: 85,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatCurrency(neto),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: neto < 0 ? Colors.red : null,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
        border: TableBorder(
          verticalInside: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
