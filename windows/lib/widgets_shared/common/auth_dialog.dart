import 'package:flutter/material.dart';
import 'dart:async';
import 'custom_input_field.dart';
import 'custom_button.dart';
import 'custom_snackbar.dart';

/// Widget para diálogos de autenticación de supervisor
/// Proporciona una interfaz estándar para validar credenciales de supervisor
class AuthDialog extends StatefulWidget {
  final String title;
  final String message;
  final String usernameLabel;
  final String passwordLabel;
  final Function(String username, String password) onAuth;

  const AuthDialog({
    Key? key,
    this.title = 'Autenticación de Supervisor',
    this.message = 'Ingrese sus credenciales para continuar',
    this.usernameLabel = 'Usuario',
    this.passwordLabel = 'Contraseña',
    required this.onAuth,
  }) : super(key: key);

  /// Método estático para mostrar el diálogo de autenticación
  /// Devuelve true si la autenticación es exitosa, false en caso contrario
  static Future<bool?> show({
    required BuildContext context,
    String title = 'Autenticación de Supervisor',
    String message = 'Ingrese sus credenciales para continuar',
    String usernameLabel = 'Usuario',
    String passwordLabel = 'Contraseña',
    required bool Function(String username, String password) onValidate,
  }) async {
    final completer = Completer<bool?>();

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AuthDialog(
          title: title,
          message: message,
          usernameLabel: usernameLabel,
          passwordLabel: passwordLabel,
          onAuth: (username, password) async {
            if (onValidate(username, password)) {
              Navigator.of(context).pop(true);
              completer.complete(true);
            } else {
              CustomSnackBar.showError(context, 'Credenciales inválidas');
              completer.complete(false);
            }
          },
        );
      },
    );

    return completer.future;
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleAuth() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onAuth(_usernameController.text, _passwordController.text);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Color(0xFF0B7A2F), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.message.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                widget.message,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 24),
            CustomInputField(
              controller: _usernameController,
              label: widget.usernameLabel,
              prefix: Icon(Icons.person_outline),
              enabled: !_isLoading,
            ),
            SizedBox(height: 16),
            CustomInputField(
              controller: _passwordController,
              label: widget.passwordLabel,
              prefix: Icon(Icons.lock_outline),
              obscureText: true,
              enabled: !_isLoading,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    type: ButtonType.secondary,
                    onPressed:
                        _isLoading
                            ? null
                            : () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Autentificar',
                    type: ButtonType.primary,
                    onPressed: _isLoading ? null : _handleAuth,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
