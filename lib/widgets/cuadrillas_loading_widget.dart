import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para mostrar el estado de carga de cuadrillas
/// Incluye animaciones y progreso de carga
class CuadrillasLoadingWidget extends StatefulWidget {
  final int totalCuadrillas;
  final int cuadrillasProcessed;
  final String currentCuadrilla;
  final bool hasError;
  final bool showInBackground; // Nueva propiedad para mostrar que carga en background

  const CuadrillasLoadingWidget({
    super.key,
    required this.totalCuadrillas,
    required this.cuadrillasProcessed,
    required this.currentCuadrilla,
    this.hasError = false,
    this.showInBackground = false,
  });

  @override
  State<CuadrillasLoadingWidget> createState() => _CuadrillasLoadingWidgetState();
}

class _CuadrillasLoadingWidgetState extends State<CuadrillasLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación de pulso para el ícono
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animación de rotación para el ícono de carga
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    // Iniciar animaciones
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalCuadrillas > 0 
        ? widget.cuadrillasProcessed / widget.totalCuadrillas 
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con ícono y título
        Row(
          children: [
            // Ícono animado más pequeño
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.8, // Más pequeño
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 32, // Reducido de 60
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.hasError 
                                ? Colors.red.withOpacity(0.1)
                                : AppColors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.hasError ? Icons.error : Icons.groups,
                            size: 18, // Reducido de 32
                            color: widget.hasError ? Colors.red : AppColors.greenDark,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Título compacto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.hasError 
                        ? 'Error en cuadrillas'
                        : 'Cargando empleados...',
                    style: const TextStyle(
                      fontSize: 14, // Reducido
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  if (!widget.hasError)
                    Text(
                      '${widget.cuadrillasProcessed} de ${widget.totalCuadrillas}',
                      style: TextStyle(
                        fontSize: 12, // Más pequeño
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            
            // Botón cerrar pequeño
            GestureDetector(
              onTap: () => CuadrillasLoadingOverlay.hide(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8), // Reducido
        
        // Barra de progreso compacta
        if (!widget.hasError) ...[
          Container(
            width: double.infinity,
            height: 6, // Más delgada
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Cuadrilla actual - solo si hay espacio
          if (widget.currentCuadrilla.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Más compacto
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 12,
                    color: AppColors.greenDark,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.currentCuadrilla,
                      style: TextStyle(
                        fontSize: 11, // Más pequeño
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          // Mensaje de error compacto
          Text(
            'Error al cargar datos. Los datos básicos están disponibles.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Overlay helper para mostrar el loading sobre toda la pantalla
class CuadrillasLoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Muestra una notificación de progreso no intrusiva
  static void show(
    BuildContext context, {
    required int totalCuadrillas,
    required int cuadrillasProcessed,
    required String currentCuadrilla,
    bool hasError = false,
    bool showInBackground = false,
  }) {
    // Remover overlay anterior si existe
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: CuadrillasLoadingWidget(
                  totalCuadrillas: totalCuadrillas,
                  cuadrillasProcessed: cuadrillasProcessed,
                  currentCuadrilla: currentCuadrilla,
                  hasError: hasError,
                  showInBackground: showInBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Actualiza el progreso del overlay
  static void updateProgress({
    required int cuadrillasProcessed,
    required String currentCuadrilla,
    bool hasError = false,
  }) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Oculta el overlay
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
