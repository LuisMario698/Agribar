import 'package:agribar/screens/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:agribar/theme/app_styles.dart';

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
      builder: (context, child) {
        return Center(child: SizedBox(width: 1920, height: 1080, child: child));
      },
    );
  }
}
