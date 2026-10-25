import 'package:flutter/foundation.dart';

enum Papel { professor, aluno }

// Temporário: ainda não existe login nem tabela de usuários.
const int professorIdTeste = 1;
const String professorNomeTeste = 'Prof. Carlos';

const Map<int, String> alunosTeste = {
  1: 'Guilherme',
  2: 'Maria',
  3: 'João',
};

// Simula quem está logado. Muda na aba Perfil.
final ValueNotifier<Papel> papelAtual = ValueNotifier(Papel.professor);
final ValueNotifier<int> alunoLogadoId = ValueNotifier(1);