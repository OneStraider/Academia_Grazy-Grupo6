import 'package:flutter/material.dart';

import '../../models/exercicios.dart';
import '../../models/treino.dart';
import '../../models/treino_exercicios.dart';
import '../../services/exercicios_services.dart';
import '../../services/treino_services.dart';
import '../../theme/app_theme.dart';
import '../alunos_mock.dart';

class _ItemTreino {
  final int? id;
  final Exercicio exercicio;
  final int series;
  final int repeticoes;
  final double carga;
  final int descanso;

  _ItemTreino(
    this.exercicio,
    this.series,
    this.repeticoes,
    this.carga,
    this.descanso, {
    this.id,
  });
}

class NovoTreinoScreen extends StatefulWidget {
  final Treino? treino;

  const NovoTreinoScreen({super.key, this.treino});

  @override
  State<NovoTreinoScreen> createState() => _NovoTreinoScreenState();
}

class _NovoTreinoScreenState extends State<NovoTreinoScreen> {
  final _form = GlobalKey<FormState>();
  final _service = TreinoService();
  final _nome = TextEditingController();
  final _obs = TextEditingController();
  final List<_ItemTreino> _itens = [];

  int? _alunoId;
  DateTime _validade = DateTime.now().add(const Duration(days: 30));

  bool get _editando => widget.treino != null;

  // A validade precisa ser uma data futura: o primeiro dia aceito é amanhã.
  DateTime get _primeiraDataValida {
    final hoje = DateTime.now();
    return DateTime(hoje.year, hoje.month, hoje.day + 1);
  }

  bool get _validadeNoFuturo =>
      !DateUtils.dateOnly(_validade).isBefore(_primeiraDataValida);

  @override
  void initState() {
    super.initState();

    final t = widget.treino;

    if (t != null) {
      _alunoId = t.alunoId;
      _nome.text = t.nome;
      _obs.text = t.observacoes ?? '';
      _validade = t.validade;

      _carregarItens(t.id!);
    }
  }

  Future<void> _carregarItens(int treinoId) async {
    final lista = await _service.listarExercicios(treinoId);

    if (!mounted) return;

    setState(() {
      _itens.addAll([
        for (final te in lista)
          if (te.exercicio != null)
            _ItemTreino(
              te.exercicio!,
              te.series,
              te.repeticoes,
              te.carga,
              te.descansoSegundos,
              id: te.id,
            ),
      ]);
    });
  }

  String _data(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Future<void> _escolherData() async {
    final primeira = _primeiraDataValida;

    final escolhida = await showDatePicker(
      context: context,
      // Ao editar um treino vencido, o calendário abre em amanhã.
      initialDate: _validade.isBefore(primeira) ? primeira : _validade,
      firstDate: primeira,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (escolhida != null) {
      setState(() {
        _validade = escolhida;
      });
    }
  }

  Future<void> _adicionarExercicio() async {
    final exercicios = await ExercicioService().listar();

    if (!mounted) return;

    if (exercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum exercício cadastrado.'),
        ),
      );

      return;
    }

    final item = await showModalBottomSheet<_ItemTreino>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AdicionarExercicioSheet(
        exercicios: exercicios,
      ),
    );

    if (item != null) {
      setState(() {
        _itens.add(item);
      });
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    if (!_validadeNoFuturo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A validade precisa ser a partir de amanhã.'),
        ),
      );

      return;
    }

    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um exercício.'),
        ),
      );

      return;
    }

    final treino = Treino(
      id: widget.treino?.id,
      alunoId: _alunoId!,
      professorId: widget.treino?.professorId ?? professorIdTeste,
      nome: _nome.text.trim(),
      validade: _validade,
      status: widget.treino?.status ?? 'ATIVO',
      observacoes:
          _obs.text.trim().isEmpty ? null : _obs.text.trim(),
    );

    final itens = [
      for (var i = 0; i < _itens.length; i++)
        TreinoExercicio(
          id: _itens[i].id,
          treinoId: widget.treino?.id ?? 0,
          exercicioId: _itens[i].exercicio.id!,
          ordem: i + 1,
          series: _itens[i].series,
          repeticoes: _itens[i].repeticoes,
          carga: _itens[i].carga,
          descansoSegundos: _itens[i].descanso,
        ),
    ];

    try {
      if (_editando) {
        await _service.editar(treino, itens);
      } else {
        await _service.cadastrar(treino, itens);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
        ),
      );
    }
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir treino?'),
        content: const Text(
          'Os exercícios e o histórico de execuções deste treino '
          'também serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) {
      return;
    }

    try {
      await _service.excluir(widget.treino!.id!);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _obs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar treino' : 'Novo treino',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados do treino',
                      style: tema.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue:
                          alunosTeste.containsKey(_alunoId)
                              ? _alunoId
                              : null,
                      decoration: const InputDecoration(
                        labelText: 'Aluno',
                      ),
                      items: [
                        for (final e in alunosTeste.entries)
                          DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _alunoId = v;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Escolha o aluno' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nome,
                      decoration: const InputDecoration(
                        labelText: 'Nome do treino',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Informe o nome'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _escolherData,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Validade',
                          suffixIcon:
                              const Icon(Icons.calendar_today_outlined),
                          errorText: _validadeNoFuturo
                              ? null
                              : 'Escolha uma data a partir de amanhã',
                        ),
                        child: Text(
                          _data(_validade),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _obs,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercícios',
                  style: tema.titleMedium,
                ),
                Text(
                  '${_itens.length} adicionados',
                  style: tema.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < _itens.length; i++)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primariaSuave,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaria,
                          ),
                        ),
                      ),
                      title: Text(
                        _itens[i].exercicio.nome,
                      ),
                      subtitle: Text(
                        '${_itens[i].series} x '
                        '${_itens[i].repeticoes} · '
                        '${_itens[i].carga} kg · '
                        '${_itens[i].descanso}s',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _itens.removeAt(i);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _adicionarExercicio,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exercício'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvar,
              child: Text(
                _editando
                    ? 'Salvar alterações'
                    : 'Salvar treino',
              ),
            ),
            if (_editando) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _excluir,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir treino'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(
                    color: Colors.red.shade200,
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    48,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AdicionarExercicioSheet extends StatefulWidget {
  final List<Exercicio> exercicios;

  const _AdicionarExercicioSheet({
    required this.exercicios,
  });

  @override
  State<_AdicionarExercicioSheet> createState() =>
      _AdicionarExercicioSheetState();
}

class _AdicionarExercicioSheetState
    extends State<_AdicionarExercicioSheet> {
  Exercicio? _escolhido;

  final _series = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  final _carga = TextEditingController(text: '0');
  final _descanso = TextEditingController(text: '60');

  void _confirmar() {
    if (_escolhido == null) {
      return;
    }

    Navigator.pop(
      context,
      _ItemTreino(
        _escolhido!,
        int.tryParse(_series.text) ?? 3,
        int.tryParse(_reps.text) ?? 10,
        double.tryParse(
              _carga.text.replaceAll(',', '.'),
            ) ??
            0,
        int.tryParse(_descanso.text) ?? 60,
      ),
    );
  }

  @override
  void dispose() {
    _series.dispose();
    _reps.dispose();
    _carga.dispose();
    _descanso.dispose();

    super.dispose();
  }

  Widget _campo(
    String rotulo,
    TextEditingController c,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextField(
          controller: c,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            labelText: rotulo,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Exercicio>(
            initialValue: _escolhido,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Exercício',
            ),
            items: [
              for (final e in widget.exercicios)
                DropdownMenuItem(
                  value: e,
                  child: Text(e.nome),
                ),
            ],
            onChanged: (v) {
              setState(() {
                _escolhido = v;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _campo('Séries', _series),
              _campo('Reps', _reps),
              _campo('Carga (kg)', _carga),
              _campo('Desc. (s)', _descanso),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _confirmar,
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}