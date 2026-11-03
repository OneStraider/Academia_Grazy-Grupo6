import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/avaliacao_fisica.dart';
import '../../models/usuario.dart';
import '../../services/avaliacao_service.dart';
import '../../services/database_events.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'avaliacao_screen.dart';

class EvolucaoScreen extends StatefulWidget {
  const EvolucaoScreen({super.key});
  @override
  State<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends State<EvolucaoScreen> {
  final _service = AvaliacaoService();
  int? _alunoId;
  List<Usuario> _alunos = [];
  late Future<List<AvaliacaoFisica>> _dados;

  bool get _ehProfessor => UsuarioService.usuarioLogado?.ehProfessor == true;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _alunoId = UsuarioService.usuarioLogado?.id;
    _dados = Future.value([]);
    _carregarAlunos();
    _dados = _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (mounted) setState(() => _dados = _carregar());
  }

  Future<void> _carregarAlunos() async {
    final alunos = await UsuarioService().listarAlunos();
    if (!mounted) return;
    setState(() {
      _alunos = alunos;
      if (_ehProfessor && alunos.isNotEmpty) _alunoId = alunos.first.id;
      _dados = _carregar();
    });
  }

  Future<List<AvaliacaoFisica>> _carregar() =>
      _alunoId == null ? Future.value([]) : _service.listar(_alunoId!);

  Future<void> _novaAvaliacao() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvaliacaoScreen()),
    );
    if (mounted) setState(() => _dados = _carregar());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: _ehProfessor
        ? FloatingActionButton.extended(
            onPressed: _novaAvaliacao,
            icon: const Icon(Icons.add),
            label: const Text('Nova avaliação'),
          )
        : null,
    body: SafeArea(
      child: FutureBuilder<List<AvaliacaoFisica>>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Não foi possível carregar a evolução.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final avaliacoes = snapshot.data!;
          final atual = avaliacoes.isEmpty ? null : avaliacoes.first;
          final antiga = avaliacoes.length < 2 ? null : avaliacoes.last;
          final variacaoPeso = atual == null || antiga == null
              ? null
              : atual.peso - antiga.peso;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            children: [
              Text(
                'Evolução',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _ehProfessor
                    ? 'Acompanhe as avaliações dos alunos'
                    : 'Seus resultados ao longo do tempo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_ehProfessor) ...[
                const SizedBox(height: 18),
                DropdownButtonFormField<int>(
                  initialValue: _alunoId,
                  decoration: const InputDecoration(
                    labelText: 'Aluno',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: _alunos
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u.id, child: Text(u.nome)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _alunoId = value;
                    _dados = _carregar();
                  }),
                ),
              ],
              const SizedBox(height: 20),
              if (atual == null)
                _vazio()
              else ...[
                _resumo(atual, variacaoPeso),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _indicador(
                        'IMC',
                        atual.imc.toStringAsFixed(1),
                        atual.classificacaoImc,
                        Icons.monitor_weight_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _indicador(
                        'Massa magra',
                        '${atual.massaMagra.toStringAsFixed(1)} kg',
                        'Última avaliação',
                        Icons.fitness_center_outlined,
                      ),
                    ),
                  ],
                ),
                if (avaliacoes.length > 1) ...[
                  const SizedBox(height: 14),
                  _grafico(avaliacoes),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${avaliacoes.length} avaliações',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < avaliacoes.length; i++)
                  _cartaoHistorico(
                    avaliacoes[i],
                    i + 1 < avaliacoes.length ? avaliacoes[i + 1] : null,
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );

  Widget _resumo(AvaliacaoFisica atual, double? variacao) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.primaria,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Peso atual',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            if (variacao != null) _variacaoBadge(variacao),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${atual.peso.toStringAsFixed(1)} kg',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Atualizado em ${_data(atual.data)}',
          style: const TextStyle(color: Colors.white70),
        ),
        if (variacao != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                variacao <= 0 ? Icons.trending_down : Icons.trending_up,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                '${variacao.abs().toStringAsFixed(1)} kg desde a primeira avaliação',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _variacaoBadge(double valor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${valor > 0 ? '+' : ''}${valor.toStringAsFixed(1)} kg',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _indicador(
    String titulo,
    String valor,
    String descricao,
    IconData icone,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(
            descricao,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );

  Widget _grafico(List<AvaliacaoFisica> avaliacoes) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variação de peso',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Peso corporal (kg)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _GraficoPesoPainter(
                avaliacoes.reversed.map((e) => e.peso).toList(),
                texto: Theme.of(context).colorScheme.onSurfaceVariant,
                grade: Theme.of(context).colorScheme.outlineVariant,
                destaque: Theme.of(context).colorScheme.primary,
                fundo: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _data(avaliacoes.last.data),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _data(avaliacoes.first.data),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _cartaoHistorico(
    AvaliacaoFisica avaliacao,
    AvaliacaoFisica? anterior,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _data(avaliacao.data),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Avaliação física',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _statusImc(avaliacao.classificacaoImc),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _dadoHistorico('Peso', '${avaliacao.peso.toStringAsFixed(1)} kg'),
              _dadoHistorico('IMC', avaliacao.imc.toStringAsFixed(1)),
              _dadoHistorico(
                'Massa magra',
                '${avaliacao.massaMagra.toStringAsFixed(1)} kg',
              ),
            ],
          ),
          if (anterior != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              'Variação de peso: ${avaliacao.peso - anterior.peso >= 0 ? '+' : ''}${(avaliacao.peso - anterior.peso).toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _dadoHistorico(String titulo, String valor) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );

  Widget _statusImc(String texto) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _vazio() => Container(
    padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.show_chart,
            size: 28,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Sua evolução começa aqui',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quando uma avaliação for registrada, seus indicadores e histórico aparecerão nesta tela.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _GraficoPesoPainter extends CustomPainter {
  final List<double> valores;
  final Color texto;
  final Color grade;
  final Color destaque;
  final Color fundo;
  _GraficoPesoPainter(
    this.valores, {
    required this.texto,
    required this.grade,
    required this.destaque,
    required this.fundo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final min = valores.reduce(math.min);
    final max = valores.reduce(math.max);
    final faixa = math.max(max - min, 1.0);
    const margemEsquerda = 42.0;
    const margemDireita = 8.0;
    final larguraGrafico = size.width - margemEsquerda - margemDireita;
    final pts = <Offset>[];
    for (var i = 0; i < valores.length; i++) {
      final x = valores.length == 1
          ? margemEsquerda + larguraGrafico / 2
          : margemEsquerda + i * larguraGrafico / (valores.length - 1);
      final y =
          size.height - 12 - ((valores[i] - min) / faixa) * (size.height - 24);
      pts.add(Offset(x, y));
    }
    final grid = Paint()
      ..color = grade
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(margemEsquerda, 0),
      Offset(margemEsquerda, size.height),
      grid,
    );
    for (var i = 0; i < 3; i++) {
      final y = i * size.height / 2;
      canvas.drawLine(
        Offset(margemEsquerda, y),
        Offset(size.width - margemDireita, y),
        grid,
      );
      final valor = max - (faixa * i / 2);
      final label = TextPainter(
        text: TextSpan(
          text: valor.toStringAsFixed(1),
          style: TextStyle(color: texto, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: margemEsquerda - 4);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final linha = Paint()
      ..color = destaque
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linha);
    final ponto = Paint()..color = destaque;
    final centro = Paint()..color = fundo;
    for (final p in pts) {
      canvas.drawCircle(p, 5, ponto);
      canvas.drawCircle(p, 2.5, centro);
    }
  }

  @override
  bool shouldRepaint(covariant _GraficoPesoPainter oldDelegate) =>
      oldDelegate.valores != valores ||
      oldDelegate.texto != texto ||
      oldDelegate.grade != grade ||
      oldDelegate.destaque != destaque ||
      oldDelegate.fundo != fundo;
}
