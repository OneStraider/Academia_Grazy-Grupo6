import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';
import 'database_events.dart';
import 'password_hasher.dart';
import 'recuperacao_senha_service.dart';

class UsuarioService {
  final DatabaseHelper databaseHelper;

  UsuarioService({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static Usuario? usuarioLogado;

  static const String alunoInativoMensagem =
      'Sua conta está inativa. Procure a secretaria para resolver pendências.';
  static const String professorInativoMensagem =
      'Seu acesso está inativo. Você aparece como fora da equipe; fale com a administração.';

  static String normalizarEmail(String email) => email.trim().toLowerCase();

  Future<int> cadastrar(Usuario usuario, String senha) async {
    if (!usuario.ehAluno) {
      throw StateError(
        'O cadastro público é apenas para alunos. Perfis de equipe são criados pela administração.',
      );
    }
    if (usuario.nome.trim().length < 3) {
      throw ArgumentError('Informe seu nome completo.');
    }
    final emailNormalizado = normalizarEmail(usuario.email);
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailNormalizado)) {
      throw ArgumentError('Informe um e-mail válido.');
    }
    if (senha.length < 8) {
      throw ArgumentError('A senha deve ter pelo menos 8 caracteres.');
    }

    final db = await databaseHelper.database;
    final existente = await db.query(
      'usuario',
      columns: ['id'],
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [emailNormalizado],
      limit: 1,
    );

    if (existente.isNotEmpty) {
      throw Exception('E-mail já cadastrado');
    }

    final contaApi = RecuperacaoSenhaService();
    try {
      if (contaApi.configurado) {
        await contaApi.cadastrarAluno(
          nome: usuario.nome,
          email: emailNormalizado,
          senha: senha,
        );
      }
    } finally {
      contaApi.dispose();
    }

    final hash = await PasswordHasher.hash(senha);
    final dados = usuario.toMap()
      ..remove('id')
      ..['nome'] = usuario.nome.trim()
      ..['email'] = emailNormalizado
      ..['senha_hash'] = hash
      ..['ativo'] = 1
      ..['criado_em'] = DateTime.now().toIso8601String();

    final id = await db.insert('usuario', dados);
    DatabaseEvents.changed();
    return id;
  }

  /// Atualiza o espelho local depois que o serviço remoto valida o código.
  Future<void> atualizarSenhaDepoisRecuperacao(
    String email,
    String novaSenha,
  ) async {
    if (novaSenha.trim().length < 8) {
      throw ArgumentError('A senha deve ter pelo menos 8 caracteres.');
    }
    final db = await databaseHelper.database;
    final hash = await PasswordHasher.hash(novaSenha);
    final atualizados = await db.update(
      'usuario',
      {'senha_hash': hash},
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [normalizarEmail(email)],
    );
    if (atualizados == 0) {
      throw StateError('Não há uma conta local para esse e-mail.');
    }
    DatabaseEvents.changed();
  }

  Future<Usuario?> login(String email, String senha) async {
    final db = await databaseHelper.database;
    final emailNormalizado = normalizarEmail(email);
    final resultado = await db.query(
      'usuario',
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [emailNormalizado],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    final usuario = Usuario.fromMap(resultado.first);
    final hashArmazenado = usuario.senhaHash;
    final hashLegado = sha256.convert(utf8.encode(senha)).toString();
    if (hashArmazenado.startsWith('pbkdf2_sha256\$')) {
      if (!await PasswordHasher.verificar(senha, hashArmazenado)) return null;
    } else if (hashArmazenado == hashLegado) {
      // Upgrades the old unsalted SHA-256 hash after a successful login.
      final hashAtualizado = await PasswordHasher.hash(senha);
      await db.update(
        'usuario',
        {'senha_hash': hashAtualizado},
        where: 'id = ?',
        whereArgs: [usuario.id],
      );
      usuario.senhaHash = hashAtualizado;
      DatabaseEvents.changed();
    } else {
      return null;
    }

    if (!usuario.ativo) {
      usuarioLogado = null;
      throw ContaInativaException(
        usuario.ehAluno ? alunoInativoMensagem : professorInativoMensagem,
      );
    }

    usuarioLogado = usuario;
    return usuario;
  }

  void sair() {
    usuarioLogado = null;
  }

  Future<List<Usuario>> listarAlunos() {
    return _listarPorTipo('ALUNO');
  }

  Future<List<Usuario>> listarProfessores() {
    return _listarPorTipo('PROFESSOR');
  }

  Future<List<Usuario>> _listarPorTipo(String tipo) async {
    final db = await databaseHelper.database;
    final resultado = await db.query(
      'usuario',
      where: 'tipo = ? AND ativo = 1',
      whereArgs: [tipo],
      orderBy: 'nome ASC',
    );

    return resultado.map(Usuario.fromMap).toList();
  }

  Future<Usuario?> buscarPorId(int id) async {
    final db = await databaseHelper.database;
    final resultado = await db.query(
      'usuario',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Usuario.fromMap(resultado.first);
  }
}

class ContaInativaException implements Exception {
  final String mensagem;
  const ContaInativaException(this.mensagem);

  @override
  String toString() => mensagem;
}
