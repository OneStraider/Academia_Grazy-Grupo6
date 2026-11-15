import 'package:flutter/material.dart';

import '../../models/treino.dart';
import '../../services/database_events.dart';
import '../../services/treino_services.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'detalhes_treino_screen.dart';
import 'novo_treino_screen.dart';

class _Dados {
  final List<Treino> treinos;
  final Map<int, int> contagem;
  final Map<int, String> nomesAlunos;

  _Dados(this.treinos, this.contagem, this.nomesAlunos);
}

class _TreinoListaItem {
  final String? titulo;
  final Treino? treino;
  final bool vencido;
  final bool concluido;

  const _TreinoListaItem.secao(this.titulo)
    : treino = null,
      vencido = false,
      concluido = false;

  const _TreinoListaItem.treino(
    this.treino, {
    this.vencido = false,
    this.concluido = false,
  }) : titulo = null;
}

class TreinosScreen extends StatefulWidget {
  const TreinosScreen({super.key});

  @override
  State<TreinosScreen> createState() => _TreinosScreenState();
}

class _TreinosScreenState extends State<TreinosScreen> {
  final _service = TreinoService();
  final _busca = TextEditingController();
  late Future<_Dados> _futuro;

  bool get _ehProfessor =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _futuro = _carregar();
  }

  void _onDatabaseChanged() {
    if (mounted) _recarregar();
  }

  // Professor vê todos os treinos. Aluno vê só os dele.
  Future<_Dados> _carregar() async {
    final treinos = _ehProfessor
        ? await _service.listar()
        : await _service.listarPorAluno(UsuarioService.usuarioLogado?.id ?? -1);

    final contagem = await _service.contagemPorTreino();
    final alunos = await UsuarioService().listarAlunos();

    return _Dados(treinos, contagem, {
      for (final aluno in alunos) aluno.id!: aluno.nome,
    });
  }

  void _recarregar() {
    setState(() {
      _futuro = _carregar();
    });
  }

  Future<void> _novoTreino() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovoTreinoScreen()),
    );
    if (mounted) _recarregar();
  }

  // Professor: abre a edição (com excluir).
  // Aluno: abre os detalhes (com iniciar treino).
  Future<void> _abrir(Treino treino) async {
    if (_ehProfessor) {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => NovoTreinoScreen(treino: treino)),
      );
    } else {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => DetalhesTreinoScreen(treino: treino)),
      );
    }
    if (mounted) _recarregar();
  }

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: _ehProfessor
          ? FloatingActionButton.extended(
              onPressed: _novoTreino,
              backgroundColor: AppTheme.primaria,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Novo treino'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Treinos', style: tema.headlineMedium),
              Text(
                _ehProfessor ? 'Treinos que você montou' : 'Seus treinos',
                style: tema.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (_ehProfessor) ...[
                TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar aluno',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: FutureBuilder<_Dados>(
                  future: _futuro,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    final dados = snapshot.data!;
                    final agora = DateTime.now();
                    final hoje = DateTime(agora.year, agora.month, agora.day);
                    final filtro = _busca.text.trim().toLowerCase();

                    final todos = dados.treinos.where((t) {
                      final aluno =
                          (dados.nomesAlunos[t.alunoId] ?? 'Aluno ${t.alunoId}')
                              .toLowerCase();
                      return aluno.contains(filtro);
                    }).toList();

                    // Vencido: status diferente de ATIVO ou validade já passou.
                    final concluidos = todos
                        .where((t) => t.concluidoEm != null)
                        .toList();
                    bool vencido(Treino t) =>
                        t.concluidoEm == null &&
                        (t.status != 'ATIVO' || t.validade.isBefore(hoje));

                    final ativos = todos
                        .where((t) => !vencido(t) && t.concluidoEm == null)
                        .toList();
                    final vencidos = todos.where(vencido).toList();

                    if (todos.isEmpty) {
                      return const Center(
                        child: Text('Nenhum treino cadastrado.'),
                      );
                    }

                    final itens = <_TreinoListaItem>[];
                    void adicionarSecao(
                      String titulo,
                      List<Treino> lista, {
                      bool vencido = false,
                      bool concluido = false,
                    }) {
                      if (lista.isEmpty) return;
                      if (itens.isNotEmpty) {
                        itens.add(const _TreinoListaItem.secao(''));
                      }
                      itens.add(_TreinoListaItem.secao(titulo));
                      itens.addAll(
                        lista.map(
                          (treino) => _TreinoListaItem.treino(
                            treino,
                            vencido: vencido,
                            concluido: concluido,
                          ),
                        ),
                      );
                    }

                    adicionarSecao('Ativos · ${ativos.length}', ativos);
                    adicionarSecao(
                      'Vencidos · ${vencidos.length}',
                      vencidos,
                      vencido: true,
                    );
                    adicionarSecao(
                      'Concluídos · ${concluidos.length}',
                      concluidos,
                      concluido: true,
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: itens.length,
                      itemBuilder: (context, index) {
                        final item = itens[index];
                        if (item.treino == null) {
                          if (item.titulo!.isEmpty) {
                            return const SizedBox(height: 8);
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              item.titulo!,
                              style: tema.titleMedium,
                            ),
                          );
                        }
                        final treino = item.treino!;
                        return _card(
                          treino,
                          item.vencido,
                          dados.contagem[treino.id] ?? 0,
                          dados.nomesAlunos[treino.alunoId] ??
                              'Aluno ${treino.alunoId}',
                          concluido: item.concluido,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    Treino t,
    bool vencido,
    int quantidade,
    String aluno, {
    bool concluido = false,
  }) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _abrir(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: concluido || !vencido
                      ? esquema.primaryContainer
                      : esquema.surfaceContainerHighest,
                  child: Text(
                    aluno[0],
                    style: TextStyle(
                      color: vencido && !concluido
                          ? esquema.onSurfaceVariant
                          : esquema.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aluno,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(t.nome),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(
                            concluido
                                ? 'Concluído'
                                : vencido
                                ? 'Vencido'
                                : 'Ativo',
                            destaque: concluido || !vencido,
                          ),
                          _chip(
                            concluido
                                ? 'Concluído em ${_data(t.concluidoEm!)}'
                                : vencido
                                ? 'Venceu em ${_data(t.validade)}'
                                : 'Até ${_data(t.validade)}',
                          ),
                          _chip(
                            '$quantidade '
                            '${quantidade == 1 ? 'exercício' : 'exercícios'}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String texto, {bool destaque = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: destaque
            ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF204536)
                  : AppTheme.sucessoSuave)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: destaque
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9FE3C1)
                    : AppTheme.sucesso)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
