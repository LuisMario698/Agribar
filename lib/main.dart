import 'package:agribar/screens/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:agribar/theme/app_styles.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  static _MainAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainAppState>();
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

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
      home: const LoginScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Españo
      ],
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF5EDD8), // Fondo cremita global
          body: Center(
            child: SizedBox(width: 1920, height: 1080, child: child),
          ),
        );
      },
    );
  }
}
