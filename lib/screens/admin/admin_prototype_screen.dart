import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/admin_service.dart';
import '../../services/database_events.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'admin_access_guard.dart';
import '../perfil/perfil_screen.dart';
import '../../widgets/modulo_page_view.dart';

enum _Periodo { ano, mes, semana }

enum _FiltroAvaliacao { todas, abertas, concluidas }

class AdminPrototypeScreen extends StatefulWidget {
  const AdminPrototypeScreen({super.key});

  @override
  State<AdminPrototypeScreen> createState() => _AdminPrototypeScreenState();
}

class _AdminPrototypeScreenState extends State<AdminPrototypeScreen> {
  static const _modulos = <(String, IconData)>[
    ('Visão geral', Icons.space_dashboard_outlined),
    ('Alunos e usuários', Icons.groups_outlined),
    ('Equipe', Icons.fitness_center_outlined),
    ('Avaliações', Icons.fact_check_outlined),
  ];

  final _service = AdminService();
  final _busca = TextEditingController();
  final _buscaEquipe = TextEditingController();
  int _pagina = 0;
  String _tipoPessoa = 'TODOS';
  late final PageController _pageController;
  _Periodo _periodo = _Periodo.mes;
  DateTime _referencia = DateTime.now();
  int? _professorSelecionado;
  _FiltroAvaliacao _filtroAvaliacao = _FiltroAvaliacao.todas;
  final Map<String, bool> _graficoBarras = {
    'treinos': false,
    'novos': false,
    'total': false,
  };
  String _buscaAtual = '';
  String _buscaEquipeAtual = '';
  late Future<AdminMetricas> _metricas;
  late Future<List<Usuario>> _pessoas;
  late Future<List<Usuario>> _professores;
  late Future<List<AdminAvaliacaoResumo>> _avaliacoes;
  late Future<List<AdminPontoSerie>> _serieTreinos;
  late Future<List<AdminPontoSerie>> _serieNovos;
  late Future<List<AdminPontoSerie>> _serieTotal;

  AdminGranularidade get _granularidade => switch (_periodo) {
    _Periodo.ano => AdminGranularidade.ano,
    _Periodo.mes => AdminGranularidade.mes,
    _Periodo.semana => AdminGranularidade.semana,
  };

  AdminPeriodo get _periodoAtual =>
      AdminPeriodo.calcular(_granularidade, _referencia);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    DatabaseEvents.revision.addListener(_atualizar);
    _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_atualizar);
    _pageController.dispose();
    _busca.dispose();
    _buscaEquipe.dispose();
    super.dispose();
  }

  void _selecionarPagina(int pagina) {
    if (pagina == _pagina) {
      _atualizar();
      return;
    }
    _busca.clear();
    _buscaEquipe.clear();
    _buscaAtual = '';
    _buscaEquipeAtual = '';
    _pageController.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
    );
  }

  void _paginaAlterada(int pagina) {
    if (pagina == _pagina) return;
    setState(() {
      _pagina = pagina;
      _busca.clear();
      _buscaEquipe.clear();
      _buscaAtual = '';
      _buscaEquipeAtual = '';
      if (pagina == 1 || pagina == 2) {
        if (pagina == 1) {
          _pessoas = _service.listarPessoas(tipo: _tipoPessoa);
        } else {
          _professores = _service.listarPessoas(tipo: 'PROFESSOR');
        }
      }
    });
  }

  void _selecionarTipoPessoa(String tipo) {
    if (tipo == _tipoPessoa) return;
    setState(() {
      _tipoPessoa = tipo;
      _busca.clear();
      _buscaAtual = '';
      _pessoas = _service.listarPessoas(tipo: tipo);
    });
  }

  void _carregar() {
    _metricas = _service.carregarMetricas(_periodoAtual);
    _pessoas = _service.listarPessoas(
      tipo: _pagina == 2
          ? 'PROFESSOR'
          : _pagina == 1
          ? _tipoPessoa
          : 'ALUNO',
      busca: _buscaAtual,
    );
    _professores = _service.listarPessoas(
      tipo: 'PROFESSOR',
      busca: _buscaEquipeAtual,
    );
    _avaliacoes = _service.listarAvaliacoes(
      periodo: _periodoAtual,
      busca: _buscaAtual,
    );
    _serieTreinos = _service.carregarSerie(
      periodo: _granularidade,
      referencia: _referencia,
      metrica: 'treinos',
      professorId: _professorSelecionado,
    );
    _serieNovos = _service.carregarSerie(
      periodo: _granularidade,
      referencia: _referencia,
      metrica: 'novos',
    );
    _serieTotal = _service.carregarSerie(
      periodo: _granularidade,
      referencia: _referencia,
      metrica: 'total',
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
    };
  }

  @override
  Widget build(BuildContext context) => AdminAccessGuard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (desktop) _navegacaoLateral(),
                Expanded(
                  child: Column(
                    children: [
                      _barraSuperior(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1320),
                            child: ModuloPageView(
                              controller: _pageController,
                              onPageChanged: _paginaAlterada,
                              children: [
                                KeyedSubtree(
                                  key: const PageStorageKey('admin_dashboard'),
                                  child: _dashboard(),
                                ),
                                KeyedSubtree(
                                  key: const PageStorageKey('admin_usuarios'),
                                  child: _listaPessoas(
                                    alunos: _tipoPessoa != 'PROFESSOR',
                                  ),
                                ),
                                KeyedSubtree(
                                  key: const PageStorageKey('admin_equipe'),
                                  child: _listaEquipe(),
                                ),
                                KeyedSubtree(
                                  key: const PageStorageKey('admin_avaliacoes'),
                                  child: _listaAvaliacoes(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _pagina == 1
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      _editarPessoa(null, aluno: _tipoPessoa != 'PROFESSOR'),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(
                    _tipoPessoa == 'PROFESSOR'
                        ? 'Novo professor'
                        : 'Novo aluno',
                  ),
                )
              : null,
          bottomNavigationBar: desktop ? null : _navegacaoInferior(),
        );
      },
    ),
  );

  Widget _navegacaoLateral() => Container(
    width: 232,
    color: AppTheme.primaria,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academia Grazy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ADMINISTRAÇÃO',
                style: TextStyle(
                  color: Color(0xFFBFD8CF),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < _modulos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              selected: i == _pagina,
              selectedTileColor: Colors.white.withValues(alpha: .15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(_modulos[i].$2, color: Colors.white),
              title: Text(
                _modulos[i].$1,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => _selecionarPagina(i),
            ),
          ),
        const Spacer(),
        ListTile(
          leading: const Icon(
            Icons.account_circle_outlined,
            color: Colors.white,
          ),
          title: const Text(
            'Meu perfil',
            style: TextStyle(color: Colors.white),
          ),
          onTap: _abrirPerfil,
        ),
      ],
    ),
  );

  Widget _barraSuperior() => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            if (MediaQuery.sizeOf(context).width < 900)
              Expanded(
                child: Text(
                  _modulos[_pagina].$1,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Expanded(
                child: Text(
                  'Painel de controle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            IconButton(
              tooltip: 'Atualizar dados',
              onPressed: _atualizar,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Meu perfil',
              onPressed: _abrirPerfil,
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navegacaoInferior() => NavigationBar(
    selectedIndex: _pagina,
    onDestinationSelected: _selecionarPagina,
    labelBehavior: MediaQuery.sizeOf(context).width < 360
        ? NavigationDestinationLabelBehavior.onlyShowSelected
        : NavigationDestinationLabelBehavior.alwaysShow,
    destinations: [
      for (final modulo in _modulos)
        NavigationDestination(
          icon: Icon(modulo.$2),
          selectedIcon: Icon(modulo.$2),
          label: modulo.$1,
        ),
    ],
  );

  void _abrirPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Meu perfil')),
          body: const PerfilScreen(),
        ),
      ),
    );
  }

  Widget _dashboard() => RefreshIndicator(
    onRefresh: () async => _atualizar(),
    child: ListView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width >= 900 ? 24 : 16,
        16,
        MediaQuery.sizeOf(context).width >= 900 ? 24 : 16,
        28,
      ),
      children: [
        _CabecalhoAdmin(
          nome: UsuarioService.usuarioLogado?.nome ?? 'Administração',
        ),
        const SizedBox(height: 16),
        FutureBuilder<AdminMetricas>(
          future: _metricas,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _erro(snapshot.error);
            if (!snapshot.hasData) return const _Carregando();
            final dados = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final colunas = ((constraints.maxWidth + 12) / 202)
                    .floor()
                    .clamp(1, 3)
                    .toInt();
                final largura =
                    (constraints.maxWidth - (colunas - 1) * 12) / colunas;
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
                        titulo: 'Avaliações realizadas',
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
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: _cartaoSerie(
                    titulo: 'Treinos por professor',
                    metrica: 'treinos',
                    future: _serieTreinos,
                    cor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _cartaoSerie(
                    titulo: 'Novos alunos',
                    metrica: 'novos',
                    future: _serieNovos,
                    cor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _cartaoSerie(
                    titulo: 'Quantidade total de alunos',
                    metrica: 'total',
                    future: _serieTotal,
                    cor: Theme.of(context).colorScheme.secondary,
                    subtitulo: 'Total acumulado ao fim de cada intervalo; distinto dos novos cadastros.',
                  ),
                ),
              ],
            );
          },
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
                onPressed: () => _selecionarPagina(3),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Ver'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _cartaoSerie({
    required String titulo,
    required String metrica,
    required Future<List<AdminPontoSerie>> future,
    required Color cor,
    String? subtitulo,
  }) => _Painel(
    titulo: titulo,
    subtitulo: subtitulo ?? 'Período: ${_rotuloPeriodo()}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (metrica == 'treinos') ...[
          FutureBuilder<List<Usuario>>(
            future: _professores,
            builder: (context, snapshot) => DropdownButtonFormField<int?>(
              initialValue: snapshot.hasData ? _professorSelecionado : null,
              decoration: const InputDecoration(
                labelText: 'Professor',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos os professores'),
                ),
                for (final p in snapshot.data ?? const <Usuario>[])
                  DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(p.nome, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => setState(() {
                _professorSelecionado = id;
                _serieTreinos = _service.carregarSerie(
                  periodo: _granularidade,
                  referencia: _referencia,
                  metrica: 'treinos',
                  professorId: id,
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.show_chart),
                label: Text('Linhas'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.bar_chart),
                label: Text('Barras'),
              ),
            ],
            selected: {_graficoBarras[metrica] ?? false},
            onSelectionChanged: (v) =>
                setState(() => _graficoBarras[metrica] = v.first),
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<AdminPontoSerie>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _erro(snapshot.error);
            if (!snapshot.hasData) {
              return const SizedBox(height: 190, child: _Carregando());
            }
            final data = snapshot.data!;
            if (data.isEmpty) {
              return SizedBox(
                height: 110,
                child: Center(child: Text('Sem dados para este período.')),
              );
            }
            final names = data.expand((p) => p.valores.keys).toSet().toList()
              ..sort();
            final bars = _graficoBarras[metrica] ?? false;
            final plottedNames = bars && metrica == 'treinos'
                ? names
                      .where(
                        (name) =>
                            data.any((point) => (point.valores[name] ?? 0) > 0),
                      )
                      .toList()
                : List<String>.of(names);
            if (bars && metrica == 'treinos') {
              int totalDaSerie(String nome) => data.fold(
                0,
                (soma, ponto) => soma + (ponto.valores[nome] ?? 0),
              );
              plottedNames.sort((a, b) {
                final porTotal = totalDaSerie(b).compareTo(totalDaSerie(a));
                return porTotal != 0 ? porTotal : a.compareTo(b);
              });
            }
            final semTreinosNoPeriodo =
                metrica == 'treinos' &&
                data.every(
                  (ponto) =>
                      names.every((nome) => (ponto.valores[nome] ?? 0) == 0),
                );
            if (plottedNames.isEmpty || semTreinosNoPeriodo) {
              final mensagem = _professorSelecionado == null
                  ? 'Não há treinos criados pelos professores neste período.'
                  : 'Não há treinos criados por este professor neste período.';
              return SizedBox(
                height: 110,
                child: Center(child: Text(mensagem)),
              );
            }
            final coresLinha = [
              cor,
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.error,
              AppTheme.primariaSuave,
            ];
            final coresBarras = [
              cor,
              Theme.of(context).colorScheme.tertiary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.error,
              Colors.indigo,
              Colors.deepOrange,
              Colors.cyan.shade800,
              Colors.pink.shade700,
              Colors.brown,
              Colors.blueGrey,
            ];
            final cores = bars ? coresBarras : coresLinha;
            final colors = {
              for (var i = 0; i < names.length; i++)
                names[i]: cores[i % cores.length],
            };
            final totalPeriodo = metrica == 'total'
                ? (data.last.valores[names.first] ?? 0)
                : data.fold<int>(
                    0,
                    (soma, ponto) =>
                        soma +
                        plottedNames.fold<int>(
                          0,
                          (subtotal, nome) =>
                              subtotal + (ponto.valores[nome] ?? 0),
                        ),
                  );
            final zeroProfessores = names.length - plottedNames.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (bars) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalPeriodo',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Text(switch (metrica) {
                        'treinos' => 'treinos no período',
                        'novos' => 'novos alunos',
                        _ => 'alunos ao fim do período',
                      }, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 190,
                  child: CustomPaint(
                    painter: _SerieChartPainter(
                      data: data,
                      series: plottedNames,
                      colors: colors,
                      bars: bars,
                      textDirection: Directionality.of(context),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                if (bars && metrica == 'treinos' && zeroProfessores > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$zeroProfessores professores sem treinos no período',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < plottedNames.length; i++)
                      _LegendaSerie(
                        label: plottedNames[i],
                        color: colors[plottedNames[i]]!,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _seletorPeriodo() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<_Periodo>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: _Periodo.semana, label: Text('Semana')),
        ButtonSegment(value: _Periodo.mes, label: Text('Mês')),
        ButtonSegment(value: _Periodo.ano, label: Text('Ano')),
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
              _pagina == 1
                  ? 'Gestão de usuários'
                  : (alunos ? 'Cadastro de alunos' : 'Equipe de professores'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _pagina == 1
                  ? 'Gerencie os cadastros e os acessos da academia.'
                  : (alunos
                        ? 'Consulte os dados e a situação de acesso.'
                        : 'Gerencie quem está atuando na equipe.'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_pagina == 1) ...[
              const SizedBox(height: 14),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'TODOS', label: Text('Todos')),
                  ButtonSegment(value: 'ALUNO', label: Text('Alunos')),
                  ButtonSegment(value: 'PROFESSOR', label: Text('Professores')),
                ],
                selected: {_tipoPessoa},
                onSelectionChanged: (valores) =>
                    _selecionarTipoPessoa(valores.first),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _busca,
              onChanged: (valor) => setState(() {
                _buscaAtual = valor;
                _pessoas = _service.listarPessoas(
                  tipo: _tipoPessoa,
                  busca: valor,
                );
              }),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou e-mail',
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
                              tipo: _tipoPessoa,
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
                  alunos: pessoa.ehAluno,
                  onTap: () => _detalhesPessoa(pessoa),
                  onEditar: () => _editarPessoa(pessoa, aluno: pessoa.ehAluno),
                  onStatus: () => _alterarAtivo(pessoa),
                );
              },
            );
          },
        ),
      ),
      if (_tipoPessoa == 'ALUNO')
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _AvisoSecretaria(),
        ),
    ],
  );

  Widget _listaEquipe() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipe', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Professores e cadastros da equipe da academia.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _buscaEquipe,
              onChanged: (valor) => setState(() {
                _buscaEquipeAtual = valor;
                _professores = _service.listarPessoas(
                  tipo: 'PROFESSOR',
                  busca: valor,
                );
              }),
              decoration: InputDecoration(
                hintText: 'Buscar professor',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaEquipe.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () {
                          _buscaEquipe.clear();
                          setState(() {
                            _buscaEquipeAtual = '';
                            _professores = _service.listarPessoas(
                              tipo: 'PROFESSOR',
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
          future: _professores,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _erro(snapshot.error);
            if (!snapshot.hasData) return const _Carregando();
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhum professor encontrado.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisExtent: 146,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final professor = snapshot.data![index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _detalhesPessoa(professor),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: professor.ativo
                                ? AppTheme.primariaSuave
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            child: Text(
                              professor.nome.isEmpty
                                  ? '?'
                                  : professor.nome[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaria,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  professor.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  professor.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                _StatusPill(
                                  status: professor.ativo
                                      ? 'Na equipe'
                                      : 'Fora da equipe',
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (acao) {
                              if (acao == 'editar') {
                                _editarPessoa(professor, aluno: false);
                              } else {
                                _alterarAtivo(professor);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar dados'),
                              ),
                              PopupMenuItem(
                                value: 'status',
                                child: Text(
                                  professor.ativo
                                      ? 'Bloquear acesso'
                                      : 'Reativar acesso',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _listaAvaliacoes() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            _seletorPeriodo(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _escolherData,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Referência: ${_data(_referencia)}'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _busca,
              onChanged: (value) => setState(() {
                _buscaAtual = value;
                _avaliacoes = _service.listarAvaliacoes(
                  periodo: _periodoAtual,
                  busca: value,
                );
              }),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar aluno ou professor',
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_FiltroAvaliacao>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _FiltroAvaliacao.todas,
                    label: Text('Todas'),
                  ),
                  ButtonSegment(
                    value: _FiltroAvaliacao.abertas,
                    label: Text('Em aberto'),
                  ),
                  ButtonSegment(
                    value: _FiltroAvaliacao.concluidas,
                    label: Text('Concluídas'),
                  ),
                ],
                selected: {_filtroAvaliacao},
                onSelectionChanged: (value) =>
                    setState(() => _filtroAvaliacao = value.first),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<AdminAvaliacaoResumo>>(
          future: _avaliacoes,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _erro(snapshot.error);
            if (!snapshot.hasData) return const _Carregando();
            final filtradas = snapshot.data!
                .where(
                  (a) => switch (_filtroAvaliacao) {
                    _FiltroAvaliacao.todas => true,
                    _FiltroAvaliacao.abertas => a.status == 'ABERTA',
                    _FiltroAvaliacao.concluidas => a.status == 'CONCLUIDA',
                  },
                )
                .toList(growable: false);
            if (filtradas.isEmpty) {
              return const Center(
                child: Text('Nenhuma avaliação encontrada para este filtro.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: filtradas.length,
              itemBuilder: (context, index) {
                final avaliacao = filtradas[index];
                final aberta = avaliacao.status == 'ABERTA';
                return Card(
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
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Ações da avaliação',
                      onSelected: (value) async {
                        if (value == 'status') {
                          try {
                            await _service.definirStatusAvaliacao(
                              avaliacao.id,
                              aberta ? 'CONCLUIDA' : 'ABERTA',
                            );
                          } catch (error) {
                            _mensagem('$error');
                          }
                        } else if (value == 'excluir') {
                          final confirma = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Excluir avaliação?'),
                              content: Text(
                                'O registro de ${avaliacao.aluno} será removido permanentemente.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            ),
                          );
                          if (confirma == true) {
                            try {
                              await _service.excluirAvaliacao(avaliacao.id);
                            } catch (error) {
                              _mensagem('$error');
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'status',
                          child: Text(
                            aberta ? 'Marcar concluída' : 'Reabrir avaliação',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excluir',
                          child: Text('Excluir avaliação'),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _StatusPill(
                          status: aberta ? 'Em aberto' : 'Concluída',
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
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
    if (pessoa.ehProfessor) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _PerfilProfessorAdmin(professor: pessoa, service: _service),
        ),
      );
      return;
    }
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
        title: Text(ativoNovo ? 'Reativar acesso?' : 'Bloquear acesso?'),
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
            child: Text(ativoNovo ? 'Reativar acesso' : 'Bloquear acesso'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _service.definirAtivo(pessoa.id!, ativoNovo);
      if (mounted) {
        _mensagem(ativoNovo ? 'Acesso reativado.' : 'Acesso bloqueado.');
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
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final hoje = DateTime.now();
    final dataHoje =
        '${hoje.day.toString().padLeft(2, '0')}/'
        '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
    return Container(
      padding: EdgeInsets.all(desktop ? 24 : 18),
      decoration: BoxDecoration(
        color: AppTheme.primaria,
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: desktop ? 34 : 28,
                  ),
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
                  ?.copyWith(fontSize: 42),
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

class _PerfilProfessorAdmin extends StatelessWidget {
  final Usuario professor;
  final AdminService service;
  const _PerfilProfessorAdmin({required this.professor, required this.service});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil do professor')),
    body: FutureBuilder<List<AdminTreinoResumo>>(
      future: service.listarTreinosProfessor(professor.id!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Não foi possível carregar os treinos: ${snapshot.error}',
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const _Carregando();
        final treinos = snapshot.data!;
        final andamento = treinos
            .where((t) => t.status == 'ATIVO' && !t.concluido)
            .toList(growable: false);
        final concluidos = treinos
            .where((t) => t.concluido)
            .toList(growable: false);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(
                        professor.nome.isEmpty
                            ? '?'
                            : professor.nome[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            professor.nome,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(professor.email),
                          const SizedBox(height: 6),
                          Text(
                            'Professor · ${professor.ativo ? 'Acesso liberado' : 'Acesso bloqueado'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _tituloListaTreinos(
              context,
              'Treinos em andamento',
              andamento.length,
            ),
            if (andamento.isEmpty)
              const _EstadoVazioAdmin(
                texto: 'Este professor não tem treinos em andamento.',
              ),
            for (final treino in andamento)
              _TreinoProfessorTile(treino: treino, status: 'Em andamento'),
            const SizedBox(height: 16),
            _tituloListaTreinos(
              context,
              'Treinos concluídos',
              concluidos.length,
            ),
            if (concluidos.isEmpty)
              const _EstadoVazioAdmin(
                texto: 'Este professor ainda não tem treinos concluídos.',
              ),
            for (final treino in concluidos)
              _TreinoProfessorTile(treino: treino, status: 'Concluído'),
          ],
        );
      },
    ),
  );

  Widget _tituloListaTreinos(BuildContext context, String titulo, int count) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$titulo ($count)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}

class _TreinoProfessorTile extends StatelessWidget {
  final AdminTreinoResumo treino;
  final String status;
  const _TreinoProfessorTile({required this.treino, required this.status});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.fitness_center),
      title: Text(treino.nome),
      subtitle: Text(
        'Aluno: ${treino.aluno} · Status: $status · Validade: ${treino.validade.day}/${treino.validade.month}/${treino.validade.year}',
      ),
    ),
  );
}

class _EstadoVazioAdmin extends StatelessWidget {
  final String texto;
  const _EstadoVazioAdmin({required this.texto});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(texto)),
  );
}

class _LegendaSerie extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendaSerie({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _SerieChartPainter extends CustomPainter {
  final List<AdminPontoSerie> data;
  final List<String> series;
  final Map<String, Color> colors;
  final bool bars;
  final TextDirection textDirection;
  const _SerieChartPainter({
    required this.data,
    required this.series,
    required this.colors,
    required this.bars,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = bars ? 10.0 : 32.0;
    const right = 8.0, top = 10.0, bottom = 26.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxValue = data
        .expand((p) => series.map((name) => p.valores[name] ?? 0))
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE6DE)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: const Color(0xFF62716B), fontSize: 10);
    if (bars) {
      for (var i = 0; i <= 4; i++) {
        final y = plot.bottom - plot.height * i / 4;
        canvas.drawLine(
          Offset(plot.left, y),
          Offset(plot.right, y),
          i == 0
              ? (Paint()
                  ..color = AppTheme.primaria
                  ..strokeWidth = 2)
              : gridPaint,
        );
      }
    } else {
      for (var i = 0; i <= 3; i++) {
        final y = plot.bottom - plot.height * i / 3;
        canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
        _drawText(
          canvas,
          '${(maxValue * i / 3).round()}',
          Offset(0, y - 6),
          labelStyle,
          textDirection,
        );
      }
    }
    final count = data.length;
    final step = plot.width / count;
    if (bars) {
      final groupWidth = step * .86;
      final barWidth = groupWidth / series.length;
      for (var i = 0; i < count; i++) {
        for (var j = 0; j < series.length; j++) {
          final value = data[i].valores[series[j]] ?? 0;
          final height = plot.height * value / maxValue;
          final gap = barWidth > 8 ? 2.0 : 1.0;
          final rect = Rect.fromLTWH(
            plot.left + step * i + (step - groupWidth) / 2 + barWidth * j,
            plot.bottom - height,
            math.max(1, barWidth - gap),
            height,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            Paint()..color = colors[series[j]]!,
          );
        }
      }
    } else {
      for (final name in series) {
        final points = <Offset>[];
        for (var i = 0; i < count; i++) {
          final value = data[i].valores[name] ?? 0;
          points.add(
            Offset(
              plot.left + step * (i + .5),
              plot.bottom - plot.height * value / maxValue,
            ),
          );
        }
        final line = Paint()
          ..color = colors[name]!
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final path = Path();
        for (var i = 0; i < points.length; i++) {
          if (i == 0) {
            path.moveTo(points[i].dx, points[i].dy);
          } else {
            path.lineTo(points[i].dx, points[i].dy);
          }
        }
        canvas.drawPath(path, line);
        for (final point in points) {
          canvas.drawCircle(point, 3, Paint()..color = colors[name]!);
        }
      }
    }
    final labelStride = (count / 7).ceil().clamp(1, count);
    for (var i = 0; i < count; i += labelStride) {
      _drawText(
        canvas,
        data[i].rotulo,
        Offset(plot.left + step * (i + .5) - 13, plot.bottom + 6),
        labelStyle,
        textDirection,
      );
    }
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset at,
    TextStyle style,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _SerieChartPainter old) =>
      old.data != data ||
      old.series != series ||
      old.colors != colors ||
      old.bars != bars;
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
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width >= 900 ? 20 : 16,
      ),
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
          Text(
            alunos ? 'Aluno' : 'Professor',
            style: Theme.of(context).textTheme.labelMedium,
          ),
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
            child: Text(pessoa.ativo ? 'Bloquear acesso' : 'Reativar acesso'),
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
        status == 'Ativo' ||
        status == 'Na equipe' ||
        status == 'Registrada' ||
        status == 'Concluída';
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
