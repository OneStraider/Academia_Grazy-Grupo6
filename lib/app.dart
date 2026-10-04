import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class AcademiaGrazyApp extends StatelessWidget {
  const AcademiaGrazyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia Grazy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Academia Grazy'),
              SizedBox(height: 8),
              Text(
                'Teste do ExercicioService concluído.\n'
                'Veja o resultado no terminal.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
