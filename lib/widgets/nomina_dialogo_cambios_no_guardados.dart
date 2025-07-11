import 'package:flutter/material.dart';

/// Widget para manejar cambios no guardados en la pantalla de nómina
/// Muestra un diálogo de confirmación cuando el usuario intenta salir
/// sin guardar los cambios realizados
class NominaDialogoCambiosNoGuardados {
  
  /// Muestra un diálogo de confirmación para cambios no guardados
  /// 
  /// [context] - Contexto de la aplicación
  /// [onGuardar] - Función que se ejecuta para guardar los cambios
  /// [onSalirSinGuardar] - Función que se ejecuta si el usuario decide salir sin guardar
  /// [onCancelar] - Función opcional que se ejecuta si el usuario cancela (por defecto cierra el diálogo)
  /// 
  /// Retorna `true` si el usuario confirma salir, `false` si cancela
  static Future<bool> mostrarDialogo({
    required BuildContext context,
    required VoidCallback onGuardar,
    required VoidCallback onSalirSinGuardar,
    VoidCallback? onCancelar,
    String? mensaje,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cambios sin guardar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensaje ?? 
                'Tienes cambios sin guardar en la nómina. Si sales ahora, se perderán todos los datos modificados.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¿Qué deseas hacer con los cambios?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Botón Cancelar
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onCancelar != null) {
                  onCancelar();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Botón Salir sin guardar
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onSalirSinGuardar();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.exit_to_app, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Salir sin guardar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón Guardar y salir
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onGuardar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Guardar y salir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Método auxiliar para mostrar un diálogo simple de confirmación de salida
  /// cuando hay cambios pendientes pero no se especifica una acción de guardado
  static Future<bool> mostrarConfirmacionSalida({
    required BuildContext context,
    String? titulo,
    String? mensaje,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo ?? 'Confirmar salida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            mensaje ?? 
            'Hay cambios sin guardar. ¿Estás seguro de que deseas salir?',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Salir'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
}

/// Mixin para facilitar el uso del diálogo de cambios no guardados
/// en widgets que necesiten esta funcionalidad
mixin CambiosNoGuardadosMixin<T extends StatefulWidget> on State<T> {
  bool _tieneCambiosNoGuardados = false;
  
  /// Indica si hay cambios no guardados
  bool get tieneCambiosNoGuardados => _tieneCambiosNoGuardados;
  
  /// Marca que hay cambios no guardados
  void marcarCambiosNoGuardados() {
    setState(() {
      _tieneCambiosNoGuardados = true;
    });
  }
  
  /// Marca que los cambios han sido guardados
  void marcarCambiosGuardados() {
    setState(() {
      _tieneCambiosNoGuardados = false;
    });
  }
  
  /// Maneja la salida con verificación de cambios no guardados
  Future<bool> manejarSalida({
    required VoidCallback onGuardar,
    required VoidCallback onSalirSinGuardar,
    VoidCallback? onCancelar,
    String? mensaje,
  }) async {
    if (!_tieneCambiosNoGuardados) {
      return true; // No hay cambios, permitir salir
    }
    
    return await NominaDialogoCambiosNoGuardados.mostrarDialogo(
      context: context,
      onGuardar: onGuardar,
      onSalirSinGuardar: onSalirSinGuardar,
      onCancelar: onCancelar,
      mensaje: mensaje,
    );
  }
}

/// Widget Wrapper que intercepta el back button y maneja cambios no guardados
class InterceptorSalidaNomina extends StatelessWidget {
  final Widget child;
  final bool tieneCambiosNoGuardados;
  final VoidCallback onGuardar;
  final VoidCallback? onSalirSinGuardar;
  final String? mensajePersonalizado;

  const InterceptorSalidaNomina({
    Key? key,
    required this.child,
    required this.tieneCambiosNoGuardados,
    required this.onGuardar,
    this.onSalirSinGuardar,
    this.mensajePersonalizado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!tieneCambiosNoGuardados) {
          return true; // Permitir salir si no hay cambios
        }
        
        return await NominaDialogoCambiosNoGuardados.mostrarDialogo(
          context: context,
          onGuardar: onGuardar,
          onSalirSinGuardar: onSalirSinGuardar ?? () {},
          mensaje: mensajePersonalizado,
        );
      },
      child: child,
    );
  }
}
