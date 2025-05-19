import 'package:flutter/material.dart';
import '../screens/Login_screen.dart';

class AuthUtils {
  /// Cierra la sesión actual del usuario y lo redirige a la pantalla de login.

  static void logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Remueve todas las rutas anteriores
    );
  }
}
