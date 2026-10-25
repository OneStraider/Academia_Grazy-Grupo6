import 'package:flutter/material.dart';

import '../../models/avaliacao_fisica.dart';
import '../../models/treino.dart';
import '../../models/usuario.dart';
import '../../services/agendamento_service.dart';
import '../../services/avaliacao_service.dart';
import '../../services/treino_services.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../evolucao/avaliacao_screen.dart';
import '../evolucao/evolucao_screen.dart';
import '../exercicios/exercicios_screen.dart';
import '../treinos/detalhes_treino_screen.dart';
import '../treinos/novo_treino_screen.dart';
import '../treinos/treinos_screen.dart';

class _AlunoResumo {
  final Usuario aluno;
  final Treino? treino;
  const _AlunoResumo(this.aluno, this.treino);
}

class _HomeDados {
  final Treino? treino;
  final String? professorNome;
  final int exercicios;
  final Map<String, Object?>? proximaAula;
  final List<AvaliacaoFisica> avaliacoes;
  final List<_AlunoResumo> alunos;
  final List<Map<String, Object?>> aulas;
  const _HomeDados({
    this.treino,
    this.professorNome,
    this.exercicios = 0,
    this.proximaAula,
    this.avaliacoes = const [],
    this.alunos = const [],
    this.aulas = const [],
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _treinos = TreinoService();
  late Future<_HomeDados> _dados;
  Usuario? get _usuario => UsuarioService.usuarioLogado;
  bool get _professor =>
      _usuario?.ehProfessor == true || _usuario?.ehAdmin == true;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<_HomeDados> _carregar() async {
    final user = _usuario;
    if (user == null) return const _HomeDados();
    final agendamentos = await AgendamentoService().listarHorarios(
      alunoId: user.id,
    );
    if (_professor) {
      final pessoas = await UsuarioService().listarAlunos();
      final treinos = await _treinos.listar();
      final resumos = <_AlunoResumo>[];
      for (final aluno in pessoas) {
        final doAluno = treinos.where((t) => t.alunoId == aluno.id).toList()
          ..sort((a, b) => b.validade.compareTo(a.validade));
        resumos.add(
          _AlunoResumo(aluno, doAluno.isEmpty ? null : doAluno.first),
        );
      }
      return _HomeDados(alunos: resumos, aulas: agendamentos.take(3).toList());
    }

    final pessoaTreinos = await _treinos.listarPorAluno(user.id!);
    final hoje = DateUtils.dateOnly(DateTime.now());
    final treino = pessoaTreinos
        .where(
          (t) =>
              t.status == 'ATIVO' &&
              !DateUtils.dateOnly(t.validade).isBefore(hoje),
        )
        .firstOrNull;
    final quantidade = treino == null
        ? 0
        : (await _treinos.contagemPorTreino())[treino.id] ?? 0;
    final professor = treino == null
        ? null
        : await UsuarioService().buscarPorId(treino.professorId);
    final aula = agendamentos
        .where((h) => h['agendamento_id'] != null)
        .firstOrNull;
    final avaliacoes = await AvaliacaoService().listar(user.id!);
    return _HomeDados(
      treino: treino,
      professorNome: professor?.nome,
      exercicios: quantidade,
      proximaAula: aula,
      avaliacoes: avaliacoes,
    );
  }

  Future<void> _atualizar() async {
    setState(() => _dados = _carregar());
    await _dados;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<_HomeDados>(
      future: _dados,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Não foi possível carregar a Home.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final user = _usuario;
        final nome = user?.nome ?? 'Usuário';
        return RefreshIndicator(
          onRefresh: _atualizar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _cabecalho(nome),
              const SizedBox(height: 24),
              _atalhos(),
              const SizedBox(height: 24),
              if (_professor) ...[
                _tituloSecao(
                  'Seus alunos',
                  acao: 'Ver treinos',
                  aoClicar: () => _navegar(const TreinosScreen()),
                ),
                const SizedBox(height: 10),
                _listaAlunos(snapshot.data!.alunos),
                const SizedBox(height: 22),
                _tituloSecao(
                  'Suas próximas aulas',
                  acao: 'Ver agenda',
                  aoClicar: () => _navegar(const AgendamentosScreen()),
                ),
                const SizedBox(height: 10),
                _listaAulas(snapshot.data!.aulas),
              ] else ...[
                _tituloSecao(
                  'Treino de hoje',
                  acao: snapshot.data!.treino == null ? null : 'Ver detalhes',
                  aoClicar: snapshot.data!.treino == null
                      ? null
                      : () => _navegar(
                          DetalhesTreinoScreen(treino: snapshot.data!.treino!),
                        ),
                ),
                const SizedBox(height: 10),
                _cartaoTreino(snapshot.data!),
                const SizedBox(height: 22),
                _tituloSecao(
                  'Próximo agendamento',
                  acao: 'Ver agenda',
                  aoClicar: () => _navegar(const AgendamentosScreen()),
                ),
                const SizedBox(height: 10),
                _cartaoProximaAula(snapshot.data!.proximaAula),
                const SizedBox(height: 22),
                _tituloSecao(
                  'Evolução',
                  acao: 'Ver evolução',
                  aoClicar: () => _navegar(const EvolucaoScreen()),
                ),
                const SizedBox(height: 10),
                _cartaoEvolucao(snapshot.data!.avaliacoes),
              ],
            ],
          ),
        );
      },
    ),
  );

  Widget _cabecalho(String nome) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dataHoje(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 3),
            Text(
              'Olá, $nome!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      CircleAvatar(
        radius: 32,
        backgroundColor: AppTheme.primariaSuave,
        child: Text(
          nome.isEmpty ? '?' : nome[0].toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaria,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  Widget _atalhos() => Row(
    children: _professor
        ? [
            _atalho(
              'Montar treino',
              Icons.add,
              () => _navegar(const NovoTreinoScreen()),
            ),
            const SizedBox(width: 9),
            _atalho(
              'Nova avaliação',
              Icons.monitor_heart_outlined,
              () => _navegar(const AvaliacaoScreen()),
            ),
            const SizedBox(width: 9),
            _atalho(
              'Exercícios',
              Icons.tune,
              () => _navegar(const ExerciciosScreen()),
            ),
          ]
        : [
            _atalho(
              'Exercícios',
              Icons.tune,
              () => _navegar(const ExerciciosScreen()),
            ),
            const SizedBox(width: 9),
            _atalho(
              'Evolução',
              Icons.monitor_heart_outlined,
              () => _navegar(const EvolucaoScreen()),
            ),
            const SizedBox(width: 9),
            _atalho(
              'Agenda',
              Icons.calendar_month_outlined,
              () => _navegar(const AgendamentosScreen()),
            ),
          ],
  );

  Widget _atalho(String label, IconData icone, VoidCallback acao) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: acao,
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borda),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primariaSuave,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, size: 21, color: AppTheme.primaria),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tituloSecao(String titulo, {String? acao, VoidCallback? aoClicar}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleLarge),
          if (acao != null)
            TextButton(
              onPressed: aoClicar,
              child: Text(
                acao,
                style: const TextStyle(
                  color: AppTheme.primaria,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );

  Widget _cartaoTreino(_HomeDados dados) {
    final treino = dados.treino;
    if (treino == null) return _vazio('Você ainda não tem um treino ativo.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                _iconeBox(Icons.fitness_center),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treino.nome,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${dados.exercicios} exercícios · Prof. ${dados.professorNome ?? 'Academia Grazy'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(child: _pill('Válido até ${_data(treino.validade)}')),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () =>
                      _navegar(DetalhesTreinoScreen(treino: treino)),
                  child: const Text('Ver treino'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoProximaAula(Map<String, Object?>? aula) {
    if (aula == null) return _vazio('Você ainda não tem um agendamento.');
    final inicio = DateTime.parse(aula['inicio'] as String);
    final vagas = (aula['capacidade'] as int) - (aula['ocupadas'] as int);
    final agendamentoId = aula['agendamento_id'] as int;
    final status = aula['agendamento_status'] as String? ?? 'AGENDADO';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.primariaSuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${inicio.day}',
                    style: const TextStyle(
                      color: AppTheme.primaria,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _mesAbrev(inicio.month).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaria,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aula['nome_aula'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_hora(inicio)} · Prof. ${aula['professor_nome']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status == 'CHECK_IN'
                        ? 'Check-in realizado'
                        : '$vagas vagas disponíveis',
                    style: TextStyle(
                      color: status == 'CHECK_IN'
                          ? AppTheme.sucesso
                          : AppTheme.sucesso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: status == 'CHECK_IN'
                  ? null
                  : () async {
                      try {
                        await AgendamentoService().checkin(agendamentoId);
                        await _atualizar();
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaria),
                foregroundColor: AppTheme.primaria,
              ),
              child: Text(status == 'CHECK_IN' ? 'Feito' : 'Check-in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoEvolucao(List<AvaliacaoFisica> avaliacoes) {
    if (avaliacoes.isEmpty)
      return _vazio('Nenhuma avaliação registrada até agora.');
    final atual = avaliacoes.first;
    final anterior = avaliacoes.length > 1 ? avaliacoes.last : null;
    final deltaPeso = anterior == null ? null : atual.peso - anterior.peso;
    final deltaGordura =
        anterior == null ||
            atual.percentualGordura == null ||
            anterior.percentualGordura == null
        ? null
        : atual.percentualGordura! - anterior.percentualGordura!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _medida(
                'Peso',
                '${atual.peso.toStringAsFixed(0)} kg',
                deltaPeso == null
                    ? 'Última avaliação'
                    : '${deltaPeso <= 0 ? '▼' : '▲'} ${deltaPeso.abs().toStringAsFixed(1)} kg desde ${_data(anterior!.data)}',
              ),
            ),
            Container(width: 1, height: 76, color: AppTheme.borda),
            const SizedBox(width: 16),
            Expanded(
              child: _medida(
                '% Gordura',
                atual.percentualGordura == null
                    ? '—'
                    : '${atual.percentualGordura!.toStringAsFixed(0)}%',
                deltaGordura == null
                    ? 'Sem comparação'
                    : '${deltaGordura <= 0 ? '▼' : '▲'} ${deltaGordura.abs().toStringAsFixed(1)} pontos',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaAlunos(List<_AlunoResumo> alunos) {
    if (alunos.isEmpty) return _vazio('Nenhum aluno cadastrado.');
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < alunos.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primariaSuave,
                child: Text(
                  alunos[i].aluno.nome[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaria,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                alunos[i].aluno.nome,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                alunos[i].treino == null
                    ? 'Sem treino cadastrado'
                    : '${alunos[i].treino!.nome} · até ${_data(alunos[i].treino!.validade)}',
              ),
              trailing: _pill(
                alunos[i].treino?.status == 'ATIVO' ? 'Ativo' : 'Sem treino',
                sucesso: alunos[i].treino?.status == 'ATIVO',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _listaAulas(List<Map<String, Object?>> aulas) {
    if (aulas.isEmpty) return _vazio('Não há aulas próximas na agenda.');
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < aulas.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 70),
            ListTile(
              leading: SizedBox(
                width: 55,
                child: Text(
                  _hora(DateTime.parse(aulas[i]['inicio'] as String)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              title: Text(
                aulas[i]['nome_aula'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${aulas[i]['ocupadas']} inscritos · mínimo ${aulas[i]['min_participantes']} · ${aulas[i]['capacidade']} vagas',
              ),
              trailing:
                  (aulas[i]['ocupadas'] as int) >=
                      (aulas[i]['min_participantes'] as int)
                  ? _pill('Confirmada', sucesso: true)
                  : _pill(
                      'Faltam ${(aulas[i]['min_participantes'] as int) - (aulas[i]['ocupadas'] as int)}',
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medida(String titulo, String valor, String variacao) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(
        valor,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.texto,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        variacao,
        style: const TextStyle(
          color: AppTheme.sucesso,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _iconeBox(IconData icone) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppTheme.primariaSuave,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icone, color: AppTheme.primaria, size: 27),
  );

  Widget _pill(String texto, {bool sucesso = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: sucesso ? const Color(0xFFE8F5EE) : const Color(0xFFF4F6FA),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: sucesso ? AppTheme.sucesso : AppTheme.textoSecundario,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _vazio(String texto) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaria),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    ),
  );

  Future<void> _navegar(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
    if (mounted) await _atualizar();
  }

  String _dataHoje() {
    final d = DateTime.now();
    const dias = [
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${_capitalizar(dias[d.weekday - 1])}, ${d.day} de ${meses[d.month - 1]}';
  }

  String _capitalizar(String texto) =>
      '${texto[0].toUpperCase()}${texto.substring(1)}';
  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _mesAbrev(int m) => const [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ][m - 1];
}
