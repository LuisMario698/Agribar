/// Widget para la visualización general de empleados.
/// Muestra métricas y una tabla con los datos de los empleados.

import 'package:flutter/material.dart';
import 'widgets_general/EmpleadosMetricsRow.dart';
import '../widgets_shared/widgets_shared/index.dart';
import '../services/edicion_empleado_service.dart';
import '../widgets/editar_empleado_dialog.dart';

class EmpleadosGeneralTab extends StatefulWidget {
  final List<Map<String, dynamic>> empleadosData;
  final List<String> empleadosHeaders;
  final Function(int) toggleHabilitado;
  final VoidCallback? onEmpleadoActualizado; // Nuevo callback

  const EmpleadosGeneralTab({
    Key? key,
    required this.empleadosData,
    required this.empleadosHeaders,
    required this.toggleHabilitado,
    this.onEmpleadoActualizado, // Nuevo parámetro opcional
  }) : super(key: key);

  @override
  State<EmpleadosGeneralTab> createState() => _EmpleadosGeneralTabState();
}

class _EmpleadosGeneralTabState extends State<EmpleadosGeneralTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];
  
  // Variables para paginación visual
  int _paginaActual = 1;
  int _elementosPorPagina = 100;
  List<Map<String, dynamic>> _datosVisibles = [];

  @override
  void initState() {
    super.initState();
    _filteredData = widget.empleadosData;
    _actualizarDatosVisibles();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmpleadosGeneralTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.empleadosData != oldWidget.empleadosData) {
      setState(() {
        _filteredData = widget.empleadosData;
        _paginaActual = 1; // Resetear a primera página
        _actualizarDatosVisibles();
      });
    }
  }

  void _actualizarDatosVisibles() {
    final inicio = (_paginaActual - 1) * _elementosPorPagina;
    final fin = inicio + _elementosPorPagina;
    _datosVisibles = _filteredData.take(fin).skip(inicio).toList();
    
    // Debug para verificar paginación
    print('🔍 DEBUG Paginación:');
    print('   Total empleados: ${_filteredData.length}');
    print('   Página actual: $_paginaActual');
    print('   Elementos por página: $_elementosPorPagina');
    print('   Inicio: $inicio, Fin: $fin');
    print('   Empleados visibles: ${_datosVisibles.length}');
    if (_filteredData.length >= 10000) {
      print('   🚨 EMPLEADOS >= 10000 DETECTADOS');
      final totalPaginas = (_filteredData.length / _elementosPorPagina).ceil();
      print('   Total páginas calculado: $totalPaginas');
    }
  }

  void _editarEmpleado(Map<String, dynamic> empleado, int index) async {
    try {
      final idEmpleado = empleado['id_empleado'] as int;
      
      // Obtener datos completos del empleado
      final datosCompletos = await EdicionEmpleadoService.obtenerEmpleadoCompleto(idEmpleado);
      
      if (datosCompletos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: No se pudieron cargar los datos del empleado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Mostrar diálogo de edición
      if (mounted) {
        final resultado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return EditarEmpleadoDialog(
              empleadoData: datosCompletos,
              onEmpleadoActualizado: () {
                // Callback para actualizar la lista después de editar
                if (mounted) {
                  widget.onEmpleadoActualizado?.call(); // Llamar al callback del padre
                }
              },
            );
          },
        );
        
        // Si se guardaron los cambios, actualizar la lista
        if (resultado == true && mounted) {
          widget.onEmpleadoActualizado?.call(); // Llamar al callback del padre
        }
      }
      
    } catch (e) {
      print('❌ Error al editar empleado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del empleado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredData = widget.empleadosData;
        _paginaActual = 1; // Resetear paginación al filtrar
        _actualizarDatosVisibles();
      });
      return;
    }

    setState(() {
      _filteredData =
          widget.empleadosData.where((empleado) {
            final clave = (empleado['clave'] ?? '').toLowerCase();
            final nombre = (empleado['nombre'] ?? '').toLowerCase();
            final apellidoPaterno =
                (empleado['apellidoPaterno'] ?? '').toLowerCase();
            final apellidoMaterno =
                (empleado['apellidoMaterno'] ?? '').toLowerCase();
            final cuadrilla = (empleado['cuadrilla'] ?? '').toLowerCase();

            return clave.contains(query) ||
                nombre.contains(query) ||
                apellidoPaterno.contains(query) ||
                apellidoMaterno.contains(query) ||
                cuadrilla.contains(query) ||
                '$nombre $apellidoPaterno $apellidoMaterno'.contains(query);
          }).toList();
      _paginaActual = 1; // Resetear paginación al filtrar
      _actualizarDatosVisibles();
    });
  }

  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _paginaActual = nuevaPagina;
      _actualizarDatosVisibles();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredData = widget.empleadosData;
    });
  }

  Widget _buildPaginationControls(int totalPaginas) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _paginaActual > 1 ? () => _cambiarPagina(_paginaActual - 1) : null,
          icon: Icon(Icons.chevron_left),
          tooltip: 'Página anterior',
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF0B7A2F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$_paginaActual de $totalPaginas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          onPressed: _paginaActual < totalPaginas ? () => _cambiarPagina(_paginaActual + 1) : null,
          icon: Icon(Icons.chevron_right),
          tooltip: 'Página siguiente',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular métricas basadas en datos filtrados
    int empleadosActivos =
        _filteredData.where((emp) => emp['habilitado'] == true).length;
    int empleadosInactivos =
        _filteredData.where((emp) => emp['habilitado'] == false).length;
    
    // Calcular información de paginación
    final totalPaginas = (_filteredData.length / _elementosPorPagina).ceil();
    final inicio = (_paginaActual - 1) * _elementosPorPagina + 1;
    final fin = (_paginaActual * _elementosPorPagina).clamp(0, _filteredData.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 50,
              child: GenericSearchBar(
                controller: _searchController,
                hintText: 'Buscar empleado por nombre o clave...',
                onClearPressed: _clearSearch,
                fillColor: Color(0xFFF3F1EA),
                searchIcon: Icons.person_search,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 50,
              child: EmpleadosMetricsRow(
                activos: empleadosActivos,
                inactivos: empleadosInactivos,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Información de paginación
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $inicio-$fin de ${_filteredData.length} empleados',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (totalPaginas > 1) _buildPaginationControls(totalPaginas),
            ],
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: GenericDataTable<Map<String, dynamic>>(
            data: _datosVisibles, // Usar datos visibles en lugar de _filteredData
            headers: widget.empleadosHeaders,
            buildCells: (row, rowIdx) {
              // Calcular el índice real considerando la paginación
              final originalIndex = widget.empleadosData.indexWhere(
                (emp) => emp['id_empleado'] == row['id_empleado'],
              );

              return [
                DataCell(Text(
                  row['clave'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['nombre'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['apellidoPaterno'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['apellidoMaterno'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['curp'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['rfc'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(Text(
                  row['estadoorigen'] ?? '',
                  style: TextStyle(
                    color: !(row['habilitado'] as bool? ?? true) ? Colors.grey[600] : null,
                  ),
                )),
                DataCell(
                  Container(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: row['habilitado']
                            ? Color(0xFF0B7A2F)
                            : Color(0xFFE53935),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => widget.toggleHabilitado(originalIndex),
                      child: Text(
                        row['habilitado'] ? 'Sí' : 'No',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    width: 50,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        padding: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _editarEmpleado(row, originalIndex);
                      },
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }
}
