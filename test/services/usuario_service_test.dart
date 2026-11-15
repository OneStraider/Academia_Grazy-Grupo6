import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/models/usuario.dart';
import 'package:academia_grazy_grupo6/services/password_hasher.dart';
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

  test(
    'hash de senha verifica a senha e sair limpa o usuário logado',
    () async {
      final hash = await PasswordHasher.hash('123456');
      expect(await PasswordHasher.verificar('123456', hash), isTrue);
      expect(await PasswordHasher.verificar('incorreta', hash), isFalse);

      UsuarioService.usuarioLogado = Usuario(
        nome: 'Maria',
        email: 'maria@teste.com',
        senhaHash: 'hash',
        tipo: 'ALUNO',
      );
      UsuarioService().sair();

      expect(UsuarioService.usuarioLogado, isNull);
    },
  );
}
