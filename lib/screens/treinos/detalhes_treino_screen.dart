import 'package:flutter/material.dart';

import '../../models/treino.dart';
import '../../models/treino_exercicios.dart';
import '../../models/execucao_treino.dart';
import '../../services/usuario_service.dart';
import '../../services/execucao_service.dart';
import '../../services/database_events.dart';
import '../../services/treino_services.dart';
import '../../theme/app_theme.dart';
import 'executar_treinos_screen.dart';

class _Dados {
  final Treino treino;
  final List<TreinoExercicio> itens;
  final Set<int> concluidos;
  final String professorNome;
  final List<ExecucaoTreino> historico;

  _Dados(
    this.treino,
    this.itens,
    this.concluidos,
    this.professorNome,
    this.historico,
  );
}

// Tela do aluno: detalhes do treino + botão de iniciar.
class DetalhesTreinoScreen extends StatefulWidget {
  final Treino treino;

  const DetalhesTreinoScreen({super.key, required this.treino});

  @override
  State<DetalhesTreinoScreen> createState() => _DetalhesTreinoScreenState();
}

class _DetalhesTreinoScreenState extends State<DetalhesTreinoScreen> {
  final _treinoService = TreinoService();
  final _execucaoService = ExecucaoService();
  late Future<_Dados> _futuro;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _futuro = _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (mounted) _recarregar();
  }

  Future<_Dados> _carregar() async {
    final id = widget.treino.id!;
    final treino = await _treinoService.buscarPorId(id) ?? widget.treino;
    final itens = await _treinoService.listarExercicios(id);
    final concluidos = await _execucaoService.exerciciosConcluidos(id);
    final professor = await UsuarioService().buscarPorId(treino.professorId);
    final historico = await _execucaoService.historico(id);
    return _Dados(
      treino,
      itens,
      concluidos,
      professor?.nome ?? 'Professor',
      historico,
    );
  }

  void _recarregar() {
    setState(() {
      _futuro = _carregar();
    });
  }

  Future<void> _iniciar(_Dados dados) async {
    // Começa no primeiro exercício que ainda não foi feito hoje.
    var inicio = dados.itens.indexWhere(
      (i) => !dados.concluidos.contains(i.id),
    );
    if (inicio < 0) inicio = 0;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExecutarTreinoScreen(
          treino: widget.treino,
          itens: dados.itens,
          indiceInicial: inicio,
        ),
      ),
    );

    if (mounted) _recarregar();
  }

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do treino')),
      body: FutureBuilder<_Dados>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final dados = snapshot.data!;
          final t = dados.treino;
          final agora = DateTime.now();
          final hoje = DateTime(agora.year, agora.month, agora.day);
          final vencido = t.status != 'ATIVO' || t.validade.isBefore(hoje);
          final feitos = dados.concluidos.length;
          final tudoFeito = t.concluidoEm != null;

          String rotuloBotao = 'Iniciar treino';
          if (tudoFeito) {
            rotuloBotao = 'Concluído';
          } else if (feitos > 0) {
            rotuloBotao = 'Continuar treino';
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.nome, style: tema.titleLarge),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                vencido
                                    ? _chip('Vencido')
                                    : _chip(
                                        'Ativo',
                                        destaque: true,
                                        icone: Icons.check,
                                      ),
                                _chip(dados.professorNome),
                                _chip('Até ${_data(t.validade)}'),
                              ],
                            ),
                            if (t.observacoes != null) ...[
                              const SizedBox(height: 10),
                              Text(t.observacoes!, style: tema.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (dados.historico.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Histórico de execução', style: tema.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            for (final execucao in dados.historico.take(10))
                              ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  execucao.exercicioNome ?? 'Exercício',
                                ),
                                subtitle: Text(
                                  '${execucao.dataExecucao.day}/${execucao.dataExecucao.month}/${execucao.dataExecucao.year} · ${execucao.seriesRealizadas} séries × ${execucao.repeticoes} · ${execucao.carga} kg',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (tudoFeito)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.sucessoSuave,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.sucesso),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Treino concluído!',
                                style: TextStyle(
                                  color: AppTheme.sucesso,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercícios', style: tema.titleMedium),
                        Text(
                          '${dados.itens.length} no total',
                          style: tema.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < dados.itens.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _linha(
                              i + 1,
                              dados.itens[i],
                              dados.concluidos.contains(dados.itens[i].id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton.icon(
                    onPressed: (vencido || tudoFeito || dados.itens.isEmpty)
                        ? null
                        : () => _iniciar(dados),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(vencido ? 'Treino vencido' : rotuloBotao),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _linha(int numero, TreinoExercicio te, bool feito) {
    final ex = te.exercicio;

    return ListTile(
      tileColor: feito ? AppTheme.sucessoSuave : null,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: feito ? AppTheme.sucesso : AppTheme.primariaSuave,
        child: feito
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '$numero',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaria,
                ),
              ),
      ),
      title: Text(
        ex?.nome ?? 'Exercício',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${ex?.grupoMuscular ?? ''} · ${te.descansoSegundos}s de descanso',
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${te.series} × ${te.repeticoes}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${_fmt(te.carga)} kg',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, {bool destaque = false, IconData? icone}) {
    final cor = destaque ? AppTheme.sucesso : AppTheme.textoSecundario;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: destaque ? AppTheme.sucessoSuave : AppTheme.fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
