import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/auth_validation_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para el diálogo de autenticación de supervisor
/// 
/// Este widget encapsula toda la lógica del diálogo de login del supervisor
/// incluyendo validación de credenciales y manejo de errores.
class NominaSupervisorAuthWidget extends StatefulWidget {
  /// Callback que se ejecuta cuando la autenticación es exitosa
  final VoidCallback onAuthSuccess;
  /// Callback que se ejecuta al cerrar el diálogo
  final VoidCallback onClose;

  const NominaSupervisorAuthWidget({
    Key? key,
    required this.onAuthSuccess,
    required this.onClose,
  }) : super(key: key);
  @override
  State<NominaSupervisorAuthWidget> createState() => _NominaSupervisorAuthWidgetState();
}

class _NominaSupervisorAuthWidgetState extends State<NominaSupervisorAuthWidget> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthValidationService _authService = AuthValidationService();
  String? _errorMessage;
  bool _isAuthenticating = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final usuario = _userController.text.trim();
    final password = _passwordController.text.trim();
    
    if (usuario.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Debe ingresar usuario y contraseña';
      });
      return;
    }
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    
    try {
      // Validar credenciales usando el servicio de autenticación
      final userData = await _authService.validarCredencialesConPermisos(
        usuario, 
        password
      );
      
      if (userData != null && userData['puede_gestionar'] == true && userData['puede_cerrar_semana'] == true) {
        // Autenticación exitosa y usuario con permisos para cerrar semanas
        widget.onAuthSuccess();
        await respaldarYLimpiarNominaUltimaSemana(userData['nombre_usuario']);
      } else {
        setState(() {
          _errorMessage = 'Usuario sin permisos para cerrar semanas o credenciales incorrectas';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }
Future<void> respaldarYLimpiarNominaUltimaSemana(String usuario) async {
  final db = DatabaseService();
  await db.connect();

  int idSemana;

  // 1. Obtener el último id_semana
  final result = await db.connection.query(
    '''
    SELECT id_semana 
    FROM semanas_nomina 
    ORDER BY fecha_inicio DESC 
    LIMIT 1;
    '''
  );
  if (result.isEmpty) {
    // No hay semanas registradas
    await db.close();
    throw Exception('No hay semanas registradas');
  }
  idSemana = result.first[0]; // o result.first['id_semana'] según tu driver

  // 2. Inicia la transacción de respaldo, limpieza y cierre
  await db.connection.transaction((ctx) async {
    // Respaldar a historial
    await ctx.query(
      '''
      INSERT INTO nomina_empleados_historial (
        id_empleado, id_semana, id_cuadrilla,
        dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
        total, debe, subtotal, comedor, total_neto,
        fecha_cierre, usuario_cierre,
        dia_7,
        act_1, act_2, act_3, act_4, act_5, act_6, act_7
      )
      SELECT
        id_empleado, id_semana, id_cuadrilla,
        dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
        total, debe, subtotal, comedor, total_neto,
        NOW(), @usuario,
        dia_7,
        act_1, act_2, act_3, act_4, act_5, act_6, act_7
      FROM nomina_empleados_semanal
      WHERE id_semana = @id_semana;
      ''',
      substitutionValues: {'usuario': usuario, 'id_semana': idSemana},
    );

    // Eliminar nómina semanal solo de esa semana
    await ctx.query(
      '''
      DELETE FROM nomina_empleados_semanal
      WHERE id_semana = @id_semana;
      ''',
      substitutionValues: {'id_semana': idSemana},
    );

    // Marcar la semana como cerrada
    await ctx.query(
      '''
      UPDATE semanas_nomina
      SET esta_cerrada = true,
          autorizado_por = @usuario,
          fecha_autorizacion = NOW()
      WHERE id_semana = @id_semana;
      ''',
      substitutionValues: {'usuario': usuario, 'id_semana': idSemana},
    );
  });

  await db.close();
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 28,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Autorización de Supervisor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo usuarios con rol de Supervisor (ID:1) o Administrador (ID:2) pueden cerrar semanas.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userController,
              enabled: !_isAuthenticating,
              decoration: InputDecoration(
                labelText: 'Usuario Supervisor/Administrador',
                hintText: 'Ingrese su nombre de usuario',
                labelStyle: TextStyle(color: AppColors.greenDark),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.greenDark,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  borderSide: BorderSide(
                    color: AppColors.greenDark,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isAuthenticating,
              obscureText: true,
              onSubmitted: (_) => _isAuthenticating ? null : _handleAuth(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingrese su contraseña',
                labelStyle: TextStyle(color: AppColors.greenDark),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.greenDark,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  borderSide: BorderSide(
                    color: AppColors.greenDark,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isAuthenticating ? null : widget.onClose,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: _isAuthenticating 
                          ? Colors.grey.shade400 
                          : AppColors.greenDark
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: _isAuthenticating 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.verified_user),
                  onPressed: _isAuthenticating ? null : _handleAuth,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  label: Text(_isAuthenticating ? 'Verificando...' : 'Autorizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}