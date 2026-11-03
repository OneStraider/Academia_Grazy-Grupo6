import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/preferencias_app_service.dart';

class AcademiaGrazyApp extends StatelessWidget {
  const AcademiaGrazyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PreferenciasAppService.modoEscuro,
      builder: (context, modoEscuro, _) => MaterialApp(
        title: 'Academia Grazy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: modoEscuro ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
