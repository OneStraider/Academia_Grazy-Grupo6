import 'package:flutter/material.dart';

import '../../models/treino.dart';
import '../../services/treino_services.dart';
import '../../theme/app_theme.dart';
import '../alunos_mock.dart';
import 'detalhes_treino_screen.dart';
import 'novo_treino_screen.dart';

class _Dados {
  final List<Treino> treinos;
  final Map<int, int> contagem;

  _Dados(this.treinos, this.contagem);
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

  bool get _ehProfessor => papelAtual.value == Papel.professor;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  // Professor vê todos os treinos. Aluno vê só os dele.
  Future<_Dados> _carregar() async {
    final treinos = _ehProfessor
        ? await _service.listar()
        : await _service.listarPorAluno(alunoLogadoId.value);

    final contagem = await _service.contagemPorTreino();

    return _Dados(treinos, contagem);
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
        MaterialPageRoute(
          builder: (_) => DetalhesTreinoScreen(treino: treino),
        ),
      );
    }
    if (mounted) _recarregar();
  }

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void dispose() {
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
                          (alunosTeste[t.alunoId] ?? '').toLowerCase();
                      return aluno.contains(filtro);
                    }).toList();

                    // Vencido: status diferente de ATIVO ou validade já passou.
                    bool vencido(Treino t) =>
                        t.status != 'ATIVO' || t.validade.isBefore(hoje);

                    final ativos = todos.where((t) => !vencido(t)).toList();
                    final vencidos = todos.where(vencido).toList();

                    if (todos.isEmpty) {
                      return const Center(
                        child: Text('Nenhum treino cadastrado.'),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: [
                        if (ativos.isNotEmpty) ...[
                          Text('Ativos · ${ativos.length}',
                              style: tema.titleMedium),
                          const SizedBox(height: 8),
                          for (final t in ativos)
                            _card(t, false, dados.contagem[t.id] ?? 0),
                        ],
                        if (vencidos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Vencidos · ${vencidos.length}',
                              style: tema.titleMedium),
                          const SizedBox(height: 8),
                          for (final t in vencidos)
                            _card(t, true, dados.contagem[t.id] ?? 0),
                        ],
                      ],
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

  Widget _card(Treino t, bool vencido, int quantidade) {
    final aluno = alunosTeste[t.alunoId] ?? 'Aluno ${t.alunoId}';

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
                  backgroundColor:
                      vencido ? AppTheme.borda : AppTheme.primariaSuave,
                  child: Text(
                    aluno[0],
                    style: TextStyle(
                      color: vencido
                          ? AppTheme.textoSecundario
                          : AppTheme.primaria,
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
                          _chip(vencido ? 'Vencido' : 'Ativo',
                              destaque: !vencido),
                          _chip(vencido
                              ? 'Venceu em ${_data(t.validade)}'
                              : 'Até ${_data(t.validade)}'),
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
        color: destaque ? const Color(0xFFE3F4EB) : AppTheme.fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: destaque ? AppTheme.sucesso : AppTheme.textoSecundario,
        ),
      ),
    );
  }
}