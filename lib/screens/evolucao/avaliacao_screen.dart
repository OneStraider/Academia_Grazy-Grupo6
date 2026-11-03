import 'package:flutter/material.dart';

import '../../models/anamnese.dart';
import '../../models/avaliacao_fisica.dart';
import '../../models/usuario.dart';
import '../../services/avaliacao_service.dart';
import '../../services/usuario_service.dart';

class AvaliacaoScreen extends StatefulWidget {
  const AvaliacaoScreen({super.key});
  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends State<AvaliacaoScreen> {
  final _form = GlobalKey<FormState>();
  final _service = AvaliacaoService();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _gordura = TextEditingController();
  final _condicoes = TextEditingController();
  final _medicamentos = TextEditingController();
  final _restricoes = TextEditingController();
  List<Usuario> _alunos = [];
  int? _alunoId;

  @override
  void initState() {
    super.initState();
    UsuarioService().listarAlunos().then((alunos) {
      if (!mounted) return;
      setState(() {
        _alunos = alunos;
        _alunoId = UsuarioService.usuarioLogado?.ehAluno == true
            ? UsuarioService.usuarioLogado!.id
            : (alunos.isEmpty ? null : alunos.first.id);
      });
    });
  }

  @override
  void dispose() {
    _peso.dispose();
    _altura.dispose();
    _gordura.dispose();
    _condicoes.dispose();
    _medicamentos.dispose();
    _restricoes.dispose();
    super.dispose();
  }

  double? _numero(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova avaliação')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Registre as medidas e informações de saúde do aluno.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _secao('Identificação', Icons.person_outline, [
            DropdownButtonFormField<int>(
              initialValue: _alunoId,
              decoration: const InputDecoration(
                labelText: 'Aluno',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _alunos
                  .map(
                    (u) => DropdownMenuItem(value: u.id, child: Text(u.nome)),
                  )
                  .toList(),
              onChanged: UsuarioService.usuarioLogado?.ehAluno == true
                  ? null
                  : (v) => setState(() => _alunoId = v),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data da avaliação',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(_data(DateTime.now())),
            ),
          ]),
          const SizedBox(height: 12),
          _secao('Medidas corporais', Icons.monitor_weight_outlined, [
            _campo('Peso (kg)', _peso),
            _campo('Altura (m)', _altura),
            _campo('Gordura corporal (%)', _gordura, obrigatorio: false),
            Builder(
              builder: (context) {
                final peso = _numero(_peso.text),
                    altura = _numero(_altura.text),
                    gordura = _numero(_gordura.text);
                if (peso == null || altura == null || altura <= 0)
                  return const SizedBox.shrink();
                final imc = peso / (altura * altura);
                final massaMagra = gordura == null
                    ? peso
                    : peso * (1 - gordura / 100);
                final classificacao = imc < 18.5
                    ? 'Abaixo do peso'
                    : imc < 25
                    ? 'Peso normal'
                    : imc < 30
                    ? 'Sobrepeso'
                    : 'Obesidade';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IMC ${imc.toStringAsFixed(1)} · $classificacao',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Massa magra estimada: ${massaMagra.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 12),
          _secao('Anamnese', Icons.health_and_safety_outlined, [
            _texto('Condições de saúde', _condicoes),
            _texto('Medicamentos', _medicamentos),
            _texto('Restrições', _restricoes),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar avaliação'),
          ),
        ],
      ),
    ),
  );

  Widget _secao(String titulo, IconData icone, List<Widget> conteudo) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 9),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...conteudo,
        ],
      ),
    ),
  );

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _campo(
    String label,
    TextEditingController controller, {
    bool obrigatorio = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!obrigatorio && (value == null || value.isEmpty)) return null;
        final n = _numero(value ?? '');
        if (n == null || n <= 0) return 'Informe um valor válido';
        if (label.contains('%') && n > 100) return 'Use um percentual até 100';
        return null;
      },
    ),
  );

  Widget _texto(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _salvar() async {
    if (!_form.currentState!.validate() || _alunoId == null) return;
    final peso = _numero(_peso.text)!;
    final altura = _numero(_altura.text)!;
    final gordura = _numero(_gordura.text);
    final massaMagra = gordura == null ? peso : peso * (1 - gordura / 100);
    try {
      await _service.salvar(
        AvaliacaoFisica(
          alunoId: _alunoId,
          professorId: UsuarioService.usuarioLogado?.id ?? 1,
          data: DateTime.now(),
          peso: peso,
          altura: altura,
          percentualGordura: gordura,
          massaMagra: massaMagra,
        ),
        Anamnese(
          alunoId: _alunoId!,
          condicoes: _condicoes.text,
          medicamentos: _medicamentos.text,
          restricoes: _restricoes.text,
          atualizadoEm: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $e')));
    }
  }
}
