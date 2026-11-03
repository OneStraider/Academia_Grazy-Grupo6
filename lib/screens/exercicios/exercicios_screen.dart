import 'package:flutter/material.dart';

import '../../models/exercicios.dart';
import '../../services/exercicios_services.dart';
import '../../services/database_events.dart';
import '../../services/usuario_service.dart';
import 'exercicio_form_screen.dart';

class ExerciciosScreen extends StatefulWidget {
  const ExerciciosScreen({super.key});
  @override
  State<ExerciciosScreen> createState() => _ExerciciosScreenState();
}

class _ExerciciosScreenState extends State<ExerciciosScreen> {
  final _service = ExercicioService();
  final _busca = TextEditingController();
  String? _grupo;
  String _consultaAplicada = '';
  bool _digitandoBusca = false;
  late Future<List<Exercicio>> _dados;
  bool get _podeEditar =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _dados = _service.listar();
  }

  void _onDatabaseChanged() {
    if (mounted) _carregar();
  }

  void _carregar() => setState(() => _dados = _service.listar());

  void _buscar() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _consultaAplicada = _busca.text.trim();
      _digitandoBusca = false;
    });
  }

  void _limparBusca() {
    _busca.clear();
    setState(() {
      _consultaAplicada = '';
      _digitandoBusca = false;
    });
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Exercícios')),
    floatingActionButton: !_podeEditar
        ? null
        : FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExercicioFormScreen()),
              );
              _carregar();
            },
            icon: const Icon(Icons.add),
            label: const Text('Novo exercício'),
          ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _busca,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: 'Buscar exercício',
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: _limparBusca,
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (_) => setState(() => _digitandoBusca = true),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _grupo,
            decoration: const InputDecoration(labelText: 'Grupo muscular'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              for (final grupo in [
                'Peito',
                'Costas',
                'Pernas',
                'Braços',
                'Ombros',
                'Abdômen',
              ])
                DropdownMenuItem(value: grupo, child: Text(grupo)),
            ],
            onChanged: (value) => setState(() => _grupo = value),
          ),
          Expanded(
            child: FutureBuilder<List<Exercicio>>(
              future: _dados,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Erro: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final termo = _digitandoBusca
                    ? _busca.text
                    : _consultaAplicada;
                final exercicios = _service.filtrar(
                  snapshot.data!,
                  termo,
                  grupo: _grupo,
                );
                if (exercicios.isEmpty)
                  return Center(
                    child: Text(
                      termo.isEmpty && _grupo == null
                          ? 'Nenhum exercício cadastrado.'
                          : 'Nenhum exercício encontrado para essa busca.',
                    ),
                  );
                return ListView(
                  padding: const EdgeInsets.only(top: 10, bottom: 96),
                  children: [
                    if (termo.isNotEmpty || _grupo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${exercicios.length} resultado(s)${termo.isNotEmpty ? ' para "$termo"' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    for (final exercicio in exercicios)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(exercicio.nome),
                          subtitle: Text(
                            '${exercicio.grupoMuscular} · ${exercicio.descricao}',
                          ),
                          trailing: !_podeEditar
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (acao) async {
                                    if (acao == 'editar')
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ExercicioFormScreen(
                                            exercicio: exercicio,
                                          ),
                                        ),
                                      );
                                    if (acao == 'excluir')
                                      await _service.excluir(exercicio.id!);
                                    _carregar();
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'excluir',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                        ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
