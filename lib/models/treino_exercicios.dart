import '../models/exercicios.dart';

class TreinoExercicio {
  final int? id;
  final int treinoId;
  final int exercicioId;
  final int ordem;
  final int series;
  final int repeticoes;
  final double carga;
  final int descansoSegundos;
  final String? observacoes;

  // Só leitura (JOIN)
  final Exercicio? exercicio;

  TreinoExercicio({
    this.id,
    required this.treinoId,
    required this.exercicioId,
    this.ordem = 0,
    required this.series,
    required this.repeticoes,
    required this.carga,
    required this.descansoSegundos,
    this.observacoes,
    this.exercicio,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'treino_id': treinoId,
        'exercicio_id': exercicioId,
        'ordem': ordem,
        'series': series,
        'repeticoes': repeticoes,
        'carga': carga,
        'descanso_segundos': descansoSegundos,
        'observacoes': observacoes,
      };

  factory TreinoExercicio.fromMap(Map<String, dynamic> map) => TreinoExercicio(
        id: map['id'] as int?,
        treinoId: map['treino_id'] as int,
        exercicioId: map['exercicio_id'] as int,
        ordem: map['ordem'] as int,
        series: map['series'] as int,
        repeticoes: map['repeticoes'] as int,
        carga: (map['carga'] as num).toDouble(),
        descansoSegundos: map['descanso_segundos'] as int,
        observacoes: map['observacoes'] as String?,
      );
}