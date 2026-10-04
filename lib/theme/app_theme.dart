import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores principais
  static const Color primaria = Color(0xFF2F5BEA);
  static const Color primariaSuave = Color(0xFFE6EBFC);

  // Superfícies e fundos
  static const Color fundo = Color(0xFFF4F6FA);
  static const Color superficie = Color(0xFFFFFFFF);

  // Bordas
  static const Color borda = Color(0xFFE3E7EE);

  // Textos
  static const Color texto = Color(0xFF111827);
  static const Color textoSecundario = Color(0xFF5B6474);

  // Status
  static const Color sucesso = Color(0xFF0F7B4F);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: fundo,

    colorScheme: const ColorScheme.light(
      primary: primaria,
      surface: superficie,
      onPrimary: Colors.white,
      onSurface: texto,
    ),

    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: texto,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: texto,
        ),
        bodyMedium: TextStyle(
          color: textoSecundario,
        ),
        bodySmall: TextStyle(
          color: textoSecundario,
        ),
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: borda,
          width: 1,
        ),
      ),
    ),

    // Botões principais
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaria,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Campos de texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: borda,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: borda,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaria,
          width: 2,
        ),
      ),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: fundo,
      foregroundColor: texto,
      elevation: 0,
      centerTitle: false,
    ),

    // Barra inferior
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: superficie,
      elevation: 0,
      indicatorColor: primariaSuave,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: textoSecundario,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}