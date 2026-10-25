import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/models/usuario.dart';
import 'package:academia_grazy_grupo6/services/usuario_service.dart';

void main() {
  test('Usuario converte para mapa e preserva os perfis', () {
    final usuario = Usuario(
      id: 7,
      nome: 'Maria',
      email: 'maria@teste.com',
      senhaHash: 'hash',
      tipo: 'ALUNO',
    );

    final copia = Usuario.fromMap(usuario.toMap());

    expect(copia.id, 7);
    expect(copia.nome, 'Maria');
    expect(copia.email, 'maria@teste.com');
    expect(copia.senhaHash, 'hash');
    expect(copia.ehAluno, isTrue);
    expect(copia.ehProfessor, isFalse);
    expect(copia.ehAdmin, isFalse);
  });

  test('gerarHash usa SHA-256 e sair limpa o usuário logado', () {
    expect(
      UsuarioService.gerarHash('123456'),
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
    );

    UsuarioService.usuarioLogado = Usuario(
      nome: 'Maria',
      email: 'maria@teste.com',
      senhaHash: 'hash',
      tipo: 'ALUNO',
    );
    UsuarioService().sair();

    expect(UsuarioService.usuarioLogado, isNull);
  });
}
