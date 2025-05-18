import 'package:flutter/material.dart';

// Colores globales
class AppColors {
  static const green = Color(0xFF7BAE2F);
  static const greenDark = Color(0xFF43A047);
  static const background = Color(0xFFF3E9D2);
  static const tableHeader = Color(0xFFF3F3F3);
  static const tableBorder = Color(0xFFBDBDBD);
  static const white = Colors.white;
  static const black12 = Colors.black12;
  static const black26 = Colors.black26;
  static const darkBackground = Color(0xFF232323);
  static const darkCard = Color(0xFF2D2D2D);
  static const darkTableHeader = Color(0xFF333333);
  static const darkText = Color(0xFFEFEFEF);
}

// Dimensiones globales
class AppDimens {
  static const cardRadius = 18.0;
  static const cardShadowBlur = 12.0;
  static const tableCardPadding = 8.0;
  static const indicatorCardWidth = 260.0;
  static const indicatorCardHeight = 80.0;
  static const indicatorIconSize = 22.0;
  static const buttonRadius = 12.0;
  static const buttonFontSize = 16.0;
  static const tableButtonTop = 12.0;
  static const tableButtonRight = 40.0;
  static const columnClaveWidth = 60.0;
  static const columnNombreWidth = 150.0;
  static const columnTotalSemanalWidth = 100.0;
  static const columnComederoWidth = 70.0;
  static const columnObsWidth = 150.0;
  static const columnOtrasPercWidth = 150.0;
  static const columnDeduccionesWidth = 100.0;
  static const columnNetoWidth = 120.0;
}

// Estilos de texto globales
class AppTextStyles {
  static const tableHeader = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  static const tableCell = TextStyle(fontSize: 14);
  static const indicatorLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const indicatorValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  static const button = TextStyle(fontSize: 16, color: Colors.white);
}

class AppThemes {
  static final light = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.green,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.green,
      secondary: AppColors.greenDark,
      background: AppColors.background,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    iconTheme: IconThemeData(color: AppColors.green),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.green,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme.dark(
      primary: AppColors.green,
      secondary: AppColors.greenDark,
      background: AppColors.darkBackground,
      surface: AppColors.darkCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColors.darkText,
      onSurface: AppColors.darkText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
    ),
    cardColor: AppColors.darkCard,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkText),
      bodyMedium: TextStyle(color: AppColors.darkText),
      titleLarge: TextStyle(
        color: AppColors.darkText,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: IconThemeData(color: AppColors.green),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
