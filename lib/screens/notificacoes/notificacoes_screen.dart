import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notificacao.dart';
import '../../services/database_events.dart';
import '../../services/execucao_service.dart';
import '../../services/notificacao_service.dart';
import '../../services/treino_services.dart';
import '../../services/usuario_service.dart';
import '../treinos/executar_treinos_screen.dart';

class NotificacoesIcone extends StatefulWidget {
  const NotificacoesIcone({super.key});

  @override
  State<NotificacoesIcone> createState() => _NotificacoesIconeState();
}

class _NotificacoesIconeState extends State<NotificacoesIcone> {
  final _service = NotificacaoService();
  int _naoLidas = 0;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_atualizar);
    _atualizar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_atualizar);
    super.dispose();
  }

  Future<void> _atualizar() async {
    final usuarioId = UsuarioService.usuarioLogado?.id;
    if (usuarioId == null) return;
    final total = await _service.contarNaoLidas(usuarioId);
    if (mounted && total != _naoLidas) setState(() => _naoLidas = total);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notificações',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
    ),
    icon: Badge(
      isLabelVisible: _naoLidas > 0,
      label: Text(_naoLidas > 99 ? '99+' : '$_naoLidas'),
      child: const Icon(Icons.notifications_outlined),
    ),
  );
}

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final _service = NotificacaoService();
  late Future<List<Notificacao>> _notificacoes;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _carregar() {
    final usuarioId = UsuarioService.usuarioLogado?.id;
    _notificacoes = usuarioId == null
        ? Future.value(const [])
        : _service.listar(usuarioId);
  }

  void _onDatabaseChanged() {
    if (mounted) setState(_carregar);
  }

  Future<void> _abrir(Notificacao notificacao) async {
    final usuario = UsuarioService.usuarioLogado;
    if (usuario == null || usuario.id != notificacao.destinatarioId) return;

    await _service.marcarComoLida(notificacao.id, usuario.id!);
    if (!mounted) return;

    if (notificacao.avaliacaoRealizada) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notificacao.titulo),
          content: Text(notificacao.mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    if (notificacao.treinoConcluido) {
      if (!usuario.ehProfessor) return;
      final treinoId = notificacao.treinoId;
      if (treinoId == null) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => RelatorioTreinoScreen(treinoId: treinoId),
        ),
      );
      return;
    }

    if (!usuario.ehAluno) return;
    final treinoId = notificacao.treinoId;
    if (treinoId == null) return;
    final treinoService = TreinoService();
    final treino = await treinoService.buscarPorId(treinoId);
    if (!mounted) return;
    if (treino == null || treino.alunoId != usuario.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este treino não está mais disponível.')),
      );
      return;
    }
    if (treino.concluidoEm != null || treino.status != 'ATIVO') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este treino já foi concluído ou venceu.'),
        ),
      );
      return;
    }
    final itens = await treinoService.listarExercicios(treino.id!);
    final concluidos = await ExecucaoService().exerciciosConcluidos(treino.id!);
    if (!mounted) return;
    final inicio = itens.indexWhere((item) => !concluidos.contains(item.id));
    if (itens.isEmpty || inicio < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este treino não tem exercícios pendentes.'),
        ),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExecutarTreinoScreen(
          treino: treino,
          itens: itens,
          indiceInicial: inicio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notificações')),
    body: FutureBuilder<List<Notificacao>>(
      future: _notificacoes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Não foi possível carregar as notificações.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final itens = snapshot.data!;
        if (itens.isEmpty) {
          return const Center(child: Text('Você ainda não tem notificações.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = itens[index];
            final esquema = Theme.of(context).colorScheme;
            return Card(
              color: item.lida
                  ? esquema.surfaceContainerLow
                  : esquema.surfaceContainerHigh,
              child: ListTile(
                onTap: () => _abrir(item),
                leading: CircleAvatar(
                  backgroundColor: item.avaliacaoRealizada
                      ? esquema.tertiaryContainer
                      : item.treinoConcluido
                      ? esquema.primaryContainer
                      : esquema.secondaryContainer,
                  child: Icon(
                    item.avaliacaoRealizada
                        ? Icons.monitor_heart_outlined
                        : item.treinoConcluido
                        ? Icons.task_alt
                        : Icons.fitness_center,
                    color: item.avaliacaoRealizada
                        ? esquema.onTertiaryContainer
                        : item.treinoConcluido
                        ? esquema.onPrimaryContainer
                        : esquema.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  item.titulo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(item.mensagem),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('dd/MM/yyyy · HH:mm').format(item.criadoEm),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: item.lida
                    ? null
                    : Icon(Icons.circle, size: 10, color: esquema.secondary),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    ),
  );
}

class RelatorioTreinoScreen extends StatefulWidget {
  final int treinoId;

  const RelatorioTreinoScreen({super.key, required this.treinoId});

  @override
  State<RelatorioTreinoScreen> createState() => _RelatorioTreinoScreenState();
}

class _RelatorioTreinoScreenState extends State<RelatorioTreinoScreen> {
  late final Future<Map<String, Object?>?> _relatorio = ExecucaoService()
      .relatorio(widget.treinoId);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Feedback do treino')),
    body: FutureBuilder<Map<String, Object?>?>(
      future: _relatorio,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Não foi possível abrir o treino.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final relatorio = snapshot.data;
        final usuario = UsuarioService.usuarioLogado;
        final treino = relatorio?['treino'] as Map<String, Object?>?;
        if (treino == null ||
            usuario == null ||
            treino['professor_id'] != usuario.id) {
          return const Center(
            child: Text('Este relatório não está disponível.'),
          );
        }
        final exercicios =
            relatorio!['exercicios'] as List<Map<String, Object?>>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              treino['nome'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text('Aluno: ${treino['aluno_nome']}'),
            if (treino['concluido_em'] != null)
              Text(
                'Concluído em ${DateFormat('dd/MM/yyyy · HH:mm').format(DateTime.parse(treino['concluido_em'] as String))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 18),
            for (final exercicio in exercicios)
              _FeedbackExercicioCard(dados: exercicio),
          ],
        );
      },
    ),
  );
}

class _FeedbackExercicioCard extends StatelessWidget {
  final Map<String, Object?> dados;

  const _FeedbackExercicioCard({required this.dados});

  String _rotulo(String? nivel) => switch (nivel) {
    'MUITO_FACIL' => 'Muito fácil',
    'BOM' => 'Bom',
    'MUITO_DIFICIL' => 'Muito difícil',
    _ => 'Sem feedback',
  };

  @override
  Widget build(BuildContext context) {
    final data = dados['data_execucao'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dados['exercicio_nome'] as String,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (data != null) ...[
              const SizedBox(height: 3),
              Text(
                DateFormat('dd/MM/yyyy · HH:mm').format(DateTime.parse(data)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (dados['series_realizadas'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${dados['series_realizadas']} séries × ${dados['repeticoes']} repetições · ${dados['carga']} kg',
              ),
            ],
            const SizedBox(height: 8),
            Text('Avaliação: ${_rotulo(dados['nivel'] as String?)}'),
            if ((dados['comentario'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(dados['comentario'] as String),
            ],
          ],
        ),
      ),
    );
  }
}
