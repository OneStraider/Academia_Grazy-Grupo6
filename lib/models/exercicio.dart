class Exercicio {
  int? id;
  String nome;
  String grupoMuscular;
  String descricao;
  String? imagemUrl;

  Exercicio({
    this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.descricao,
    this.imagemUrl,
  });

  // Transforma o objeto Dart em Map para o SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'grupo_muscular': grupoMuscular,
      'descricao': descricao,
      'imagem_url': imagemUrl,
    };
  }

  // Transforma um registro do SQLite em objeto Dart
  factory Exercicio.fromMap(Map<String, dynamic> map) {
    return Exercicio(
      id: map['id'],
      nome: map['nome'],
      grupoMuscular: map['grupo_muscular'],
      descricao: map['descricao'],
      imagemUrl: map['imagem_url'],
    );
  }
}