/// Archivo de estilos globales de la aplicación.
/// Define colores, dimensiones y estilos de texto consistentes para toda la aplicación.

import 'package:flutter/material.dart';

/// Clase que define la paleta de colores de la aplicación.
/// Contiene constantes de color utilizadas en toda la interfaz de usuario.
class AppColors {
  // Colores principales
  static const green = Color(0xFF7BAE2F); // Color primario verde
  static const greenDark = Color(0xFF43A047); // Variante oscura del verde
  static const background = Color(0xFFF3E9D2); // Color de fondo principal

  // Colores para tablas
  static const tableHeader = Color(0xFFF3F3F3); // Color de encabezado de tabla
  static const tableBorder = Color(0xFFBDBDBD); // Color de bordes de tabla

  // Colores básicos
  static const white = Colors.white;
  static const black12 = Colors.black12;
  static const black26 = Colors.black26;

  // Colores para tema oscuro
  static const darkBackground = Color(0xFF232323); // Fondo en modo oscuro
  static const darkCard = Color(0xFF2D2D2D); // Color de tarjetas en modo oscuro
  static const darkTableHeader = Color(
    0xFF333333,
  ); // Encabezado de tabla en modo oscuro
  static const darkText = Color(0xFFEFEFEF); // Color de texto en modo oscuro
}

/// Clase que define las dimensiones consistentes en toda la aplicación.
/// Mantiene la coherencia visual entre diferentes componentes.
class AppDimens {
  // Dimensiones de tarjetas
  static const cardRadius = 18.0; // Radio de borde de tarjetas
  static const cardShadowBlur = 12.0; // Desenfoque de sombra de tarjetas
  static const tableCardPadding = 8.0; // Relleno interno de tarjetas de tabla

  // Dimensiones de indicadores
  static const indicatorCardWidth = 260.0; // Ancho de tarjeta de indicador
  static const indicatorCardHeight = 80.0; // Alto de tarjeta de indicador
  static const indicatorIconSize = 22.0; // Tamaño de icono de indicador

  // Dimensiones de botones
  static const buttonRadius = 12.0; // Radio de borde de botones
  static const buttonFontSize = 16.0; // Tamaño de fuente de botones

  // Espaciado de tabla
  static const tableButtonTop = 12.0; // Margen superior de botones en tabla
  static const tableButtonRight = 40.0; // Margen derecho de botones en tabla

  // Anchos de columnas de tabla
  static const columnClaveWidth = 60.0; // Ancho de columna de clave
  static const columnNombreWidth = 150.0; // Ancho de columna de nombre
  static const columnTotalSemanalWidth =
      100.0; // Ancho de columna total semanal
  static const columnComederoWidth = 70.0; // Ancho de columna de comedero
  static const columnObsWidth = 150.0; // Ancho de columna de observaciones
  static const columnOtrasPercWidth =
      150.0; // Ancho de columna otras percepciones
  static const columnDeduccionesWidth = 100.0; // Ancho de columna deducciones
  static const columnNetoWidth = 120.0; // Ancho de columna neto
}

/// Clase que define los estilos de texto utilizados en la aplicación.
/// Proporciona consistencia tipográfica en toda la interfaz.
class AppTextStyles {
  // Estilos de tabla
  static const tableHeader = TextStyle(
    // Estilo de encabezado de tabla
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );
  static const tableCell = TextStyle(
    // Estilo de celda de tabla
    fontSize: 14,
  );
  static const indicatorLabel = TextStyle(
    // Estilo de etiqueta de indicador
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const indicatorValue = TextStyle(
    // Estilo de valor de indicador
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  static const button = TextStyle(fontSize: 16, color: Colors.white);
}

/// Clase que define los temas de la aplicación.
/// Contiene configuraciones de tema claro y oscuro.
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
