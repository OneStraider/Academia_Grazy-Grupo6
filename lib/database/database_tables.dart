class DatabaseTables {
  static const String exercicio = '''
    CREATE TABLE exercicio (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      grupo_muscular TEXT NOT NULL,
      descricao TEXT NOT NULL,
      imagem_url TEXT
    )
  ''';

  static const String treino = '''
    CREATE TABLE treino (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      aluno_id INTEGER NOT NULL,
      professor_id INTEGER NOT NULL,
      nome TEXT NOT NULL,
      validade TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'ATIVO',
      observacoes TEXT
    )
  ''';

  static const String treinoExercicio = '''
    CREATE TABLE treino_exercicio (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      treino_id INTEGER NOT NULL,
      exercicio_id INTEGER NOT NULL,
      ordem INTEGER NOT NULL DEFAULT 0,
      series INTEGER NOT NULL,
      repeticoes INTEGER NOT NULL,
      carga REAL NOT NULL,
      descanso_segundos INTEGER NOT NULL,
      observacoes TEXT,

      FOREIGN KEY (treino_id)
        REFERENCES treino (id)
        ON DELETE CASCADE,

      FOREIGN KEY (exercicio_id)
        REFERENCES exercicio (id)
        ON DELETE CASCADE
    )
  ''';
}

