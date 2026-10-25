import 'package:flutter/material.dart';

import '../../services/agendamento_service.dart';
import '../../theme/app_theme.dart';

class AgendamentoDetalhesScreen extends StatefulWidget {
  final int agendamentoId;
  const AgendamentoDetalhesScreen({super.key, required this.agendamentoId});
  @override
  State<AgendamentoDetalhesScreen> createState() =>
      _AgendamentoDetalhesScreenState();
}

class _AgendamentoDetalhesScreenState extends State<AgendamentoDetalhesScreen> {
  final _service = AgendamentoService();
  late Future<Map<String, Object?>?> _aula;

  @override
  void initState() {
    super.initState();
    _aula = _service.buscarAgendamento(widget.agendamentoId);
  }

  Future<void> _acao(Future<void> Function() executar, String sucesso) async {
    try {
      await executar();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(sucesso)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes do agendamento')),
    body: FutureBuilder<Map<String, Object?>?>(
      future: _aula,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Não foi possível carregar os detalhes.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final aula = snapshot.data;
        if (aula == null)
          return const Center(child: Text('Agendamento não encontrado.'));
        final inicio = DateTime.parse(aula['inicio'] as String);
        final status = aula['status'] as String;
        final checkinDisponivel =
            inicio.difference(DateTime.now()) <= const Duration(minutes: 30) &&
            inicio.isAfter(DateTime.now());
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaria,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available, color: Colors.white),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          'Aula agendada',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _status(status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    aula['nome_aula'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dataLonga(inicio),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Informações da aula',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _linha(
                    Icons.school_outlined,
                    'Professor',
                    aula['professor_nome'] as String,
                  ),
                  const Divider(height: 1, indent: 58),
                  _linha(
                    Icons.person_outline,
                    'Aluno',
                    aula['aluno_nome'] as String,
                  ),
                  const Divider(height: 1, indent: 58),
                  _linha(
                    Icons.people_outline,
                    'Capacidade',
                    '${aula['capacidade']} alunos',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (status != 'CHECK_IN')
              FilledButton.icon(
                onPressed: checkinDisponivel
                    ? () => _acao(
                        () => _service.checkin(widget.agendamentoId),
                        'Check-in confirmado.',
                      )
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  checkinDisponivel
                      ? 'Fazer check-in'
                      : 'Check-in liberado 30 min antes',
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.sucesso),
                    SizedBox(width: 10),
                    Text(
                      'Check-in realizado',
                      style: TextStyle(
                        color: AppTheme.sucesso,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _acao(
                () => _service.cancelar(widget.agendamentoId),
                'Agendamento cancelado.',
              ),
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Cancelar agendamento'),
            ),
          ],
        );
      },
    ),
  );

  Widget _linha(IconData icon, String titulo, String valor) => ListTile(
    leading: Icon(icon, color: AppTheme.primaria),
    title: Text(titulo, style: Theme.of(context).textTheme.bodySmall),
    subtitle: Text(valor, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _status(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status == 'CHECK_IN' ? 'Check-in feito' : 'Confirmada',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  String _dataLonga(DateTime date) {
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
    return '${dias[date.weekday - 1]}, ${date.day} de ${meses[date.month - 1]} de ${date.year}';
  }
}
