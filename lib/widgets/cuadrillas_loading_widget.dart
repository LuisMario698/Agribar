import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para mostrar el estado de carga de cuadrillas
/// Incluye animaciones y progreso de carga
class CuadrillasLoadingWidget extends StatefulWidget {
  final int totalCuadrillas;
  final int cuadrillasProcessed;
  final String currentCuadrilla;
  final bool hasError;
  final VoidCallback? onCancel;

  const CuadrillasLoadingWidget({
    super.key,
    required this.totalCuadrillas,
    required this.cuadrillasProcessed,
    required this.currentCuadrilla,
    this.hasError = false,
    this.onCancel,
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícono animado
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.hasError 
                              ? Colors.red.withOpacity(0.1)
                              : AppColors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.hasError ? Icons.error : Icons.groups,
                          size: 32,
                          color: widget.hasError ? Colors.red : AppColors.greenDark,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Título
          Text(
            widget.hasError 
                ? 'Error al cargar cuadrillas'
                : 'Cargando cuadrillas...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progreso
          if (!widget.hasError) ...[
            Text(
              'Procesando ${widget.cuadrillasProcessed} de ${widget.totalCuadrillas}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Barra de progreso
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Cuadrilla actual
            if (widget.currentCuadrilla.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Procesando: ${widget.currentCuadrilla}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ] else ...[
            // Mensaje de error
            Text(
              'Hubo un problema al cargar los datos de las cuadrillas. Por favor, intenta de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Botón de cancelar (opcional)
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                widget.hasError ? 'Cerrar' : 'Cancelar',
                style: TextStyle(
                  color: widget.hasError ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlay helper para mostrar el loading sobre toda la pantalla
class CuadrillasLoadingOverlay {
  static OverlayEntry? _overlayEntry;

  /// Muestra el overlay de loading
  static void show(
    BuildContext context, {
    required int totalCuadrillas,
    required int cuadrillasProcessed,
    required String currentCuadrilla,
    bool hasError = false,
    VoidCallback? onCancel,
  }) {
    // Remover overlay anterior si existe
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(24),
            child: CuadrillasLoadingWidget(
              totalCuadrillas: totalCuadrillas,
              cuadrillasProcessed: cuadrillasProcessed,
              currentCuadrilla: currentCuadrilla,
              hasError: hasError,
              onCancel: onCancel ?? () => hide(),
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
