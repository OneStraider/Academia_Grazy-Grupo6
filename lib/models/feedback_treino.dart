class FeedbackTreino {
  final int? id;
  final int execucaoId;
  final String nivel;
  final String? comentario;
  const FeedbackTreino({
    this.id,
    required this.execucaoId,
    required this.nivel,
    this.comentario,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'execucao_id': execucaoId,
    'nivel': nivel,
    'comentario': comentario,
  };
  factory FeedbackTreino.fromMap(Map<String, dynamic> map) => FeedbackTreino(
    id: map['id'] as int?,
    execucaoId: map['execucao_id'] as int,
    nivel: map['nivel'] as String,
    comentario: map['comentario'] as String?,
  );
}
