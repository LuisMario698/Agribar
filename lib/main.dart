import 'package:agribar/screens/Login_screen.dart';
import 'package:agribar/screens/Dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:agribar/theme/app_styles.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

void main() async {
  // Asegura que Flutter esté inicializado correctamente
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración específica para plataformas de escritorio
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Definir opciones de ventana predeterminadas
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1820, 960), // Tamaño inicial de la venta
      minimumSize: Size(1220, 770), // Tamaño mínimo permitido
      maximumSize: Size(1920, 1080), // Tamaño maximo permitido
      center: true, // Centrar la ventana al inicio
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // Mostrar y enfocar la ventana una vez que esté lista
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(MainApp());
}

/// Widget principal que representa la aplicación.
/// Maneja el estado global del tema de la aplicación.
class MainApp extends StatefulWidget {
  /// Método estático para acceder al estado de MainApp desde cualquier parte de la app
  static _MainAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainAppState>();
  @override
  State<MainApp> createState() => _MainAppState();
}

/// Estado del widget MainApp que mantiene la configuración del tema
class _MainAppState extends State<MainApp> {
  // Estado actual del tema de la aplicación
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  /// Método para cambiar el tema de la aplicación
  /// [mode] - El nuevo modo de tema a aplicar
  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: _themeMode,
      // ✅ Login habilitado - Los usuarios deben autenticarse
      home: const LoginScreen(),
      
      // 🔧 Configuración para mejorar el manejo de eventos de teclado
      debugShowCheckedModeBanner: false,
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Español
      ],
      builder: (context, child) {
        // 🔧 Wrapper para manejar mejor los eventos de teclado y errores
        return Container(
          color: const Color(0xFFF5EDD8), 
          child: MediaQuery(
            // 🔧 Configuración de MediaQuery para mejorar la respuesta táctil
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // Prevenir escalado excesivo de texto
            ),
            child: child ?? Container(),
          ),
        );
      },
    );
  }
}
