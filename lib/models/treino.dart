class Treino {
  final int? id;
  final int alunoId;
  final int professorId;
  final String nome;
  final DateTime validade;
  final String status;
  final String? observacoes;
  final DateTime? concluidoEm;
  final DateTime? criadoEm;

  Treino({
    this.id,
    required this.alunoId,
    required this.professorId,
    required this.nome,
    required this.validade,
    this.status = 'ATIVO',
    this.observacoes,
    this.concluidoEm,
    this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'aluno_id': alunoId,
    'professor_id': professorId,
    'nome': nome,
    'validade': validade.toIso8601String().substring(0, 10),
    'status': status,
    'observacoes': observacoes,
    'concluido_em': concluidoEm?.toIso8601String(),
    'criado_em': criadoEm?.toIso8601String(),
  };

  factory Treino.fromMap(Map<String, dynamic> map) => Treino(
    id: map['id'] as int?,
    alunoId: map['aluno_id'] as int,
    professorId: map['professor_id'] as int,
    nome: map['nome'] as String,
    validade: DateTime.parse(map['validade'] as String),
    status: map['status'] as String,
    observacoes: map['observacoes'] as String?,
    concluidoEm: map['concluido_em'] == null
        ? null
        : DateTime.parse(map['concluido_em'] as String),
    criadoEm: map['criado_em'] == null
        ? null
        : DateTime.tryParse(map['criado_em'] as String),
  );
}
