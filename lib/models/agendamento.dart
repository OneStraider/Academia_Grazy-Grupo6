import 'horario_aula.dart';

// MODELO: AGENDAMENTO
class Agendamento {
  final int id;
  final int alunoId;
  final int horarioId;
  final String status; // AGENDADO, CANCELADO, PRESENTE
  final String criadoEm; // ISO 8601
  final String? checkinEm; // ISO 8601, opcional

  // Campo de leitura (preenchido por JOIN, fora do toMap)
  final HorarioAula? horario;

  Agendamento({
    required this.id,
    required this.alunoId,
    required this.horarioId,
    required this.status,
    required this.criadoEm,
    this.checkinEm,
    this.horario,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aluno_id': alunoId,
      'horario_id': horarioId,
      'status': status,
      'criado_em': criadoEm,
      'checkin_em': checkinEm,
      // horario NÃO entra aqui — é preenchido por JOIN
    };
  }

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      id: map['id'] as int,
      alunoId: map['aluno_id'] as int,
      horarioId: map['horario_id'] as int,
      status: map['status'] as String,
      criadoEm: map['criado_em'] as String,
      checkinEm: map['checkin_em'] as String?,
      // horario vem de JOIN se houver
      horario: map['horario'] != null
          ? HorarioAula.fromMap(map['horario'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'Agendamento(id: $id, aluno_id: $alunoId, horario_id: $horarioId, status: $status, criado_em: $criadoEm, checkin_em: $checkinEm, horario: $horario)';
  }
}
