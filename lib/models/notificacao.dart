class Notificacao {
  final int id;
  final int destinatarioId;
  final String tipo;
  final String titulo;
  final String mensagem;
  final int? treinoId;
  final int? avaliacaoId;
  final DateTime criadoEm;
  final DateTime? lidaEm;

  const Notificacao({
    required this.id,
    required this.destinatarioId,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.treinoId,
    this.avaliacaoId,
    required this.criadoEm,
    this.lidaEm,
  });

  bool get lida => lidaEm != null;
  bool get treinoConcluido => tipo == 'TREINO_CONCLUIDO';
  bool get avaliacaoRealizada => tipo == 'AVALIACAO_REALIZADA';

  factory Notificacao.fromMap(Map<String, Object?> map) => Notificacao(
    id: map['id'] as int,
    destinatarioId: map['destinatario_id'] as int,
    tipo: map['tipo'] as String,
    titulo: map['titulo'] as String,
    mensagem: map['mensagem'] as String,
    treinoId: (map['treino_id'] as num?)?.toInt(),
    avaliacaoId: (map['avaliacao_id'] as num?)?.toInt(),
    criadoEm: DateTime.parse(map['criado_em'] as String),
    lidaEm: map['lida_em'] == null
        ? null
        : DateTime.parse(map['lida_em'] as String),
  );
}
