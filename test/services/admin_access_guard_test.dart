import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/models/usuario.dart';
import 'package:academia_grazy_grupo6/screens/admin/admin_access_guard.dart';
import 'package:academia_grazy_grupo6/services/usuario_service.dart';

void main() {
  tearDown(() => UsuarioService.usuarioLogado = null);

  testWidgets('bloqueia o conteúdo administrativo para aluno autenticado', (
    tester,
  ) async {
    UsuarioService.usuarioLogado = Usuario(
      id: 3,
      nome: 'Aluna',
      email: 'aluna@teste.com',
      senhaHash: 'hash',
      tipo: 'ALUNO',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminAccessGuard(child: Text('Conteúdo confidencial')),
      ),
    );

    expect(find.text('Conteúdo confidencial'), findsNothing);
    expect(
      find.text('Este painel é exclusivo para administradores autenticados.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra o painel para admin ativo autenticado', (tester) async {
    UsuarioService.usuarioLogado = Usuario(
      id: 1,
      nome: 'Admin',
      email: 'admin@teste.com',
      senhaHash: 'hash',
      tipo: 'ADMIN',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminAccessGuard(child: Text('Conteúdo administrativo')),
      ),
    );

    expect(find.text('Conteúdo administrativo'), findsOneWidget);
  });
}
