/// Usuário autenticado ou armazenado na tabela `usuario`.
class Usuario {
  int? id;
  String nome;
  String email;
  String senhaHash;
  String tipo;
  bool ativo;
  DateTime? criadoEm;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.tipo,
    this.ativo = true,
    this.criadoEm,
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
      'ativo': ativo ? 1 : 0,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: (map['id'] as num?)?.toInt(),
      nome: map['nome'] as String,
      email: map['email'] as String,
      senhaHash: map['senha_hash'] as String,
      tipo: map['tipo'] as String,
      ativo: (map['ativo'] as num?)?.toInt() != 0,
      criadoEm: map['criado_em'] == null
          ? null
          : DateTime.tryParse(map['criado_em'] as String),
    );
  }
}
