import 'package:flutter/material.dart';

import 'models/exercicios.dart';
import 'services/exercicios_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = ExercicioService();

  // =========================
  // 1. CADASTRAR
  // =========================

  final exercicio = Exercicio(
    nome: 'Supino Reto',
    grupoMuscular: 'Peito',
    descricao: 'Exercício para trabalhar principalmente o peitoral.',
    imagemUrl: null,
  );

  final id = await service.cadastrar(exercicio);

  print('==============================');
  print('EXERCÍCIO CADASTRADO');
  print('ID: $id');
  print('==============================');

  // =========================
  // 2. LISTAR
  // =========================

  final exercicios = await service.listar();

  print('==============================');
  print('EXERCÍCIOS CADASTRADOS');
  print('Quantidade: ${exercicios.length}');
  print('==============================');

  for (final exercicio in exercicios) {
    print(
      'ID: ${exercicio.id} | '
      'Nome: ${exercicio.nome} | '
      'Grupo: ${exercicio.grupoMuscular}',
    );
  }

  // =========================
  // 3. EDITAR
  // =========================

  final exercicioEditado = Exercicio(
    id: id,
    nome: 'Supino Reto Inclinado',
    grupoMuscular: 'Peito',
    descricao: 'Exercício para peitoral superior.',
    imagemUrl: null,
  );

  final quantidadeAtualizada =
      await service.editar(exercicioEditado);

  print('==============================');
  print('EXERCÍCIO EDITADO');
  print('Registros alterados: $quantidadeAtualizada');
  print('==============================');

  // =========================
  // 4. LISTAR NOVAMENTE
  // =========================

  final exerciciosDepoisEdicao =
      await service.listar();

  for (final exercicio in exerciciosDepoisEdicao) {
    print(
      'ID: ${exercicio.id} | '
      'Nome: ${exercicio.nome} | '
      'Grupo: ${exercicio.grupoMuscular}',
    );
  }

  // =========================
  // 5. EXCLUIR
  // =========================

  final quantidadeExcluida =
      await service.excluir(id);

  print('==============================');
  print('EXERCÍCIO EXCLUÍDO');
  print('Registros excluídos: $quantidadeExcluida');
  print('==============================');

  // =========================
  // 6. VERIFICAR EXCLUSÃO
  // =========================

  final exerciciosFinais =
      await service.listar();

  print('==============================');
  print('LISTA FINAL');
  print('Quantidade: ${exerciciosFinais.length}');
  print('==============================');

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Teste do ExercicioService concluído.\n'
            'Veja o resultado no terminal.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

