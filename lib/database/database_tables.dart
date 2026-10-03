class DatabaseTables {
  // 1. USUARIO
  static const String createUsuarioTable = '''
    CREATE TABLE usuario (
      id INTEGER PRIMARY KEY,
      nome TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      senha_hash TEXT NOT NULL,
      tipo TEXT NOT NULL
    )
  ''';

  // 2. EXERCICIO
  static const String createExercicioTable = '''
    CREATE TABLE exercicio (
      id INTEGER PRIMARY KEY,
      nome TEXT NOT NULL,
      grupo_muscular TEXT NOT NULL,
      descricao TEXT NOT NULL,
      imagem_url TEXT
    )
  ''';

  // 3. TREINO
  static const String createTreinoTable = '''
    CREATE TABLE treino (
      id INTEGER PRIMARY KEY,
      aluno_id INTEGER NOT NULL,
      professor_id INTEGER NOT NULL,
      nome TEXT NOT NULL,
      validade TEXT NOT NULL,
      status TEXT NOT NULL,
      observacoes TEXT,
      FOREIGN KEY (aluno_id) REFERENCES usuario (id) ON DELETE CASCADE,
      FOREIGN KEY (professor_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  // 4. TREINO_EXERCICIO (associativa)
  static const String createTreinoExercicioTable = '''
    CREATE TABLE treino_exercicio (
      id INTEGER PRIMARY KEY,
      treino_id INTEGER NOT NULL,
      exercicio_id INTEGER NOT NULL,
      ordem INTEGER NOT NULL,
      series INTEGER NOT NULL,
      repeticoes INTEGER NOT NULL,
      carga REAL NOT NULL,
      descanso_segundos INTEGER NOT NULL,
      observacoes TEXT,
      FOREIGN KEY (treino_id) REFERENCES treino (id) ON DELETE CASCADE,
      FOREIGN KEY (exercicio_id) REFERENCES exercicio (id)
    )
  ''';

  // 5. EXECUCAO_TREINO
  static const String createExecucaoTreinoTable = '''
    CREATE TABLE execucao_treino (
      id INTEGER PRIMARY KEY,
      treino_exercicio_id INTEGER NOT NULL,
      aluno_id INTEGER NOT NULL,
      data TEXT NOT NULL,
      series_concluidas INTEGER NOT NULL,
      repeticoes_feitas INTEGER NOT NULL,
      carga_usada REAL NOT NULL,
      duracao_segundos INTEGER NOT NULL,
      FOREIGN KEY (treino_exercicio_id) REFERENCES treino_exercicio (id) ON DELETE CASCADE,
      FOREIGN KEY (aluno_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  // 6. FEEDBACK_TREINO
  static const String createFeedbackTreinoTable = '''
    CREATE TABLE feedback_treino (
      id INTEGER PRIMARY KEY,
      execucao_id INTEGER NOT NULL UNIQUE,
      dificuldade TEXT NOT NULL,
      comentario TEXT,
      data TEXT NOT NULL,
      FOREIGN KEY (execucao_id) REFERENCES execucao_treino (id) ON DELETE CASCADE
    )
  ''';

  // 7. HORARIO_AULA
  static const String createHorarioAulaTable = '''
    CREATE TABLE horario_aula (
      id INTEGER PRIMARY KEY,
      modalidade TEXT NOT NULL,
      data TEXT NOT NULL,
      horario TEXT NOT NULL,
      professor_id INTEGER NOT NULL,
      vagas_totais INTEGER NOT NULL,
      FOREIGN KEY (professor_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  // 8. AGENDAMENTO (associativa)
  static const String createAgendamentoTable = '''
    CREATE TABLE agendamento (
      id INTEGER PRIMARY KEY,
      aluno_id INTEGER NOT NULL,
      horario_id INTEGER NOT NULL,
      status TEXT NOT NULL,
      criado_em TEXT NOT NULL,
      checkin_em TEXT,
      FOREIGN KEY (aluno_id) REFERENCES usuario (id) ON DELETE CASCADE,
      FOREIGN KEY (horario_id) REFERENCES horario_aula (id) ON DELETE CASCADE
    )
  ''';

  // 9. AVALIACAO_FISICA
  static const String createAvaliacaoFisicaTable = '''
    CREATE TABLE avaliacao_fisica (
      id INTEGER PRIMARY KEY,
      aluno_id INTEGER NOT NULL,
      professor_id INTEGER NOT NULL,
      data TEXT NOT NULL,
      peso REAL NOT NULL,
      altura REAL NOT NULL,
      percentual_gordura REAL NOT NULL,
      massa_magra REAL NOT NULL,
      FOREIGN KEY (aluno_id) REFERENCES usuario (id) ON DELETE CASCADE,
      FOREIGN KEY (professor_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  // 10. ANAMNESE
  static const String createAnamneseTable = '''
    CREATE TABLE anamnese (
      id INTEGER PRIMARY KEY,
      aluno_id INTEGER NOT NULL UNIQUE,
      data TEXT NOT NULL,
      possui_restricao INTEGER NOT NULL,
      lesoes TEXT,
      medicamentos TEXT,
      observacoes TEXT,
      FOREIGN KEY (aluno_id) REFERENCES usuario (id) ON DELETE CASCADE
    )
  ''';

  // Lista de todas as tabelas na ordem correta (importante para criar sem erros de FK)
  static const List<String> todas = [
    createUsuarioTable,
    createExercicioTable,
    createTreinoTable,
    createTreinoExercicioTable,
    createExecucaoTreinoTable,
    createFeedbackTreinoTable,
    createHorarioAulaTable,
    createAgendamentoTable,
    createAvaliacaoFisicaTable,
    createAnamneseTable,
  ];
}
