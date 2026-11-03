import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';
import 'database_events.dart';
import 'password_hasher.dart';
import 'usuario_service.dart';

enum AdminGranularidade { ano, mes, semana, dia }

class AdminPeriodo {
  final AdminGranularidade granularidade;
  final DateTime referencia;
  final DateTime inicio;
  final DateTime fim;
  final DateTime inicioAnterior;

  AdminPeriodo._({
    required this.granularidade,
    required this.referencia,
    required this.inicio,
    required this.fim,
    required this.inicioAnterior,
  });

  factory AdminPeriodo.calcular(
    AdminGranularidade granularidade,
    DateTime referencia,
  ) {
    final dia = DateTime(referencia.year, referencia.month, referencia.day);
    late final DateTime inicio;
    late final DateTime fim;
    switch (granularidade) {
      case AdminGranularidade.ano:
        inicio = DateTime(referencia.year);
        fim = DateTime(referencia.year + 1);
      case AdminGranularidade.mes:
        inicio = DateTime(referencia.year, referencia.month);
        fim = DateTime(referencia.year, referencia.month + 1);
      case AdminGranularidade.semana:
        inicio = dia.subtract(Duration(days: dia.weekday - DateTime.monday));
        fim = inicio.add(const Duration(days: 7));
      case AdminGranularidade.dia:
        inicio = dia;
        fim = dia.add(const Duration(days: 1));
    }
    final anterior = switch (granularidade) {
      AdminGranularidade.ano => DateTime(inicio.year - 1),
      AdminGranularidade.mes => DateTime(inicio.year, inicio.month - 1),
      AdminGranularidade.semana => inicio.subtract(const Duration(days: 7)),
      AdminGranularidade.dia => inicio.subtract(const Duration(days: 1)),
    };
    return AdminPeriodo._(
      granularidade: granularidade,
      referencia: dia,
      inicio: inicio,
      fim: fim,
      inicioAnterior: anterior,
    );
  }

  DateTime get fimAnterior => inicio;
}

class AdminMetricas {
  final int treinos;
  final int alunos;
  final int avaliacoes;
  final int treinosAnteriores;
  final int alunosAnteriores;
  final int avaliacoesAnteriores;

  const AdminMetricas({
    required this.treinos,
    required this.alunos,
    required this.avaliacoes,
    required this.treinosAnteriores,
    required this.alunosAnteriores,
    required this.avaliacoesAnteriores,
  });
}

class AdminPessoaDetalhes {
  final Usuario usuario;
  final int treinos;
  final int avaliacoes;

  const AdminPessoaDetalhes(this.usuario, this.treinos, this.avaliacoes);
}

class AdminAvaliacaoResumo {
  final int id;
  final String aluno;
  final String professor;
  final DateTime data;
  final double peso;
  final double altura;
  final double massaMagra;
  final double? percentualGordura;
  final String? observacoes;

  const AdminAvaliacaoResumo({
    required this.id,
    required this.aluno,
    required this.professor,
    required this.data,
    required this.peso,
    required this.altura,
    required this.massaMagra,
    required this.percentualGordura,
    required this.observacoes,
  });
}

class AcessoAdminNegado implements Exception {
  const AcessoAdminNegado();

  @override
  String toString() => 'Acesso exclusivo para administradores autenticados.';
}

class AdminPermissoes {
  static bool podeAcessar(Usuario? usuario) =>
      usuario != null && usuario.ativo && usuario.ehAdmin;

  static void exigirAdmin(Usuario? usuario) {
    if (!podeAcessar(usuario)) throw const AcessoAdminNegado();
  }
}

class AdminService {
  final Future<Database> Function() _obterBanco;

  AdminService({
    DatabaseHelper? databaseHelper,
    Future<Database> Function()? databaseProvider,
  }) : _obterBanco =
           databaseProvider ??
           (() => (databaseHelper ?? DatabaseHelper.instance).database);

  static void _autorizar() =>
      AdminPermissoes.exigirAdmin(UsuarioService.usuarioLogado);

  Future<AdminMetricas> carregarMetricas(AdminPeriodo periodo) async {
    _autorizar();
    final db = await _obterBanco();
    Future<int> contar(
      String tabela,
      String colunaData,
      DateTime inicio,
      DateTime fim, {
      String? filtro,
    }) async {
      final condicao = filtro == null
          ? '$colunaData >= ? AND $colunaData < ?'
          : '$filtro AND $colunaData >= ? AND $colunaData < ?';
      final valores = filtro == null
          ? <Object?>[inicio.toIso8601String(), fim.toIso8601String()]
          : <Object?>['ALUNO', inicio.toIso8601String(), fim.toIso8601String()];
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $tabela WHERE $condicao',
              valores,
            ),
          ) ??
          0;
    }

    final inicioAnterior = periodo.inicioAnterior;
    final fimAnterior = periodo.fimAnterior;
    return AdminMetricas(
      treinos: await contar('treino', 'criado_em', periodo.inicio, periodo.fim),
      alunos: await contar(
        'usuario',
        'criado_em',
        periodo.inicio,
        periodo.fim,
        filtro: 'tipo = ?',
      ),
      avaliacoes: await contar(
        'avaliacao_fisica',
        'data',
        periodo.inicio,
        periodo.fim,
      ),
      treinosAnteriores: await contar(
        'treino',
        'criado_em',
        inicioAnterior,
        fimAnterior,
      ),
      alunosAnteriores: await contar(
        'usuario',
        'criado_em',
        inicioAnterior,
        fimAnterior,
        filtro: 'tipo = ?',
      ),
      avaliacoesAnteriores: await contar(
        'avaliacao_fisica',
        'data',
        inicioAnterior,
        fimAnterior,
      ),
    );
  }

  Future<List<Usuario>> listarPessoas({
    required String tipo,
    String busca = '',
  }) async {
    _autorizar();
    if (tipo != 'ALUNO' && tipo != 'PROFESSOR') {
      throw ArgumentError.value(tipo, 'tipo', 'Perfil não permitido.');
    }
    final db = await _obterBanco();
    final rows = await db.query(
      'usuario',
      where: 'tipo = ?',
      whereArgs: [tipo],
      orderBy: 'nome COLLATE NOCASE',
    );
    final termo = busca.trim().toLowerCase();
    return rows.map(Usuario.fromMap).where((pessoa) {
      return termo.isEmpty ||
          pessoa.nome.toLowerCase().contains(termo) ||
          pessoa.email.toLowerCase().contains(termo);
    }).toList();
  }

  Future<int> salvarPessoa({
    int? id,
    required String nome,
    required String email,
    required String tipo,
    String? senha,
  }) async {
    _autorizar();
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    if (nomeLimpo.isEmpty || !emailLimpo.contains('@')) {
      throw ArgumentError('Informe nome e e-mail válidos.');
    }
    if (tipo != 'ALUNO' && tipo != 'PROFESSOR') {
      throw ArgumentError('O perfil deve ser aluno ou professor.');
    }
    if (id == null && (senha == null || senha.trim().isEmpty)) {
      throw ArgumentError('Informe uma senha para o novo usuário.');
    }
    final db = await _obterBanco();
    final existentes = await db.query(
      'usuario',
      columns: ['id'],
      where: 'email = ? COLLATE NOCASE AND id != ?',
      whereArgs: [emailLimpo, id ?? -1],
      limit: 1,
    );
    if (existentes.isNotEmpty) {
      throw StateError('Este e-mail já está cadastrado.');
    }

    final dados = <String, Object?>{
      'nome': nomeLimpo,
      'email': emailLimpo,
      'tipo': tipo,
    };
    if (senha != null && senha.trim().isNotEmpty) {
      dados['senha_hash'] = await PasswordHasher.hash(senha);
    }
    final int pessoaId;
    if (id == null) {
      dados['ativo'] = 1;
      dados['criado_em'] = DateTime.now().toIso8601String();
      pessoaId = await db.insert('usuario', dados);
    } else {
      final alterados = await db.update(
        'usuario',
        dados,
        where: 'id = ? AND tipo IN (?, ?)',
        whereArgs: [id, 'ALUNO', 'PROFESSOR'],
      );
      if (alterados == 0) throw StateError('Pessoa não encontrada.');
      pessoaId = id;
    }
    DatabaseEvents.changed();
    return pessoaId;
  }

  Future<void> definirAtivo(int pessoaId, bool ativo) async {
    _autorizar();
    if (UsuarioService.usuarioLogado?.id == pessoaId && !ativo) {
      throw StateError('Não é possível desativar a própria conta.');
    }
    final db = await _obterBanco();
    final quantidade = await db.update(
      'usuario',
      {'ativo': ativo ? 1 : 0},
      where: 'id = ? AND tipo IN (?, ?)',
      whereArgs: [pessoaId, 'ALUNO', 'PROFESSOR'],
    );
    if (quantidade == 0) throw StateError('Pessoa não encontrada.');
    DatabaseEvents.changed();
  }

  Future<AdminPessoaDetalhes> detalhes(int pessoaId) async {
    _autorizar();
    final db = await _obterBanco();
    final pessoaRows = await db.query(
      'usuario',
      where: 'id = ? AND tipo IN (?, ?)',
      whereArgs: [pessoaId, 'ALUNO', 'PROFESSOR'],
      limit: 1,
    );
    if (pessoaRows.isEmpty) throw StateError('Pessoa não encontrada.');
    final pessoa = Usuario.fromMap(pessoaRows.first);
    final coluna = pessoa.ehAluno ? 'aluno_id' : 'professor_id';
    final treinos =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM treino WHERE $coluna = ?', [
            pessoaId,
          ]),
        ) ??
        0;
    final avaliacoes = pessoa.ehAluno
        ? Sqflite.firstIntValue(
                await db.rawQuery(
                  'SELECT COUNT(*) FROM avaliacao_fisica WHERE aluno_id = ?',
                  [pessoaId],
                ),
              ) ??
              0
        : 0;
    return AdminPessoaDetalhes(pessoa, treinos, avaliacoes);
  }

  Future<List<AdminAvaliacaoResumo>> listarAvaliacoes({
    required AdminPeriodo periodo,
    String busca = '',
  }) async {
    _autorizar();
    final db = await _obterBanco();
    final rows = await db.rawQuery(
      '''SELECT a.id, a.data, a.peso, a.altura, a.massa_magra,
                a.percentual_gordura, a.observacoes,
                aluno.nome AS aluno_nome, professor.nome AS professor_nome
         FROM avaliacao_fisica a
         JOIN usuario aluno ON aluno.id = a.aluno_id
         JOIN usuario professor ON professor.id = a.professor_id
         WHERE a.data >= ? AND a.data < ?
         ORDER BY a.data DESC''',
      [periodo.inicio.toIso8601String(), periodo.fim.toIso8601String()],
    );
    final termo = busca.trim().toLowerCase();
    return rows
        .map(
          (row) => AdminAvaliacaoResumo(
            id: (row['id'] as num).toInt(),
            aluno: row['aluno_nome'] as String,
            professor: row['professor_nome'] as String,
            data: DateTime.parse(row['data'] as String),
            peso: (row['peso'] as num).toDouble(),
            altura: (row['altura'] as num).toDouble(),
            massaMagra: (row['massa_magra'] as num).toDouble(),
            percentualGordura: (row['percentual_gordura'] as num?)?.toDouble(),
            observacoes: row['observacoes'] as String?,
          ),
        )
        .where(
          (item) =>
              termo.isEmpty ||
              item.aluno.toLowerCase().contains(termo) ||
              item.professor.toLowerCase().contains(termo),
        )
        .toList();
  }
}
