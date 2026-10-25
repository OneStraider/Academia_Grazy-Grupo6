class ExecucaoTreino {
  final int? id;
  final int treinoExercicioId;
  final DateTime dataExecucao;
  final int seriesRealizadas, repeticoes;
  final double carga;
  final String? exercicioNome;
  const ExecucaoTreino({
    this.id,
    required this.treinoExercicioId,
    required this.dataExecucao,
    required this.seriesRealizadas,
    required this.carga,
    required this.repeticoes,
    this.exercicioNome,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'treino_exercicio_id': treinoExercicioId,
    'data_execucao': dataExecucao.toIso8601String(),
    'series_realizadas': seriesRealizadas,
    'carga': carga,
    'repeticoes': repeticoes,
  };
  factory ExecucaoTreino.fromMap(Map<String, dynamic> map) => ExecucaoTreino(
    id: map['id'] as int?,
    treinoExercicioId: map['treino_exercicio_id'] as int,
    dataExecucao: DateTime.parse(map['data_execucao'] as String),
    seriesRealizadas: map['series_realizadas'] as int,
    carga: (map['carga'] as num).toDouble(),
    repeticoes: map['repeticoes'] as int,
    exercicioNome: map['exercicio_nome'] as String?,
  );
}
