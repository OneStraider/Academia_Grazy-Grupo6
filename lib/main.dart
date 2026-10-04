import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const AcademiaGrazyApp());
}

class AcademiaGrazyApp extends StatelessWidget {
  const AcademiaGrazyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academia Grazy',
      theme: AppTheme.theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Academia Grazy'),
        ),
        body: const Center(
          child: Text(
            'Academia Grazy',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}