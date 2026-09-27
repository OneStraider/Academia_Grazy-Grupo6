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
}