class HorarioAula {
  final int? id;
  final int professorId;
  final String nomeAula;
  final DateTime inicio;
  final int capacidade;
  final int minParticipantes;
  final int vagas;
  final int? agendamentoId;
  final String status;
  const HorarioAula({
    this.id,
    required this.professorId,
    this.nomeAula = 'Aula de musculação',
    required this.inicio,
    required this.capacidade,
    this.minParticipantes = 1,
    this.vagas = 0,
    this.agendamentoId,
    this.status = 'LIVRE',
  });
  factory HorarioAula.fromMap(Map<String, dynamic> m) => HorarioAula(
    id: m['id'] as int?,
    professorId: m['professor_id'] as int,
    nomeAula: m['nome_aula'] as String? ?? 'Aula de musculação',
    inicio: DateTime.parse(m['inicio'] as String),
    capacidade: m['capacidade'] as int,
    minParticipantes: m['min_participantes'] as int? ?? 1,
    vagas: m['vagas'] as int? ?? 0,
    agendamentoId: m['agendamento_id'] as int?,
    status: m['status'] as String? ?? 'LIVRE',
  );
}
