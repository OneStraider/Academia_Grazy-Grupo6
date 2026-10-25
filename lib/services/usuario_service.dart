import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';

class UsuarioService {
  final DatabaseHelper databaseHelper;

  UsuarioService({DatabaseHelper? databaseHelper})
      : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static Usuario? usuarioLogado;

  /// Gera o hash SHA-256 usado para nunca salvar a senha em texto puro.
  static String gerarHash(String senha) {
    return sha256.convert(utf8.encode(senha)).toString();
  }

  Future<int> cadastrar(Usuario usuario, String senha) async {
    if (senha.isEmpty) {
      throw Exception('A senha não pode ser vazia');
    }

    final db = await databaseHelper.database;
    final existente = await db.query(
      'usuario',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [usuario.email],
      limit: 1,
    );

    if (existente.isNotEmpty) {
      throw Exception('E-mail já cadastrado');
    }

    final dados = usuario.toMap()
      ..remove('id')
      ..['senha_hash'] = gerarHash(senha);

    return db.insert('usuario', dados);
  }

  Future<Usuario?> login(String email, String senha) async {
    final db = await databaseHelper.database;
    final resultado = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    final usuario = Usuario.fromMap(resultado.first);
    if (usuario.senhaHash != gerarHash(senha)) {
      return null;
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
      where: 'tipo = ?',
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
