import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    final path = join(
      databasePath,
      'academia_grazy.db',
    );

    return await openDatabase(
      path,

      // Versão atual do banco.
      // 1 -> exercicio
      // 2 -> treino e treino_exercicio
      // 3 -> execucao_exercicio e feedback
      version: 3,

      // Habilita as foreign keys do SQLite.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      // Executado somente quando o banco é criado pela primeira vez.
      onCreate: (db, version) async {
        await db.execute(DatabaseTables.exercicio);
        await db.execute(DatabaseTables.treino);
        await db.execute(DatabaseTables.treinoExercicio);
        await db.execute(DatabaseTables.execucaoExercicio);
        await db.execute(DatabaseTables.feedback);
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
      },
    );
  }

  // Fecha o banco quando necessário.
  Future<void> close() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}