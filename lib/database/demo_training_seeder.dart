import 'package:sqflite/sqflite.dart';

/// Seeds a richer chart dataset only in the explicitly selected demo database.
/// Every generated row is a real treino record, clearly labeled as fictitious.
class DemoTrainingSeeder {
  static const marker = 'demo_training_history_v1';
  static const observacao =
      'Dado fictício de demonstração acadêmica (demo_training_history_v1).';

  static const professores = <String>[
    'professor@academiagrazy.com',
    'ana@academiagrazy.com',
    'bruno@academiagrazy.com',
    'camila@academiagrazy.com',
    'diego@academiagrazy.com',
    'fernanda@academiagrazy.com',
    'gustavo@academiagrazy.com',
    'helena@academiagrazy.com',
    'igor@academiagrazy.com',
    'julia@academiagrazy.com',
  ];

  static const alunos = <String>[
    'guilherme@academiagrazy.com',
    'maria@academiagrazy.com',
    'joao@academiagrazy.com',
    'larissa@academiagrazy.com',
    'pedro@academiagrazy.com',
    'beatriz@academiagrazy.com',
    'lucas@academiagrazy.com',
    'sofia@academiagrazy.com',
    'matheus@academiagrazy.com',
    'isabela@academiagrazy.com',
  ];

  static const _baseMensalPorProfessor = [3, 5, 2, 4, 6, 3, 1, 5, 2, 4];
  static const _sazonalidade = [-2, -1, 0, 1, 3, 2, 1, -2, 2, 0, 1, 3];
  static const _treinosSemanaAtual = [1, 3, 2, 4, 1, 3, 2];
  static const _nomesTreino = [
    'Força A',
    'Hipertrofia B',
    'Condicionamento',
    'Resistência',
    'Treino funcional',
  ];

  Future<void> seed(Database db, {DateTime? referencia}) async {
    final agora = referencia ?? DateTime.now();
    await db.transaction((txn) async {
      final existente = await txn.query(
        'preferencia_app',
        columns: ['chave'],
        where: 'chave = ?',
        whereArgs: [marker],
        limit: 1,
      );
      if (existente.isNotEmpty) return;

      final professorIds = await _idsPorEmail(txn, professores, 'PROFESSOR');
      final alunoIds = await _idsPorEmail(txn, alunos, 'ALUNO');
      final exercicios = await txn.query(
        'exercicio',
        columns: ['id'],
        orderBy: 'id ASC',
      );
      final exercicioIds = exercicios
          .map((row) => (row['id'] as num).toInt())
          .toList(growable: false);
      if (exercicioIds.length < 4) {
        throw StateError(
          'A base de demonstração precisa de ao menos quatro exercícios.',
        );
      }

      final registros = _gerarRegistros(
        agora,
        professorIds.length,
        alunoIds.length,
      );
      for (var i = 0; i < registros.length; i++) {
        final registro = registros[i];
        final criadoEm = registro.criadoEm;
        final treinoId = await txn.insert('treino', {
          'aluno_id': alunoIds[registro.alunoIndice],
          'professor_id': professorIds[registro.professorIndice],
          'nome': _nomesTreino[i % _nomesTreino.length],
          'validade': criadoEm
              .add(const Duration(days: 30))
              .toIso8601String()
              .substring(0, 10),
          // Historical samples are inactive plans, not completed workouts.
          'status': 'INATIVO',
          'observacoes': observacao,
          'concluido_em': null,
          'criado_em': criadoEm.toIso8601String(),
        });

        for (var ordem = 0; ordem < 4; ordem++) {
          await txn.insert('treino_exercicio', {
            'treino_id': treinoId,
            'exercicio_id': exercicioIds[(i + ordem * 3) % exercicioIds.length],
            'ordem': ordem,
            'series': 3 + (ordem % 2),
            'repeticoes': 8 + ordem * 2,
            'carga': 15 + (registro.professorIndice * 1.5) + ordem * 2,
            'descanso_segundos': 60 + ordem * 15,
            'observacoes':
                'Exercício fictício vinculado ao treino de demonstração.',
          });
        }
      }

      await txn.insert('preferencia_app', {'chave': marker, 'valor': '1'});
    });
  }

  Future<List<int>> _idsPorEmail(
    DatabaseExecutor db,
    List<String> emails,
    String tipo,
  ) async {
    final ids = <int>[];
    for (final email in emails) {
      final rows = await db.query(
        'usuario',
        columns: ['id'],
        where: 'email = ? AND tipo = ? AND ativo = 1',
        whereArgs: [email, tipo],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Conta de demonstração ativa ausente ($tipo): $email');
      }
      ids.add((rows.single['id'] as num).toInt());
    }
    return ids;
  }

  List<_DemoTreino> _gerarRegistros(
    DateTime agora,
    int totalProfessores,
    int totalAlunos,
  ) {
    if (totalProfessores != professores.length ||
        totalAlunos != alunos.length) {
      throw StateError(
        'A carga requer as dez contas de demonstração existentes.',
      );
    }

    final registros = <_DemoTreino>[];
    final semanaAtual = DateTime(
      agora.year,
      agora.month,
      agora.day,
    ).subtract(Duration(days: agora.weekday - DateTime.monday));

    // Twelve calendar months with distinct activity profiles and seasonal
    // rises/dips. Dates remain within each month and never lie after today.
    for (var offset = 11; offset >= 0; offset--) {
      final mes = DateTime(agora.year, agora.month - offset);
      final diasNoMes = DateTime(
        mes.year,
        mes.month + 1,
      ).difference(mes).inDays;
      final variacaoSazonal = _sazonalidade[(mes.month - 1) % 12];
      for (var professor = 0; professor < professores.length; professor++) {
        final variacaoIndividual = ((professor * 3 + offset * 2) % 5) - 2;
        final quantidade =
            (_baseMensalPorProfessor[professor] +
                    variacaoSazonal +
                    variacaoIndividual)
                .clamp(0, 8)
                .toInt();
        for (var ordem = 0; ordem < quantidade; ordem++) {
          final dia =
              1 +
              ((ordem * diasNoMes ~/ quantidade) + professor * 3 + offset * 5) %
                  diasNoMes;
          final criadoEm = DateTime(
            mes.year,
            mes.month,
            dia,
            8 + ((professor * 3 + ordem) % 10),
            (ordem * 11) % 60,
          );
          // The current week is seeded separately, day by day below.
          if (mes.year == agora.year && mes.month == agora.month) {
            if (!criadoEm.isBefore(semanaAtual)) continue;
          }
          if (criadoEm.isAfter(agora)) continue;
          registros.add(
            _DemoTreino(
              criadoEm: criadoEm,
              professorIndice: professor,
              alunoIndice: (professor * 3 + ordem + offset * 7) % alunos.length,
            ),
          );
        }
      }
    }

    // Current-week activity includes each elapsed weekday, with varied daily
    // totals and rotating teacher/student assignments for useful week charts.
    for (var dia = 0; dia < agora.weekday; dia++) {
      final data = semanaAtual.add(Duration(days: dia));
      final quantidade = _treinosSemanaAtual[dia];
      for (var ordem = 0; ordem < quantidade; ordem++) {
        final professor = (dia * 2 + ordem * 3) % professores.length;
        registros.add(
          _DemoTreino(
            criadoEm: DateTime(
              data.year,
              data.month,
              data.day,
              8 + ((professor + ordem) % 10),
              ordem * 9,
            ),
            professorIndice: professor,
            alunoIndice: (dia * 7 + ordem * 3 + professor) % alunos.length,
          ),
        );
      }
    }

    registros.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
    return registros;
  }
}

class _DemoTreino {
  final DateTime criadoEm;
  final int professorIndice;
  final int alunoIndice;

  const _DemoTreino({
    required this.criadoEm,
    required this.professorIndice,
    required this.alunoIndice,
  });
}
