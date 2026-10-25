/// Usuário autenticado ou armazenado na tabela `usuario`.
class Usuario {
  int? id;
  String nome;
  String email;
  String senhaHash;
  String tipo;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.tipo,
  });

  bool get ehAluno => tipo.toUpperCase() == 'ALUNO';

  bool get ehProfessor => tipo.toUpperCase() == 'PROFESSOR';

  bool get ehAdmin => tipo.toUpperCase() == 'ADMIN';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'senha_hash': senhaHash,
      'tipo': tipo,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: (map['id'] as num?)?.toInt(),
      nome: map['nome'] as String,
      email: map['email'] as String,
      senhaHash: map['senha_hash'] as String,
      tipo: map['tipo'] as String,
    );
  }
}
