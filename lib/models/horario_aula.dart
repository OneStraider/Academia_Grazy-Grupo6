// MODELO: HORARIO_AULA
class HorarioAula {
  final int id;
  final String modalidade;
  final String data; // AAAA-MM-DD
  final String horario; // HH:MM
  final int professorId;
  final int vagasTotais;

  // Campo de leitura (preenchido por JOIN, fora do toMap)
  final int? vagasDisponiveis;

  HorarioAula({
    required this.id,
    required this.modalidade,
    required this.data,
    required this.horario,
    required this.professorId,
    required this.vagasTotais,
    this.vagasDisponiveis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modalidade': modalidade,
      'data': data,
      'horario': horario,
      'professor_id': professorId,
      'vagas_totais': vagasTotais,
      // vagasDisponiveis NÃO entra aqui — é calculado na consulta
    };
  }

  factory HorarioAula.fromMap(Map<String, dynamic> map) {
    return HorarioAula(
      id: map['id'] as int,
      modalidade: map['modalidade'] as String,
      data: map['data'] as String,
      horario: map['horario'] as String,
      professorId: map['professor_id'] as int,
      vagasTotais: map['vagas_totais'] as int,
      vagasDisponiveis: map['vagas_disponiveis'] as int?,
    );
  }

  @override
  String toString() {
    return 'HorarioAula(id: $id, modalidade: $modalidade, data: $data, horario: $horario, professor_id: $professorId, vagas_totais: $vagasTotais, vagas_disponiveis: $vagasDisponiveis)';
  }
}
