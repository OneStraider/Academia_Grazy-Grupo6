class Anamnese {
  final int? id;
  final int alunoId;
  final String condicoes, medicamentos, restricoes;
  final DateTime atualizadoEm;
  const Anamnese({
    this.id,
    required this.alunoId,
    this.condicoes = '',
    this.medicamentos = '',
    this.restricoes = '',
    required this.atualizadoEm,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'aluno_id': alunoId,
    'condicoes': condicoes,
    'medicamentos': medicamentos,
    'restricoes': restricoes,
    'atualizado_em': atualizadoEm.toIso8601String(),
  };
  factory Anamnese.fromMap(Map<String, dynamic> m) => Anamnese(
    id: m['id'] as int?,
    alunoId: m['aluno_id'] as int,
    condicoes: m['condicoes'] as String,
    medicamentos: m['medicamentos'] as String,
    restricoes: m['restricoes'] as String,
    atualizadoEm: DateTime.parse(m['atualizado_em'] as String),
  );
}
