import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'database_tables.dart';

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
      version: 6,

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
      },
    );
  }

  Future<void> _seed(Database db) async {
    final hash = sha256.convert(utf8.encode('grazy123')).toString();
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
