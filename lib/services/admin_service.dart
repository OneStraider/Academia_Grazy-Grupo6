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
  final String status;

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
    required this.status,
  });
}

class AdminPontoSerie {
  final String rotulo;
  final DateTime inicio;
  final Map<String, int> valores;
  const AdminPontoSerie(this.rotulo, this.inicio, this.valores);
}

class AdminTreinoProfessorTotal {
  final int? professorId;
  final String nome;
  final int total;
  final bool semProfessor;

  const AdminTreinoProfessorTotal({
    required this.professorId,
    required this.nome,
    required this.total,
    this.semProfessor = false,
  });
}

class AdminComparativoTreinos {
  final int totalPeriodo;
  final int totalSemProfessor;
  final List<AdminTreinoProfessorTotal> professores;

  const AdminComparativoTreinos({
    required this.totalPeriodo,
    required this.totalSemProfessor,
    required this.professores,
  });

  List<AdminTreinoProfessorTotal> get barrasOrdenadas {
    final barras = [...professores];
    if (totalSemProfessor > 0) {
      barras.add(
        AdminTreinoProfessorTotal(
          professorId: null,
          nome: 'Sem professor',
          total: totalSemProfessor,
          semProfessor: true,
        ),
      );
    }
    barras.sort((a, b) {
      final porTotal = b.total.compareTo(a.total);
      return porTotal != 0 ? porTotal : a.nome.compareTo(b.nome);
    });
    return barras;
  }
}

class AdminTreinoResumo {
  final int alunoId;
  final String aluno;
  final String nome;
  final String status;
  final DateTime validade;
  final bool concluido;
  const AdminTreinoResumo({
    required this.alunoId,
    required this.aluno,
    required this.nome,
    required this.status,
    required this.validade,
    required this.concluido,
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
    if (tipo != 'TODOS' && tipo != 'ALUNO' && tipo != 'PROFESSOR') {
      throw ArgumentError.value(tipo, 'tipo', 'Perfil não permitido.');
    }
    final db = await _obterBanco();
    final rows = await db.query(
      'usuario',
      where: tipo == 'TODOS' ? 'tipo IN (?, ?)' : 'tipo = ?',
      whereArgs: tipo == 'TODOS' ? ['ALUNO', 'PROFESSOR'] : [tipo],
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
      '''SELECT a.id, a.data, a.peso, a.altura, a.massa_magra, a.status,
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
            status: row['status'] as String? ?? 'CONCLUIDA',
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

  Future<void> definirStatusAvaliacao(int id, String status) async {
    _autorizar();
    if (status != 'ABERTA' && status != 'CONCLUIDA') {
      throw ArgumentError.value(status, 'status');
    }
    final db = await _obterBanco();
    final count = await db.update(
      'avaliacao_fisica',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) throw StateError('Avaliação não encontrada.');
    DatabaseEvents.changed();
  }

  Future<void> excluirAvaliacao(int id) async {
    _autorizar();
    final db = await _obterBanco();
    final count = await db.delete(
      'avaliacao_fisica',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) throw StateError('Avaliação não encontrada.');
    DatabaseEvents.changed();
  }

  Future<List<AdminPontoSerie>> carregarSerie({
    required AdminGranularidade periodo,
    required DateTime referencia,
    required String metrica,
    int? professorId,
  }) async {
    _autorizar();
    final db = await _obterBanco();
    final buckets = _buckets(periodo, referencia);
    if (buckets.isEmpty) return const [];
    final first = buckets.first.$1;
    final last = buckets.last.$2;
    final result = <AdminPontoSerie>[];

    if (metrica == 'treinos') {
      final teachers = await db.query(
        'usuario',
        columns: ['id', 'nome'],
        where: professorId == null ? 'tipo = ?' : 'tipo = ? AND id = ?',
        whereArgs: professorId == null
            ? ['PROFESSOR']
            : ['PROFESSOR', professorId],
        orderBy: 'nome COLLATE NOCASE',
      );
      final workouts = await db.rawQuery(
        '''
        SELECT t.professor_id, t.criado_em FROM treino t
        WHERE t.professor_id IN (SELECT id FROM usuario WHERE tipo='PROFESSOR')
          AND t.criado_em >= ? AND t.criado_em < ?
          ${professorId == null ? '' : 'AND t.professor_id = ?'}
      ''',
        [first.toIso8601String(), last.toIso8601String(), ?professorId],
      );
      final datesByTeacher = <int, List<DateTime>>{};
      for (final row in workouts) {
        final date = DateTime.tryParse(row['criado_em'] as String? ?? '');
        if (date != null) {
          datesByTeacher
              .putIfAbsent((row['professor_id'] as num).toInt(), () => [])
              .add(date);
        }
      }
      for (final (inicio, fim, label) in buckets) {
        final values = <String, int>{};
        for (final teacher in teachers) {
          final id = (teacher['id'] as num).toInt();
          final name = teacher['nome'] as String;
          values[name] = (datesByTeacher[id] ?? const <DateTime>[])
              .where((date) => !date.isBefore(inicio) && date.isBefore(fim))
              .length;
        }
        result.add(AdminPontoSerie(label, inicio, values));
      }
    } else if (metrica == 'novos' || metrica == 'total') {
      final dates = await db.rawQuery(
        '''
        SELECT criado_em FROM usuario WHERE tipo='ALUNO' AND criado_em < ?
        ${metrica == 'novos' ? 'AND criado_em >= ?' : ''}
      ''',
        [
          last.toIso8601String(),
          if (metrica == 'novos') first.toIso8601String(),
        ],
      );
      final created = dates
          .map((row) => DateTime.tryParse(row['criado_em'] as String? ?? ''))
          .whereType<DateTime>()
          .toList(growable: false);
      for (final (inicio, fim, label) in buckets) {
        final count = metrica == 'novos'
            ? created
                  .where((date) => !date.isBefore(inicio) && date.isBefore(fim))
                  .length
            : created.where((date) => date.isBefore(fim)).length;
        result.add(
          AdminPontoSerie(label, inicio, {
            metrica == 'novos' ? 'Novos alunos' : 'Total de alunos': count,
          }),
        );
      }
    } else {
      throw ArgumentError.value(metrica, 'metrica');
    }
    return result;
  }

  /// Counts every created treino in the same half-open date range.
  /// Treinos whose professor is missing or is not a professor are returned in
  /// an explicit "Sem professor" total so the bars reconcile with the total.
  Future<AdminComparativoTreinos> compararTreinosPorProfessor(
    AdminPeriodo periodo,
  ) async {
    _autorizar();
    final db = await _obterBanco();
    final inicio = periodo.inicio.toIso8601String();
    final fim = periodo.fim.toIso8601String();
    final professores = await db.rawQuery(
      '''
      SELECT p.id AS professor_id, p.nome, COUNT(t.id) AS total
      FROM usuario p
      LEFT JOIN treino t
        ON t.professor_id = p.id AND t.criado_em >= ? AND t.criado_em < ?
      WHERE p.tipo = 'PROFESSOR'
      GROUP BY p.id, p.nome
      ORDER BY total DESC, p.nome COLLATE NOCASE
      ''',
      [inicio, fim],
    );
    final semProfessor =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
        SELECT COUNT(*)
        FROM treino t
        LEFT JOIN usuario p
          ON p.id = t.professor_id AND p.tipo = 'PROFESSOR'
        WHERE t.criado_em >= ? AND t.criado_em < ? AND p.id IS NULL
        ''',
            [inicio, fim],
          ),
        ) ??
        0;
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM treino WHERE criado_em >= ? AND criado_em < ?',
            [inicio, fim],
          ),
        ) ??
        0;
    final detalhes = professores
        .map(
          (row) => AdminTreinoProfessorTotal(
            professorId: (row['professor_id'] as num).toInt(),
            nome: row['nome'] as String,
            total: (row['total'] as num).toInt(),
          ),
        )
        .toList(growable: false);
    final contabilizado = detalhes.fold<int>(
      semProfessor,
      (soma, professor) => soma + professor.total,
    );
    if (contabilizado != total) {
      throw StateError(
        'O total de treinos ($total) não confere com os grupos contabilizados ($contabilizado).',
      );
    }
    return AdminComparativoTreinos(
      totalPeriodo: total,
      totalSemProfessor: semProfessor,
      professores: detalhes,
    );
  }

  Future<List<AdminTreinoResumo>> listarTreinosProfessor(
    int professorId,
  ) async {
    _autorizar();
    final db = await _obterBanco();
    final rows = await db.rawQuery(
      '''
      SELECT t.aluno_id, u.nome AS aluno, t.nome, t.status, t.validade, t.concluido_em
      FROM treino t JOIN usuario u ON u.id=t.aluno_id
      WHERE t.professor_id=? ORDER BY t.validade DESC
    ''',
      [professorId],
    );
    return rows
        .map(
          (row) => AdminTreinoResumo(
            alunoId: (row['aluno_id'] as num).toInt(),
            aluno: row['aluno'] as String,
            nome: row['nome'] as String,
            status: row['status'] as String,
            validade: DateTime.parse(row['validade'] as String),
            concluido: row['concluido_em'] != null,
          ),
        )
        .toList();
  }

  List<(DateTime, DateTime, String)> _buckets(
    AdminGranularidade periodo,
    DateTime referencia,
  ) {
    final result = <(DateTime, DateTime, String)>[];
    if (periodo == AdminGranularidade.dia) {
      final start = DateTime(referencia.year, referencia.month, referencia.day);
      result.add((
        start,
        start.add(const Duration(days: 1)),
        '${start.day}/${start.month}',
      ));
    } else if (periodo == AdminGranularidade.semana) {
      final dia = DateTime(referencia.year, referencia.month, referencia.day);
      final start = dia.subtract(Duration(days: dia.weekday - DateTime.monday));
      for (var i = 0; i < 7; i++) {
        final from = start.add(Duration(days: i));
        result.add((
          from,
          from.add(const Duration(days: 1)),
          '${from.day}/${from.month}',
        ));
      }
    } else if (periodo == AdminGranularidade.mes) {
      final start = DateTime(referencia.year, referencia.month);
      final days = DateTime(
        referencia.year,
        referencia.month + 1,
      ).difference(start).inDays;
      for (var i = 0; i < days; i += 7) {
        final from = start.add(Duration(days: i));
        final end = DateTime(
          referencia.year,
          referencia.month,
          (i + 8).clamp(1, days + 1),
        );
        result.add((
          from,
          end,
          '${from.day}–${end.subtract(const Duration(days: 1)).day}',
        ));
      }
    } else {
      final year = referencia.year;
      for (var month = 1; month <= 12; month++) {
        final from = DateTime(year, month);
        result.add((
          from,
          DateTime(year, month + 1),
          '$month/${year.toString().substring(2)}',
        ));
      }
    }
    return result;
  }
}
