class AvaliacaoFisica {
  final int? id, alunoId, professorId;
  final DateTime data;
  final double peso, altura, massaMagra;
  final double? percentualGordura;
  final String? observacoes;
  const AvaliacaoFisica({
    this.id,
    required this.alunoId,
    required this.professorId,
    required this.data,
    required this.peso,
    required this.altura,
    this.percentualGordura,
    required this.massaMagra,
    this.observacoes,
  });
  double get imc => peso / (altura * altura);
  String get classificacaoImc => imc < 18.5
      ? 'Abaixo do peso'
      : imc < 25
      ? 'Peso normal'
      : imc < 30
      ? 'Sobrepeso'
      : 'Obesidade';
  Map<String, dynamic> toMap() => {
    'id': id,
    'aluno_id': alunoId,
    'professor_id': professorId,
    'data': data.toIso8601String(),
    'peso': peso,
    'altura': altura,
    'percentual_gordura': percentualGordura,
    'massa_magra': massaMagra,
    'observacoes': observacoes,
  };
  factory AvaliacaoFisica.fromMap(Map<String, dynamic> m) => AvaliacaoFisica(
    id: m['id'] as int?,
    alunoId: m['aluno_id'] as int,
    professorId: m['professor_id'] as int,
    data: DateTime.parse(m['data'] as String),
    peso: (m['peso'] as num).toDouble(),
    altura: (m['altura'] as num).toDouble(),
    percentualGordura: (m['percentual_gordura'] as num?)?.toDouble(),
    massaMagra: (m['massa_magra'] as num).toDouble(),
    observacoes: m['observacoes'] as String?,
  );
}
