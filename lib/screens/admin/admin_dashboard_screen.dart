import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/database_events.dart';
import '../../theme/app_theme.dart';
import 'admin_access_guard.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminService();
  AdminGranularidade _granularidade = AdminGranularidade.mes;
  DateTime _referencia = DateTime.now();
  late Future<AdminMetricas> _dados;

  AdminPeriodo get _periodo =>
      AdminPeriodo.calcular(_granularidade, _referencia);

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_atualizar);
    _dados = _service.carregarMetricas(_periodo);
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (!mounted) return;
    setState(() => _dados = _service.carregarMetricas(_periodo));
  }

  Future<void> _escolherReferencia() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _referencia,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _referencia = escolhida;
      _dados = _service.carregarMetricas(_periodo);
    });
  }

  void _selecionarGranularidade(AdminGranularidade? valor) {
    if (valor == null) return;
    setState(() {
      _granularidade = valor;
      _dados = _service.carregarMetricas(_periodo);
    });
  }

  String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _rotuloPeriodo(AdminPeriodo periodo) {
    final fim = periodo.fim.subtract(const Duration(days: 1));
    return switch (periodo.granularidade) {
      AdminGranularidade.ano => '${periodo.inicio.year}',
      AdminGranularidade.mes =>
        '${periodo.inicio.month.toString().padLeft(2, '0')}/${periodo.inicio.year}',
      AdminGranularidade.semana => '${_data(periodo.inicio)} – ${_data(fim)}',
      AdminGranularidade.dia => _data(periodo.inicio),
    };
  }

  @override
  Widget build(BuildContext context) => AdminAccessGuard(
    child: SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _atualizar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text(
              'Painel administrativo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Indicadores reais da academia',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Período de análise',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<AdminGranularidade>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AdminGranularidade.ano,
                          label: Text('Ano'),
                        ),
                        ButtonSegment(
                          value: AdminGranularidade.mes,
                          label: Text('Mês'),
                        ),
                        ButtonSegment(
                          value: AdminGranularidade.semana,
                          label: Text('Semana'),
                        ),
                        ButtonSegment(
                          value: AdminGranularidade.dia,
                          label: Text('Dia'),
                        ),
                      ],
                      selected: {_granularidade},
                      onSelectionChanged: (valores) =>
                          _selecionarGranularidade(valores.first),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _escolherReferencia,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text('Referência: ${_data(_referencia)}'),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Exibindo ${_rotuloPeriodo(_periodo)} e comparando com o período anterior.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<AdminMetricas>(
              future: _dados,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Não foi possível carregar os indicadores: ${snapshot.error}',
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(36),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final dados = snapshot.data!;
                return Column(
                  children: [
                    _cartaoMetrica(
                      titulo: 'Treinos criados',
                      atual: dados.treinos,
                      anterior: dados.treinosAnteriores,
                      icone: Icons.fitness_center,
                      cor: AppTheme.primaria,
                    ),
                    const SizedBox(height: 12),
                    _cartaoMetrica(
                      titulo: 'Alunos cadastrados',
                      atual: dados.alunos,
                      anterior: dados.alunosAnteriores,
                      icone: Icons.groups_2_outlined,
                      cor: AppTheme.apoio,
                    ),
                    const SizedBox(height: 12),
                    _cartaoMetrica(
                      titulo: 'Avaliações realizadas',
                      atual: dados.avaliacoes,
                      anterior: dados.avaliacoesAnteriores,
                      icone: Icons.monitor_heart_outlined,
                      cor: AppTheme.acao,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Registros anteriores à atualização do banco foram considerados a partir da data da migração, pois o app ainda não armazenava a data de criação.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _cartaoMetrica({
    required String titulo,
    required int atual,
    required int anterior,
    required IconData icone,
    required Color cor,
  }) {
    final diferenca = atual - anterior;
    final textoComparacao = anterior == 0
        ? (atual == 0
              ? 'Sem registros no período anterior'
              : 'Novo neste período')
        : '${diferenca > 0 ? '+' : ''}$diferenca em relação ao período anterior';
    final corComparacao = diferenca >= 0 ? AppTheme.sucesso : AppTheme.aviso;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icone, color: cor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    textoComparacao,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: corComparacao),
                  ),
                ],
              ),
            ),
            Text(
              '$atual',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}
