import 'package:flutter/material.dart';

class AppTheme {
  // Paleta oficial Grazi Braz.
  static const Color primaria = Color(0xFF06483F);
  static const Color acao = Color(0xFFE66532);
  static const Color destaque = Color(0xFFF5C644);
  static const Color apoio = Color(0xFF353B8E);

  // Tons vivos e claros para estados, cards e fundos.
  static const Color primariaSuave = Color(0xFFD9F0E8);
  static const Color acaoSuave = Color(0xFFFFE3D4);
  static const Color destaqueSuave = Color(0xFFFFF1C2);
  static const Color apoioSuave = Color(0xFFE8E9FA);
  static const Color fundo = Color(0xFFF4F7F3);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borda = Color(0xFFD9E5DE);

  static const Color texto = Color(0xFF173A34);
  static const Color textoSecundario = Color(0xFF566A64);
  static const Color sucesso = Color(0xFF087A54);
  static const Color sucessoSuave = primariaSuave;
  static const Color aviso = Color(0xFF8D5700);
  static const Color avisoSuave = destaqueSuave;
  static const Color erro = Color(0xFFB42318);
  static const Color erroSuave = Color(0xFFFDECEB);

  static const String familiaFonte = 'Barlow Condensed';

  static final TextTheme _textTheme = const TextTheme(
    displayLarge: TextStyle(
      color: primaria,
      fontSize: 38,
      height: 1.05,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: primaria,
      fontSize: 34,
      height: 1.08,
      fontWeight: FontWeight.bold,
    ),
    displaySmall: TextStyle(
      color: primaria,
      fontSize: 30,
      height: 1.1,
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: TextStyle(
      color: primaria,
      fontSize: 32,
      height: 1.1,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: primaria,
      fontSize: 29,
      height: 1.1,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: primaria,
      fontSize: 25,
      height: 1.12,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: primaria,
      fontSize: 22,
      height: 1.15,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: texto,
      fontSize: 19,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: texto,
      fontSize: 17,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: texto, fontSize: 17, height: 1.3),
    bodyMedium: TextStyle(color: textoSecundario, fontSize: 16, height: 1.3),
    bodySmall: TextStyle(color: textoSecundario, fontSize: 14, height: 1.25),
    labelLarge: TextStyle(
      color: texto,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: texto,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: TextStyle(
      color: textoSecundario,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ).apply(fontFamily: familiaFonte);

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    fontFamily: familiaFonte,
    scaffoldBackgroundColor: fundo,
    colorScheme: const ColorScheme.light(
      primary: primaria,
      onPrimary: Colors.white,
      primaryContainer: primariaSuave,
      onPrimaryContainer: texto,
      secondary: acao,
      onSecondary: texto,
      secondaryContainer: acaoSuave,
      onSecondaryContainer: texto,
      tertiary: apoio,
      onTertiary: Colors.white,
      tertiaryContainer: destaqueSuave,
      onTertiaryContainer: texto,
      surface: superficie,
      onSurface: texto,
      error: erro,
      onError: Colors.white,
    ),
    textTheme: _textTheme,
    cardTheme: CardThemeData(
      color: superficie,
      elevation: 2,
      shadowColor: primaria.withValues(alpha: .12),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borda, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: apoio,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: familiaFonte,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaria,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: familiaFonte,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaria, width: 2),
      ),
      labelStyle: const TextStyle(color: textoSecundario, fontSize: 16),
      floatingLabelStyle: const TextStyle(color: primaria, fontSize: 15),
      prefixIconColor: apoio,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaria,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: familiaFonte,
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: primaria,
      elevation: 0,
      indicatorColor: destaque,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selecionado = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: familiaFonte,
          color: selecionado ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaria, size: 24);
        }
        return const IconThemeData(color: Colors.white70, size: 22);
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: destaque,
      foregroundColor: primaria,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: apoio),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: texto,
      contentTextStyle: TextStyle(
        fontFamily: familiaFonte,
        color: Colors.white,
        fontSize: 16,
      ),
    ),
  );

  static final ThemeData darkTheme = _criarTemaEscuro();

  static ThemeData _criarTemaEscuro() {
    // A base Material 3 mantém os pares de contraste coerentes. Tons Grazy
    // próprios deixam o verde da marca confortável em superfícies escuras.
    final esquema =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF69D8B8),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF8CE5C8),
          onPrimary: const Color(0xFF00382C),
          primaryContainer: const Color(0xFF155342),
          onPrimaryContainer: const Color(0xFFB8F3DE),
          secondary: const Color(0xFFFFB394),
          onSecondary: const Color(0xFF54200A),
          secondaryContainer: const Color(0xFF75391F),
          onSecondaryContainer: const Color(0xFFFFDBCC),
          tertiary: const Color(0xFFC3C4FF),
          onTertiary: const Color(0xFF292A62),
          tertiaryContainer: const Color(0xFF41427A),
          onTertiaryContainer: const Color(0xFFE2E0FF),
          error: const Color(0xFFFFB4AB),
          onError: const Color(0xFF690005),
          errorContainer: const Color(0xFF93000A),
          onErrorContainer: const Color(0xFFFFDAD6),
          surface: const Color(0xFF0D1512),
          onSurface: const Color(0xFFE4EEE9),
          onSurfaceVariant: const Color(0xFFB7C8C0),
          surfaceContainerLowest: const Color(0xFF080E0C),
          surfaceContainerLow: const Color(0xFF121C18),
          surfaceContainer: const Color(0xFF17231E),
          surfaceContainerHigh: const Color(0xFF202E28),
          surfaceContainerHighest: const Color(0xFF293A32),
          outline: const Color(0xFF899B92),
          outlineVariant: const Color(0xFF40534A),
          inverseSurface: const Color(0xFFE4EEE9),
          onInverseSurface: const Color(0xFF26332D),
          inversePrimary: const Color(0xFF006B55),
        );
    final textoEscuro = _textTheme
        .apply(bodyColor: esquema.onSurface, displayColor: esquema.onSurface)
        .copyWith(
          bodyMedium: _textTheme.bodyMedium?.copyWith(
            color: esquema.onSurfaceVariant,
          ),
          bodySmall: _textTheme.bodySmall?.copyWith(
            color: esquema.onSurfaceVariant,
          ),
          labelSmall: _textTheme.labelSmall?.copyWith(
            color: esquema.onSurfaceVariant,
          ),
        );
    final contorno = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: esquema.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: familiaFonte,
      colorScheme: esquema,
      scaffoldBackgroundColor: esquema.surface,
      textTheme: textoEscuro,
      iconTheme: IconThemeData(color: esquema.onSurfaceVariant),
      cardTheme: CardThemeData(
        color: esquema.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surfaceContainerLow,
        foregroundColor: esquema.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: familiaFonte,
          color: esquema.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: esquema.surfaceContainerLow,
        indicatorColor: esquema.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selecionado = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: familiaFonte,
            color: selecionado ? esquema.onSurface : esquema.onSurfaceVariant,
            fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? esquema.onPrimaryContainer
                : esquema.onSurfaceVariant,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: contorno,
        enabledBorder: contorno,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
        labelStyle: TextStyle(color: esquema.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: esquema.primary),
        prefixIconColor: esquema.onSurfaceVariant,
        suffixIconColor: esquema.onSurfaceVariant,
        hintStyle: TextStyle(color: esquema.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: familiaFonte,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: esquema.primaryContainer,
          foregroundColor: esquema.onPrimaryContainer,
          minimumSize: const Size(0, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: esquema.primary,
          side: BorderSide(color: esquema.outline),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: esquema.primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: esquema.secondary,
        foregroundColor: esquema.onSecondary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: esquema.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textoEscuro.titleLarge,
        contentTextStyle: textoEscuro.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: esquema.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: esquema.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: esquema.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: familiaFonte,
          color: esquema.onInverseSurface,
          fontSize: 16,
        ),
      ),
      dividerColor: esquema.outlineVariant,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? esquema.onPrimary
              : esquema.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? esquema.primary
              : esquema.surfaceContainerHighest,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? esquema.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(esquema.onPrimary),
        side: BorderSide(color: esquema.outline),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: esquema.primary,
        linearTrackColor: esquema.surfaceContainerHighest,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: esquema.surfaceContainerHigh,
        headerBackgroundColor: esquema.primaryContainer,
        headerForegroundColor: esquema.onPrimaryContainer,
        todayForegroundColor: WidgetStateProperty.all(esquema.primary),
        todayBorder: BorderSide(color: esquema.primary),
      ),
    );
  }
}
