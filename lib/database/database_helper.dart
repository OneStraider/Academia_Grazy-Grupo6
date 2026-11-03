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
      version: 10,

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
      ['Guilherme', 'guilherme@academiagrazy.com', 'ALUNO'],
      ['Maria', 'maria@academiagrazy.com', 'ALUNO'],
      ['João', 'joao@academiagrazy.com', 'ALUNO'],
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
      await db.insert('exercicio', {
        'nome': item[0],
        'grupo_muscular': item[1],
        'descricao': 'Exercício de ${item[1].toLowerCase()}.',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    final professor = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT id FROM usuario WHERE tipo='PROFESSOR' LIMIT 1",
      ),
    )!;
    for (var day = 0; day < 7; day++) {
      final start = DateTime.now().add(Duration(days: day + 1));
      final slot = DateTime(start.year, start.month, start.day, 18);
      await db.insert('horario_aula', {
        'professor_id': professor,
        'nome_aula': 'Treino funcional',
        'inicio': slot.toIso8601String(),
        'capacidade': 8,
      });
    }
  }

  // Fecha o banco quando necessário.
  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}
