/// Pantalla de inicio de sesión
/// Proporciona la interfaz de autenticación para acceder al sistema.
/// Incluye un formulario de login y una imagen de fondo decorativa.

import 'package:flutter/material.dart';
import 'Dashboard_screen.dart';
import '../widgets/common/custom_input_field.dart';
import '../widgets/common/custom_button.dart';

/// Widget que representa la pantalla de inicio de sesión.
/// Maneja el estado del formulario de autenticación.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Estado de la pantalla de inicio de sesión
class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Row(
        children: [
          // Panel izquierdo: Formulario de inicio de sesión
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white, // Fondo blanco para el formulario
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la pantalla
                    Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Campo de usuario modularizado
                    CustomInputField(
                      controller: _usuarioController,
                      label: '',
                      hintText: 'Usuario',
                      prefix: Icon(Icons.person_outline),
                      fillColor: Color(0xFFF2F3EC),
                    ),
                    SizedBox(height: 20),
                    // Campo de contraseña modularizado
                    CustomInputField(
                      controller: _passwordController,
                      label: '',
                      hintText: 'Contraseña',
                      obscureText: true,
                      prefix: Icon(Icons.lock_outline),
                      fillColor: Color(0xFFF2F3EC),
                    ),
                    SizedBox(height: 10),
                    // Enlace para recuperar contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Botón de inicio de sesión modularizado
                    Center(
                      child: CustomButton(
                        text: 'Ingresar',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DashboardScreen(),
                            ),
                          );
                        },
                        type: ButtonType.primary,
                        backgroundColor: Color(0xFF5BA829),
                        width: 200,
                        height: 56,
                        borderRadius: BorderRadius.circular(16),
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Panel derecho: Logo e imagen de fondo
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5BA829), Color(0xFFB6D77A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 1000,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
