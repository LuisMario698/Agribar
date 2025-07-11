import 'package:flutter/material.dart';

/// Widget interceptor modular para manejar cambios de pestaña desde nómina
/// Verifica si hay cambios no guardados antes de permitir la navegación
class NominaTabChangeInterceptor extends StatelessWidget {
  final Widget child;
  final bool tieneCambiosNoGuardados;
  final Future<void> Function() onGuardar;
  final VoidCallback onSalirSinGuardar;
  final String? mensajePersonalizado;
  final bool Function()? verificarCambiosPersonalizado;

  const NominaTabChangeInterceptor({
    Key? key,
    required this.child,
    required this.tieneCambiosNoGuardados,
    required this.onGuardar,
    required this.onSalirSinGuardar,
    this.mensajePersonalizado,
    this.verificarCambiosPersonalizado,
  }) : super(key: key);

  /// Método estático para verificar cambios desde controladores de navegación
  static Future<bool> verificarCambiosAntesDeCambiarTab(
    BuildContext context, {
    required bool tieneCambiosNoGuardados,
    required Future<void> Function() onGuardar,
    required VoidCallback onSalirSinGuardar,
    String? mensajePersonalizado,
  }) async {
    if (!tieneCambiosNoGuardados) {
      return true; // Permitir navegación
    }

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NominaTabChangeDialog(
        onGuardar: onGuardar,
        onSalirSinGuardar: onSalirSinGuardar,
        mensajePersonalizado: mensajePersonalizado,
      ),
    );

    return resultado == true; // Solo permitir si se guardó o descartó
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!tieneCambiosNoGuardados) {
          return true; // Permitir navegación
        }

        final resultado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _NominaTabChangeDialog(
            onGuardar: onGuardar,
            onSalirSinGuardar: onSalirSinGuardar,
            mensajePersonalizado: mensajePersonalizado,
          ),
        );

        return resultado == true;
      },
      child: child,
    );
  }
}

/// Diálogo modular para confirmar cambios de pestaña
class _NominaTabChangeDialog extends StatefulWidget {
  final Future<void> Function() onGuardar;
  final VoidCallback onSalirSinGuardar;
  final String? mensajePersonalizado;

  const _NominaTabChangeDialog({
    Key? key,
    required this.onGuardar,
    required this.onSalirSinGuardar,
    this.mensajePersonalizado,
  }) : super(key: key);

  @override
  State<_NominaTabChangeDialog> createState() => _NominaTabChangeDialogState();
}

class _NominaTabChangeDialogState extends State<_NominaTabChangeDialog> {
  bool _isGuardando = false;

  Future<void> _handleGuardar() async {
    if (_isGuardando) return; // Evitar doble guardado
    
    setState(() {
      _isGuardando = true;
    });
    
    try {
      await widget.onGuardar();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // El error ya se maneja en la función de guardado, solo restauramos el estado
      if (mounted) {
        setState(() {
          _isGuardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
          minWidth: 480,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 10),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Contenido principal
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de advertencia
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    'Cambios no guardados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mensaje
                  Text(
                    widget.mensajePersonalizado ?? 
                    'Tienes cambios pendientes en la nómina que se perderán si cambias de pestaña sin guardar.\n\n¿Qué deseas hacer?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botones
                  Row(
                    children: [
                      // Botón Cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isGuardando ? null : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Botón Salir sin guardar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isGuardando ? null : () {
                            widget.onSalirSinGuardar();
                            Navigator.of(context).pop(true);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Salir sin guardar',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Botón Guardar y continuar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isGuardando ? null : _handleGuardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isGuardando 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Guardar',
                                    style: TextStyle(fontWeight: FontWeight.w600),
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
            
            // Botón X para cancelar (deshabilitado durante guardado)
            Positioned(
              right: 16,
              top: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGuardando ? null : () => Navigator.of(context).pop(false),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: _isGuardando ? Colors.grey.shade300 : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mixin para facilitar la integración del interceptor de cambios de pestaña
mixin NominaTabChangeGuardMixin<T extends StatefulWidget> on State<T> {
  
  /// Verifica cambios antes de cambiar de pestaña
  /// Retorna true si se puede continuar con el cambio
  Future<bool> verificarCambiosAntesDeCambiarTab({
    required bool tieneCambiosNoGuardados,
    required Future<void> Function() onGuardar,
    required VoidCallback onSalirSinGuardar,
    String? mensajePersonalizado,
  }) async {
    return await NominaTabChangeInterceptor.verificarCambiosAntesDeCambiarTab(
      context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: onGuardar,
      onSalirSinGuardar: onSalirSinGuardar,
      mensajePersonalizado: mensajePersonalizado,
    );
  }
}

/// Helper para integrar con controladores de navegación
class NominaTabChangeGuard {
  /// Método estático para usar en controladores de navegación
  static Future<bool> interceptarCambioTab(
    BuildContext context, {
    required bool tieneCambiosNoGuardados,
    required Future<void> Function() onGuardar,
    required VoidCallback onSalirSinGuardar,
    String? mensajePersonalizado,
  }) async {
    return await NominaTabChangeInterceptor.verificarCambiosAntesDeCambiarTab(
      context,
      tieneCambiosNoGuardados: tieneCambiosNoGuardados,
      onGuardar: onGuardar,
      onSalirSinGuardar: onSalirSinGuardar,
      mensajePersonalizado: mensajePersonalizado,
    );
  }
}
