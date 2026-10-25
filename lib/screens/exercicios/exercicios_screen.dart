import 'package:flutter/material.dart';

import '../../models/exercicios.dart';
import '../../services/exercicios_services.dart';
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
  late Future<List<Exercicio>> _dados;
  bool get _podeEditar =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;

  @override
  void initState() {
    super.initState();
    _dados = _service.listar();
  }

  void _carregar() =>
      setState(() => _dados = _service.pesquisar(_busca.text, grupo: _grupo));

  @override
  void dispose() {
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
          TextField(
            controller: _busca,
            onChanged: (_) => _carregar(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar exercício',
            ),
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
            onChanged: (value) {
              _grupo = value;
              _carregar();
            },
          ),
          Expanded(
            child: FutureBuilder<List<Exercicio>>(
              future: _dados,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Erro: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty)
                  return const Center(
                    child: Text('Nenhum exercício cadastrado.'),
                  );
                return ListView(
                  children: [
                    for (final exercicio in snapshot.data!)
                      Card(
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
