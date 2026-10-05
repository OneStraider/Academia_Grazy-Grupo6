import 'package:flutter/material.dart';

import 'app.dart';
import 'models/exercicios.dart';
import 'services/exercicios_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await popularExerciciosSeVazio();

  runApp(const AcademiaGrazyApp());
}

// Temporário: garante exercícios para montar treinos nos testes.
Future<void> popularExerciciosSeVazio() async {
  final service = ExercicioService();
  if ((await service.listar()).isNotEmpty) return;

  const base = [
    ['Supino reto', 'Peito'],
    ['Crucifixo', 'Peito'],
    ['Puxada frontal', 'Costas'],
    ['Remada', 'Costas'],
    ['Agachamento', 'Pernas'],
    ['Leg press', 'Pernas'],
  ];

  for (final b in base) {
    await service.cadastrar(Exercicio(
      nome: b[0],
      grupoMuscular: b[1],
      descricao: 'Exercício de ${b[1].toLowerCase()}.',
    ));
  }
}