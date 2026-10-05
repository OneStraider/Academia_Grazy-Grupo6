import 'package:flutter/material.dart';

import 'screens/home/home_shell.dart';
import 'theme/app_theme.dart';

class AcademiaGrazyApp extends StatelessWidget {
  const AcademiaGrazyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia Grazy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeShell(),
    );
  }
}