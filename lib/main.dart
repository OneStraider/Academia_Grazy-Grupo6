import 'package:flutter/material.dart';

import 'app.dart';
import 'database/database_helper.dart';
import 'services/preferencias_app_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;
  await PreferenciasAppService.carregar();

  runApp(const AcademiaGrazyApp());
}
