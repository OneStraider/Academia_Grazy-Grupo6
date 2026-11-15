import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import 'database/database_helper.dart';
import 'services/preferencias_app_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebBasicWebWorker;
  }

  try {
    await DatabaseHelper.instance.database;
    await PreferenciasAppService.carregar();
    runApp(const AcademiaGrazyApp());
  } catch (erro, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: erro,
        stack: stackTrace,
        library: 'inicialização do Academia Grazy',
      ),
    );
    runApp(_FalhaInicializacao(erro: erro));
  }
}

class _FalhaInicializacao extends StatelessWidget {
  final Object erro;

  const _FalhaInicializacao({required this.erro});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Não foi possível iniciar o Academia Grazy.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Detalhes do erro:'),
                const SizedBox(height: 4),
                SelectableText(erro.toString()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
