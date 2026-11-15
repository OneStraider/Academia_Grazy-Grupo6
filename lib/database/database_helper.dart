import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';
import '../services/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  // Retorna a instância do banco.
  // Se ela já existir, reutiliza.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // Inicializa o banco de dados.
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'academia_grazy.db');

    return await openDatabase(
      path,

      // Versão atual do banco.
      // 1 -> exercicio
      // 2 -> treino e treino_exercicio
      // 3 -> execucao_exercicio e feedback
      version: 13,

      // Habilita as foreign keys do SQLite.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // Executado somente quando o banco é criado pela primeira vez.
      onCreate: (db, version) async {
        await db.execute(DatabaseTables.usuario);
        await db.execute(DatabaseTables.exercicio);
        await db.execute(DatabaseTables.treino);
        await db.execute(DatabaseTables.treinoExercicio);
        await db.execute(DatabaseTables.execucaoExercicio);
        await db.execute(DatabaseTables.feedback);
        await db.execute(DatabaseTables.horarioAula);
        await db.execute(DatabaseTables.agendamento);
        await db.execute(DatabaseTables.avaliacao);
        await db.execute(DatabaseTables.anamnese);
        await db.execute(DatabaseTables.notificacao);
        await db.execute(DatabaseTables.preferenciaApp);
        await _seed(db);
        await _seedDemoMonth(db);
      },

      // Executado quando a versão do banco aumenta.
      // Os dados que já existem no celular são mantidos.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(DatabaseTables.treino);
          await db.execute(DatabaseTables.treinoExercicio);
        }

        if (oldVersion < 3) {
          await db.execute(DatabaseTables.execucaoExercicio);
          await db.execute(DatabaseTables.feedback);
        }
        if (oldVersion < 4) {
          await db.execute(DatabaseTables.usuario);
          await db.execute(DatabaseTables.horarioAula);
          await db.execute(DatabaseTables.agendamento);
          await db.execute(DatabaseTables.avaliacao);
          await db.execute(DatabaseTables.anamnese);
          await _seed(db);
          // Antes do login, os treinos usavam IDs fixos dos mocks (professor 1,
          // alunos 1..3). Remapeia esses vínculos para as contas de demonstração.
          await db.rawUpdate(
            "UPDATE treino SET professor_id = (SELECT id FROM usuario WHERE email='professor@academiagrazy.com') WHERE professor_id = 1",
          );
          await db.rawUpdate('''
            UPDATE treino
            SET aluno_id = CASE aluno_id
              WHEN 1 THEN (SELECT id FROM usuario WHERE email='guilherme@academiagrazy.com')
              WHEN 2 THEN (SELECT id FROM usuario WHERE email='maria@academiagrazy.com')
              WHEN 3 THEN (SELECT id FROM usuario WHERE email='joao@academiagrazy.com')
              ELSE aluno_id END
            WHERE aluno_id IN (1, 2, 3)
          ''');
        }
        if (oldVersion == 4) {
          await db.execute(
            "ALTER TABLE horario_aula ADD COLUMN nome_aula TEXT NOT NULL DEFAULT 'Aula de musculação'",
          );
          await db.execute(
            'ALTER TABLE horario_aula ADD COLUMN min_participantes INTEGER NOT NULL DEFAULT 1',
          );
        } else if (oldVersion == 5) {
          await db.execute(
            'ALTER TABLE horario_aula ADD COLUMN min_participantes INTEGER NOT NULL DEFAULT 1',
          );
        }

        if (oldVersion < 7) {
          // Databases upgraded from versions before 4 create the current
          // training table above, which already includes this column.
          if (oldVersion >= 4) {
            await db.execute('ALTER TABLE treino ADD COLUMN concluido_em TEXT');
          }
          await db.execute(DatabaseTables.notificacao);
          await db.execute('''
            UPDATE treino
            SET concluido_em = (
              SELECT MAX(ex.data_execucao)
              FROM treino_exercicio te
              JOIN execucao_exercicio ex ON ex.treino_exercicio_id = te.id
              JOIN feedback f ON f.execucao_id = ex.id
              WHERE te.treino_id = treino.id
            )
            WHERE concluido_em IS NULL
              AND (SELECT COUNT(*) FROM treino_exercicio te
                   WHERE te.treino_id = treino.id) > 0
              AND (SELECT COUNT(DISTINCT te.id)
                   FROM treino_exercicio te
                   JOIN execucao_exercicio ex ON ex.treino_exercicio_id = te.id
                   JOIN feedback f ON f.execucao_id = ex.id
                   WHERE te.treino_id = treino.id)
                  = (SELECT COUNT(*) FROM treino_exercicio te
                     WHERE te.treino_id = treino.id)
          ''');
        }
        if (oldVersion < 8) {
          await db.execute(DatabaseTables.preferenciaApp);
        }
        await migrarEsquemaAdministrativo(db, oldVersion, newVersion);
        if (oldVersion < 10) {
          await _migrarNotificacoesAvaliacao(db);
        }
        if (oldVersion < 11) {
          await db.execute(
            "ALTER TABLE avaliacao_fisica ADD COLUMN status TEXT NOT NULL DEFAULT 'CONCLUIDA'",
          );
        }
        if (oldVersion < 12) {
          await _seed(db);
          await _seedDemoMonth(db);
        }
        if (oldVersion < 13) {
          await _migrarDatasTreinosDemo(db);
        }
      },
    );
  }

  /// Permite notificações ligadas a avaliações sem referência a um treino.
  /// Copia os registros existentes para preservar o histórico do usuário.
  static Future<void> _migrarNotificacoesAvaliacao(Database db) async {
    await db.execute('''
      CREATE TABLE notificacao_nova (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destinatario_id INTEGER NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL CHECK(tipo IN ('TREINO_ATRIBUIDO','TREINO_CONCLUIDO','AVALIACAO_REALIZADA')),
        titulo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        treino_id INTEGER REFERENCES treino(id) ON DELETE CASCADE,
        avaliacao_id INTEGER REFERENCES avaliacao_fisica(id) ON DELETE CASCADE,
        criado_em TEXT NOT NULL,
        lida_em TEXT
      )
    ''');
    await db.execute('''
      INSERT INTO notificacao_nova
        (id, destinatario_id, tipo, titulo, mensagem, treino_id, criado_em, lida_em)
      SELECT id, destinatario_id, tipo, titulo, mensagem, treino_id, criado_em, lida_em
      FROM notificacao
    ''');
    await db.execute('DROP TABLE notificacao');
    await db.execute('ALTER TABLE notificacao_nova RENAME TO notificacao');
  }

  /// Adiciona estado e datas administrativas sem apagar os registros existentes.
  static Future<void> migrarEsquemaAdministrativo(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= 9 || newVersion < 9) return;
    final usuarioColunas = (await db.rawQuery('PRAGMA table_info(usuario)'))
        .map((coluna) => coluna['name'] as String)
        .toSet();
    final treinoColunas = (await db.rawQuery('PRAGMA table_info(treino)'))
        .map((coluna) => coluna['name'] as String)
        .toSet();
    if (!usuarioColunas.contains('ativo')) {
      await db.execute(
        'ALTER TABLE usuario ADD COLUMN ativo INTEGER NOT NULL DEFAULT 1 CHECK(ativo IN (0,1))',
      );
    }
    if (!usuarioColunas.contains('criado_em')) {
      await db.execute('ALTER TABLE usuario ADD COLUMN criado_em TEXT');
    }
    if (!treinoColunas.contains('criado_em')) {
      await db.execute('ALTER TABLE treino ADD COLUMN criado_em TEXT');
    }
    // O esquema anterior não guardava datas de criação. Registros existentes
    // recebem a data de atualização do app como marco de início das métricas.
    await db.execute(
      "UPDATE usuario SET criado_em = strftime('%Y-%m-%dT%H:%M:%f', 'now') WHERE criado_em IS NULL",
    );
    await db.execute(
      "UPDATE treino SET criado_em = strftime('%Y-%m-%dT%H:%M:%f', 'now') WHERE criado_em IS NULL",
    );
  }

  Future<void> _seed(Database db) async {
    final hash = await PasswordHasher.hash('grazy123');
    for (final user in [
      ['Administrador', 'admin@academiagrazy.com', 'ADMIN'],
      ['Prof. Carlos', 'professor@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Ana', 'ana@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Bruno', 'bruno@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Camila', 'camila@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Diego', 'diego@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Fernanda', 'fernanda@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Gustavo', 'gustavo@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Helena', 'helena@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Igor', 'igor@academiagrazy.com', 'PROFESSOR'],
      ['Prof. Júlia', 'julia@academiagrazy.com', 'PROFESSOR'],
      ['Guilherme', 'guilherme@academiagrazy.com', 'ALUNO'],
      ['Maria', 'maria@academiagrazy.com', 'ALUNO'],
      ['João', 'joao@academiagrazy.com', 'ALUNO'],
      ['Larissa', 'larissa@academiagrazy.com', 'ALUNO'],
      ['Pedro', 'pedro@academiagrazy.com', 'ALUNO'],
      ['Beatriz', 'beatriz@academiagrazy.com', 'ALUNO'],
      ['Lucas', 'lucas@academiagrazy.com', 'ALUNO'],
      ['Sofia', 'sofia@academiagrazy.com', 'ALUNO'],
      ['Matheus', 'matheus@academiagrazy.com', 'ALUNO'],
      ['Isabela', 'isabela@academiagrazy.com', 'ALUNO'],
    ]) {
      await db.insert('usuario', {
        'nome': user[0],
        'email': user[1],
        'tipo': user[2],
        'senha_hash': hash,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final item in [
      ['Supino reto', 'Peito'],
      ['Crucifixo', 'Peito'],
      ['Flexão de braço', 'Peito'],
      ['Puxada frontal', 'Costas'],
      ['Remada baixa', 'Costas'],
      ['Remada curvada', 'Costas'],
      ['Agachamento livre', 'Pernas'],
      ['Leg press', 'Pernas'],
      ['Cadeira extensora', 'Pernas'],
      ['Rosca direta', 'Braços'],
      ['Tríceps pulley', 'Braços'],
      ['Desenvolvimento', 'Ombros'],
    ]) {
      final existentes = await db.query(
        'exercicio',
        columns: ['id'],
        where: 'nome = ? COLLATE NOCASE',
        whereArgs: [item[0]],
        limit: 1,
      );
      if (existentes.isNotEmpty) continue;
      await db.insert('exercicio', {
        'nome': item[0],
        'grupo_muscular': item[1],
        'descricao': 'Exercício de ${item[1].toLowerCase()}.',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  /// Adds a one-time, local demo dataset spanning the previous month.
  /// Existing user data is preserved; the marker prevents duplicate inserts.
  Future<void> _seedDemoMonth(Database db) async {
    final marcador = await db.query(
      'preferencia_app',
      columns: ['chave'],
      where: 'chave = ?',
      whereArgs: ['demo_seed_month_v1'],
      limit: 1,
    );
    if (marcador.isNotEmpty) return;

    final alunos = <String>[
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
    final professores = <String>[
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

    Future<int> idPorEmail(String email) async {
      final rows = await db.query(
        'usuario',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Conta de demonstração ausente: $email');
      }
      return rows.single['id'] as int;
    }

    final agora = DateTime.now();
    final inicioMes = agora.subtract(const Duration(days: 29));
    DateTime dataDemo(int indice) => indice < 7
        ? inicioMes.add(Duration(days: indice * 3, hours: indice % 5))
        : agora.subtract(Duration(days: (9 - indice) * 2, hours: 3));
    final alunoIds = <int>[];
    for (var i = 0; i < alunos.length; i++) {
      final id = await idPorEmail(alunos[i]);
      alunoIds.add(id);
      await db.update(
        'usuario',
        {'criado_em': dataDemo(i).toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    final professorIds = <int>[];
    for (final email in professores) {
      professorIds.add(await idPorEmail(email));
    }

    final exercicios = await db.query('exercicio', columns: ['id']);
    final exercicioIds = exercicios.map((row) => row['id'] as int).toList();
    if (exercicioIds.length < 4) {
      throw StateError('O catálogo precisa de ao menos quatro exercícios.');
    }

    for (var i = 0; i < alunoIds.length; i++) {
      final alunoId = alunoIds[i];
      final professorId = professorIds[i];
      final dataCriacao = dataDemo(i);
      final concluido = i % 3 == 0;
      final treinoId = await db.insert('treino', {
        'aluno_id': alunoId,
        'professor_id': professorId,
        'nome': [
          'Força A',
          'Hipertrofia B',
          'Condicionamento',
          'Resistência',
        ][i % 4],
        'validade': agora
            .add(const Duration(days: 30))
            .toIso8601String()
            .substring(0, 10),
        'status': 'ATIVO',
        'observacoes': 'Treino de demonstração para apresentação local.',
        'criado_em': dataCriacao.toIso8601String(),
        'concluido_em': concluido ? dataCriacao.toIso8601String() : null,
      });

      for (var ordem = 0; ordem < 4; ordem++) {
        final itemId = await db.insert('treino_exercicio', {
          'treino_id': treinoId,
          'exercicio_id': exercicioIds[(i + ordem) % exercicioIds.length],
          'ordem': ordem,
          'series': 3 + ordem % 2,
          'repeticoes': 8 + ordem * 2,
          'carga': 12.5 + i + ordem * 2,
          'descanso_segundos': 60 + ordem * 15,
          'observacoes': 'Série de demonstração.',
        });
        if (concluido) {
          final dataExecucao = dataCriacao.add(Duration(minutes: ordem * 12));
          final execucaoId = await db.insert('execucao_exercicio', {
            'treino_exercicio_id': itemId,
            'data_execucao': dataExecucao.toIso8601String(),
            'series_realizadas': 3 + ordem % 2,
            'carga': 12.5 + i + ordem * 2,
            'repeticoes': 8 + ordem * 2,
          });
          await db.insert('feedback', {
            'execucao_id': execucaoId,
            'nivel': const ['FACIL', 'MODERADO', 'DIFICIL'][ordem % 3],
            'comentario': 'Registro de execução de demonstração.',
          });
        }
      }
    }

    for (var i = 0; i < alunoIds.length; i++) {
      final data = inicioMes.add(Duration(days: i * 3 + 1, hours: 9));
      await db.insert('avaliacao_fisica', {
        'aluno_id': alunoIds[i],
        'professor_id': professorIds[i],
        'data': data.toIso8601String(),
        'peso': 58 + i * 3.2,
        'altura': 1.58 + (i % 6) * 0.04,
        'percentual_gordura': 18 + (i % 7) * 1.7,
        'massa_magra': 42 + i * 1.6,
        'observacoes': 'Dados fictícios de demonstração; não usar para orientação de saúde.',
        'status': i % 4 == 0 ? 'ABERTA' : 'CONCLUIDA',
      });
    }

    final nomesAula = [
      'Musculação',
      'Treino funcional',
      'Mobilidade',
      'Circuito',
    ];
    final horariosIds = <int>[];
    for (var i = 0; i < 15; i++) {
      final dia = DateTime(
        agora.year,
        agora.month,
        agora.day + i * 2 + 1,
        17 + i % 3,
      );
      final horarioId = await db.insert('horario_aula', {
        'professor_id': professorIds[i % professorIds.length],
        'nome_aula': nomesAula[i % nomesAula.length],
        'inicio': dia.toIso8601String(),
        'capacidade': 8,
        'min_participantes': 1,
      });
      horariosIds.add(horarioId);
    }
    for (var i = 0; i < 8; i++) {
      await db.insert('agendamento', {
        'horario_id': horariosIds[i],
        'aluno_id': alunoIds[i % alunoIds.length],
        'status': 'AGENDADO',
        'criado_em': agora
            .subtract(Duration(days: (i % 5) + 1))
            .toIso8601String(),
      });
    }

    await db.insert('preferencia_app', {
      'chave': 'demo_seed_month_v1',
      'valor': '1',
    });
  }

  /// Repositions seeded rows for databases that already had the first demo
  /// load, so the current-week charts show sample activity too.
  Future<void> _migrarDatasTreinosDemo(Database db) async {
    const marcador = 'demo_weekly_dates_v1';
    final jaMigrado = await db.query(
      'preferencia_app',
      columns: ['chave'],
      where: 'chave = ?',
      whereArgs: [marcador],
      limit: 1,
    );
    if (jaMigrado.isNotEmpty) return;

    const emails = [
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
    final agora = DateTime.now();
    final inicioMes = agora.subtract(const Duration(days: 29));
    for (var i = 0; i < emails.length; i++) {
      final data = i < 7
          ? inicioMes.add(Duration(days: i * 3, hours: i % 5))
          : agora.subtract(Duration(days: (9 - i) * 2, hours: 3));
      final usuario = await db.query(
        'usuario',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [emails[i]],
        limit: 1,
      );
      if (usuario.isEmpty) continue;
      final alunoId = usuario.single['id'] as int;
      await db.update(
        'usuario',
        {'criado_em': data.toIso8601String()},
        where: 'id = ?',
        whereArgs: [alunoId],
      );
      final treinos = await db.query(
        'treino',
        columns: ['id', 'concluido_em'],
        where: 'aluno_id = ? AND observacoes = ?',
        whereArgs: [alunoId, 'Treino de demonstração para apresentação local.'],
        orderBy: 'id ASC',
        limit: 1,
      );
      if (treinos.isEmpty) continue;
      final treinoId = treinos.single['id'] as int;
      final concluido = treinos.single['concluido_em'] != null;
      await db.update(
        'treino',
        {
          'criado_em': data.toIso8601String(),
          'concluido_em': concluido ? data.toIso8601String() : null,
        },
        where: 'id = ?',
        whereArgs: [treinoId],
      );
      if (concluido) {
        final itens = await db.query(
          'treino_exercicio',
          columns: ['id'],
          where: 'treino_id = ?',
          whereArgs: [treinoId],
          orderBy: 'ordem ASC',
        );
        for (var ordem = 0; ordem < itens.length; ordem++) {
          await db.update(
            'execucao_exercicio',
            {
              'data_execucao': data
                  .add(Duration(minutes: ordem * 12))
                  .toIso8601String(),
            },
            where: 'treino_exercicio_id = ?',
            whereArgs: [itens[ordem]['id']],
          );
        }
      }
    }
    await db.insert('preferencia_app', {'chave': marcador, 'valor': '1'});
  }

  // Fecha o banco quando necessário.
  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}
