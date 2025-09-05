import 'dart:async';

/// Servicio singleton para cachear cuadrillas y empleados
/// Permite cargar los datos una sola vez por sesión de la aplicación
class CuadrillasCache {
  static final CuadrillasCache _instance = CuadrillasCache._internal();
  factory CuadrillasCache() => _instance;
  CuadrillasCache._internal();

  // Cache de datos
  List<Map<String, dynamic>>? _cuadrillasCache;
  int? _semanaIdCache;
  bool _isLoading = false;
  bool _hasError = false;
  
  // Streams para notificar cambios
  final StreamController<CuadrillasLoadingState> _loadingStateController = 
      StreamController<CuadrillasLoadingState>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _cuadrillasController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Getters públicos
  List<Map<String, dynamic>>? get cuadrillas => _cuadrillasCache;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasCachedData => _cuadrillasCache != null;
  
  // Streams públicos
  Stream<CuadrillasLoadingState> get loadingStateStream => _loadingStateController.stream;
  Stream<List<Map<String, dynamic>>> get cuadrillasStream => _cuadrillasController.stream;

  /// Verifica si los datos están disponibles y son válidos para la semana actual
  bool isValidForSemana(int semanaId) {
    return _cuadrillasCache != null && _semanaIdCache == semanaId && !_hasError;
  }

  /// Obtiene las cuadrillas del cache o las carga si es necesario
  Future<List<Map<String, dynamic>>> getCuadrillas(
    int semanaId,
    Future<List<Map<String, dynamic>>> Function() loadCuadrillasBasicas,
    Future<void> Function(List<Map<String, dynamic>>) loadEmpleados,
  ) async {
    // Si ya tenemos datos válidos para esta semana, devolverlos inmediatamente
    if (isValidForSemana(semanaId)) {
      print('📋 [CACHE] Usando cuadrillas en cache para semana $semanaId');
      return _cuadrillasCache!;
    }

    // Si ya se está cargando, esperar a que termine
    if (_isLoading) {
      print('⏳ [CACHE] Carga en progreso, esperando...');
      await _waitForLoading();
      if (_cuadrillasCache != null && !_hasError) {
        return _cuadrillasCache!;
      }
    }

    // Iniciar nueva carga
    return await _loadCuadrillas(semanaId, loadCuadrillasBasicas, loadEmpleados);
  }

  /// Carga las cuadrillas y las almacena en cache
  Future<List<Map<String, dynamic>>> _loadCuadrillas(
    int semanaId,
    Future<List<Map<String, dynamic>>> Function() loadCuadrillasBasicas,
    Future<void> Function(List<Map<String, dynamic>>) loadEmpleados,
  ) async {
    print('🔄 [CACHE] Iniciando carga de cuadrillas para semana $semanaId');
    
    _isLoading = true;
    _hasError = false;
    _notifyLoadingState(CuadrillasLoadingState.loading(0, 0, 'Iniciando...'));

    try {
      // 1. Cargar cuadrillas básicas
      final cuadrillasBasicas = await loadCuadrillasBasicas();
      
      // 2. Inicializar cache con cuadrillas básicas (sin empleados)
      _cuadrillasCache = cuadrillasBasicas.map((c) => {
        ...c,
        'empleados': <Map<String, dynamic>>[],
      }).toList();
      _semanaIdCache = semanaId;
      
      // 3. Notificar que hay datos básicos disponibles
      _cuadrillasController.add(_cuadrillasCache!);
      _notifyLoadingState(CuadrillasLoadingState.loadingEmployees(
        cuadrillasBasicas.length, 0, 'Cargando empleados...'
      ));

      // 4. Cargar empleados en background
      await loadEmpleados(_cuadrillasCache!);

      // 5. Marcar como completado
      _isLoading = false;
      _notifyLoadingState(CuadrillasLoadingState.completed());
      _cuadrillasController.add(_cuadrillasCache!);

      print('✅ [CACHE] Cuadrillas cargadas y almacenadas en cache');
      return _cuadrillasCache!;

    } catch (e) {
      print('❌ [CACHE] Error cargando cuadrillas: $e');
      _isLoading = false;
      _hasError = true;
      _notifyLoadingState(CuadrillasLoadingState.error(e.toString()));
      
      // Devolver datos básicos si están disponibles, aunque haya error en empleados
      return _cuadrillasCache ?? [];
    }
  }

  /// Actualiza una cuadrilla específica en el cache
  void updateCuadrilla(int index, Map<String, dynamic> cuadrilla) {
    if (_cuadrillasCache != null && index < _cuadrillasCache!.length) {
      _cuadrillasCache![index] = cuadrilla;
      _cuadrillasController.add(_cuadrillasCache!);
    }
  }

  /// Actualiza el progreso de carga de empleados
  void updateLoadingProgress(int total, int processed, String current) {
    _notifyLoadingState(CuadrillasLoadingState.loadingEmployees(total, processed, current));
  }

  /// Espera a que termine la carga actual
  Future<void> _waitForLoading() async {
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Notifica cambios en el estado de carga
  void _notifyLoadingState(CuadrillasLoadingState state) {
    _loadingStateController.add(state);
  }

  /// Invalida el cache (forzar recarga la próxima vez)
  void invalidateCache() {
    print('🗑️ [CACHE] Invalidando cache de cuadrillas');
    _cuadrillasCache = null;
    _semanaIdCache = null;
    _isLoading = false;
    _hasError = false;
  }

  /// Limpia completamente el cache
  void clearCache() {
    print('🧹 [CACHE] Limpiando cache completo');
    invalidateCache();
    _notifyLoadingState(CuadrillasLoadingState.idle());
  }

  /// Cierra los streams
  void dispose() {
    _loadingStateController.close();
    _cuadrillasController.close();
  }
}

/// Estados de carga de cuadrillas
class CuadrillasLoadingState {
  final CuadrillasLoadingType type;
  final int total;
  final int processed;
  final String currentItem;
  final String? errorMessage;

  const CuadrillasLoadingState({
    required this.type,
    this.total = 0,
    this.processed = 0,
    this.currentItem = '',
    this.errorMessage,
  });

  factory CuadrillasLoadingState.idle() => const CuadrillasLoadingState(
    type: CuadrillasLoadingType.idle,
  );

  factory CuadrillasLoadingState.loading(int total, int processed, String current) =>
      CuadrillasLoadingState(
        type: CuadrillasLoadingType.loading,
        total: total,
        processed: processed,
        currentItem: current,
      );

  factory CuadrillasLoadingState.loadingEmployees(int total, int processed, String current) =>
      CuadrillasLoadingState(
        type: CuadrillasLoadingType.loadingEmployees,
        total: total,
        processed: processed,
        currentItem: current,
      );

  factory CuadrillasLoadingState.completed() => const CuadrillasLoadingState(
    type: CuadrillasLoadingType.completed,
  );

  factory CuadrillasLoadingState.error(String message) => CuadrillasLoadingState(
    type: CuadrillasLoadingType.error,
    errorMessage: message,
  );

  bool get isLoading => type == CuadrillasLoadingType.loading || 
                       type == CuadrillasLoadingType.loadingEmployees;
  bool get hasError => type == CuadrillasLoadingType.error;
  bool get isCompleted => type == CuadrillasLoadingType.completed;
}

enum CuadrillasLoadingType {
  idle,
  loading,
  loadingEmployees,
  completed,
  error,
}
