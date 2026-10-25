class Agendamento {
  final int? id;
  final int horarioId, alunoId;
  final String status;
  final DateTime criadoEm;
  const Agendamento({
    this.id,
    required this.horarioId,
    required this.alunoId,
    required this.status,
    required this.criadoEm,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'horario_id': horarioId,
    'aluno_id': alunoId,
    'status': status,
    'criado_em': criadoEm.toIso8601String(),
  };
  factory Agendamento.fromMap(Map<String, dynamic> map) => Agendamento(
    id: map['id'] as int?,
    horarioId: map['horario_id'] as int,
    alunoId: map['aluno_id'] as int,
    status: map['status'] as String,
    criadoEm: DateTime.parse(map['criado_em'] as String),
  );
}
