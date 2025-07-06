import 'package:flutter/material.dart';
import '../theme/app_styles.dart';

/// Widget modular para el diálogo de autenticación de supervisor
/// 
/// Este widget encapsula toda la lógica del diálogo de login del supervisor
/// incluyendo validación de credenciales y manejo de errores.
class SupervisorAuthWidget extends StatefulWidget {
  /// Callback que se ejecuta cuando la autenticación es exitosa
  final VoidCallback onAuthSuccess;
  /// Callback que se ejecuta al cerrar el diálogo
  final VoidCallback onClose;

  const SupervisorAuthWidget({
    Key? key,
    required this.onAuthSuccess,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SupervisorAuthWidget> createState() => _SupervisorAuthWidgetState();
}

class _SupervisorAuthWidgetState extends State<SupervisorAuthWidget> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuth() {
    if (_userController.text == 'supervisor' && _passwordController.text == '1234') {
      widget.onAuthSuccess();
    } else {
      setState(() {
        _errorMessage = 'Usuario o contraseña incorrectos';
      });
    }
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