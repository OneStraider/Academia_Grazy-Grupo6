import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/admin_service.dart';
import '../../services/database_events.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'admin_access_guard.dart';
import '../perfil/perfil_screen.dart';

enum _Periodo { ano, mes, semana, dia }

class AdminPrototypeScreen extends StatefulWidget {
  const AdminPrototypeScreen({super.key});

  @override
  State<AdminPrototypeScreen> createState() => _AdminPrototypeScreenState();
}

class _AdminPrototypeScreenState extends State<AdminPrototypeScreen> {
  final _service = AdminService();
  final _busca = TextEditingController();
  int _pagina = 0;
  _Periodo _periodo = _Periodo.mes;
  DateTime _referencia = DateTime.now();
  String _buscaAtual = '';
  late Future<AdminMetricas> _metricas;
  late Future<List<Usuario>> _pessoas;
  late Future<List<AdminAvaliacaoResumo>> _avaliacoes;

  AdminGranularidade get _granularidade => switch (_periodo) {
    _Periodo.ano => AdminGranularidade.ano,
    _Periodo.mes => AdminGranularidade.mes,
    _Periodo.semana => AdminGranularidade.semana,
    _Periodo.dia => AdminGranularidade.dia,
  };

  AdminPeriodo get _periodoAtual =>
      AdminPeriodo.calcular(_granularidade, _referencia);

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_atualizar);
    _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_atualizar);
    _busca.dispose();
    super.dispose();
  }

  void _carregar() {
    _metricas = _service.carregarMetricas(_periodoAtual);
    _pessoas = _service.listarPessoas(
      tipo: _pagina == 2 ? 'PROFESSOR' : 'ALUNO',
      busca: _buscaAtual,
    );
    _avaliacoes = _service.listarAvaliacoes(
      periodo: _periodoAtual,
      busca: _buscaAtual,
    );
  }

  void _atualizar() {
    if (!mounted) return;
    setState(_carregar);
  }

  void _definirPeriodo(_Periodo periodo) {
    setState(() {
      _periodo = periodo;
      _carregar();
    });
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _referencia,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (data == null || !mounted) return;
    setState(() {
      _referencia = data;
      _carregar();
    });
  }

  String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _rotuloPeriodo() {
    final periodo = _periodoAtual;
    final fim = periodo.fim.subtract(const Duration(days: 1));
    return switch (_periodo) {
      _Periodo.ano => '${periodo.inicio.year}',
      _Periodo.mes =>
        '${periodo.inicio.month.toString().padLeft(2, '0')}/${periodo.inicio.year}',
      _Periodo.semana => '${_data(periodo.inicio)} – ${_data(fim)}',
      _Periodo.dia => _data(periodo.inicio),
    };
  }

  @override
  Widget build(BuildContext context) => AdminAccessGuard(
    child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                'Visão geral',
                'Alunos',
                'Equipe',
                'Avaliações',
                'Perfil',
              ][_pagina],
            ),
            Text(
              'ACADEMIA GRAZY · ADMINISTRAÇÃO',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white70, letterSpacing: .7),
            ),
          ],
        ),
        actions: [
          if (_pagina != 4)
            IconButton(
              tooltip: 'Meu perfil',
              onPressed: () => setState(() => _pagina = 4),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (_pagina) {
        0 => _dashboard(),
        1 => _listaPessoas(alunos: true),
        2 => _listaPessoas(alunos: false),
        3 => _listaAvaliacoes(),
        _ => const PerfilScreen(),
      },
      floatingActionButton: _pagina == 1 || _pagina == 2
          ? FloatingActionButton.extended(
              onPressed: () => _editarPessoa(null, aluno: _pagina == 1),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(_pagina == 1 ? 'Novo aluno' : 'Novo professor'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pagina,
        onDestinationSelected: (index) => setState(() {
          _pagina = index;
          _busca.clear();
          _buscaAtual = '';
          _carregar();
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Equipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Avaliações',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    ),
  );

  Widget _dashboard() => RefreshIndicator(
    onRefresh: () async => _atualizar(),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _CabecalhoAdmin(
          nome: UsuarioService.usuarioLogado?.nome ?? 'Administração',
        ),
        const SizedBox(height: 16),
        _Painel(
          titulo: 'Período de análise',
          subtitulo:
              'Comparação calculada com o período imediatamente anterior',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _seletorPeriodo(),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _escolherData,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text('${_rotuloPeriodo()}  ·  Alterar referência'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FutureBuilder<AdminMetricas>(
          future: _metricas,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _erro(snapshot.error);
            if (!snapshot.hasData) return const _Carregando();
            final dados = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final largura = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: largura,
                      child: _Indicador(
                        titulo: 'Treinos criados',
                        valor: '${dados.treinos}',
                        anterior: dados.treinosAnteriores,
                        icone: Icons.fitness_center,
                        cor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _Indicador(
                        titulo: 'Novos alunos',
                        valor: '${dados.alunos}',
                        anterior: dados.alunosAnteriores,
                        icone: Icons.person_add_alt_1,
                        cor: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(
                      width: largura,
                      child: _Indicador(
                        titulo: 'Avaliações',
                        valor: '${dados.avaliacoes}',
                        anterior: dados.avaliacoesAnteriores,
                        icone: Icons.fact_check_outlined,
                        cor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        _Painel(
          titulo: 'Atividade no período',
          subtitulo: 'Treinos criados, comparados ao período anterior',
          child: FutureBuilder<AdminMetricas>(
            future: _metricas,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _erro(snapshot.error);
              if (!snapshot.hasData) return const _Carregando();
              return _ComparacaoTreinos(
                atual: snapshot.data!.treinos,
                anterior: snapshot.data!.treinosAnteriores,
                corAtual: Theme.of(context).colorScheme.primary,
                corAnterior: Theme.of(context).colorScheme.primaryContainer,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _Painel(
          titulo: 'Avaliações dos alunos',
          subtitulo: 'Registros reais no período selecionado',
          child: Row(
            children: [
              const Expanded(
                child: Text('Consulte os registros de avaliação física.'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _pagina = 3),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _seletorPeriodo() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<_Periodo>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: _Periodo.ano, label: Text('Ano')),
        ButtonSegment(value: _Periodo.mes, label: Text('Mês')),
        ButtonSegment(value: _Periodo.semana, label: Text('Semana')),
        ButtonSegment(value: _Periodo.dia, label: Text('Dia')),
      ],
      selected: {_periodo},
      onSelectionChanged: (valores) => _definirPeriodo(valores.first),
    ),
  );

  Widget _listaPessoas({required bool alunos}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alunos ? 'Cadastro de alunos' : 'Equipe de professores',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              alunos
                  ? 'Consulte os dados e a situação de acesso.'
                  : 'Gerencie quem está atuando na equipe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _busca,
              onChanged: (valor) => setState(() {
                _buscaAtual = valor;
                _pessoas = _service.listarPessoas(
                  tipo: alunos ? 'ALUNO' : 'PROFESSOR',
                  busca: valor,
                );
              }),
              decoration: InputDecoration(
                hintText: alunos ? 'Buscar aluno' : 'Buscar professor',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _busca.clear();
                          setState(() {
                            _buscaAtual = '';
                            _pessoas = _service.listarPessoas(
                              tipo: alunos ? 'ALUNO' : 'PROFESSOR',
                            );
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Usuario>>(
          future: _pessoas,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Não foi possível carregar os cadastros: ${snapshot.error}',
                ),
              );
            }
            if (!snapshot.hasData) return const _Carregando();
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum cadastro encontrado.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pessoa = snapshot.data![index];
                return _PessoaTile(
                  pessoa: pessoa,
                  alunos: alunos,
                  onTap: () => _detalhesPessoa(pessoa),
                  onEditar: () => _editarPessoa(pessoa, aluno: alunos),
                  onStatus: () => _alterarAtivo(pessoa),
                );
              },
            );
          },
        ),
      ),
      if (alunos)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _AvisoSecretaria(),
        ),
    ],
  );

  Widget _listaAvaliacoes() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
    children: [
      Text(
        'Avaliações físicas',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      Text(
        'Registros reais de alunos e professores.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      _seletorPeriodo(),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _escolherData,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text('Referência: ${_data(_referencia)}'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _busca,
        onChanged: (valor) => setState(() {
          _buscaAtual = valor;
          _avaliacoes = _service.listarAvaliacoes(
            periodo: _periodoAtual,
            busca: valor,
          );
        }),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Buscar aluno ou professor',
        ),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<AdminAvaliacaoResumo>>(
        future: _avaliacoes,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _erro(snapshot.error);
          if (!snapshot.hasData) return const _Carregando();
          if (snapshot.data!.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhuma avaliação encontrada neste período.'),
              ),
            );
          }
          return Column(
            children: [
              _ResumoAvaliacao(
                rotulo: 'No período',
                valor: '${snapshot.data!.length}',
              ),
              const SizedBox(height: 12),
              for (final avaliacao in snapshot.data!)
                Card(
                  child: ListTile(
                    onTap: () => _detalhesAvaliacao(avaliacao),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        avaliacao.aluno.substring(0, 1),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      avaliacao.aluno,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${avaliacao.professor} · ${_data(avaliacao.data)}',
                    ),
                    trailing: const _StatusPill(status: 'Registrada'),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _editarPessoa(Usuario? pessoa, {required bool aluno}) async {
    final nome = TextEditingController(text: pessoa?.nome ?? '');
    final email = TextEditingController(text: pessoa?.email ?? '');
    final senha = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          pessoa == null
              ? (aluno ? 'Novo aluno' : 'Novo professor')
              : 'Editar cadastro',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Informe um e-mail válido.'
                      : null,
                ),
                if (pessoa == null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: senha,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha inicial',
                    ),
                    validator: (v) => v == null || v.trim().length < 6
                        ? 'Use pelo menos 6 caracteres.'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (salvou == true) {
      try {
        await _service.salvarPessoa(
          id: pessoa?.id,
          nome: nome.text,
          email: email.text,
          tipo: aluno ? 'ALUNO' : 'PROFESSOR',
          senha: pessoa == null ? senha.text : null,
        );
        if (mounted) _mensagem('Cadastro salvo.');
      } catch (erro) {
        if (mounted) _mensagem('$erro');
      }
    }
    nome.dispose();
    email.dispose();
    senha.dispose();
  }

  Future<void> _detalhesPessoa(Usuario pessoa) async {
    try {
      final dados = await _service.detalhes(pessoa.id!);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dados.usuario.nome,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(dados.usuario.email),
                const SizedBox(height: 12),
                _DetalheLinha(
                  rotulo: 'Perfil',
                  valor: dados.usuario.ehAluno ? 'Aluno' : 'Professor',
                ),
                _DetalheLinha(
                  rotulo: 'Situação',
                  valor: dados.usuario.ativo
                      ? (dados.usuario.ehAluno ? 'Ativo' : 'Na equipe')
                      : (dados.usuario.ehAluno ? 'Inativo' : 'Fora da equipe'),
                ),
                _DetalheLinha(
                  rotulo: 'Treinos relacionados',
                  valor: '${dados.treinos}',
                ),
                if (dados.usuario.ehAluno)
                  _DetalheLinha(
                    rotulo: 'Avaliações',
                    valor: '${dados.avaliacoes}',
                  ),
                if (!dados.usuario.ativo && dados.usuario.ehAluno)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _AvisoSecretaria(),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (erro) {
      _mensagem('$erro');
    }
  }

  Future<void> _alterarAtivo(Usuario pessoa) async {
    final ativoNovo = !pessoa.ativo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ativoNovo ? 'Reativar cadastro?' : 'Desativar cadastro?'),
        content: Text(
          ativoNovo
              ? 'A pessoa poderá voltar a acessar o aplicativo.'
              : pessoa.ehAluno
              ? 'O aluno perderá acesso e será orientado a resolver pendências na secretaria. O histórico será preservado.'
              : 'O professor perderá acesso e aparecerá como fora da equipe. O histórico será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ativoNovo ? 'Reativar' : 'Desativar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _service.definirAtivo(pessoa.id!, ativoNovo);
      if (mounted) {
        _mensagem(ativoNovo ? 'Cadastro reativado.' : 'Cadastro desativado.');
      }
    } catch (erro) {
      _mensagem('$erro');
    }
  }

  void _detalhesAvaliacao(AdminAvaliacaoResumo avaliacao) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Avaliação de ${avaliacao.aluno}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _DetalheLinha(
                rotulo: 'Professor responsável',
                valor: avaliacao.professor,
              ),
              _DetalheLinha(rotulo: 'Data', valor: _data(avaliacao.data)),
              _DetalheLinha(
                rotulo: 'Peso',
                valor: '${avaliacao.peso.toStringAsFixed(1)} kg',
              ),
              _DetalheLinha(
                rotulo: 'Altura',
                valor: '${avaliacao.altura.toStringAsFixed(2)} m',
              ),
              _DetalheLinha(
                rotulo: 'Massa magra',
                valor: '${avaliacao.massaMagra.toStringAsFixed(1)} kg',
              ),
              if (avaliacao.percentualGordura != null)
                _DetalheLinha(
                  rotulo: 'Gordura corporal',
                  valor: '${avaliacao.percentualGordura!.toStringAsFixed(1)}%',
                ),
              _DetalheLinha(
                rotulo: 'Observações',
                valor: avaliacao.observacoes?.trim().isNotEmpty == true
                    ? avaliacao.observacoes!
                    : 'Sem observações.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _erro(Object? erro) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text('Não foi possível carregar os dados: $erro'),
    ),
  );

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }
}

class _CabecalhoAdmin extends StatelessWidget {
  final String nome;
  const _CabecalhoAdmin({required this.nome});

  @override
  Widget build(BuildContext context) {
    final primeiroNome = nome.trim().split(RegExp(r'\s+')).first;
    final hoje = DateTime.now();
    final dataHoje =
        '${hoje.day.toString().padLeft(2, '0')}/'
        '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaria, Color(0xFF0B6D5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaria.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAINEL DE CONTROLE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Olá, $primeiroNome',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: Colors.white, fontSize: 27),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acompanhe os resultados e a equipe da academia.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppTheme.destaque,
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      dataHoje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              size: 30,
              color: AppTheme.destaque,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final String titulo, valor;
  final int anterior;
  final IconData icone;
  final Color cor;
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.anterior,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final atual = int.tryParse(valor) ?? 0;
    final esquema = Theme.of(context).colorScheme;
    final variacao = anterior == 0
        ? (atual == 0 ? '0%' : 'Novo')
        : '${(((atual - anterior) / anterior) * 100).toStringAsFixed(1)}%';
    final subiu = atual >= anterior;
    final corVariacao = anterior == 0
        ? esquema.tertiary
        : subiu
        ? esquema.primary
        : esquema.error;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icone, color: cor, size: 20),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: corVariacao.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    anterior == 0
                        ? Icons.trending_up
                        : subiu
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: corVariacao,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '$variacao vs. anterior',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: corVariacao,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  final String titulo, subtitulo;
  final Widget child;
  const _Painel({
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _ComparacaoTreinos extends StatelessWidget {
  final int atual, anterior;
  final Color corAtual, corAnterior;
  const _ComparacaoTreinos({
    required this.atual,
    required this.anterior,
    required this.corAtual,
    required this.corAnterior,
  });
  @override
  Widget build(BuildContext context) {
    final maior = (atual > anterior ? atual : anterior).clamp(1, 1 << 30);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BarraComparativa(
            rotulo: 'Anterior',
            valor: anterior,
            altura: anterior / maior,
            cor: corAnterior,
          ),
          _BarraComparativa(
            rotulo: 'Atual',
            valor: atual,
            altura: atual / maior,
            cor: corAtual,
          ),
        ],
      ),
    );
  }
}

class _BarraComparativa extends StatelessWidget {
  final String rotulo;
  final int valor;
  final double altura;
  final Color cor;
  const _BarraComparativa({
    required this.rotulo,
    required this.valor,
    required this.altura,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$valor'),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: altura,
              widthFactor: .36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _PessoaTile extends StatelessWidget {
  final Usuario pessoa;
  final bool alunos;
  final VoidCallback onTap, onEditar, onStatus;
  const _PessoaTile({
    required this.pessoa,
    required this.alunos,
    required this.onTap,
    required this.onEditar,
    required this.onStatus,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      leading: CircleAvatar(
        backgroundColor: pessoa.ativo
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        child: Text(
          pessoa.nome.isEmpty ? '?' : pessoa.nome.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: pessoa.ativo
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(pessoa.nome, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pessoa.email, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          _StatusPill(
            status: pessoa.ativo
                ? (alunos ? 'Ativo' : 'Na equipe')
                : (alunos ? 'Inativo' : 'Fora da equipe'),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        tooltip: 'Ações do cadastro',
        onSelected: (acao) => acao == 'editar' ? onEditar() : onStatus(),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'editar', child: Text('Editar dados')),
          PopupMenuItem(
            value: 'status',
            child: Text(pessoa.ativo ? 'Desativar acesso' : 'Ativar acesso'),
          ),
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final ativo =
        status == 'Ativo' || status == 'Na equipe' || status == 'Registrada';
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ativo ? esquema.primaryContainer : esquema.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: ativo ? esquema.onPrimaryContainer : esquema.onErrorContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvisoSecretaria extends StatelessWidget {
  const _AvisoSecretaria();
  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: esquema.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alunos inativos devem resolver as pendências na secretaria para voltar a acessar o app.',
              style: TextStyle(
                color: esquema.onTertiaryContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoAvaliacao extends StatelessWidget {
  final String rotulo, valor;
  const _ResumoAvaliacao({required this.rotulo, required this.valor});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Text(rotulo, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(valor, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    ),
  );
}

class _DetalheLinha extends StatelessWidget {
  final String rotulo, valor;
  const _DetalheLinha({required this.rotulo, required this.valor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(rotulo, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}

class _Carregando extends StatelessWidget {
  const _Carregando();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator()),
  );
}
