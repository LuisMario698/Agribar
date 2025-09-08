/// Módulo de Nómina del Sistema Agribar
/// Implementa la funcionalidad completa del sistema de nómina,
/// incluyendo captura de días, cálculos y gestión de deducciones.

import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/semana_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../widgets/nomina_historial_semanas_cerradas_widget.dart';
import '../widgets/nomina_armar_cuadrilla_widget.dart';
import '../widgets/custom_week_selector_dialog.dart';
import '../theme/app_styles.dart';
import '../widgets/nomina_supervisor_auth_widget.dart';
import '../widgets/nomina_actualizar_cuadrilla_widget.dart';
import '../widgets/nomina_detalles_empleado_widget.dart';
import '../widgets/nomina_week_selection_card.dart';
import '../widgets/nomina_cuadrilla_selection_card.dart';
import '../widgets/nomina_indicators_row.dart';
import '../widgets/nomina_tabla_seccion_principal.dart';
import '../widgets/nomina_resumen_cuadrillas_dialog.dart';
import '../widgets/nomina_export_section.dart';
import '../widgets/nomina_flow_indicator.dart';
import '../widgets/nomina_dialogo_cambios_no_guardados.dart';
import '../widgets/cuadrillas_loading_widget.dart';
import '../services/cuadrillas_cache_service.dart';

/// Widget principal de la pantalla de nómina.
/// Gestiona el proceso completo de nómina semanal incluyendo:
/// - Selección de cuadrilla y periodo
/// - Captura de días trabajados
/// - Cálculo de percepciones y deducciones
/// - Vista normal y expandida de la información
///
///variables de estado en _NominaScreenState
DateTime? _startDate;
DateTime? _endDate;
bool _isWeekClosed = false;
bool semanaActiva = false;
bool _haySemanaActiva = false;
Map<String, dynamic>? semanaSeleccionada;

class NominaScreen extends StatefulWidget {
  const NominaScreen({
    super.key,
    this.showFullTable = false, // Control de vista expandida
    this.onCloseFullTable, // Callback al cerrar vista completa
    this.onOpenFullTable, // Callback al abrir vista completa
    this.onCambiosChanged, // Callback para notificar cambios no guardados
    this.onGuardadoCallbackSet, // Callback para establecer función de guardado
  });

  final bool showFullTable;
  final VoidCallback? onCloseFullTable;
  final VoidCallback? onOpenFullTable;
  final Function(bool)? onCambiosChanged; // Nuevo callback
  final Function(Future<void> Function())? onGuardadoCallbackSet; // Callback para establecer función de guardado

  @override
  State<NominaScreen> createState() => _NominaScreenState();
}

class _NominaScreenState extends State<NominaScreen> 
    with CambiosNoGuardadosMixin {

  /// Obtiene la semana abierta actual desde el servicio de semanas
  Future<Map<String, dynamic>?> obtenerSemanaAbierta() async {
    return await SemanaService().obtenerSemanaAbierta();
  }
  
  @override
  void marcarCambiosNoGuardados() {
    super.marcarCambiosNoGuardados();
    widget.onCambiosChanged?.call(true); // Notificar al dashboard
  }
  
  @override
  void marcarCambiosGuardados() {
    super.marcarCambiosGuardados();
    widget.onCambiosChanged?.call(false); // Notificar al dashboard
  }
  bool showTablaPrincipal =
      true; // true for tabla principal, false for dias trabajados
  bool isTableExpanded = false;

  // Variable principal para empleados en la cuadrilla seleccionada
  List<Map<String, dynamic>> empleadosFiltrados = [];

  // Variables para manejo de empleados y cuadrillas
  List<Map<String, dynamic>> empleadosDisponiblesFiltrados = [];
  List<Map<String, dynamic>> empleadosEnCuadrillaFiltrados = [];
  final TextEditingController _buscarDisponiblesController =
      TextEditingController();
  final TextEditingController _buscarEnCuadrillaController =
      TextEditingController();
  List<Map<String, dynamic>> empleadosNomina = [];

  Map<String, dynamic>? semanaSeleccionada;
  int? idSemanaSeleccionada;
  Map<String, dynamic>? cuadrillaSeleccionada;
  final  List<Map<String, dynamic>> _optionsCuadrilla = [];
  // Variables para detectar cambios no guardados (usando CambiosNoGuardadosMixin)
  Map<String, dynamic> _originalNominaData = {};
  
  // 🔧 Variables para manejo de datos temporales (cambios en tiempo real sin guardar)
  List<Map<String, dynamic>> empleadosNominaTemp = [];
  Map<String, dynamic> _originalDataBeforeEditing = {};
  
  // 🛡️ Variable para control de lifecycle del widget
  bool _isDisposed = false;
  
  // 🎯 Variables para control de flujo robusto
  bool _puedeArmarCuadrilla = false;
  bool _puedeCapturarDatos = false;
  bool _bloqueadoPorFaltaSemana = true;
  bool _mostrandoMensajeGuia = false;
  
  // 🔄 Variable para recordar la opción de cierre de semana
  String _ultimaOpcionCierre = 'resetear';
  
  // 🎯 Variable temporal para conservar cuadrillas con empleados al mantener
  List<Map<String, dynamic>> _cuadrillasTemporales = [];
  
  // 🔄 Variables para indicadores de carga
  bool _isGuardando = false;
  bool _isCreandoSemana = false;
  
  // 🎯 Variable para forzar actualización de indicadores
  int _indicatorsUpdateKey = 0;
  
  // 🚫 Variable para controlar actualizaciones del total semanal
  bool _puedeActualizarTotal = false;
  
  // 📋 Cache de cuadrillas para evitar recargas innecesarias
  final CuadrillasCache _cuadrillasCache = CuadrillasCache();
  bool _isCuadrillasLoadingInBackground = false;
  
  Map<String, dynamic> _selectedCuadrilla = {
    'nombre': '',
    'empleados': [],
  }; // Variables para manejo de semanas cerradas
  List<Map<String, dynamic>> semanasCerradas = [];
  bool showSemanasCerradas = false;
  int? semanaCerradaSeleccionada;

  // Variables para manejo de empleados y cuadrillas
  bool showArmarCuadrilla = false;
  List<Map<String, dynamic>> todosLosEmpleados = [];
  List<Map<String, dynamic>> empleadosEnCuadrilla = [];

  @override
  void initState() {
    super.initState();
    // Inicializar valores por defecto SOLO si no están ya establecidos
    if (_selectedCuadrilla['nombre'] == null || _selectedCuadrilla['nombre'] == '') {
      _selectedCuadrilla = {'nombre': '', 'empleados': []};
    }
    
    // 🎯 Permitir armar cuadrillas desde el inicio
    _puedeArmarCuadrilla = true;
    _puedeCapturarDatos = false;
    _bloqueadoPorFaltaSemana = true; // Sin semana, pero se puede armar cuadrillas
    
    // Registrar la función de guardado con el Dashboard
    widget.onGuardadoCallbackSet?.call(_guardarNomina);
    
    // Cargar datos iniciales básicos
    _loadInitialData();
    
    // 🎯 Verificar semana activa (esto ya carga cuadrillas con empleados internamente)
    verificarSemanaActiva();
    
    // 🆕 Cargar semanas cerradas desde la base de datos
    _cargarSemanasCerradas();
  }

  /// Helper method para llamadas seguras a setState
  void _safeSetState(VoidCallback callback) {
    if (mounted && !_isDisposed) {
      setState(callback);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _buscarDisponiblesController.dispose();
    _buscarEnCuadrillaController.dispose();
    
    // 🧹 Limpiar overlay de loading si está visible
    CuadrillasLoadingOverlay.hide();
    
    super.dispose();
  }

  Future<void> cargarDatosNomina() async {
    if (semanaSeleccionada != null && cuadrillaSeleccionada != null) {
      
      print('🔄 CARGANDO datos de nómina para cuadrilla: ${cuadrillaSeleccionada!['nombre']}');
      
      final data = await obtenerNominaEmpleadosDeCuadrilla(
        semanaSeleccionada!['id'],
        cuadrillaSeleccionada!['id'],
      );

      print('📊 Datos cargados: ${data.length} empleados');
      if (data.isNotEmpty) {
        final firstEmp = data.first;
        print('  Primer empleado: ${firstEmp['nombre']}');
        print('  Datos días: dia_0_s=${firstEmp['dia_0_s']}, dia_1_s=${firstEmp['dia_1_s']}');
        print('  Total BD: ${firstEmp['total']}');
      }

      if (mounted) {
        setState(() {
          // ✅ Actualizar TODOS los datos necesarios
          empleadosNomina = List<Map<String, dynamic>>.from(data);
          empleadosFiltrados = List<Map<String, dynamic>>.from(data);
          empleadosNominaTemp = List<Map<String, dynamic>>.from(data);
        
          // ✅ Sincronizar con _optionsCuadrilla
          final indiceCuadrilla = _optionsCuadrilla.indexWhere(
            (c) => c['id'] == cuadrillaSeleccionada!['id'],
          );
          
          if (indiceCuadrilla != -1) {
            _optionsCuadrilla[indiceCuadrilla]['empleados'] = 
                List<Map<String, dynamic>>.from(data);
          }
          
          // ✅ También sincronizar empleadosEnCuadrilla
          empleadosEnCuadrilla = List<Map<String, dynamic>>.from(data);
        });
        
        print('✅ Datos actualizados en state - empleadosFiltrados: ${empleadosFiltrados.length}');
        
        // ✅ Forzar una actualización adicional para asegurar que la tabla se redibuje
        Future.microtask(() {
          if (mounted) {
            setState(() {
              print('🔄 Forzando actualización final de UI después de cargar datos');
            });
          }
        });
        
        // ✅ Guardar los datos originales después de cargar SOLO si no hay cambios
        if (!tieneCambiosNoGuardados) {
          _saveOriginalData();
        }
        
        // 📊 LLAMADA CALCULO TOTAL SEMANAL: Después de cargar datos de nómina
        // Se ejecuta con un pequeño delay para asegurar que el widget esté completamente montado
        Future.microtask(() => _actualizarTotalSemana());
      }
    }
  }

  void verificarSemanaActiva() async {
    final semana = await obtenerSemanaAbierta();

    if (semana != null) {
      if (mounted) {
        setState(() {
          _startDate = semana['fechaInicio'];
          _endDate = semana['fechaFin'];
          _isWeekClosed = semana['cerrada'] ?? false;
          _haySemanaActiva = true;
          idSemanaSeleccionada = semana['id'];
          semanaSeleccionada = semana; // ✅ Asignar semanaSeleccionada
          
          // 🎯 Habilitar flujo después de seleccionar semana
          _bloqueadoPorFaltaSemana = false;
          _puedeArmarCuadrilla = true; // Siempre permitir armar cuadrillas
          _puedeCapturarDatos = false; // Solo después de armar cuadrilla
        });

        // 🗑️ CACHE: Verificar si cambió la semana para invalidar cache si es necesario
        if (_cuadrillasCache.hasCachedData && !_cuadrillasCache.isValidForSemana(semana['id'])) {
          print('🔄 Semana cambió, invalidando cache de cuadrillas');
          _invalidarCacheCuadrillas();
        }
      }

      // 🚨 Solo ejecutar si el widget sigue montado
      if (mounted) {
        // ✅ Recargar cuadrillas con empleados ahora que hay semana activa
        print('🔄 [INIT] Iniciando carga de cuadrillas con empleados...');
        await _cargarCuadrillasHabilitadas();
        
        print('🔄 [INIT] Cargando cuadrillas de semana específica...');
        await _cargarCuadrillasSemana(semana['id']);
        
        print('🔄 [INIT] Cargando datos completos de empleados de cuadrillas...');
        // ✅ Cargar empleados de todas las cuadrillas desde la BD
        await _cargarEmpleadosDeCuadrillas();
        
        // � MEJORA: Asegurar que el dropdown se actualice después de cargar empleados
        if (mounted) {
          setState(() {
            print('✅ [INIT] Carga inicial completa - Cuadrillas disponibles: ${_optionsCuadrilla.length}');
            _optionsCuadrilla.forEach((c) => print('   - ${c['nombre']}: ${(c['empleados'] as List?)?.length ?? 0} empleados'));
          });
        }
        
        // �📊 LLAMADA CALCULO TOTAL SEMANAL: Después de verificar y cargar semana activa
        // Se ejecuta con un pequeño delay para asegurar que el widget esté completamente montado
        Future.microtask(() => _actualizarTotalSemana());
      }
    } else {
      if (mounted) {
        setState(() {
          _haySemanaActiva = false;
          semanaSeleccionada = null;
          
          // 🎯 Permitir armar cuadrillas incluso sin semana
          _bloqueadoPorFaltaSemana = true;
          _puedeArmarCuadrilla = true; // Siempre permitir armar cuadrillas
          _puedeCapturarDatos = false;
        });
        
        // 🧹 Limpiar cache ya que no hay semana activa
        _cuadrillasCache.clearCache();
      }
    }
  }

  /// 🆕 Cargar semanas cerradas desde la base de datos
  Future<void> _cargarSemanasCerradas() async {
    try {
      print('\n\n�🟢🟢 [HISTORIAL] INICIANDO CARGA DE SEMANAS CERRADAS 🟢🟢🟢');
      
      // 🔍 DEBUG: Verificar primero qué semanas hay en la BD
      final db = DatabaseService();
      await db.connect();
      
      final semanasQuery = await db.connection.query('''
        SELECT 
          id_semana,
          fecha_inicio,
          fecha_fin,
          esta_cerrada,
          creado_en
        FROM semanas_nomina
        ORDER BY fecha_inicio DESC;
      ''');
      
      print('📋 [HISTORIAL] TODAS LAS SEMANAS EN BD (${semanasQuery.length}):');
      for (var semana in semanasQuery) {
        final cerrada = semana[3] == true ? 'CERRADA' : 'ABIERTA';
        print('   • ID: ${semana[0]}, Fechas: ${semana[1]} - ${semana[2]}, Estado: $cerrada');
        
        // Verificar datos de nómina para esta semana
        final nominaQuery = await db.connection.query('''
          SELECT COUNT(*) as total_empleados, SUM(total_neto) as total_nomina
          FROM nomina_empleados_semanal
          WHERE id_semana = @semanaId;
        ''', substitutionValues: {'semanaId': semana[0]});
        
        if (nominaQuery.isNotEmpty) {
          print('     ➜ Empleados en nómina: ${nominaQuery.first[0]}, Total: \$${nominaQuery.first[1] ?? 0}');
        }
      }
      
      await db.close();
      
      print('🚀 [HISTORIAL] Llamando a obtenerSemanasCerradas()...');
      
      // Llamar función original
      final semanasCerradasBD = await obtenerSemanasCerradas();
      
      print('✅ [HISTORIAL] obtenerSemanasCerradas() retornó: ${semanasCerradasBD.length} semanas');
      
      for (int i = 0; i < semanasCerradasBD.length; i++) {
        final semana = semanasCerradasBD[i];
        print('   📊 Semana $i: ID=${semana['id']}, Cuadrillas=${(semana['cuadrillas'] as List).length}, Total=\$${semana['totalSemana']}');
        
        final cuadrillas = semana['cuadrillas'] as List;
        for (int j = 0; j < cuadrillas.length; j++) {
          final cuadrilla = cuadrillas[j];
          print('      🔸 ${cuadrilla['nombre']}: ${cuadrilla['empleados']?.length ?? 0} empleados, Total: \$${cuadrilla['total']}');
        }
      }
      
      if (mounted) {
        setState(() {
          semanasCerradas = semanasCerradasBD;
        });
        print('✅ [HISTORIAL] Estado actualizado con ${semanasCerradasBD.length} semanas cerradas');
      }
      
      print('🟢🟢🟢 [HISTORIAL] CARGA COMPLETADA 🟢🟢🟢\n\n');
    } catch (e) {
      print('❌❌❌ [HISTORIAL] ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  /// Invalida el cache de cuadrillas cuando sea necesario
  void _invalidarCacheCuadrillas() {
    print('🗑️ Invalidando cache de cuadrillas');
    _cuadrillasCache.invalidateCache();
  }

  /// Muestra un SnackBar de progreso no intrusivo para cargas pequeñas
  void _mostrarProgresoCarga(int processed, int total, String current) {
    if (!mounted) return;

    // Solo mostrar cada 10 cuadrillas procesadas para no spam
    if (processed % 10 != 0 && processed != total) return;

    final progress = (processed / total * 100).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: processed / total,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando empleados... $progress% ($processed/$total)',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.green.withOpacity(0.9),
      ),
    );
  }

  // 🎯 Validaciones del flujo robusto
  
  /// Verifica si se puede armar cuadrilla (ya no requiere semana seleccionada)
  bool _validarPuedeArmarCuadrilla() {
    return true; // Ahora siempre se puede armar cuadrilla
  }
  
  /// Verifica si se puede capturar datos (requiere semana y cuadrilla)
  bool _validarPuedeCapturarDatos() {
    return semanaSeleccionada != null && 
           cuadrillaSeleccionada != null &&
           (cuadrillaSeleccionada!['empleados'] as List).isNotEmpty;
  }
  
  /// Actualiza los estados de validación del flujo
  void _actualizarEstadosValidacion() {
    if (!mounted || _isDisposed) return;
    setState(() {
      _puedeArmarCuadrilla = _validarPuedeArmarCuadrilla();
      _puedeCapturarDatos = _validarPuedeCapturarDatos();
    });
  }
  
  /// Valida si hay cambios sin guardar antes de cambiar semana/cuadrilla
  Future<bool> _validarCambiosSinGuardar(String accion) async {
    if (!tieneCambiosNoGuardados) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cambios sin guardar'),
          ],
        ),
        content: Text(
          'Tienes cambios sin guardar. Si continúas $accion, '
          'perderás los cambios realizados.\n\n¿Deseas continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Continuar sin guardar'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Muestra mensaje guía cuando no se cumple el flujo
  void _mostrarMensajeGuia(String mensaje, {IconData icon = Icons.info_outline, String? accionSugerida}) {
    if (_mostrandoMensajeGuia || !mounted || _isDisposed) return;
    
    setState(() {
      _mostrandoMensajeGuia = true;
    });
    
    Color backgroundColor;
    if (icon == Icons.warning_amber_rounded || icon == Icons.error_outline) {
      backgroundColor = Colors.orange.shade600;
    } else if (icon == Icons.check_circle_outline) {
      backgroundColor = Colors.green.shade600;
    } else {
      backgroundColor = Colors.blue.shade600;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            if (accionSugerida != null) ...[
              SizedBox(height: 4),
              Text(
                accionSugerida,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: accionSugerida != null ? SnackBarAction(
          label: '¿Cómo?',
          textColor: Colors.white,
          onPressed: () => _mostrarAyudaContextual(),
        ) : null,
      ),
    ).closed.then((_) {
      if (mounted && !_isDisposed) {
        setState(() {
          _mostrandoMensajeGuia = false;
        });
      }
    });
  }
  
  /// Muestra ayuda contextual según el estado actual
  void _mostrarAyudaContextual() {
    String titulo = "Guía de uso";
    String contenido = "";
    
    if (semanaSeleccionada == null) {
      titulo = "Seleccionar Semana";
      contenido = "1. Haz clic en 'Seleccionar semana'\n"
                  "2. Elige las fechas de inicio y fin\n"
                  "3. Confirma la selección";
    } else if (cuadrillaSeleccionada == null) {
      titulo = "Armar Cuadrilla";
      contenido = "1. Selecciona una cuadrilla del dropdown\n"
                  "2. Haz clic en 'Armar cuadrilla'\n"
                  "3. Agrega empleados y guarda";
    } else {
      titulo = "Capturar Datos";
      contenido = "1. Ingresa los días trabajados por empleado\n"
                  "2. Agrega deducciones si es necesario\n"
                  "3. Haz clic en 'Guardar'";
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(contenido),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // 🎯 Funciones para manejar shortcuts de teclado
  
  /// Maneja los shortcuts de teclado
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final isControlPressed = event.logicalKey == LogicalKeyboardKey.controlLeft ||
                               event.logicalKey == LogicalKeyboardKey.controlRight ||
                               HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                               HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
      
      if (isControlPressed) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyS:
            // Ctrl + S: Guardar
            if (_canSave && !_isGuardando) {
            //  _guardarNomina();
            }
            break;
          case LogicalKeyboardKey.keyN:
            // Ctrl + N: Nueva semana
            if (!_isCreandoSemana) {
              _seleccionarSemana();
            }
            break;
          case LogicalKeyboardKey.keyA:
            // Ctrl + A: Armar cuadrilla
            if (_puedeArmarCuadrilla) {
              _toggleArmarCuadrilla();
            }
            break;
          case LogicalKeyboardKey.keyH:
            // Ctrl + H: Ayuda
            _mostrarAyudaContextual();
            break;
        }
      } else {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.f1:
            // F1: Ayuda
            _mostrarAyudaContextual();
            break;
          case LogicalKeyboardKey.f5:
            // F5: Refrescar/Recargar datos
            if (semanaSeleccionada != null && cuadrillaSeleccionada != null) {
              cargarDatosNomina();
            }
            break;
        }
      }
    }
  }
  
  /// Muestra diálogo con shortcuts disponibles
  void _mostrarShortcuts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 8),
            Text('Atajos de Teclado'),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutRow('Ctrl + S', 'Guardar datos de nómina'),
              _buildShortcutRow('Ctrl + N', 'Crear nueva semana'),
              _buildShortcutRow('Ctrl + A', 'Armar cuadrilla'),
              _buildShortcutRow('Ctrl + H', 'Mostrar ayuda'),
              _buildShortcutRow('F1', 'Ayuda contextual'),
              _buildShortcutRow('F5', 'Recargar datos'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShortcutRow(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarCuadrillasSemana(int semanaId) async {
    // Solo cargar los empleados de las cuadrillas existentes
    await _cargarEmpleadosDeCuadrillas();
  }


  // ✅ Nueva función para cargar empleados de todas las cuadrillas desde la BD
  Future<void> _cargarEmpleadosDeCuadrillas() async {
    if (idSemanaSeleccionada == null) return;

    try {
      for (int i = 0; i < _optionsCuadrilla.length; i++) {
        if (!mounted) break; // Salir si el widget ya no está montado
        
        final cuadrilla = _optionsCuadrilla[i];
        if (cuadrilla['id'] != null) {
          // Obtener empleados con datos de nómina completos
          List<Map<String, dynamic>> empleadosCuadrilla = 
              await obtenerNominaEmpleadosDeCuadrilla(
                idSemanaSeleccionada!,
                cuadrilla['id'],
              );
          
          // Actualizar la cuadrilla con los empleados de la BD solo si está montado
          if (mounted) {
            setState(() {
              // Mantener el orden original de los empleados
              _optionsCuadrilla[i]['empleados'] = List<Map<String, dynamic>>.from(empleadosCuadrilla);
            });
          }
        }
      }
      
      // 🔧 CRÍTICO: Si hay una cuadrilla seleccionada, actualizar también empleadosFiltrados
      if (mounted && cuadrillaSeleccionada != null) {
        final cuadrillaActual = _optionsCuadrilla.firstWhere(
          (c) => c['id'] == cuadrillaSeleccionada!['id'],
          orElse: () => <String, dynamic>{},
        );
        
        if (cuadrillaActual.isNotEmpty && cuadrillaActual['empleados'] != null) {
          setState(() {
            empleadosFiltrados = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
            empleadosNomina = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
            empleadosNominaTemp = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
            empleadosEnCuadrilla = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
            
            // Actualizar también la referencia de la cuadrilla seleccionada
            _selectedCuadrilla['empleados'] = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
            cuadrillaSeleccionada!['empleados'] = List<Map<String, dynamic>>.from(cuadrillaActual['empleados']);
          });
          
          // Actualizar estados de validación
          _puedeCapturarDatos = _validarPuedeCapturarDatos();
          
          print('✅ Empleados sincronizados para cuadrilla seleccionada: ${empleadosFiltrados.length} empleados');
        }
      }
      
      print('🔄 Empleados cargados para todas las cuadrillas desde BD');
    } catch (e) {
      print('❌ Error al cargar empleados de cuadrillas: $e');
    }
  }

  // Cargar semana activa automáticamente al abrir pantalla

  Future<void> _cargarCuadrillasHabilitadas() async {
    // 🚀 Verificar si necesitamos cargar o ya tenemos datos en cache
    if (semanaSeleccionada == null || idSemanaSeleccionada == null) {
      print('ℹ️ No hay semana activa, cargando cuadrillas básicas sin empleados');
      await _cargarCuadrillasBasicasSinCache();
      return;
    }

    print('� [CACHE] Verificando cache para semana ${idSemanaSeleccionada}');
    
    try {
      // Obtener cuadrillas del cache (carga automáticamente si es necesario)
      final cuadrillasFromCache = await _cuadrillasCache.getCuadrillas(
        idSemanaSeleccionada!,
        _loadCuadrillasBasicas,
        _loadEmpleadosEnBackground,
      );

      // Actualizar las opciones de cuadrilla con los datos del cache
      if (mounted) {
        setState(() {
          _optionsCuadrilla.clear();
          _optionsCuadrilla.addAll(cuadrillasFromCache);
        });
        
        print('📊 [CACHE] Cuadrillas cargadas desde cache: ${_optionsCuadrilla.length}');
      }

      // Escuchar actualizaciones del cache
      _cuadrillasCache.cuadrillasStream.listen((cuadrillas) {
        if (mounted) {
          setState(() {
            _optionsCuadrilla.clear();
            _optionsCuadrilla.addAll(cuadrillas);
          });
          print('🔄 [CACHE] Cuadrillas actualizadas desde stream: ${cuadrillas.length}');
        }
      });

    } catch (e) {
      print('❌ Error al cargar cuadrillas desde cache: $e');
      // Fallback a carga básica
      await _cargarCuadrillasBasicasSinCache();
    }
  }

  /// Carga cuadrillas básicas sin usar cache (fallback)
  Future<void> _cargarCuadrillasBasicasSinCache() async {
    final cuadrillasBD = await obtenerCuadrillasHabilitadas();
    
    if (mounted) {
      setState(() {
        _optionsCuadrilla.clear();
        _optionsCuadrilla.addAll(cuadrillasBD.map((c) => {
          ...c,
          'empleados': <Map<String, dynamic>>[],
        }).toList());
      });
      
      print('📊 Cargadas ${_optionsCuadrilla.length} cuadrillas básicas (sin cache)');
    }
  }

  /// Función para cargar cuadrillas básicas (usada por el cache)
  Future<List<Map<String, dynamic>>> _loadCuadrillasBasicas() async {
    print('🔄 [CACHE] Cargando cuadrillas básicas desde BD');
    return await obtenerCuadrillasHabilitadas();
  }

  /// Función para cargar empleados en background (usada por el cache)
  Future<void> _loadEmpleadosEnBackground(List<Map<String, dynamic>> cuadrillas) async {
    print('🔄 [CACHE] Iniciando carga de empleados en background');
    
    _isCuadrillasLoadingInBackground = true;
    
    // 🎯 CAMBIO: Mostrar notificación solo si hay muchas cuadrillas (más de 20)
    // Para pocas cuadrillas, solo mostrar un mensaje inicial sutil
    if (mounted) {
      if (cuadrillas.length > 20) {
        CuadrillasLoadingOverlay.show(
          context,
          totalCuadrillas: cuadrillas.length,
          cuadrillasProcessed: 0,
          currentCuadrilla: 'Iniciando carga...',
          showInBackground: true,
        );
      } else {
        // Para pocas cuadrillas: mostrar SnackBar inicial discreto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Cargando empleados de ${cuadrillas.length} cuadrillas...',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: AppColors.green.withOpacity(0.9),
          ),
        );
        print('🔄 [CARGA LIGERA] Cargando ${cuadrillas.length} cuadrillas sin bloquear UI');
      }
    }
    
    int erroresConsecutivos = 0;
    const int maxErroresPermitidos = 5;
    const int batchSize = 3;
    
    try {
      for (int batchStart = 0; batchStart < cuadrillas.length; batchStart += batchSize) {
        // Verificar si el widget sigue montado
        if (!mounted) break;
        
        final batchEnd = (batchStart + batchSize).clamp(0, cuadrillas.length);
        final batch = cuadrillas.sublist(batchStart, batchEnd);
        
        // Procesar lote actual
        final List<Future<void>> batchFutures = batch.asMap().entries.map((entry) async {
          final realIndex = batchStart + entry.key;
          final cuadrilla = entry.value;
          
          // Actualizar progreso
          _cuadrillasCache.updateLoadingProgress(
            cuadrillas.length, 
            realIndex, 
            cuadrilla['nombre'] ?? 'Sin nombre'
          );
          
          // Actualizar progreso de manera no intrusiva
          if (mounted) {
            if (cuadrillas.length > 20) {
              // Para muchas cuadrillas: usar overlay
              CuadrillasLoadingOverlay.hide();
              CuadrillasLoadingOverlay.show(
                context,
                totalCuadrillas: cuadrillas.length,
                cuadrillasProcessed: realIndex,
                currentCuadrilla: cuadrilla['nombre'] ?? 'Sin nombre',
                showInBackground: true,
              );
            } else {
              // Para pocas cuadrillas: usar SnackBar ocasional
              _mostrarProgresoCarga(realIndex, cuadrillas.length, cuadrilla['nombre'] ?? 'Sin nombre');
            }
          }
          
          try {
            final empleadosAsignados = await obtenerEmpleadosAsignadosCuadrilla(
              cuadrilla['id'], 
              idSemanaSeleccionada
            );
            
            // Actualizar cuadrilla en el cache
            cuadrillas[realIndex]['empleados'] = empleadosAsignados;
            _cuadrillasCache.updateCuadrilla(realIndex, cuadrillas[realIndex]);
            
            print('✅ [CACHE] Cuadrilla ${cuadrilla['nombre']}: ${empleadosAsignados.length} empleados');
            erroresConsecutivos = 0;
            
          } catch (e) {
            print('❌ [CACHE] Error en cuadrilla ${cuadrilla['nombre']}: $e');
            cuadrillas[realIndex]['empleados'] = [];
            _cuadrillasCache.updateCuadrilla(realIndex, cuadrillas[realIndex]);
            
            erroresConsecutivos++;
            if (erroresConsecutivos >= maxErroresPermitidos) {
              throw Exception('Demasiados errores consecutivos');
            }
          }
        }).toList();
        
        await Future.wait(batchFutures);
        
        // Pausa entre lotes
        if (batchEnd < cuadrillas.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      print('✅ [CACHE] Carga de empleados completada');
      
    } catch (e) {
      print('❌ [CACHE] Error en carga de empleados: $e');
    } finally {
      _isCuadrillasLoadingInBackground = false;
      
      // Ocultar loading overlay
      if (mounted) {
        CuadrillasLoadingOverlay.hide();
        
        // Mostrar notificación de completado
        final totalEmpleados = cuadrillas.fold<int>(0, 
          (sum, c) => sum + ((c['empleados'] as List?)?.length ?? 0));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Empleados cargados: $totalEmpleados en ${cuadrillas.length} cuadrillas',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        
        print('✅ [CACHE] Carga de empleados completada - Total: $totalEmpleados empleados');
      }
    }
  }

  Future<void> _loadInitialData() async {
    final empleados = await obtenerEmpleadosHabilitados();

    if (mounted) {
      setState(() {
        todosLosEmpleados = empleados;
        empleadosDisponiblesFiltrados = List.from(empleados);
        empleadosEnCuadrillaFiltrados = [];
      });
    }
  }

  Future<void> _seleccionarSemana() async {
    // 🎯 Validar cambios sin guardar antes de cambiar semana
    if (!await _validarCambiosSinGuardar('seleccionar una nueva semana')) {
      return;
    }
    
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => CustomWeekSelectorDialog(
        initialRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      ),
    );

    if (picked != null) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isCreandoSemana = true;
      });
      
      try {
        // Guardar en la base de datos
        final nuevaSemana = await SemanaService().crearNuevaSemana(
          picked.start,
          picked.end,
        );
        
        if (nuevaSemana != null) {
          if (!mounted || _isDisposed) return;
          setState(() {
            _startDate = nuevaSemana['fechaInicio'];
            _endDate = nuevaSemana['fechaFin'];
            _isWeekClosed = false;
            idSemanaSeleccionada = nuevaSemana['id'];
            semanaSeleccionada = nuevaSemana; // ✅ Asignar semanaSeleccionada
            
            // 🎯 Resetear estados del flujo al cambiar semana
            _bloqueadoPorFaltaSemana = false;
            _puedeArmarCuadrilla = true;
            _puedeCapturarDatos = false;
            
            // Limpiar cuadrilla seleccionada al cambiar semana
            cuadrillaSeleccionada = null;
            _selectedCuadrilla = {'nombre': '', 'empleados': []};
            empleadosFiltrados = [];
            empleadosNomina = [];
            marcarCambiosGuardados(); // Usar el método del mixin
          });

          // 🗑️ CACHE: Invalidar cache al cambiar de semana
          _invalidarCacheCuadrillas();

          // 🎯 Si la última opción fue "mantener", copiar empleados a la nueva semana ANTES de recargar
          if (_ultimaOpcionCierre == 'mantener') {
            await _copiarCuadrillasANuevaSemana(nuevaSemana['id']);
          }
          
          // ✅ Recargar cuadrillas con empleados para la nueva semana
          await _cargarCuadrillasHabilitadas();
          await _cargarCuadrillasSemana(nuevaSemana['id']);
          
          // ✅ Cargar empleados de todas las cuadrillas desde la BD
          await _cargarEmpleadosDeCuadrillas();
          
          // 🎯 Actualizar validaciones después del cambio
          _actualizarEstadosValidacion();
          
          // 📊 LLAMADA CALCULO TOTAL SEMANAL: Después de crear nueva semana
          // Se ejecuta con un pequeño delay para asegurar que el widget esté completamente montado
          Future.microtask(() => _actualizarTotalSemana());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Semana creada correctamente. Ahora puedes armar cuadrillas.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al guardar la semana en la base de datos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (!mounted || _isDisposed) return;
        setState(() {
          _isCreandoSemana = false;
        });
      }
    }
  }

  /// Configura una semana manualmente con fechas específicas
  void _onCerrarSemana() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una semana antes de cerrar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _showSupervisorLoginDialog();
  }
  Future<void> guardarNomina() async {
    final idSemana = semanaSeleccionada?['id'];
    final idCuadrilla = cuadrillaSeleccionada?['id'];
    final db = DatabaseService();
    
    if (idSemana == null || idCuadrilla == null) {
      return;
    }
    
    try {
      await db.connect();

      //  Función auxiliar para obtener valores numéricos seguros
      // 🔧 CORREGIDO: Envía 0 para valores vacíos, pero maneja correctamente los tipos
      int _getSafeIntValue(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.round();
        if (value is num) return value.round();
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) return 0; // String vacío = 0
          final parsed = num.tryParse(trimmed);
          return parsed?.round() ?? 0;
        }
        return 0;
      }

      // Función auxiliar para obtener valores de texto seguros
      // 🔧 CORREGIDO: Para campos de rancho, retornar "0" si está vacío
      String _getSafeStringValue(dynamic value) {
        if (value == null) return '0'; // NULL = "0"
        final stringValue = value.toString().trim();
        return stringValue.isEmpty ? '0' : stringValue; // String vacío = "0"
      }

      for (int i = 0; i < empleadosFiltrados.length; i++) {
        final empleado = empleadosFiltrados[i];
        final idEmpleado = empleado['id'];
        
        // ✅ Inicializar campos por defecto si no existen - 🔧 CORREGIDO: usar "0" para campos
        for (int day = 0; day < 7; day++) {
          empleado['dia_${day}_id'] ??= '0'; // 🔧 String "0" para actividades
          empleado['dia_${day}_s'] ??= 0;    // Entero 0 para sueldos
          empleado['dia_${day}_campo'] ??= '0'; // 🔧 String "0" para campos/ranchos
        }
        empleado['total'] ??= 0;
        empleado['debe'] ??= 0;
        empleado['subtotal'] ??= 0;
        empleado['comedor'] ??= 0;
        empleado['totalNeto'] ??= 0;

        // 🎯 VERIFICAR si ya existe registro para esta combinación exacta
        final result = await db.connection.query(
          '''SELECT id_nomina FROM nomina_empleados_semanal 
             WHERE id_empleado = @idEmp 
             AND id_semana = @idSemana 
             AND id_cuadrilla = @idCuadrilla''',
          substitutionValues: {
            'idEmp': idEmpleado, 
            'idSemana': idSemana,
            'idCuadrilla': idCuadrilla,
          },
        );

        // 🔧 Mapear correctamente desde la tabla hacia la BD
        // Tabla: dia_0_s, dia_1_s, ... dia_6_s → BD: dia_1, dia_2, ... dia_7
        // Incluye campos de actividad, salario y campo
        final data = {
          'id_empleado': idEmpleado,
          'id_semana': idSemana,
          'id_cuadrilla': idCuadrilla,
          'act_1': _getSafeIntValue(empleado['dia_0_id']), // dia_0_id de tabla → act_1 de BD
          'dia_1': _getSafeIntValue(empleado['dia_0_s']), // dia_0_s de tabla → dia_1 de BD
          'campo_1': _getSafeStringValue(empleado['dia_0_campo']), // dia_0_campo de tabla → campo_1 de BD
          'act_2': _getSafeIntValue(empleado['dia_1_id']), // dia_1_id de tabla → act_2 de BD
          'dia_2': _getSafeIntValue(empleado['dia_1_s']), // dia_1_s de tabla → dia_2 de BD
          'campo_2': _getSafeStringValue(empleado['dia_1_campo']), // dia_1_campo de tabla → campo_2 de BD
          'act_3': _getSafeIntValue(empleado['dia_2_id']), // dia_2_id de tabla → act_3 de BD
          'dia_3': _getSafeIntValue(empleado['dia_2_s']), // dia_2_s de tabla → dia_3 de BD
          'campo_3': _getSafeStringValue(empleado['dia_2_campo']), // dia_2_campo de tabla → campo_3 de BD
          'act_4': _getSafeIntValue(empleado['dia_3_id']), // dia_3_id de tabla → act_4 de BD
          'dia_4': _getSafeIntValue(empleado['dia_3_s']), // dia_3_s de tabla → dia_4 de BD
          'campo_4': _getSafeStringValue(empleado['dia_3_campo']), // dia_3_campo de tabla → campo_4 de BD
          'act_5': _getSafeIntValue(empleado['dia_4_id']), // dia_4_id de tabla → act_5 de BD
          'dia_5': _getSafeIntValue(empleado['dia_4_s']), // dia_4_s de tabla → dia_5 de BD
          'campo_5': _getSafeStringValue(empleado['dia_4_campo']), // dia_4_campo de tabla → campo_5 de BD
          'act_6': _getSafeIntValue(empleado['dia_5_id']), // dia_5_id de tabla → act_6 de BD
          'dia_6': _getSafeIntValue(empleado['dia_5_s']), // dia_5_s de tabla → dia_6 de BD
          'campo_6': _getSafeStringValue(empleado['dia_5_campo']), // dia_5_campo de tabla → campo_6 de BD
          'act_7': _getSafeIntValue(empleado['dia_6_id']), // dia_6_id de tabla → act_7 de BD
          'dia_7': _getSafeIntValue(empleado['dia_6_s']), // dia_6_s de tabla → dia_7 de BD
          'campo_7': _getSafeStringValue(empleado['dia_6_campo']), // dia_6_campo de tabla → campo_7 de BD
          'total': _getSafeIntValue(empleado['total']),
          'debe': _getSafeIntValue(empleado['debe']),
          'subtotal': _getSafeIntValue(empleado['subtotal']),
          'comedor': _getSafeIntValue(empleado['comedor']),
          'total_neto': _getSafeIntValue(empleado['totalNeto']),
        };

        // 🔧 DEBUG: Mostrar datos procesados que se van a guardar
        print('🔧 [DATOS PROCESADOS] ${empleado['nombre']}:');
        print('   - dia_1=${data['dia_1']}, dia_2=${data['dia_2']}, dia_3=${data['dia_3']}');
        print('   - dia_4=${data['dia_4']}, dia_5=${data['dia_5']}, dia_6=${data['dia_6']}, dia_7=${data['dia_7']}');
        print('   - campos: ${data['campo_1']}, ${data['campo_2']}, ${data['campo_3']}, ${data['campo_4']}, ${data['campo_5']}, ${data['campo_6']}, ${data['campo_7']}');
        print('   - total=${data['total']}, debe=${data['debe']}, subtotal=${data['subtotal']}');
        print('   - comedor=${data['comedor']}, total_neto=${data['total_neto']}');

        if (result.isNotEmpty) {
          // Si existe, actualiza
          print('� [UPDATE] Actualizando registro existente para empleado $idEmpleado');
          await db.connection.query(
            '''UPDATE nomina_empleados_semanal
               SET 
                 act_1 = @a1, dia_1 = @d1, campo_1 = @c1,
                 act_2 = @a2, dia_2 = @d2, campo_2 = @c2,
                 act_3 = @a3, dia_3 = @d3, campo_3 = @c3,
                 act_4 = @a4, dia_4 = @d4, campo_4 = @c4,
                 act_5 = @a5, dia_5 = @d5, campo_5 = @c5,
                 act_6 = @a6, dia_6 = @d6, campo_6 = @c6,
                 act_7 = @a7, dia_7 = @d7, campo_7 = @c7,
                 total = @total, debe = @debe, subtotal = @subtotal, 
                 comedor = @comedor, total_neto = @neto
               WHERE id_empleado = @idEmp AND id_semana = @idSemana AND id_cuadrilla = @idCuadrilla
            ''',
            substitutionValues: {
              'a1': data['act_1'], 'd1': data['dia_1'], 'c1': data['campo_1'],
              'a2': data['act_2'], 'd2': data['dia_2'], 'c2': data['campo_2'],
              'a3': data['act_3'], 'd3': data['dia_3'], 'c3': data['campo_3'],
              'a4': data['act_4'], 'd4': data['dia_4'], 'c4': data['campo_4'],
              'a5': data['act_5'], 'd5': data['dia_5'], 'c5': data['campo_5'],
              'a6': data['act_6'], 'd6': data['dia_6'], 'c6': data['campo_6'],
              'a7': data['act_7'], 'd7': data['dia_7'], 'c7': data['campo_7'],
              'total': data['total'],
              'debe': data['debe'],
              'subtotal': data['subtotal'],
              'comedor': data['comedor'],
              'neto': data['total_neto'],
              'idEmp': idEmpleado,
              'idSemana': idSemana,
              'idCuadrilla': idCuadrilla,
            },
          );
          print('✅ [UPDATE EXITOSO] Empleado $idEmpleado actualizado');
        } else {
          // Si no existe, insertar nuevo registro
          print('➕ [INSERT] Creando nuevo registro para empleado $idEmpleado');
          await db.connection.query(
            '''INSERT INTO nomina_empleados_semanal (
                 id_empleado, id_semana, id_cuadrilla,
                 act_1, dia_1, campo_1,
                 act_2, dia_2, campo_2,
                 act_3, dia_3, campo_3,
                 act_4, dia_4, campo_4,
                 act_5, dia_5, campo_5,
                 act_6, dia_6, campo_6,
                 act_7, dia_7, campo_7,
                 total, debe, subtotal, comedor, total_neto
               ) VALUES (
                 @idEmp, @idSemana, @idCuadrilla,
                 @a1, @d1, @c1,
                 @a2, @d2, @c2,
                 @a3, @d3, @c3,
                 @a4, @d4, @c4,
                 @a5, @d5, @c5,
                 @a6, @d6, @c6,
                 @a7, @d7, @c7,
                 @total, @debe, @subtotal, @comedor, @neto
               )
            ''',
            substitutionValues: {
              'idEmp': idEmpleado,
              'idSemana': idSemana,
              'idCuadrilla': idCuadrilla,
              'a1': data['act_1'], 'd1': data['dia_1'], 'c1': data['campo_1'],
              'a2': data['act_2'], 'd2': data['dia_2'], 'c2': data['campo_2'],
              'a3': data['act_3'], 'd3': data['dia_3'], 'c3': data['campo_3'],
              'a4': data['act_4'], 'd4': data['dia_4'], 'c4': data['campo_4'],
              'a5': data['act_5'], 'd5': data['dia_5'], 'c5': data['campo_5'],
              'a6': data['act_6'], 'd6': data['dia_6'], 'c6': data['campo_6'],
              'a7': data['act_7'], 'd7': data['dia_7'], 'c7': data['campo_7'],
              'total': data['total'],
              'debe': data['debe'],
              'subtotal': data['subtotal'],
              'comedor': data['comedor'],
              'neto': data['total_neto'],
            },
          );
          print('✅ [INSERT EXITOSO] Empleado $idEmpleado creado');
        } 
      }
      
    //  print("🎉 [GUARDADO COMPLETO] Nómina guardada correctamente - ${empleadosFiltrados.length} empleados procesados");
    } catch (e) {
      //print("💥 [ERROR CRÍTICO] Error al guardar nómina: $e");
      //print("🔍 Stack trace: ${StackTrace.current}");
      rethrow;
    } finally {
      await db.close();
      //print("🔌 [CONEXIÓN] Base de datos cerrada");
    }
  }

  Future<List<Map<String, dynamic>>> obtenerNominaEmpleadosDeCuadrilla(
    int semanaId,
    int cuadrillaId,
  ) async {
    final db = DatabaseService();
    await db.connect();

    try {
      // 🔧 PASO 1: Obtener TODOS los empleados asignados a la cuadrilla (desde guardarEmpleadosCuadrillaSemana)
      final empleadosAsignadosResult = await db.connection.query('''
        SELECT DISTINCT ecs.id_empleado
        FROM nomina_empleados_semanal ecs
        WHERE ecs.id_semana = @semanaId AND ecs.id_cuadrilla = @cuadrillaId;
      ''', substitutionValues: {'semanaId': semanaId, 'cuadrillaId': cuadrillaId});

      if (empleadosAsignadosResult.isEmpty) {
        print('⚠️ No hay empleados asignados a la cuadrilla $cuadrillaId en la semana $semanaId');
        await db.close();
        return [];
      }

      // 🔧 PASO 2: Para cada empleado asignado, obtener sus datos básicos + datos de nómina si existen
      List<Map<String, dynamic>> empleadosCompletos = [];

      for (final row in empleadosAsignadosResult) {
        final empleadoId = row[0] as int;

        // Obtener datos básicos del empleado
        final empleadoBasicoResult = await db.connection.query('''
          SELECT 
            e.id_empleado,
            e.codigo,
            CONCAT(e.nombre, ' ', e.apellido_paterno, ' ', e.apellido_materno) AS nombre
          FROM empleados e
          WHERE e.id_empleado = @empleadoId;
        ''', substitutionValues: {'empleadoId': empleadoId});

        if (empleadoBasicoResult.isEmpty) continue;

        final empleadoBasico = empleadoBasicoResult.first;

        // Obtener datos de nómina si existen
        final nominaResult = await db.connection.query('''
          SELECT 
            n.dia_1, n.act_1, n.campo_1,
            n.dia_2, n.act_2, n.campo_2,
            n.dia_3, n.act_3, n.campo_3,
            n.dia_4, n.act_4, n.campo_4,
            n.dia_5, n.act_5, n.campo_5,
            n.dia_6, n.act_6, n.campo_6,
            n.dia_7, n.act_7, n.campo_7,
            n.total,
            n.debe,
            n.subtotal,
            n.comedor, 
            n.total_neto
          FROM nomina_empleados_semanal n
          WHERE n.id_empleado = @empleadoId AND n.id_semana = @semanaId AND n.id_cuadrilla = @cuadrillaId;
        ''', substitutionValues: {
          'empleadoId': empleadoId,
          'semanaId': semanaId,
          'cuadrillaId': cuadrillaId
        });

        // 🔧 COMBINAR datos básicos + datos de nómina (o valores por defecto si no hay datos)
        Map<String, dynamic> empleadoCompleto;
        
        if (nominaResult.isNotEmpty) {
          // El empleado tiene datos de nómina guardados
          final nominaData = nominaResult.first;
          empleadoCompleto = {
            'codigo': empleadoBasico[1]?.toString() ?? '',
            'nombre': empleadoBasico[2]?.toString() ?? '',
            'id': empleadoBasico[0]?.toString() ?? '',
            // Mapear de BD a formato de tabla (ahora incluye campo) - 🔧 CORREGIDO: usar "0" para campos vacíos
            'dia_0_s': nominaData[0]?.toString() ?? '0', // dia_1 BD → dia_0_s tabla
            'dia_0_id': nominaData[1]?.toString() ?? '0', // act_1 BD → dia_0_id tabla
            'dia_0_campo': nominaData[2]?.toString() ?? '0', // campo_1 BD → dia_0_campo tabla
            'dia_1_s': nominaData[3]?.toString() ?? '0', // dia_2 BD → dia_1_s tabla
            'dia_1_id': nominaData[4]?.toString() ?? '0', // act_2 BD → dia_1_id tabla
            'dia_1_campo': nominaData[5]?.toString() ?? '0', // campo_2 BD → dia_1_campo tabla
            'dia_2_s': nominaData[6]?.toString() ?? '0', // dia_3 BD → dia_2_s tabla
            'dia_2_id': nominaData[7]?.toString() ?? '0', // act_3 BD → dia_2_id tabla
            'dia_2_campo': nominaData[8]?.toString() ?? '0', // campo_3 BD → dia_2_campo tabla
            'dia_3_s': nominaData[9]?.toString() ?? '0', // dia_4 BD → dia_3_s tabla
            'dia_3_id': nominaData[10]?.toString() ?? '0', // act_4 BD → dia_3_id tabla
            'dia_3_campo': nominaData[11]?.toString() ?? '0', // campo_4 BD → dia_3_campo tabla
            'dia_4_s': nominaData[12]?.toString() ?? '0', // dia_5 BD → dia_4_s tabla
            'dia_4_id': nominaData[13]?.toString() ?? '0', // act_5 BD → dia_4_id tabla
            'dia_4_campo': nominaData[14]?.toString() ?? '0', // campo_5 BD → dia_4_campo tabla
            'dia_5_s': nominaData[15]?.toString() ?? '0', // dia_6 BD → dia_5_s tabla
            'dia_5_id': nominaData[16]?.toString() ?? '0', // act_6 BD → dia_5_id tabla
            'dia_5_campo': nominaData[17]?.toString() ?? '0', // campo_6 BD → dia_5_campo tabla
            'dia_6_s': nominaData[18]?.toString() ?? '0', // dia_7 BD → dia_6_s tabla
            'dia_6_id': nominaData[19]?.toString() ?? '0', // act_7 BD → dia_6_id tabla
            'dia_6_campo': nominaData[20]?.toString() ?? '0', // campo_7 BD → dia_6_campo tabla
            'total': nominaData[21]?.toString() ?? '0',
            'debe': nominaData[22]?.toString() ?? '0',
            'subtotal': nominaData[23]?.toString() ?? '0',
            'comedor': nominaData[24]?.toString() ?? '0',
            'totalNeto': nominaData[25]?.toString() ?? '0',
          };
          print('✅ Empleado ${empleadoCompleto['nombre']} con datos de nómina cargados');
        } else {
          // El empleado no tiene datos de nómina, usar valores por defecto
          empleadoCompleto = {
            'codigo': empleadoBasico[1]?.toString() ?? '',
            'nombre': empleadoBasico[2]?.toString() ?? '',
            'id': empleadoBasico[0]?.toString() ?? '',
            // Valores por defecto para empleado nuevo - 🔧 CORREGIDO: usar "0" para campos vacíos
            'dia_0_s': '0', 'dia_0_id': '0', 'dia_0_campo': '0',
            'dia_1_s': '0', 'dia_1_id': '0', 'dia_1_campo': '0',
            'dia_2_s': '0', 'dia_2_id': '0', 'dia_2_campo': '0',
            'dia_3_s': '0', 'dia_3_id': '0', 'dia_3_campo': '0',
            'dia_4_s': '0', 'dia_4_id': '0', 'dia_4_campo': '0',
            'dia_5_s': '0', 'dia_5_id': '0', 'dia_5_campo': '0',
            'dia_6_s': '0', 'dia_6_id': '0', 'dia_6_campo': '0',
            'total': '0',
            'debe': '0',
            'subtotal': '0',
            'comedor': '0',
            'totalNeto': '0',
          };
          print('📝 Empleado ${empleadoCompleto['nombre']} nuevo sin datos previos');
        }

        empleadosCompletos.add(empleadoCompleto);
      }

      print('📊 [CARGAR COMPLETO] ${empleadosCompletos.length} empleados cargados (incluyendo nuevos)');
      return empleadosCompletos;

    } finally {
      await db.close();
    }
  }

  Future<void> _cerrarSemanaActual({String opcion = 'resetear', String? usuarioAutorizado}) async {
    if (_startDate == null || _endDate == null) return;

    // � INSERTAR DATOS DIRECTAMENTE EN HISTORIAL AL CERRAR SEMANA
    print('🔥 [HISTORIAL] INSERTANDO DATOS DIRECTAMENTE EN nomina_empleados_historial...');
    
    if (idSemanaSeleccionada != null) {
      final db = DatabaseService();
      try {
        await db.connect();
        
        // Obtener TODOS los datos de nomina_empleados_semanal para esta semana
        final datosParaHistorial = await db.connection.query('''
          SELECT id_empleado, id_semana, id_cuadrilla, 
                 dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
                 act_1, act_2, act_3, act_4, act_5, act_6, act_7,
                 campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
                 total, debe, subtotal, comedor
          FROM nomina_empleados_semanal 
          WHERE id_semana = @idSemana
        ''', substitutionValues: {'idSemana': idSemanaSeleccionada});
        
        print('🔥 [HISTORIAL] Encontrados ${datosParaHistorial.length} registros en nomina_empleados_semanal');
        
        if (datosParaHistorial.isNotEmpty) {
          // Borrar datos existentes en historial para esta semana
          await db.connection.execute('DELETE FROM nomina_empleados_historial WHERE id_semana = @idSemana',
              substitutionValues: {'idSemana': idSemanaSeleccionada});
          
          // Insertar cada registro directamente en historial
          int insertados = 0;
          for (var row in datosParaHistorial) {
            try {
              await db.connection.execute('''
                INSERT INTO nomina_empleados_historial (
                  id_empleado, id_semana, id_cuadrilla, 
                  dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
                  act_1, act_2, act_3, act_4, act_5, act_6, act_7,
                  campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
                  total, debe, subtotal, comedor, fecha_cierre, usuario_cierre
                ) VALUES (
                  @idEmpleado, @idSemana, @idCuadrilla, 
                  @dia1, @dia2, @dia3, @dia4, @dia5, @dia6, @dia7,
                  @act1, @act2, @act3, @act4, @act5, @act6, @act7,
                  @campo1, @campo2, @campo3, @campo4, @campo5, @campo6, @campo7,
                  @total, @debe, @subtotal, @comedor, CURRENT_TIMESTAMP, @usuario
                )
              ''', substitutionValues: {
                'idEmpleado': row[0],
                'idSemana': row[1],
                'idCuadrilla': row[2],
                // Días (índices 3-9)
                'dia1': row[3] ?? 0,
                'dia2': row[4] ?? 0,
                'dia3': row[5] ?? 0,
                'dia4': row[6] ?? 0,
                'dia5': row[7] ?? 0,
                'dia6': row[8] ?? 0,
                'dia7': row[9] ?? 0,  // ¡AGREGADO DIA_7!
                // Actividades (índices 10-16)
                'act1': row[10] ?? 0,
                'act2': row[11] ?? 0,
                'act3': row[12] ?? 0,
                'act4': row[13] ?? 0,
                'act5': row[14] ?? 0,
                'act6': row[15] ?? 0,
                'act7': row[16] ?? 0,  // ¡AGREGADO ACT_7!
                // Campos (índices 17-23)
                'campo1': row[17]?.toString() ?? "0",
                'campo2': row[18]?.toString() ?? "0",
                'campo3': row[19]?.toString() ?? "0",
                'campo4': row[20]?.toString() ?? "0",
                'campo5': row[21]?.toString() ?? "0",
                'campo6': row[22]?.toString() ?? "0",
                'campo7': row[23]?.toString() ?? "0",  // ¡AGREGADO CAMPO_7!
                // Totales (índices 24-27)
                'total': row[24] ?? 0,
                'debe': row[25] ?? 0,
                'subtotal': row[26] ?? 0,
                'comedor': row[27] ?? 0,
                'usuario': usuarioAutorizado ?? 'Sistema',
              });
              insertados++;
            } catch (e) {
              print('❌ Error al insertar registro en historial: $e');
            }
          }
          
          // Verificar que se guardaron
          final verificacion = await db.connection.query(
              'SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @idSemana',
              substitutionValues: {'idSemana': idSemanaSeleccionada});
          
          print('🔥 [HISTORIAL] ✅ INSERTADOS: $insertados registros');
          print('🔥 [HISTORIAL] ✅ VERIFICADO: ${verificacion.first[0]} registros en historial');
          
        } else {
          print('⚠️ [HISTORIAL] No hay datos en nomina_empleados_semanal para semana $idSemanaSeleccionada');
        }
        
        await db.close();
      } catch (e) {
        print('❌ [HISTORIAL] ERROR CRÍTICO: $e');
      }
    }

    // �🔄 Guardar la opción seleccionada para uso futuro
    _ultimaOpcionCierre = opcion;

    // Crear una lista de todas las cuadrillas con sus empleados y datos completos
    List<Map<String, dynamic>> cuadrillasInfo = [];

    // Primero procesamos todas las cuadrillas de _optionsCuadrilla
    for (var cuadrilla in _optionsCuadrilla) {
      List<Map<String, dynamic>> empleadosConTablas = [];

      // Si es la cuadrilla actual, usamos empleadosFiltrados
      if (cuadrilla['nombre'] == _selectedCuadrilla['nombre']) {
        empleadosConTablas =
            empleadosFiltrados.map((emp) {
              return _procesarEmpleado(emp);
            }).toList();
      } else {
        // Para otras cuadrillas, procesamos sus empleados si tienen
        final empleadosCuadrilla = List<Map<String, dynamic>>.from(
          cuadrilla['empleados'] ?? [],
        );
        empleadosConTablas =
            empleadosCuadrilla.map((emp) {
              return _procesarEmpleado(emp);
            }).toList();
      }
      // Calculamos el total de la cuadrilla (será 0 si no tiene empleados)
      final totalCuadrilla = empleadosConTablas.fold<double>(
        0.0,
        (sum, emp) =>
            sum + (emp['tabla_principal']?['neto'] as num? ?? 0).toDouble(),
      );

      // Agregamos la cuadrilla siempre, tenga o no empleados
      cuadrillasInfo.add({
        'nombre': cuadrilla['nombre'],
        'empleados': empleadosConTablas,
        'total': totalCuadrilla,
      });
    }

    // Calcular el total de todas las cuadrillas
    final totalSemana = cuadrillasInfo.fold<double>(
      0.0,
      (sum, cuadrilla) => sum + (cuadrilla['total'] as double),
    );

    final semanaCerrada = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'fechaInicio': _startDate,
      'fechaFin': _endDate,
      'cuadrillas': cuadrillasInfo,
      'totalSemana': totalSemana,
      'cuadrillaSeleccionada': 0,
    };

    // 🆕 Marcar la semana como cerrada en la base de datos
    if (idSemanaSeleccionada != null) {
      print('🚀🚀🚀 [UI] INICIANDO CIERRE DE SEMANA $idSemanaSeleccionada DESDE LA INTERFAZ!!! 🚀🚀🚀');
      print('🔍 [UI] Verificando idSemanaSeleccionada: $idSemanaSeleccionada (tipo: ${idSemanaSeleccionada.runtimeType})');
      print('👤 [UI] Usuario autorizado: $usuarioAutorizado');
      
      // Obtener datos actuales de nómina para enviar al historial
      final datosNomina = await _obtenerDatosNominaSemanal(idSemanaSeleccionada!);
      print('📊 [UI] Datos de nómina obtenidos: ${datosNomina?.length ?? 0} registros');
      
      // Determinar si mantener cuadrillas según la opción elegida
      final mantenerCuadrillas = (opcion == 'mantener');
      
      final cerradaExitosamente = await cerrarSemanaEnBD(
        idSemanaSeleccionada!, 
        autorizadoPor: usuarioAutorizado,
        datosNomina: datosNomina,
        mantenerCuadrillas: mantenerCuadrillas
      );
      print('🔄🔄🔄 [UI] RESULTADO DEL CIERRE: $cerradaExitosamente 🔄🔄🔄');
      if (!cerradaExitosamente) {
        print('❌❌❌ ERROR: NO SE PUDO MARCAR LA SEMANA COMO CERRADA EN BD ❌❌❌');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error: No se pudo cerrar la semana en la base de datos'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        // ⛔ DETENER el proceso si falla el cierre en BD
        return;
      } else {
        print('✅✅✅ SEMANA MARCADA COMO CERRADA EN BD EXITOSAMENTE ✅✅✅');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Semana cerrada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      print('⚠️⚠️⚠️ [UI] NO HAY idSemanaSeleccionada PARA CERRAR ⚠️⚠️⚠️');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: No hay semana seleccionada para cerrar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted || _isDisposed) return;
    setState(() {
      semanasCerradas.add(semanaCerrada);
      _isWeekClosed = true;

      // 🔄 Reiniciar completamente el estado para nueva semana
      _startDate = null;
      _endDate = null;
      idSemanaSeleccionada = null;
      semanaSeleccionada = null;
      
      // 🔄 Deseleccionar y limpiar cuadrilla actual
      cuadrillaSeleccionada = null;
      _selectedCuadrilla = {'nombre': '', 'empleados': []};
      
      // 🔄 Limpiar listas de empleados
      empleadosFiltrados = [];
      empleadosEnCuadrilla = [];
      empleadosNomina = [];
      empleadosNominaTemp = [];
      
      // 🔄 Resetear estados de validación del flujo
      _bloqueadoPorFaltaSemana = true;
      _puedeArmarCuadrilla = false;
      _puedeCapturarDatos = false;
      marcarCambiosGuardados(); // Usar el método del mixin
      
      // 🔄 Cerrar diálogo de armar cuadrilla si está abierto
      showArmarCuadrilla = false;
      
      // 🔄 Comportamiento según opción seleccionada
      if (opcion == 'resetear') {
        // 🔄 Desarmar todas las cuadrillas - quitar todos los empleados asignados
        for (var cuadrilla in _optionsCuadrilla) {
          cuadrilla['empleados'] = [];
        }
        _cuadrillasTemporales = []; // Limpiar temporales
        print('🔄 Opción RESETEAR: Cuadrillas desarmadas completamente');
      } else if (opcion == 'mantener') {
        // 🎯 Mantener cuadrillas armadas pero resetear solo datos de nómina
        _cuadrillasTemporales = List<Map<String, dynamic>>.from(_optionsCuadrilla.map((cuadrilla) => {
          'id': cuadrilla['id'],
          'nombre': cuadrilla['nombre'],
          'empleados': List<Map<String, dynamic>>.from(cuadrilla['empleados'] ?? [])
        }));
        print('🎯 Opción MANTENER: Conservando ${_cuadrillasTemporales.length} cuadrillas en temporales');
        
        // Debug: mostrar cuántos empleados se están conservando
        for (var cuadrilla in _cuadrillasTemporales) {
          final empleados = cuadrilla['empleados'] as List;
          print('   - ${cuadrilla['nombre']}: ${empleados.length} empleados');
        }
        // Las cuadrillas en _optionsCuadrilla mantienen sus empleados asignados
        // Solo se resetearán los valores de sueldos/actividades cuando se cree nueva semana
      }
      
      // 🔄 Resetear datos originales para detectar cambios
      _originalNominaData = {};
      _originalDataBeforeEditing = {};
      
      // 🔄 Resetear estado de semana activa
      _haySemanaActiva = false;
      semanaActiva = false;
    });

    // 🔄 Recargar cuadrillas habilitadas solo si se eligió resetear
    if (opcion == 'resetear') {
      await _cargarCuadrillasHabilitadas();
      print('🔄 Cuadrillas recargadas desde BD (resetear)');
    } else {
      print('🎯 Cuadrillas mantenidas en memoria (mantener)');
    }

    // 🎯 Mensaje específico según la opción seleccionada
    final mensajeCierre = opcion == 'mantener'
        ? '✅ Semana cerrada correctamente. Las cuadrillas se mantendrán para la próxima semana.'
        : '✅ Semana cerrada correctamente. Las cuadrillas se han desarmado y el sistema está listo para una nueva semana.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensajeCierre),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
    
    // 🎯 Mostrar mensaje guía para empezar nueva semana
    Future.delayed(Duration(seconds: 6), () {
      if (mounted) {
        _mostrarMensajeGuia(
          'Sistema reiniciado. Ahora puedes seleccionar una nueva semana para empezar.',
          icon: Icons.restart_alt,
          accionSugerida: 'Haz clic en "Seleccionar semana" para continuar'
        );
      }
    });
  }

  /// 🎯 Función para copiar empleados de cuadrillas a una nueva semana (opción mantener)
  Future<void> _copiarCuadrillasANuevaSemana(int nuevaSemanaId) async {
    try {
      print('🎯 Iniciando copia de cuadrillas a nueva semana $nuevaSemanaId');
      print('🎯 Cuadrillas temporales disponibles: ${_cuadrillasTemporales.length}');
      
      if (_cuadrillasTemporales.isEmpty) {
        print('⚠️ No hay cuadrillas temporales para copiar');
        return;
      }
      
      // Obtener todas las cuadrillas que tienen empleados asignados
      int empleadosCopiadosTotal = 0;
      
      for (var cuadrilla in _cuadrillasTemporales) {
        final empleadosCuadrilla = List<Map<String, dynamic>>.from(
          cuadrilla['empleados'] ?? []
        );
        
        if (empleadosCuadrilla.isNotEmpty) {
          print('📋 Copiando cuadrilla "${cuadrilla['nombre']}" con ${empleadosCuadrilla.length} empleados');
          
          // Usar el servicio de semana para guardar los empleados en la nueva semana
          await SemanaService().guardarEmpleadosCuadrillaSemana(
            semanaId: nuevaSemanaId,
            cuadrillaId: cuadrilla['id'],
            empleados: empleadosCuadrilla,
          );
          
          empleadosCopiadosTotal += empleadosCuadrilla.length;
          print('✅ Cuadrilla "${cuadrilla['nombre']}" copiada exitosamente');
        }
      }
      
      if (empleadosCopiadosTotal > 0) {
        print('🎉 Copia completada: $empleadosCopiadosTotal empleados copiados a nueva semana');
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.group, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Cuadrillas mantenidas: $empleadosCopiadosTotal empleados copiados a la nueva semana'
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('ℹ️ No había empleados asignados para copiar');
      }
      
    } catch (e) {
      print('❌ Error al copiar cuadrillas a nueva semana: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('❌ Error al copiar cuadrillas: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    
    // 🔄 Limpiar cuadrillas temporales después de copiar
    _cuadrillasTemporales = [];
    print('🧹 Cuadrillas temporales limpiadas');
  }

  // Función auxiliar para procesar los datos de un empleado
  Map<String, dynamic> _procesarEmpleado(Map<String, dynamic> emp) {
    final numDays = _endDate!.difference(_startDate!).inDays + 1;

    // Tabla Principal: días normales y total - usar el formato correcto de la BD
    final diasNormales = List.generate(
      numDays,
      (i) => double.tryParse(emp['dia_${i}_s']?.toString() ?? '0') ?? 0.0,
    );

    // Calcular totales
    final totalDiasNormales = diasNormales.fold<double>(
      0,
      (sum, dia) => sum + dia,
    );

    // Calcular deducciones - usando datos reales de la BD
    final debe = double.tryParse(emp['debe']?.toString() ?? '0') ?? 0.0;
    final comedorValue = double.tryParse(emp['comedor']?.toString() ?? '0') ?? 0.0;

    // Calcular subtotal y total neto
    final subtotal = totalDiasNormales - debe;
    final totalNeto = subtotal - comedorValue;

    // Crear objeto con todos los datos
    return {
      ...emp, // Mantener datos básicos del empleado
      'totalNeto': totalNeto, // Agregar totalNeto directamente
      'tabla_principal': {
        'dias': diasNormales,
        'total': totalDiasNormales,
        'debe': debe,
        'comedor': comedorValue,
        'subtotal': subtotal,
        'neto': totalNeto,
      },
    };
  }

  /// ✨ Función para refresh manual de la tabla
  Future<void> _refreshTablaManual() async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Actualizando tabla...'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );

      // ✅ 1. Recargar cuadrillas si hay semana seleccionada
      if (idSemanaSeleccionada != null) {
        await _cargarCuadrillasSemana(idSemanaSeleccionada!);
        await _cargarEmpleadosDeCuadrillas();
      }
      
      // ✅ 2. Recargar datos completos de nómina
      await cargarDatosNomina();
      
      // ✅ 3. Actualizar la cuadrilla seleccionada si existe
      if (_selectedCuadrilla['nombre'] != null && mounted) {
        final cuadrillaActualizada = _optionsCuadrilla.firstWhere(
          (c) => c['nombre'] == _selectedCuadrilla['nombre'],
          orElse: () => {},
        );
        
        if (cuadrillaActualizada.isNotEmpty) {
          setState(() {
            _selectedCuadrilla = cuadrillaActualizada;
            cuadrillaSeleccionada = cuadrillaActualizada;
            empleadosEnCuadrilla = List<Map<String, dynamic>>.from(
              cuadrillaActualizada['empleados'] ?? []
            );
          });
        }
      }
      
      // ✅ 4. Recalcular totales
      for (var empleado in empleadosFiltrados) {
        _recalcularTotalesEmpleado(empleado);
      }
      
      // ✅ 5. Guardar estado original
      if (mounted) {
        _saveOriginalData();
        marcarCambiosGuardados();
        
        // 🔄 Habilitar actualización del total semanal para refresh manual
        _puedeActualizarTotal = true;
        _actualizarTotalSemana();
      }
      
      // ✅ 6. Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Tabla actualizada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error en refresh manual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al actualizar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarSemanasCerradas() {
    if (!mounted || _isDisposed) return;
    
    print('\n🔵🔵🔵 [BOTÓN HISTORIAL] PRESIONADO 🔵🔵🔵');
    print('🔍 [BOTÓN HISTORIAL] semanasCerradas.length en memoria: ${semanasCerradas.length}');
    
    // 🔍 DEBUG: Imprimir información antes de mostrar
    for (int i = 0; i < semanasCerradas.length; i++) {
      final semana = semanasCerradas[i];
      print('  📋 Semana $i en memoria:');
      print('    - ID: ${semana['id']}');
      print('    - Fechas: ${semana['fechaInicio']} - ${semana['fechaFin']}');
      print('    - Cuadrillas: ${(semana['cuadrillas'] as List).length}');
      print('    - Total semana: \$${semana['totalSemana']}');
      
      final cuadrillas = semana['cuadrillas'] as List;
      for (int j = 0; j < cuadrillas.length && j < 3; j++) { // Solo primeras 3 cuadrillas
        final cuadrilla = cuadrillas[j];
        print('      🔸 ${cuadrilla['nombre']}: ${cuadrilla['empleados']?.length ?? 0} empleados, Total: \$${cuadrilla['total']}');
      }
      if (cuadrillas.length > 3) {
        print('      ... y ${cuadrillas.length - 3} cuadrillas más');
      }
    }
    
    if (!mounted || _isDisposed) return;
    
    setState(() {
      showSemanasCerradas = true;
      semanaCerradaSeleccionada = null;
    });
    
    print('🔵🔵🔵 [BOTÓN HISTORIAL] ESTADO ACTUALIZADO 🔵🔵🔵\n');
  }

  void _showSupervisorLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => NominaSupervisorAuthWidget(
            onAuthSuccess: (String usuarioAutenticado) async {
              Navigator.of(context).pop();
              
              // 🔄 Crear backup antes de cerrar semana
              await _crearBackupAntesDeCarrar();
              
              // Pasar el usuario autenticado al método de cierre
              _mostrarResumenCuadrillasYCerrar(usuarioAutorizado: usuarioAutenticado);
            },
            onClose: () => Navigator.of(context).pop(),
          ),
    );
  }

  void _toggleArmarCuadrilla() {
    // 🎯 Ahora se puede armar cuadrilla sin necesidad de semana
    // Solo mostrar mensaje informativo si no hay semana pero permitir continuar
    if (semanaSeleccionada == null) {
      _mostrarMensajeGuia(
        'Puedes armar cuadrillas sin tener una semana activa. Para capturar datos necesitarás seleccionar una semana.',
        icon: Icons.info_outline,
        accionSugerida: 'Continúa armando la cuadrilla'
      );
    }
    
    if (showArmarCuadrilla) {
      // Cuando ya está abierto, guardar cambios
      // Asegurarnos de actualizar la lista real de empleados en la cuadrilla
      // antes de cerrar el diálogo (guardamos lo que está en empleadosEnCuadrilla)
      if (!mounted || _isDisposed) return;
      setState(() {
        // Actualizamos la lista real en _selectedCuadrilla
        _selectedCuadrilla['empleados'] = List<Map<String, dynamic>>.from(
          empleadosEnCuadrilla,
        );
      });

      // Al cerrar el diálogo, mostrar opción de mantener datos
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return NominaActualizarCuadrillaWidget(
            empleadosExistentes: empleadosFiltrados,
            empleadosCompletoCuadrilla: _selectedCuadrilla['empleados'] ?? [],
            onMantenerDatos: () {
              // Mantener los datos existentes
              if (!mounted || _isDisposed) return;
              setState(() {
                // Crear un mapa de los empleados existentes para mantener sus datos
                final empleadosExistentesMap = Map.fromEntries(
                  empleadosFiltrados.map((e) => MapEntry(e['id'], e)),
                );
                final listaCompleta = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'] ?? [],
                );
                _selectedCuadrilla['empleados'] =
                    listaCompleta.map((empleado) {
                      if (empleadosExistentesMap.containsKey(empleado['id'])) {
                        return empleadosExistentesMap[empleado['id']]!;
                      } else {
                        return {
                          'id': empleado['id'],
                          'clave': empleado['id'],
                          'nombre': empleado['nombre'],
                          'puesto': empleado['puesto'] ?? 'Jornalero',
                          'dias': 0,
                          'total': 0.0,
                          'sueldoDiario': 200.0,
                        };
                      }
                    }).toList();

                empleadosFiltrados = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'],
                );
                showArmarCuadrilla = false;
              });
            },
            onEmpezarDeCero: () {
              // Reiniciar con datos nuevos
              if (!mounted || _isDisposed) return;
              setState(() {
                final listaCompleta = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'] ?? [],
                );
                _selectedCuadrilla['empleados'] =
                    listaCompleta.map((empleado) {
                      return {
                        'id': empleado['id'],
                        'clave': empleado['id'],
                        'nombre': empleado['nombre'],
                        'puesto': empleado['puesto'] ?? 'Jornalero',
                        'dias': 0,
                        'total': 0.0,
                        'sueldoDiario': 200.0,
                      };
                    }).toList();

                empleadosFiltrados = List<Map<String, dynamic>>.from(
                  _selectedCuadrilla['empleados'],
                );
                showArmarCuadrilla = false;
              });
            },
            onClose: () => Navigator.of(context).pop(),
          );
        },
      );
    } else {
      // Al abrir el diálogo, resetear selecciones y cargar empleados actuales
      if (!mounted || _isDisposed) return;
      setState(() {
        showArmarCuadrilla = true;

        // Buscar la cuadrilla actual en _optionsCuadrilla para obtener los empleados más actualizados
        final cuadrillaActualizada = _optionsCuadrilla.firstWhere(
          (c) => c['nombre'] == _selectedCuadrilla['nombre'],
          orElse: () => _selectedCuadrilla,
        );

        print('🔍 Debug - Cuadrilla seleccionada: ${_selectedCuadrilla['nombre']}');
        print('🔍 Debug - Cuadrilla actualizada encontrada: ${cuadrillaActualizada['nombre']}');
        print('🔍 Debug - Empleados en cuadrilla actualizada: ${cuadrillaActualizada['empleados']?.length ?? 0}');
        
        // ✅ Mostrar detalles de los empleados para debug
        if (cuadrillaActualizada['empleados'] != null) {
          for (var emp in cuadrillaActualizada['empleados']) {
            print('🔍 Debug - Empleado: ${emp['nombre']} (ID: ${emp['id']})');
          }
        }

        // Inicializamos las listas originales con los datos más actualizados
        empleadosEnCuadrilla = List<Map<String, dynamic>>.from(
          cuadrillaActualizada['empleados'] ?? [],
        );

        print('🔍 Debug - Empleados en cuadrilla local: ${empleadosEnCuadrilla.length}');

        // Inicializamos las listas de visualización filtrada
        empleadosDisponiblesFiltrados = List.from(todosLosEmpleados);
        empleadosEnCuadrillaFiltrados = List.from(empleadosEnCuadrilla);

        // Limpiamos los controladores de búsqueda
        if (_buscarDisponiblesController.text.isNotEmpty)
          _buscarDisponiblesController.clear();
        if (_buscarEnCuadrillaController.text.isNotEmpty)
          _buscarEnCuadrillaController.clear();

        // Asegurarnos de que cada empleado en la cuadrilla tenga el campo 'puesto'
        for (var empleado in empleadosEnCuadrilla) {
          empleado['puesto'] = empleado['puesto'] ?? 'Jornalero';
        }
      });
    }
  }

  // Función para guardar los datos de nómina
  Future<void> _guardarNomina() async {
    // 🎯 Validaciones del flujo antes de guardar
    if (!_validarPuedeCapturarDatos()) {
      if (semanaSeleccionada == null) {
        _mostrarMensajeGuia(
          'Primero debes seleccionar una semana.',
          icon: Icons.schedule,
          accionSugerida: 'Usa el botón "Seleccionar semana" en la parte superior'
        );
      } else if (cuadrillaSeleccionada == null) {
        _mostrarMensajeGuia(
          'Primero debes seleccionar una cuadrilla.',
          icon: Icons.groups,
          accionSugerida: 'Elige una cuadrilla del dropdown y haz clic en "Armar cuadrilla"'
        );
      } else {
        _mostrarMensajeGuia(
          'No hay empleados en la cuadrilla para guardar.',
          icon: Icons.person_off,
          accionSugerida: 'Agrega empleados usando "Armar cuadrilla"'
        );
      }
      return;
    }
    
    // 🔧 Validación adicional de datos antes de guardar
    bool hayDatosValidos = false;
    bool hayCambiosPendientes = _detectUnsavedChanges();
    
    for (final emp in empleadosFiltrados) {
      // Verificar si tiene al menos un día trabajado
      for (int day = 0; day < 7; day++) {
        final diasTrabajados = int.tryParse(emp['dia_${day}_s']?.toString() ?? '0') ?? 0;
        if (diasTrabajados > 0) {
          hayDatosValidos = true;
          break;
        }
      }
      if (hayDatosValidos) break;
    }
    
    // Si no hay datos válidos Y no hay cambios pendientes, mostrar mensaje
    if (!hayDatosValidos && !hayCambiosPendientes) {
      // Mostrar diálogo informativo que solo permite cancelar
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sin datos para guardar'),
            ],
          ),
          content: Text(
            'No se han detectado días trabajados en ningún empleado.\n\n'
            'Primero captura algunos datos en la tabla antes de guardar.'
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Entendido'),
            ),
          ],
        ),
      );
      
      // Siempre regresar sin guardar cuando no hay datos ni cambios
      return;
    }
    
    // Si hay cambios pendientes pero no hay sueldos, continuar con el guardado sin confirmación
    
    if (_startDate == null ||
        _endDate == null ||
        _selectedCuadrilla['nombre'] == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar una semana y una cuadrilla'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔄 Mostrar indicador de guardando
    if (mounted) {
      setState(() {
        _isGuardando = true;
      });
    }

    try {
      // 🔧 Aplicar los cambios temporales a los datos reales antes de guardar
      _applyTempChangesToReal();
      
      // ✅ Guardar los datos de nómina completos en la base de datos
      await guardarNomina();
      
      // ❌ ELIMINADO: guardarEmpleadosCuadrillaSemana sobrescribe los datos recién guardados
      // La función guardarNomina() ya maneja INSERT/UPDATE correctamente
      // No necesitamos una segunda operación que elimine y vuelva a insertar

      // ✅ IMPORTANTE: Mantener los datos guardados en _optionsCuadrilla para persistir entre cambios
      if (mounted && _selectedCuadrilla['id'] != null) {
        final indiceCuadrilla = _optionsCuadrilla.indexWhere(
          (c) => c['id'] == _selectedCuadrilla['id'],
        );
        
        if (indiceCuadrilla != -1) {
          setState(() {
            // Actualizar los empleados de la cuadrilla en _optionsCuadrilla con los datos guardados
            _optionsCuadrilla[indiceCuadrilla]['empleados'] = 
                List<Map<String, dynamic>>.from(empleadosFiltrados);
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos de nómina guardados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Resetear el estado de cambios no guardados después de guardar exitosamente
      if (mounted) {
        _saveOriginalData();
        marcarCambiosGuardados(); // ✅ Marcar como guardado
        
        // 🔄 Habilitar actualización del total semanal
        _puedeActualizarTotal = true;
        
        // 🔄 Forzar actualización del Total semana después del guardado
        _actualizarTotalSemana();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 🔄 Ocultar indicador de guardando
      if (mounted) {
        setState(() {
          _isGuardando = false;
        });
      }
    }
  }

  // Función para determinar si se puede guardar
  bool get _canSave {
    // Verificar que hay semana seleccionada
    bool hasSemana =
        _startDate != null && _endDate != null && semanaSeleccionada != null;

    // Verificar que hay cuadrilla seleccionada
    bool hasCuadrilla =
        cuadrillaSeleccionada != null &&
        cuadrillaSeleccionada!['nombre'] != null &&
        cuadrillaSeleccionada!['nombre'] != '';

    // Verificar que hay empleados en la cuadrilla (verificar múltiples fuentes)
    bool hasEmpleados = false;
    
    // Verificar empleadosFiltrados (tabla principal visible)
    if (empleadosFiltrados.isNotEmpty) {
      hasEmpleados = true;
    } 
    // Verificar empleadosNomina (datos cargados de BD)
    else if (empleadosNomina.isNotEmpty) {
      hasEmpleados = true;
    } 
    // Verificar cuadrilla seleccionada
    else if (cuadrillaSeleccionada != null &&
            cuadrillaSeleccionada!['empleados'] != null &&
            (cuadrillaSeleccionada!['empleados'] as List).isNotEmpty) {
      hasEmpleados = true;
    }
    // Verificar _selectedCuadrilla como última opción
    else if (_selectedCuadrilla['empleados'] != null &&
            (_selectedCuadrilla['empleados'] as List).isNotEmpty) {
      hasEmpleados = true;
    }

    final canSave = hasSemana && hasCuadrilla && hasEmpleados;
    
    // Debug para troubleshooting
    if (!canSave) {
      print('🔍 _canSave = false: hasSemana=$hasSemana, hasCuadrilla=$hasCuadrilla, hasEmpleados=$hasEmpleados');
      print('   empleadosFiltrados.length=${empleadosFiltrados.length}');
      print('   empleadosNomina.length=${empleadosNomina.length}');
      print('   cuadrillaSeleccionada empleados=${cuadrillaSeleccionada != null ? (cuadrillaSeleccionada!['empleados'] as List?)?.length ?? 0 : 0}');
    }
    
    return canSave;
  }

  // Función para mostrar detalles del empleado
  void _mostrarDetallesEmpleado(
    BuildContext context,
    Map<String, dynamic> empleado,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return NominaDetallesEmpleadoWidget(empleado: empleado);
      },
    );
  }

  /// Guarda una copia de los datos originales para detectar cambios
  void _saveOriginalData() {
    _originalNominaData = {};
    // ✅ Guardar desde empleadosFiltrados que es lo que se muestra en la tabla
    for (int i = 0; i < empleadosFiltrados.length; i++) {
      final emp = empleadosFiltrados[i];
      _originalNominaData[emp['id']] = Map<String, dynamic>.from(emp);
    }
    marcarCambiosGuardados(); // Usar el método del mixin
    
    // 🔧 También inicializar los datos temporales
    _initializeTempData();
  }

  /// 🔧 Inicializa los datos temporales para edición en tiempo real
  void _initializeTempData() {
    // 🔧 Usar empleadosFiltrados como fuente (datos mostrados en tabla)
    empleadosNominaTemp = empleadosFiltrados.map((emp) {
      // 🔧 Crear copia manteniendo tipos específicos
      final empCopy = <String, dynamic>{};
      for (String key in emp.keys) {
        empCopy[key] = emp[key];
      }
      // Recalcular totales al inicializar
      _recalcularTotalesEmpleado(empCopy);
      return empCopy;
    }).toList();
    
    // Guardar una copia para poder revertir cambios
    _originalDataBeforeEditing = {};
    for (final emp in empleadosFiltrados) {
      // 🔧 Crear copia manteniendo tipos específicos
      final empCopy = <String, dynamic>{};
      for (String key in emp.keys) {
        empCopy[key] = emp[key];
      }
      _originalDataBeforeEditing[emp['id']] = empCopy;
    }
  }

  /// 🔧 Aplica los cambios temporales a los datos reales (al guardar)
  void _applyTempChangesToReal() {
    for (int i = 0; i < empleadosNomina.length && i < empleadosNominaTemp.length; i++) {
      // 🔧 Copiar manteniendo tipos específicos para la base de datos
      final tempEmp = empleadosNominaTemp[i];
      final realEmp = empleadosNomina[i];
      
      // Copiar cada campo manteniendo el tipo correcto
      for (String key in tempEmp.keys) {
        realEmp[key] = tempEmp[key];
      }
    }
    
    // También aplicar a empleadosFiltrados para mantener sincronización
    for (int i = 0; i < empleadosFiltrados.length && i < empleadosNominaTemp.length; i++) {
      final tempEmp = empleadosNominaTemp[i];
      final filtEmp = empleadosFiltrados[i];
      
      // Copiar cada campo manteniendo el tipo correcto
      for (String key in tempEmp.keys) {
        filtEmp[key] = tempEmp[key];
      }
    }
  }

  /// Detecta si hay cambios no guardados comparando con los datos originales
  bool _detectUnsavedChanges() {
    if (_originalNominaData.isEmpty && empleadosFiltrados.isNotEmpty) {
      return true; // Hay datos nuevos sin guardar
    }
    
    // ✅ Comparar con empleadosFiltrados que es lo que se muestra en la tabla
    for (final emp in empleadosFiltrados) {
      final empId = emp['id'];
      final originalEmp = _originalNominaData[empId];
      
      if (originalEmp == null) {
        return true; // Empleado nuevo
      }
      
      // Comparar campos que pueden cambiar (incluye actividad, salario y campo)
      final fieldsToCheck = [
        'dia_0_s', 'dia_0_id', 'dia_0_campo',
        'dia_1_s', 'dia_1_id', 'dia_1_campo',
        'dia_2_s', 'dia_2_id', 'dia_2_campo',
        'dia_3_s', 'dia_3_id', 'dia_3_campo',
        'dia_4_s', 'dia_4_id', 'dia_4_campo',
        'dia_5_s', 'dia_5_id', 'dia_5_campo',
        'dia_6_s', 'dia_6_id', 'dia_6_campo',
        'debe', 'comedor'
      ];
      
      for (final field in fieldsToCheck) {
        if (emp[field]?.toString() != originalEmp[field]?.toString()) {
          return true; // Hay cambios
        }
      }
    }
    return false;
  }

  /// Muestra diálogo de confirmación para cambios no guardados
  Future<bool?> _showUnsavedChangesDialog() async {
    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
              minWidth: 460,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Contenido principal centrado
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Espacio superior para el botón X
                      const SizedBox(height: 8),
                      
                      // Icono de advertencia con gradiente
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade300,
                              Colors.orange.shade500,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Título principal
                      const Text(
                        'Cambios no guardados',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Mensaje descriptivo
                      Text(
                        'Tienes cambios sin guardar en la cuadrilla actual.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        '¿Deseas guardarlos antes de cambiar de cuadrilla?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botones de acción
                      Row(
                        children: [
                          // Botón Descartar
                          Expanded(
                            child: Container(
                              height: 50,
                              margin: const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                                  backgroundColor: Colors.red.shade50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Descartar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Botón Guardar
                          Expanded(
                            child: Container(
                              height: 50,
                              margin: const EdgeInsets.only(left: 8),
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7BAE2F),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: const Color(0xFF7BAE2F).withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Guardar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botón X de cancelar en la esquina superior derecha
                Positioned(
                  right: 16,
                  top: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
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

  /// Maneja el cambio de cuadrilla con verificación de cambios no guardados
  Future<void> _handleCuadrillaChange(Map<String, dynamic>? newCuadrilla) async {
    // 🎯 Ya no se valida semana, se permite seleccionar cuadrilla sin semana
    // Solo mostrar mensaje informativo
    if (semanaSeleccionada == null && newCuadrilla != null) {
      _mostrarMensajeGuia(
        'Cuadrilla seleccionada. Para capturar datos necesitarás seleccionar una semana.',
        icon: Icons.info_outline,
        accionSugerida: 'Usa "Seleccionar semana" cuando quieras capturar datos'
      );
    }
    
    // Detectar cambios no guardados
    bool hayCambios = _detectUnsavedChanges();
    
    if (hayCambios) {
      // Marcar que hay cambios
      marcarCambiosNoGuardados();
      
      final dialogResult = await _showUnsavedChangesDialog();
      
      // Si el usuario cancela (null), no hacer nada
      if (dialogResult == null) {
        return; // Cancelar la operación, mantener todo igual
      }
      
      // Si el usuario quiere guardar (true), guardar antes de cambiar
      if (dialogResult == true) {
      //  await _guardarNomina();
      }
      
      // Si dialogResult es false (descartar), proceder sin guardar
    }
    
    // Proceder con el cambio de cuadrilla
    await _changeCuadrilla(newCuadrilla);
    
    // 🎯 Actualizar validaciones después del cambio
    _actualizarEstadosValidacion();
    
    // 🎯 Mostrar mensaje de éxito si se seleccionó una cuadrilla con empleados
    if (newCuadrilla != null && (newCuadrilla['empleados'] as List).isNotEmpty) {
      _mostrarMensajeGuia(
        'Cuadrilla "${newCuadrilla['nombre']}" seleccionada. Ya puedes capturar datos.',
        icon: Icons.check_circle_outline
      );
    }
  }

  /// Realiza el cambio de cuadrilla
  Future<void> _changeCuadrilla(Map<String, dynamic>? option) async {
    if (!mounted || _isDisposed) return;
    
    print('🔄 INICIANDO cambio de cuadrilla: ${option?['nombre'] ?? 'DESELECCIONAR'}');
    
    setState(() {
      if (option == null) {
        // Deseleccionar cuadrilla
        print('  ❌ Deseleccionando cuadrilla');
        _selectedCuadrilla = {
          'nombre': '',
          'empleados': [],
        };
        cuadrillaSeleccionada = null;
        empleadosFiltrados = [];
        empleadosEnCuadrilla = [];
        empleadosDisponiblesFiltrados = List.from(todosLosEmpleados);
        empleadosEnCuadrillaFiltrados = [];
        empleadosNomina = [];
        
        // 🎯 Resetear estado de captura al deseleccionar cuadrilla
        _puedeCapturarDatos = false;
      } else {
        // Seleccionar cuadrilla - SOLO actualizar referencias básicas
        print('  ✅ Seleccionando cuadrilla: ${option['nombre']}');
        _selectedCuadrilla = option;
        cuadrillaSeleccionada = option;
        empleadosDisponiblesFiltrados = List.from(todosLosEmpleados);
        _buscarDisponiblesController.clear();
        _buscarEnCuadrillaController.clear();
        
        // 🎯 Habilitar captura solo si la cuadrilla tiene empleados
        _puedeCapturarDatos = _validarPuedeCapturarDatos();
      }
    });

    // Cargar nómina solo si hay cuadrilla y semana seleccionada
    if (option != null && idSemanaSeleccionada != null) {
      print('  🔄 Cargando datos desde BD...');
      
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedCuadrilla = option;
          cuadrillaSeleccionada = option;
          
          // ✅ Resetear SOLO una vez antes de cargar desde BD
          empleadosNomina = [];
          empleadosFiltrados = [];
          empleadosNominaTemp = [];
          empleadosEnCuadrilla = [];
          empleadosEnCuadrillaFiltrados = [];
        });
        print('  🔄 Listas reseteadas, cargando desde BD...');
      }

      // ✅ Cargar datos desde BD para obtener información completa
      if (mounted && !_isDisposed) {
        await cargarDatosNomina();
      }
      
      // Guardar los datos originales después de cargar
      if (mounted && !_isDisposed) {
        _saveOriginalData();
        
        // 🎯 Actualizar estado de captura después de cargar cuadrilla
        _puedeCapturarDatos = _validarPuedeCapturarDatos();
      }
      
      print('✅ Cuadrilla "${option['nombre']}" cargada con ${empleadosFiltrados.length} empleados');
      print('📊 Datos finales empleadosFiltrados[0]: ${empleadosFiltrados.isNotEmpty ? empleadosFiltrados[0] : 'VACÍO'}');
    } else {
      print('❌ No se puede cargar: option=${option != null}, semana=${idSemanaSeleccionada != null}');
    }
  }

  /// Actualiza el estado de cambios cuando se modifica un campo
  void _onFieldChanged(int index, String key, dynamic value) {
    if (!mounted || _isDisposed) return;
    
    setState(() {
      if (index < empleadosFiltrados.length) {
        // 🔧 Convertir valores numéricos a enteros para mantener tipos correctos
        dynamic processedValue = value;
        if (_isNumericField(key)) {
          processedValue = int.tryParse(value.toString()) ?? 0;
        }
        
        // ✅ Actualizar directamente empleadosFiltrados (tabla principal)
        empleadosFiltrados[index][key] = processedValue;
        
        // 🚫 NO recalcular aquí - dejar que NuevaTablaEditable se encargue del cálculo
        // Solo recalcular si es un cambio en campos que no son totales calculados
        if (!_isTotalField(key)) {
          // Los totales los calculará NuevaTablaEditable automáticamente
          print('📝 Campo actualizado por usuario: $key = $processedValue');
        } else {
          // Si es un total calculado, actualizar directamente sin recalcular
          print('📊 Total actualizado por NuevaTablaEditable: $key = $processedValue');
        }
        
        // ✅ Sincronizar con empleadosNominaTemp si existe
        if (index < empleadosNominaTemp.length) {
          empleadosNominaTemp[index][key] = processedValue;
          // Tampoco recalcular aquí para evitar duplicación
        }
        
        // Detectar cambios para habilitar/deshabilitar el botón guardar
        if (_detectUnsavedChanges()) {
          marcarCambiosNoGuardados();
        }
      }
    });
  }
  
  /// 🔧 Determina si un campo es numérico
  bool _isNumericField(String key) {
    // Los campos de campo (dia_X_campo) son texto, no numéricos
    if (key.contains('_campo')) {
      return false;
    }
    return key.contains('dia_') || 
           key == 'total' || 
           key == 'subtotal' || 
           key == 'totalNeto' || 
           key == 'debe' || 
           key == 'comedor';
  }
  
  /// 🔧 Determina si un campo es un total calculado (no editable por el usuario)
  bool _isTotalField(String key) {
    return key == 'total' || 
           key == 'subtotal' || 
           key == 'totalNeto';
  }

  /// 🔧 Recalcula los totales de un empleado específico
  void _recalcularTotalesEmpleado(Map<String, dynamic> empleado) {
    if (_startDate == null || _endDate == null) return;
    
    final numDays = _endDate!.difference(_startDate!).inDays + 1;
    
    // Sumar solo las celdas "S" (salario) por día
    final total = List.generate(numDays, (i) {
      return int.tryParse(empleado['dia_${i}_s']?.toString() ?? '0') ?? 0;
    }).reduce((a, b) => a + b);
    
    final debe = int.tryParse(empleado['debe']?.toString() ?? '0') ?? 0;
    final comedorValue = int.tryParse(empleado['comedor']?.toString() ?? '0') ?? 0;
    final subtotal = total - debe;
    final totalNeto = subtotal - comedorValue;

    // Actualizar los totales en el empleado
    empleado['total'] = total;
    empleado['subtotal'] = subtotal;
    empleado['totalNeto'] = totalNeto;
    
    // 📊 El total semanal se actualiza únicamente al guardar, no en tiempo real
    // para evitar problemas de setState() después del dispose()
  }

  /// 🔄 Método para forzar la actualización del indicador Total semana
  /// 📊 CALCULO TOTAL SEMANAL: Se llama después de guardar datos para recalcular el total de la semana
  void _actualizarTotalSemana() {
    // Verificar que el widget esté montado y no esté disposed antes de llamar setState
    if (!mounted || _isDisposed) {
      print('⚠️ [CALCULO TOTAL SEMANAL] Widget desmontado o disposed, cancelando actualización');
      return;
    }
    
    // Solo actualizar el total cuando se permite (después de guardar)
    if (!_puedeActualizarTotal) {
      print('⚠️ [CALCULO TOTAL SEMANAL] Actualización no permitida (no se ha guardado), cancelando');
      return;
    }
    
    // Forzar reconstrucción del widget de indicadores incrementando la key
    // Esto causará que el NominaIndicatorsRow se reconstruya y recalcule automáticamente el total
    _safeSetState(() {
      _indicatorsUpdateKey++;
    });
    
    print('🔄 [CALCULO TOTAL SEMANAL] Forzando recálculo del total semanal - Key: $_indicatorsUpdateKey');
    
    // Resetear la bandera después de la actualización
    _puedeActualizarTotal = false;
  }

  @override
  Widget build(BuildContext context) {
    return InterceptorSalidaNomina(
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: _guardarTodosLosDatos,
      onSalirSinGuardar: _salirSinGuardar,
      mensajePersonalizado: 'Tienes cambios pendientes en la nómina. Los datos modificados se perderán si sales sin guardar.',
      child: RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nóminas',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenDark,
                            ),
                          ),
                          Row(
                            children: [
                              // Botón de historial de backups
                              IconButton(
                                onPressed: _mostrarHistorialBackups,
                                icon: Icon(Icons.backup),
                                tooltip: 'Historial de Backups',
                              ),
                              // Botón para crear backup de prueba
                              IconButton(
                                onPressed: _crearBackupAntesDeCarrar,
                                icon: Icon(Icons.backup_rounded, color: Colors.orange),
                                tooltip: 'Crear Backup de Prueba',
                              ),
                              SizedBox(width: 8),
                              // Botón de shortcuts en la esquina superior derecha
                              IconButton(
                                onPressed: _mostrarShortcuts,
                                icon: Icon(Icons.keyboard),
                                tooltip: 'Atajos de teclado (Ctrl+H)',
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 24,
                    ), 
                    
                    // 🎯 Indicador de progreso del flujo
                    NominaFlowIndicator(
                      hasSemana: semanaSeleccionada != null,
                      hasCuadrilla: cuadrillaSeleccionada != null,
                      hasEmpleados: empleadosFiltrados.isNotEmpty,
                      puedeCapturar: _puedeCapturarDatos,
                    ),
                    
                    const SizedBox(
                      height: 24,
                    ), // Filter row with improved design using modular widgets
                    Row(
                      children: [
                        // Week Selection Card
                        Expanded(
                          flex: 2,
                          child: NominaWeekSelectionCard(
                            startDate: _startDate,
                            endDate: _endDate,
                            isWeekClosed: _isWeekClosed,
                            haySemanaActiva: _haySemanaActiva,
                            semanaActiva: semanaActiva,
                            onSeleccionarSemana: _seleccionarSemana,
                            onCerrarSemana: _onCerrarSemana,
                            // 🎯 Habilitar mensajes guía del flujo
                            mostrarEstadoFlujo: true,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Cuadrilla Selection Card
                        Expanded(
                          flex: 2,
                          child: NominaCuadrillaSelectionCard(
                            optionsCuadrilla: _optionsCuadrilla,
                            selectedCuadrilla: _selectedCuadrilla,
                            empleadosEnCuadrilla: empleadosEnCuadrilla,
                            onCuadrillaSelected: (
                              Map<String, dynamic>? option,
                            ) async {
                              await _handleCuadrillaChange(option);
                            },
                            semanaSeleccionada:
                                semanaSeleccionada, // ✅ <--- Agregado aquí
                            onToggleArmarCuadrilla: _toggleArmarCuadrilla,
                            // 🎯 Nuevas propiedades para validación del flujo
                            puedeArmarCuadrilla: _puedeArmarCuadrilla,
                            bloqueadoPorFaltaSemana: _bloqueadoPorFaltaSemana,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Indicators with improved design
                        Expanded(
                          flex: 3,
                          child: NominaIndicatorsRow(
                            key: ValueKey('indicators_$_indicatorsUpdateKey'),
                            empleadosFiltrados: empleadosFiltrados,
                            optionsCuadrilla: _optionsCuadrilla,
                            startDate: _startDate,
                            endDate: _endDate,
                            semanaId: idSemanaSeleccionada,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Table section with modular design
                    Expanded(
                      child: NominaTablaSeccionPrincipal(
                        empleadosFiltrados: empleadosFiltrados, // ✅ Siempre usar empleadosFiltrados
                        empleadosNomina: empleadosNomina, // ← ✅ Agregado aquí
                        startDate: _startDate,
                        endDate: _endDate,
                        onTableChange: _onFieldChanged,
                        onMostrarSemanasCerradas: _mostrarSemanasCerradas,
                        onRefreshTabla: _refreshTablaManual, // ✨ Callback para refresh manual
                      ),
                    ), // Export section
                    const SizedBox(height: 24),
                    NominaExportSection(
                      canSave: _canSave,
                      startDate: _startDate,
                      endDate: _endDate,
                      cuadrillaSeleccionada: cuadrillaSeleccionada,
                      empleadosFiltrados: empleadosFiltrados,
                      onGuardar: _guardarNomina,
                      // 🎯 Nueva propiedad para validación del flujo
                      puedeCapturarDatos: _puedeCapturarDatos,
                      // 🔄 Nueva propiedad para indicador de guardando
                      isGuardando: _isGuardando,
                    ),
                  ],
                ),
              ),
            ),
            ),
            // Overlay dialogs
            if (showSemanasCerradas)
              NominaHistorialSemanasCerradasWidget(
                semanasCerradas: semanasCerradas,
                onClose: () => setState(() => showSemanasCerradas = false),
                onSemanaCerradaUpdated: (semanaActualizada) {
                  // Callback opcional para cuando se actualiza una semana cerrada
                  // Por ahora no necesitamos hacer nada adicional
                },
              ),
            // Diálogo de armar cuadrilla modularizado
            if (showArmarCuadrilla)
              NominaArmarCuadrillaWidget(
              optionsCuadrilla: _optionsCuadrilla, // 🔧 Usar _optionsCuadrilla en lugar de cuadrillas
              selectedCuadrilla: cuadrillaSeleccionada ?? {},
              todosLosEmpleados: todosLosEmpleados,
              empleadosEnCuadrilla: empleadosEnCuadrilla,
              onCuadrillaSaved: (cuadrilla, empleados) async {
                setState(() {
                  // Actualizar la cuadrilla seleccionada con los nuevos empleados
                  _selectedCuadrilla = cuadrilla;
                  cuadrillaSeleccionada = cuadrilla; // ✅ Asignar cuadrillaSeleccionada también
                  empleadosEnCuadrilla = empleados;

                  // Buscar y actualizar la cuadrilla en _optionsCuadrilla
                  final indiceCuadrilla = _optionsCuadrilla.indexWhere(
                    (c) => c['nombre'] == cuadrilla['nombre']
                  );
                  
                  if (indiceCuadrilla != -1) {
                    // Actualizar la cuadrilla existente en la lista compartida
                    _optionsCuadrilla[indiceCuadrilla]['empleados'] =
                        List<Map<String, dynamic>>.from(empleados);
                  }

                  // Cerrar el diálogo
                  showArmarCuadrilla = false;
                });
                
                // ✅ IMPORTANTE: Ya no necesitamos guardar la relación empleado-cuadrilla
                // porque guardarNomina() maneja todo el proceso de INSERT/UPDATE
                // Eliminar la llamada duplicada que sobrescribe los datos
                
                
                // ✅ Recargar todas las cuadrillas para asegurar sincronización completa
                if (idSemanaSeleccionada != null) {
                  await _cargarCuadrillasSemana(idSemanaSeleccionada!);
                  // ✅ Cargar empleados de todas las cuadrillas desde la BD
                  await _cargarEmpleadosDeCuadrillas();
                }
                
                // Cargar los datos completos de nómina usando la función existente
                await cargarDatosNomina();
                
                // 🔧 IMPORTANTE: Guardar datos originales después de cargar para evitar falsos positivos de cambios
                if (mounted) {
                  _saveOriginalData();
                  marcarCambiosGuardados();
                }
              },
              onActualizarTablas: () async {
                // ✨ REFRESH AUTOMÁTICO: Actualizar completamente los datos después de guardar cambios en cuadrilla
                try {
                  setState(() {
                    // Forzar rebuilding de la UI
                  });
                  
                  // ✅ 1. Recargar cuadrillas completas desde la base de datos
                  if (idSemanaSeleccionada != null) {
                    await _cargarCuadrillasSemana(idSemanaSeleccionada!);
                    await _cargarEmpleadosDeCuadrillas();
                  }
                  
                  // ✅ 2. Recargar datos completos de nómina
                  await cargarDatosNomina();
                  
                  // ✅ 3. Actualizar la cuadrilla seleccionada si aún existe
                  if (_selectedCuadrilla['nombre'] != null) {
                    final cuadrillaActualizada = _optionsCuadrilla.firstWhere(
                      (c) => c['nombre'] == _selectedCuadrilla['nombre'],
                      orElse: () => {},
                    );
                    
                    if (cuadrillaActualizada.isNotEmpty && mounted) {
                      setState(() {
                        _selectedCuadrilla = cuadrillaActualizada;
                        cuadrillaSeleccionada = cuadrillaActualizada;
                        empleadosEnCuadrilla = List<Map<String, dynamic>>.from(
                          cuadrillaActualizada['empleados'] ?? []
                        );
                      });
                    }
                  }
                  
                  // ✅ 4. Recalcular totales y actualizar empleados filtrados
                  for (var empleado in empleadosFiltrados) {
                    _recalcularTotalesEmpleado(empleado);
                  }
                  
                  // ✅ 5. Actualizar datos originales para evitar falsos cambios
                  if (mounted) {
                    _saveOriginalData();
                    marcarCambiosGuardados();
                  }
                  
                  // ✅ 6. Mostrar confirmación de actualización
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Tabla actualizada correctamente'),
                          ],
                        ),
                        backgroundColor: Colors.blue.shade600,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                  
                } catch (e) {
                  print('❌ Error al actualizar tablas: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(child: Text('Error al actualizar tabla: $e')),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              onClose: () => setState(() => showArmarCuadrilla = false),
              onMostrarDetallesEmpleado: _mostrarDetallesEmpleado,
            ),
          ],
        ),
      ),
    ),
    );
  }

  /// 🔄 Crea un backup completo de la semana antes de cerrarla
  Future<void> _crearBackupAntesDeCarrar() async {
    print('🚀 INICIANDO _crearBackupAntesDeCarrar()');
    
    if (semanaSeleccionada == null) {
      print('⚠️ No hay semana seleccionada para hacer backup');
      return;
    }

    print('✅ Semana seleccionada encontrada: $semanaSeleccionada');

    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Creando backup de la semana...'),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Crear backup usando pg_dump
      print('🔍 DEBUG: ID de semana seleccionada: ${semanaSeleccionada!['id']}');
      print('🔍 DEBUG: Datos completos de semana: $semanaSeleccionada');
      
      final resultado = await crearBackupSemana(
        semanaSeleccionada!['id'], 
        'SUPERVISOR' // Por ahora usamos un valor fijo, después podemos mejorarlo
      );

      if (mounted) {
        if (resultado['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.backup, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✅ Backup creado exitosamente'),
                        Text(
                          '📁 ${resultado['archivo']} (${(resultado['tamanio'] / 1024).toStringAsFixed(1)} KB)',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('❌ Error al crear backup: ${resultado['error']}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      print('❌ Error en _crearBackupAntesDeCarrar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear backup: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 📋 Muestra el historial de backups con archivos .sql descargables
  Future<void> _mostrarHistorialBackups() async {
    try {
      final backups = await obtenerHistorialBackups();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.folder_zip, color: AppColors.greenDark),
              SizedBox(width: 8),
              Text('Historial de Backups (.sql)'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: backups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.backup_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay archivos de backup disponibles',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Los backups se crean automáticamente al cerrar semanas',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      final fechaBackup = backup['fecha_backup'] ?? 'N/A';
                      final nombreArchivo = backup['archivo_backup'] ?? 'Sin archivo';
                      final tamanioArchivo = backup['tamanio_archivo'] ?? 0;
                      final rutaArchivo = backup['ruta_archivo'] ?? '';
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            nombreArchivo,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📅 ${fechaBackup.toString().substring(0, 19)}'),
                              Text('👤 ${backup['supervisor_usuario']}'),
                              Text('📊 Semana: ${backup['semana_id']}'),
                              Text('💾 ${(tamanioArchivo / 1024).toStringAsFixed(1)} KB'),
                              Text('🔧 Archivo SQL exportado con pg_dump'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón descargar
                              IconButton(
                                onPressed: () => _descargarArchivoBackup(rutaArchivo, nombreArchivo),
                                icon: Icon(Icons.download, size: 20),
                                tooltip: 'Descargar archivo',
                                color: Colors.blue.shade600,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('❌ Error al mostrar historial de backups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📥 Descarga un archivo de backup SQL
  Future<void> _descargarArchivoBackup(String rutaArchivo, String nombreArchivo) async {
    try {
      final resultado = await descargarBackup(rutaArchivo, nombreArchivo);

      if (mounted) {
        if (resultado['success'] == true) {
          // Verificar si fue cancelado por el usuario
          if (resultado['cancelled'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Descarga cancelada por el usuario'),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.download_done, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✅ Archivo SQL guardado exitosamente'),
                          Text(
                            'Ubicación: ${resultado['ruta_descarga']}',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${resultado['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al descargar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al descargar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarResumenCuadrillasYCerrar({String? usuarioAutorizado}) async {
    if (_startDate == null || _endDate == null) return;

    // 🚨 CRÍTICO: Guardar todos los datos pendientes ANTES de mostrar el resumen
    if (_detectUnsavedChanges() || empleadosNominaTemp.isNotEmpty) {
      // Mostrar indicador de guardado
      if (mounted) {
        setState(() {
          _isGuardando = true;
        });
      }
      
      try {
        // Aplicar cambios temporales y guardar
        _applyTempChangesToReal();
        await guardarNomina();
        
        // Marcar como guardado
        if (mounted) {
          _saveOriginalData();
          marcarCambiosGuardados();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos guardados antes del cierre'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return; // No continuar con el cierre si hay error
      } finally {
        if (mounted) {
          setState(() {
            _isGuardando = false;
          });
        }
      }
    }

    // Crear una lista de todas las cuadrillas con sus empleados y datos completos
    List<Map<String, dynamic>> cuadrillasInfo = [];

    // Procesamos todas las cuadrillas de _optionsCuadrilla
    for (var cuadrilla in _optionsCuadrilla) {
      List<Map<String, dynamic>> empleadosConTablas = [];

      // 🔧 OBTENER DATOS ACTUALIZADOS DE LA BD para cada cuadrilla con empleados
      final empleadosCuadrilla = List<Map<String, dynamic>>.from(
        cuadrilla['empleados'] ?? [],
      );
      
      // Solo procesar si la cuadrilla tiene empleados asignados
      if (empleadosCuadrilla.isNotEmpty && idSemanaSeleccionada != null) {
        try {
          // Obtener datos actualizados de la BD para esta cuadrilla
          final datosActualizados = await obtenerNominaEmpleadosDeCuadrilla(
            idSemanaSeleccionada!,
            cuadrilla['id'],
          );
          
          // Si hay datos en la BD, usarlos; sino usar cálculos locales
          if (datosActualizados.isNotEmpty) {
            empleadosConTablas = datosActualizados.map((emp) {
              // Los datos ya vienen con todos los cálculos desde la BD
              final totalNeto = double.tryParse(emp['totalNeto']?.toString() ?? '0') ?? 0.0;
              
              return {
                ...emp,
                'totalNeto': totalNeto,
                'tabla_principal': {
                  'total': double.tryParse(emp['total']?.toString() ?? '0') ?? 0.0,
                  'debe': double.tryParse(emp['debe']?.toString() ?? '0') ?? 0.0,
                  'comedor': double.tryParse(emp['comedor']?.toString() ?? '0') ?? 0.0,
                  'subtotal': double.tryParse(emp['subtotal']?.toString() ?? '0') ?? 0.0,
                  'neto': totalNeto,
                },
              };
            }).toList();
          } else {
            // Fallback: usar procesamiento local solo si no hay datos en BD
            empleadosConTablas = empleadosCuadrilla.map((emp) {
              return _procesarEmpleado(emp);
            }).toList();
          }
        } catch (e) {
          print('⚠️ Error obteniendo datos de cuadrilla ${cuadrilla['nombre']}: $e');
          // Fallback: usar procesamiento local
          empleadosConTablas = empleadosCuadrilla.map((emp) {
            return _procesarEmpleado(emp);
          }).toList();
        }
      }
      
      // Solo agregamos cuadrillas que tienen empleados
      if (empleadosConTablas.isNotEmpty) {
        // Calculamos el total de la cuadrilla usando totalNeto directamente
        final totalCuadrilla = empleadosConTablas.fold<double>(
          0.0,
          (sum, emp) => sum + (double.tryParse(emp['totalNeto']?.toString() ?? '0') ?? 0.0),
        );

        cuadrillasInfo.add({
          'nombre': cuadrilla['nombre'],
          'empleados': empleadosConTablas,
          'total': totalCuadrilla,
        });
        
        print('✅ Cuadrilla ${cuadrilla['nombre']}: ${empleadosConTablas.length} empleados, Total: \$${totalCuadrilla.toStringAsFixed(2)}');
      }
    }

    print('🔍 Resumen final: ${cuadrillasInfo.length} cuadrillas con datos');

    // Mostrar diálogo de resumen (sin datos temporales ya que todo está guardado)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResumenCuadrillasDialog(
        cuadrillasInfo: cuadrillasInfo,
        fechaInicio: _startDate!,
        fechaFin: _endDate!,
        empleadosNominaTemp: null, // Ya no necesitamos datos temporales
        onConfirmarCierre: (String opcion) async {
          Navigator.of(context).pop();
          await _cerrarSemanaActual(opcion: opcion, usuarioAutorizado: usuarioAutorizado);
        },
        onCancelar: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Método para guardar todos los datos (usado por el diálogo de cambios no guardados)
  void _guardarTodosLosDatos() async {
    try {
      // Marcar que se están guardando los cambios
      if (mounted) {
        setState(() {
          _isGuardando = true;
        });
      }
      
      // Llamar al método existente de guardado
      await _guardarNomina();
      
      // Marcar que los cambios han sido guardados
      marcarCambiosGuardados();
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Todos los datos han sido guardados correctamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      // Mostrar error si algo falla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al guardar los datos: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuardando = false;
        });
      }
    }
  }

  /// Guarda los datos actuales directamente en nomina_empleados_historial
  Future<void> _guardarEnHistorial(String? usuarioAutorizado) async {
    if (idSemanaSeleccionada == null) return;
    
    print('🔥 [HISTORIAL] GUARDANDO DATOS DIRECTAMENTE EN nomina_empleados_historial...');
    
    final db = DatabaseService();
    try {
      await db.connect();
      
      // Borrar datos existentes en historial para esta semana
      await db.connection.execute('DELETE FROM nomina_empleados_historial WHERE id_semana = @idSemana',
          substitutionValues: {'idSemana': idSemanaSeleccionada});
      
      int insertados = 0;
      
      // Procesar TODAS las cuadrillas con sus empleados (igual que se hace para semanal)
      for (var cuadrilla in _optionsCuadrilla) {
        List<Map<String, dynamic>> empleadosParaProcesar = [];

        // Si es la cuadrilla actual, usar empleadosFiltrados
        if (cuadrilla['nombre'] == _selectedCuadrilla['nombre']) {
          empleadosParaProcesar = empleadosFiltrados;
        } else {
          // Para otras cuadrillas, usar sus empleados
          empleadosParaProcesar = List<Map<String, dynamic>>.from(
            cuadrilla['empleados'] ?? [],
          );
        }

        print('🔥 [HISTORIAL] Procesando cuadrilla ${cuadrilla['nombre']}: ${empleadosParaProcesar.length} empleados');

        // Insertar cada empleado de esta cuadrilla en historial
        for (var empleado in empleadosParaProcesar) {
          final idEmpleado = empleado['id_empleado'];
          final idCuadrilla = cuadrilla['id'];

          try {
            await db.connection.execute('''
              INSERT INTO nomina_empleados_historial (
                id_empleado, id_semana, id_cuadrilla,
                dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
                total, debe, subtotal, comedor, total_neto,
                act_1, act_2, act_3, act_4, act_5, act_6, act_7,
                campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
                fecha_cierre, usuario_cierre
              ) VALUES (
                @idEmp, @idSemana, @idCuadrilla,
                @d1, @d2, @d3, @d4, @d5, @d6, @d7,
                @total, @debe, @subtotal, @comedor, @neto,
                @a1, @a2, @a3, @a4, @a5, @a6, @a7,
                @c1, @c2, @c3, @c4, @c5, @c6, @c7,
                CURRENT_TIMESTAMP, @usuario
              )
            ''', substitutionValues: {
              'idEmp': idEmpleado,
              'idSemana': idSemanaSeleccionada,
              'idCuadrilla': idCuadrilla,
              'd1': empleado['dia_0_s'] ?? 0,
              'd2': empleado['dia_1_s'] ?? 0,
              'd3': empleado['dia_2_s'] ?? 0,
              'd4': empleado['dia_3_s'] ?? 0,
              'd5': empleado['dia_4_s'] ?? 0,
              'd6': empleado['dia_5_s'] ?? 0,
              'd7': empleado['dia_6_s'] ?? 0,
              'total': empleado['total'] ?? 0,
              'debe': empleado['debe'] ?? 0,
              'subtotal': empleado['subtotal'] ?? 0,
              'comedor': empleado['comedor'] ?? 0,
              'neto': empleado['totalNeto'] ?? 0,
              'a1': empleado['dia_0_id'] ?? 0,
              'a2': empleado['dia_1_id'] ?? 0,
              'a3': empleado['dia_2_id'] ?? 0,
              'a4': empleado['dia_3_id'] ?? 0,
              'a5': empleado['dia_4_id'] ?? 0,
              'a6': empleado['dia_5_id'] ?? 0,
              'a7': empleado['dia_6_id'] ?? 0,
              'c1': empleado['dia_0_campo'] ?? '0',
              'c2': empleado['dia_1_campo'] ?? '0',
              'c3': empleado['dia_2_campo'] ?? '0',
              'c4': empleado['dia_3_campo'] ?? '0',
              'c5': empleado['dia_4_campo'] ?? '0',
              'c6': empleado['dia_5_campo'] ?? '0',
              'c7': empleado['dia_6_campo'] ?? '0',
              'usuario': usuarioAutorizado ?? 'Sistema',
            });
            insertados++;
          } catch (e) {
            print('❌ Error al insertar empleado ${empleado['nombre']} en historial: $e');
          }
        }
      }
      
      // Verificar que se guardaron
      final verificacion = await db.connection.query(
          'SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @idSemana',
          substitutionValues: {'idSemana': idSemanaSeleccionada});
      
      print('🔥 [HISTORIAL] ✅ INSERTADOS: $insertados empleados');
      print('🔥 [HISTORIAL] ✅ VERIFICADO: ${verificacion.first[0]} registros en historial');
      
      await db.close();
    } catch (e) {
      print('❌ [HISTORIAL] ERROR CRÍTICO: $e');
    }
  }

  /// Obtiene los datos actuales de nomina_empleados_semanal para una semana específica
  Future<List<Map<String, dynamic>>?> _obtenerDatosNominaSemanal(int idSemana) async {
    final db = DatabaseService();
    try {
      await db.connect();
      
      // DEBUG: Primero verificar si hay datos
      final conteo = await db.connection.query('''
        SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @idSemana
      ''', substitutionValues: {'idSemana': idSemana});
      
      print('🔍 [DEBUG] Registros en nomina_empleados_semanal para semana $idSemana: ${conteo.first[0]}');
      
      // Si no hay datos, buscar en cualquier semana para debug
      if (conteo.first[0] == 0) {
        final cualquierDato = await db.connection.query('''
          SELECT COUNT(*), MAX(id_semana) FROM nomina_empleados_semanal
        ''');
        print('🔍 [DEBUG] Total registros en nomina_empleados_semanal: ${cualquierDato.first[0]}, última semana: ${cualquierDato.first[1]}');
      }
      
      final resultados = await db.connection.query('''
        SELECT 
          id_empleado, id_semana, id_cuadrilla, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
          total, debe, subtotal, comedor
        FROM nomina_empleados_semanal 
        WHERE id_semana = @idSemana
      ''', substitutionValues: {'idSemana': idSemana});
      
      final datos = resultados.map((row) => {
        'id_empleado': row[0],
        'id_semana': row[1], 
        'id_cuadrilla': row[2],
        'dia_1': row[3],
        'dia_2': row[4],
        'dia_3': row[5],
        'dia_4': row[6],
        'dia_5': row[7],
        'dia_6': row[8],
        'total': row[9],
        'debe': row[10],
        'subtotal': row[11],
        'comedor': row[12],
      }).toList();
      
      print('🔍 [DEBUG] Datos obtenidos: ${datos.length} registros');
      if (datos.isNotEmpty) {
        print('🔍 [DEBUG] Primer registro: ${datos.first}');
      }
      
      return datos;
    } catch (e) {
      print('❌ Error al obtener datos de nómina semanal: $e');
      return null;
    } finally {
      await db.close();
    }
  }

  /// Método para salir sin guardar (usado por el diálogo de cambios no guardados)
  void _salirSinGuardar() {
    // Limpiar los cambios no guardados
    marcarCambiosGuardados();
    
    // Mostrar mensaje informativo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Los cambios no guardados se han descartado'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
