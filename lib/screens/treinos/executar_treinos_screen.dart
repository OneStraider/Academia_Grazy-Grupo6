import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/treino.dart';
import '../../models/treino_exercicios.dart';
import '../../services/execucao_service.dart';
import '../../theme/app_theme.dart';

class _Feedback {
  final String nivel;
  final String? comentario;

  _Feedback(this.nivel, this.comentario);
}

// Execução do treino: uma série por vez, com descanso e feedback no fim
// de cada exercício.
class ExecutarTreinoScreen extends StatefulWidget {
  final Treino treino;
  final List<TreinoExercicio> itens;
  final int indiceInicial;

  const ExecutarTreinoScreen({
    super.key,
    required this.treino,
    required this.itens,
    this.indiceInicial = 0,
  });

  @override
  State<ExecutarTreinoScreen> createState() => _ExecutarTreinoScreenState();
}

class _ExecutarTreinoScreenState extends State<ExecutarTreinoScreen> {
  final _execucaoService = ExecucaoService();
  Timer? _timer;

  int _indice = 0;
  int _serieAtual = 1;
  double _carga = 0;
  int _reps = 1;
  bool _descansando = false;
  int _restante = 0;
  bool _salvando = false;

  TreinoExercicio get _item => widget.itens[_indice];
  bool get _ehUltimo => _indice == widget.itens.length - 1;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
    _carregarExercicio();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Prepara os valores do exercício atual (sem setState: quem chama decide).
  void _carregarExercicio() {
    _timer?.cancel();
    _serieAtual = 1;
    _carga = _item.carga;
    _reps = _item.repeticoes;
    _descansando = false;
    _restante = 0;
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  void _iniciarDescanso(int segundos) {
    _timer?.cancel();

    setState(() {
      _descansando = true;
      _restante = segundos;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_restante <= 1) {
        t.cancel();
        setState(() {
          _descansando = false;
          _restante = 0;
        });
      } else {
        setState(() {
          _restante--;
        });
      }
    });
  }

  void _pularDescanso() {
    _timer?.cancel();
    setState(() {
      _descansando = false;
      _restante = 0;
    });
  }

  Future<void> _finalizarSerie() async {
    final item = _item;

    if (_serieAtual < item.series) {
      setState(() {
        _serieAtual++;
      });
      _iniciarDescanso(item.descansoSegundos);
      return;
    }

    await _concluirExercicio();
  }

  Future<void> _concluirExercicio() async {
    if (_salvando) return;

    setState(() {
      _salvando = true;
    });

    final item = _item;

    try {
      // REQ-06: grava a execução.
      final execucaoId = await _execucaoService.registrarExecucao(
        treinoExercicioId: item.id!,
        series: item.series,
        carga: _carga,
        repeticoes: _reps,
      );

      if (!mounted) return;

      final feedback = await showModalBottomSheet<_Feedback>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: AppTheme.superficie,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _FeedbackSheet(
          nomeExercicio: item.exercicio!.nome,
          resumo: '${item.series} séries · ${_fmt(_carga)} kg · '
              '$_reps repetições',
        ),
      );

      // REQ-07: grava o feedback (se o aluno não tocou em "Pular").
      if (feedback != null) {
        await _execucaoService.registrarFeedback(
          execucaoId: execucaoId,
          nivel: feedback.nivel,
          comentario: feedback.comentario,
        );
      }

      if (!mounted) return;

      if (_ehUltimo) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino concluído!')),
        );
        Navigator.pop(context, true);
        return;
      }

      setState(() {
        _indice++;
        _carregarExercicio();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // "Próximo exercício": pula sem registrar. No último, encerra.
  void _proximoOuEncerrar() {
    if (_ehUltimo) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _indice++;
      _carregarExercicio();
    });
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do treino?'),
        content: const Text(
          'Os exercícios já concluídos ficam salvos. '
          'O exercício atual será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmou == true && mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final item = _item;
    final ex = item.exercicio!;
    final total = widget.itens.length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _sair,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.treino.nome,
              style: tema.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('Exercício ${_indice + 1} de $total', style: tema.bodySmall),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progresso em segmentos.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < total; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _indice
                              ? AppTheme.primaria
                              : AppTheme.borda,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.primariaSuave,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppTheme.primaria,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.fundo,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ex.grupoMuscular,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textoSecundario,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(ex.nome, style: tema.headlineSmall),
                          const SizedBox(height: 6),
                          Text(ex.descricao, style: tema.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Série $_serieAtual de ${item.series}',
                                  style: tema.titleMedium,
                                ),
                              ),
                              for (var i = 0; i < item.series; i++)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i < _serieAtual - 1
                                        ? AppTheme.primaria
                                        : (i == _serieAtual - 1
                                            ? Colors.white
                                            : AppTheme.borda),
                                    border: i == _serieAtual - 1
                                        ? Border.all(
                                            color: AppTheme.primaria,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ajuste(
                            rotulo: 'Carga',
                            valor: '${_fmt(_carga)} kg',
                            onMenos: () => setState(() {
                              _carga = (_carga - 2.5).clamp(0, 999).toDouble();
                            }),
                            onMais: () => setState(() {
                              _carga = (_carga + 2.5).clamp(0, 999).toDouble();
                            }),
                          ),
                          const Divider(height: 1),
                          _ajuste(
                            rotulo: 'Repetições',
                            valor: '$_reps',
                            onMenos: () => setState(() {
                              _reps = _reps > 1 ? _reps - 1 : 1;
                            }),
                            onMais: () => setState(() {
                              _reps++;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primariaSuave,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppTheme.primaria, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _descansando
                                ? 'Descansando... ${_restante}s'
                                : 'Descanso de ${item.descansoSegundos}s '
                                    'depois de cada série',
                            style: const TextStyle(
                              color: AppTheme.primaria,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_descansando)
                          TextButton(
                            onPressed: _pularDescanso,
                            child: const Text('Pular'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        (_descansando || _salvando) ? null : _finalizarSerie,
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar série'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _salvando ? null : _proximoOuEncerrar,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _ehUltimo ? 'Encerrar treino' : 'Próximo exercício',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ajuste({
    required String rotulo,
    required String valor,
    required VoidCallback onMenos,
    required VoidCallback onMais,
  }) {
    final tema = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: tema.bodyMedium)),
          IconButton.outlined(
            onPressed: onMenos,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 80,
            child: Text(
              valor,
              textAlign: TextAlign.center,
              style: tema.titleMedium,
            ),
          ),
          IconButton.outlined(
            onPressed: onMais,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final String nomeExercicio;
  final String resumo;

  const _FeedbackSheet({required this.nomeExercicio, required this.resumo});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  // [valor gravado no banco, texto na tela]
  static const _niveis = [
    ['MUITO_FACIL', 'Muito fácil'],
    ['BOM', 'Bom'],
    ['MUITO_DIFICIL', 'Muito difícil'],
  ];

  String _nivel = 'BOM';
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _comentario.text.trim();
    Navigator.pop(
      context,
      _Feedback(_nivel, texto.isEmpty ? null : texto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borda,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFE3F4EB),
                    child: Icon(Icons.check, color: AppTheme.sucesso),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.nomeExercicio} concluído',
                          style: tema.titleMedium,
                        ),
                        Text(widget.resumo, style: tema.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Como foi o exercício?', style: tema.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final n in _niveis)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() {
                            _nivel = n[0];
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _nivel == n[0]
                                  ? AppTheme.primariaSuave
                                  : AppTheme.superficie,
                              border: Border.all(
                                color: _nivel == n[0]
                                    ? AppTheme.primaria
                                    : AppTheme.borda,
                                width: _nivel == n[0] ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              n[1],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.texto,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _comentario,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _enviar,
                child: const Text('Enviar e continuar'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Pular'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}