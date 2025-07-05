import 'package:agribar/services/database_service.dart';
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
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_userController.text == 'supervisor' && _passwordController.text == '1234') {
      widget.onAuthSuccess();
      await respaldarYLimpiarNominaUltimaSemana(_userController.text);
    } else {
      setState(() {
        _errorMessage = 'Usuario o contraseña incorrectos';
      });
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
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'Usuario',
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
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
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
                  onPressed: widget.onClose,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.greenDark),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.verified_user),
                  onPressed: _handleAuth,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  label: const Text('Autorizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}