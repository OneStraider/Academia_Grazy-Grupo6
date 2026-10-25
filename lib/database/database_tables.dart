class DatabaseTables {
  static const String usuario = '''CREATE TABLE usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE, senha_hash TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK(tipo IN ('ADMIN','PROFESSOR','ALUNO'))
  )''';
  static const String exercicio = '''CREATE TABLE exercicio (
    id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT NOT NULL,
    grupo_muscular TEXT NOT NULL, descricao TEXT NOT NULL, imagem_url TEXT
  )''';
  static const String treino = '''CREATE TABLE treino (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    aluno_id INTEGER NOT NULL REFERENCES usuario(id),
    professor_id INTEGER NOT NULL REFERENCES usuario(id), nome TEXT NOT NULL,
    validade TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'ATIVO', observacoes TEXT
  )''';
  static const String treinoExercicio = '''CREATE TABLE treino_exercicio (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    treino_id INTEGER NOT NULL REFERENCES treino(id) ON DELETE CASCADE,
    exercicio_id INTEGER NOT NULL REFERENCES exercicio(id), ordem INTEGER NOT NULL DEFAULT 0,
    series INTEGER NOT NULL, repeticoes INTEGER NOT NULL, carga REAL NOT NULL,
    descanso_segundos INTEGER NOT NULL, observacoes TEXT
  )''';
  static const String execucaoExercicio = '''CREATE TABLE execucao_exercicio (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    treino_exercicio_id INTEGER NOT NULL REFERENCES treino_exercicio(id) ON DELETE CASCADE,
    data_execucao TEXT NOT NULL, series_realizadas INTEGER NOT NULL,
    carga REAL NOT NULL, repeticoes INTEGER NOT NULL
  )''';
  static const String feedback = '''CREATE TABLE feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    execucao_id INTEGER NOT NULL REFERENCES execucao_exercicio(id) ON DELETE CASCADE,
    nivel TEXT NOT NULL, comentario TEXT
  )''';
  static const String horarioAula = '''CREATE TABLE horario_aula (
    id INTEGER PRIMARY KEY AUTOINCREMENT, professor_id INTEGER NOT NULL REFERENCES usuario(id),
    nome_aula TEXT NOT NULL, inicio TEXT NOT NULL,
    capacidade INTEGER NOT NULL CHECK(capacidade > 0),
    min_participantes INTEGER NOT NULL DEFAULT 1 CHECK(min_participantes > 0),
    ativo INTEGER NOT NULL DEFAULT 1
  )''';
  static const String agendamento = '''CREATE TABLE agendamento (
    id INTEGER PRIMARY KEY AUTOINCREMENT, horario_id INTEGER NOT NULL REFERENCES horario_aula(id),
    aluno_id INTEGER NOT NULL REFERENCES usuario(id), status TEXT NOT NULL DEFAULT 'AGENDADO',
    criado_em TEXT NOT NULL
  )''';
  static const String avaliacao = '''CREATE TABLE avaliacao_fisica (
    id INTEGER PRIMARY KEY AUTOINCREMENT, aluno_id INTEGER NOT NULL REFERENCES usuario(id),
    professor_id INTEGER NOT NULL REFERENCES usuario(id), data TEXT NOT NULL,
    peso REAL NOT NULL, altura REAL NOT NULL, percentual_gordura REAL,
    massa_magra REAL NOT NULL, observacoes TEXT
  )''';
  static const String anamnese = '''CREATE TABLE anamnese (
    id INTEGER PRIMARY KEY AUTOINCREMENT, aluno_id INTEGER NOT NULL UNIQUE REFERENCES usuario(id),
    condicoes TEXT NOT NULL DEFAULT '', medicamentos TEXT NOT NULL DEFAULT '',
    restricoes TEXT NOT NULL DEFAULT '', atualizado_em TEXT NOT NULL
  )''';
}
