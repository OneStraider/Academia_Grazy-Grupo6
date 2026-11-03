import 'package:flutter/material.dart';

import '../../services/agendamento_service.dart';
import '../../services/database_events.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'agendamento_detalhes_screen.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});
  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  final _service = AgendamentoService();
  late Future<List<Map<String, Object?>>> _dados;
  late DateTime _diaSelecionado;
  late final List<DateTime> _dias;

  bool get _ehProfessor =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    final hoje = DateUtils.dateOnly(DateTime.now());
    _dias = List.generate(7, (i) => hoje.add(Duration(days: i)));
    _diaSelecionado = _dias.first;
    _carregar();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (mounted) _atualizar();
  }

  void _carregar() {
    _dados = _service.listarHorarios(alunoId: UsuarioService.usuarioLogado?.id);
  }

  Future<void> _atualizar() async {
    setState(_carregar);
  }

  Future<void> _criarHorario() async {
    final configuracao = await _mostrarFormularioHorario();
    if (configuracao == null || !mounted) return;
    final inicio = configuracao['inicio'] as DateTime;
    try {
      await _service.criarHorario(
        professorId: UsuarioService.usuarioLogado!.id!,
        nomeAula: configuracao['nome'] as String,
        capacidade: configuracao['vagas'] as int,
        minParticipantes: configuracao['minimo'] as int,
        inicio: inicio,
      );
      setState(() {
        final novoDia = DateUtils.dateOnly(inicio);
        if (!_dias.any((d) => DateUtils.isSameDay(d, novoDia)))
          _dias.add(novoDia);
        _diaSelecionado = novoDia;
        _carregar();
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _agendar(int horarioId) async {
    try {
      await _service.agendar(
        horarioId: horarioId,
        alunoId: UsuarioService.usuarioLogado!.id!,
      );
      await _atualizar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<Map<String, Object?>?> _mostrarFormularioHorario({
    Map<String, Object?>? horario,
  }) => showDialog<Map<String, Object?>>(
    context: context,
    builder: (_) => _FormularioHorario(horario: horario),
  );

  Future<void> _gerenciarHorario(Map<String, Object?> horario) async {
    final resultado = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GerenciarHorarioSheet(horario: horario),
    );
    if (!mounted || resultado == null) return;
    setState(() {
      if (resultado is DateTime) {
        final novoDia = DateUtils.dateOnly(resultado);
        if (!_dias.any((d) => DateUtils.isSameDay(d, novoDia)))
          _dias.add(novoDia);
        _diaSelecionado = novoDia;
      }
      _carregar();
    });
  }

  Future<void> _checkin(int id) async {
    try {
      await _service.checkin(id, alunoId: UsuarioService.usuarioLogado!.id!);
      await _atualizar();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-in confirmado.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _cancelar(int id) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: const Text('A vaga ficará disponível para outro aluno.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar aula'),
          ),
        ],
      ),
    );
    if (confirma != true) return;
    try {
      await _service.cancelar(id, alunoId: UsuarioService.usuarioLogado!.id!);
      await _atualizar();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _mes(DateTime d) => '${_nomeMes(d.month)} ${d.year}';
  String _nomeMes(int mes) => const [
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
  ][mes - 1];
  String _diaSemana(DateTime d) =>
      const ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'][d.weekday - 1];

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: _ehProfessor
        ? FloatingActionButton.extended(
            onPressed: _criarHorario,
            icon: const Icon(Icons.add),
            label: const Text('Novo horário'),
          )
        : null,
    body: SafeArea(
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Não foi possível carregar a agenda.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final todos = snapshot.data!;
          final doDia = todos
              .where(
                (h) => DateUtils.isSameDay(
                  DateTime.parse(h['inicio'] as String),
                  _diaSelecionado,
                ),
              )
              .toList();
          final marcados = doDia
              .where((h) => h['agendamento_id'] != null)
              .toList();
          final destaque = marcados.isEmpty ? null : marcados.last;
          final outrosAgendamentos = marcados.length < 2
              ? <Map<String, Object?>>[]
              : marcados.take(marcados.length - 1).toList();
          final horariosParaExibir = _ehProfessor
              ? doDia
              : doDia.where((h) => h['agendamento_id'] == null).toList();
          return RefreshIndicator(
            onRefresh: _atualizar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              children: [
                Text(
                  'Agenda',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _ehProfessor
                      ? 'Organize os horários das aulas'
                      : 'Encontre uma aula e reserve sua vaga',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _seletorDias(),
                const SizedBox(height: 22),
                if (!_ehProfessor && destaque != null) ...[
                  _cabecalho('Sua última reserva do dia'),
                  const SizedBox(height: 10),
                  _cardAgendado(destaque),
                  const SizedBox(height: 18),
                ],
                _cabecalho(
                  _ehProfessor ? 'Aulas do dia' : 'Horários disponíveis',
                ),
                const SizedBox(height: 10),
                if (horariosParaExibir.isEmpty)
                  _vazio(temReserva: marcados.isNotEmpty)
                else
                  for (final horario in horariosParaExibir)
                    _cardHorario(horario),
                if (!_ehProfessor) ...[
                  const SizedBox(height: 12),
                  _cabecalho(
                    destaque == null
                        ? 'Suas aulas neste dia'
                        : 'Outras aulas agendadas',
                  ),
                  const SizedBox(height: 10),
                  if (marcados.isEmpty)
                    _vazioAgendamentos()
                  else
                    for (final aula in outrosAgendamentos)
                      _cardAgendadoCompacto(aula),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _seletorDias() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _mes(_diaSelecionado),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _dias.length,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final dia = _dias[index];
            final selecionado = DateUtils.isSameDay(dia, _diaSelecionado);
            final esquema = Theme.of(context).colorScheme;
            final escuro = Theme.of(context).brightness == Brightness.dark;
            final corSelecionada = escuro
                ? esquema.primaryContainer
                : AppTheme.primaria;
            final textoSelecionado = escuro
                ? esquema.onPrimaryContainer
                : Colors.white;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _diaSelecionado = dia),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                decoration: BoxDecoration(
                  color: selecionado
                      ? corSelecionada
                      : esquema.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selecionado
                        ? corSelecionada
                        : esquema.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _diaSemana(dia),
                      style: TextStyle(
                        color: selecionado
                            ? textoSelecionado.withValues(alpha: .78)
                            : esquema.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${dia.day}',
                      style: TextStyle(
                        color: selecionado
                            ? textoSelecionado
                            : esquema.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _cabecalho(String titulo, {String? acao}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(titulo, style: Theme.of(context).textTheme.titleMedium),
      if (acao != null)
        Text(
          acao,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
    ],
  );

  Widget _cardAgendado(Map<String, Object?> aula) {
    final inicio = DateTime.parse(aula['inicio'] as String);
    final id = aula['agendamento_id'] as int;
    final status = aula['agendamento_status'] as String? ?? 'AGENDADO';
    final checkinDisponivel =
        inicio.difference(DateTime.now()) <= const Duration(minutes: 30) &&
        inicio.isAfter(DateTime.now());
    return Card(
      color: AppTheme.primaria,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Aula reservada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _badge(
                  status == 'CHECK_IN' ? 'Check-in feito' : 'Confirmada',
                  claro: true,
                ),
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
              '${_diaSemana(inicio).toUpperCase()}, ${inicio.day} de ${_nomeMes(inicio.month)}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Professor(a) ${aula['professor_nome']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            if (status != 'CHECK_IN')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: checkinDisponivel ? () => _checkin(id) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaria,
                  ),
                  child: Text(
                    checkinDisponivel
                        ? 'Fazer check-in'
                        : 'Check-in libera 30 min antes',
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AgendamentoDetalhesScreen(agendamentoId: id),
                        ),
                      );
                      if (mounted) await _atualizar();
                    },
                    child: const Text(
                      'Ver detalhes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _cancelar(id),
                    child: const Text(
                      'Cancelar aula',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAgendadoCompacto(Map<String, Object?> aula) {
    final esquema = Theme.of(context).colorScheme;
    final inicio = DateTime.parse(aula['inicio'] as String);
    final id = aula['agendamento_id'] as int;
    final hora =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: esquema.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_available_outlined,
                color: esquema.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aula['nome_aula'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hora,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _verDetalhes(id),
              child: const Text('Detalhes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verDetalhes(int agendamentoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgendamentoDetalhesScreen(agendamentoId: agendamentoId),
      ),
    );
    if (mounted) await _atualizar();
  }

  Widget _cardHorario(Map<String, Object?> horario) {
    final inicio = DateTime.parse(horario['inicio'] as String);
    final capacidade = horario['capacidade'] as int;
    final minimo = horario['min_participantes'] as int? ?? 1;
    final ocupadas = horario['ocupadas'] as int;
    final vagas = capacidade - ocupadas;
    final reservado = horario['agendamento_id'] != null;
    final cheio = vagas <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _ehProfessor ? () => _gerenciarHorario(horario) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horario['nome_aula'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')} · Professor(a) ${horario['professor_nome']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _badge(
                          reservado
                              ? 'Sua reserva'
                              : cheio
                              ? 'Lotado'
                              : '$vagas vagas',
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _ehProfessor
                              ? '$ocupadas inscritos · mínimo $minimo'
                              : '$ocupadas/$capacidade alunos',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_ehProfessor && !reservado)
                FilledButton.tonal(
                  onPressed: cheio
                      ? null
                      : () => _agendar(horario['id'] as int),
                  child: Text(cheio ? 'Lotado' : 'Agendar'),
                )
              else if (_ehProfessor)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, {bool claro = false}) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: claro
            ? Colors.white.withValues(alpha: .18)
            : esquema.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: claro ? Colors.white : esquema.onPrimaryContainer,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _vazio({bool temReserva = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.event_busy,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          temReserva
              ? 'Nenhum outro horário disponível neste dia'
              : 'Nenhum horário neste dia',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          temReserva
              ? 'Suas aulas agendadas aparecem na lista abaixo.'
              : _ehProfessor
              ? 'Adicione um horário para abrir vagas.'
              : 'Escolha outra data para ver as aulas.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _vazioAgendamentos() => Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text(
      'Você ainda não tem aulas agendadas para este dia.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _FormularioHorario extends StatefulWidget {
  final Map<String, Object?>? horario;
  const _FormularioHorario({this.horario});

  @override
  State<_FormularioHorario> createState() => _FormularioHorarioState();
}

class _FormularioHorarioState extends State<_FormularioHorario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _vagas;
  late final TextEditingController _minimo;
  late DateTime _data;
  late TimeOfDay _hora;

  bool get _editando => widget.horario != null;

  @override
  void initState() {
    super.initState();
    final horario = widget.horario;
    final agora = DateTime.now();
    final horarioSugerido = agora.add(const Duration(hours: 1, minutes: 10));
    final inicio = horario == null
        ? DateTime(
            agora.year,
            agora.month,
            agora.day,
            horarioSugerido.day == agora.day ? horarioSugerido.hour : 23,
            horarioSugerido.day == agora.day ? horarioSugerido.minute : 59,
          )
        : DateTime.parse(horario['inicio'] as String);
    _nome = TextEditingController(text: horario?['nome_aula'] as String? ?? '');
    _vagas = TextEditingController(text: '${horario?['capacidade'] ?? 8}');
    _minimo = TextEditingController(
      text: '${horario?['min_participantes'] ?? 1}',
    );
    _data = DateUtils.dateOnly(inicio);
    _hora = TimeOfDay.fromDateTime(inicio);
  }

  @override
  void dispose() {
    _nome.dispose();
    _vagas.dispose();
    _minimo.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final primeiroDia = hoje;
    final data = await showDatePicker(
      context: context,
      initialDate: _data.isBefore(primeiroDia) ? primeiroDia : _data,
      firstDate: primeiroDia,
      lastDate: DateTime(hoje.year + 2),
    );
    if (data != null && mounted)
      setState(() => _data = DateUtils.dateOnly(data));
  }

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null && mounted) setState(() => _hora = hora);
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, Object?>{
      'nome': _nome.text.trim(),
      'vagas': int.parse(_vagas.text),
      'minimo': int.parse(_minimo.text),
      'inicio': DateTime(
        _data.year,
        _data.month,
        _data.day,
        _hora.hour,
        _hora.minute,
      ),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(_editando ? 'Editar aula' : 'Nova aula'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(
              labelText: 'Nome da aula',
              hintText: 'Ex.: Luta boxe',
              prefixIcon: Icon(Icons.fitness_center),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome da aula' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vagas,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade de vagas',
              prefixIcon: Icon(Icons.people_outline),
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 ? 'Informe pelo menos 1 vaga' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _minimo,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mínimo de participantes',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            validator: (v) {
              final minimo = int.tryParse(v ?? '');
              final capacidade = int.tryParse(_vagas.text);
              if (minimo == null || minimo < 1)
                return 'Informe pelo menos 1 participante';
              if (capacidade != null && minimo > capacidade)
                return 'O mínimo não pode superar as vagas';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherData,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _escolherHora,
                icon: const Icon(Icons.access_time),
                label: Text(_hora.format(context)),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _salvar,
        child: Text(_editando ? 'Salvar alterações' : 'Criar aula'),
      ),
    ],
  );
}

class _GerenciarHorarioSheet extends StatefulWidget {
  final Map<String, Object?> horario;
  const _GerenciarHorarioSheet({required this.horario});

  @override
  State<_GerenciarHorarioSheet> createState() => _GerenciarHorarioSheetState();
}

class _GerenciarHorarioSheetState extends State<_GerenciarHorarioSheet> {
  final _service = AgendamentoService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _vagas;
  late final TextEditingController _minimo;
  late DateTime _data;
  late TimeOfDay _hora;
  late Future<List<Map<String, Object?>>> _participantes;
  bool _editando = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_atualizarParticipantes);
    _nome = TextEditingController(text: widget.horario['nome_aula'] as String);
    _vagas = TextEditingController(text: '${widget.horario['capacidade']}');
    _minimo = TextEditingController(
      text: '${widget.horario['min_participantes'] ?? 1}',
    );
    final inicio = DateTime.parse(widget.horario['inicio'] as String);
    _data = DateUtils.dateOnly(inicio);
    _hora = TimeOfDay.fromDateTime(inicio);
    _participantes = _service.listarParticipantes(widget.horario['id'] as int);
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_atualizarParticipantes);
    _nome.dispose();
    _vagas.dispose();
    _minimo.dispose();
    super.dispose();
  }

  void _atualizarParticipantes() {
    if (!mounted) return;
    setState(() {
      _participantes = _service.listarParticipantes(
        widget.horario['id'] as int,
      );
    });
  }

  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data.isBefore(hoje) ? hoje : _data,
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (selecionada != null && mounted)
      setState(() => _data = DateUtils.dateOnly(selecionada));
  }

  Future<void> _escolherHora() async {
    final selecionada = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (selecionada != null && mounted) setState(() => _hora = selecionada);
  }

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;
    final inicio = DateTime(
      _data.year,
      _data.month,
      _data.day,
      _hora.hour,
      _hora.minute,
    );
    setState(() => _salvando = true);
    try {
      await _service.editarHorario(
        horarioId: widget.horario['id'] as int,
        nomeAula: _nome.text.trim(),
        capacidade: int.parse(_vagas.text),
        minParticipantes: int.parse(_minimo.text),
        inicio: inicio,
      );
      if (mounted) Navigator.pop(context, inicio);
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir aula?'),
        content: const Text(
          'A aula será removida da agenda e as inscrições vinculadas serão canceladas junto com ela.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir aula'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await _service.excluirHorario(widget.horario['id'] as int);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * .88;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editando ? 'Editar aula' : 'Participantes da aula',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _editando ? _formularioEdicao() : _detalhes(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalhes() => FutureBuilder<List<Map<String, Object?>>>(
    future: _participantes,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Não foi possível carregar os inscritos: ${snapshot.error}',
          ),
        );
      if (!snapshot.hasData)
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      final participantes = snapshot.data!;
      final minimo = widget.horario['min_participantes'] as int? ?? 1;
      final capacidade = widget.horario['capacidade'] as int;
      final atingiuMinimo = participantes.length >= minimo;
      final esquema = Theme.of(context).colorScheme;
      final inicio = DateTime.parse(widget.horario['inicio'] as String);
      final progresso = (participantes.length / minimo).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.horario['nome_aula'] as String,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatarData(inicio)} · ${_horaTexto(inicio)} · ${widget.horario['professor_nome']}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: atingiuMinimo
                  ? esquema.primaryContainer
                  : esquema.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atingiuMinimo
                      ? 'Mínimo atingido'
                      : 'Aula ainda não confirmada',
                  style: TextStyle(
                    color: atingiuMinimo
                        ? esquema.onPrimaryContainer
                        : esquema.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${participantes.length} de $minimo participantes mínimos · limite de $capacidade vagas',
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progresso,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: atingiuMinimo ? esquema.primary : esquema.tertiary,
                ),
                if (!atingiuMinimo) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Faltam ${minimo - participantes.length} para a aula acontecer.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Alunos inscritos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              _contador('${participantes.length}/$capacidade'),
            ],
          ),
          const SizedBox(height: 8),
          if (participantes.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Nenhum aluno se inscreveu ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < participantes.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 66),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Text(
                          (participantes[i]['aluno_nome'] as String)
                              .characters
                              .first
                              .toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        participantes[i]['aluno_nome'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(participantes[i]['aluno_email'] as String),
                      trailing: Text(
                        participantes[i]['status'] == 'CHECK_IN'
                            ? 'Check-in'
                            : 'Inscrito',
                        style: TextStyle(
                          color: participantes[i]['status'] == 'CHECK_IN'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editando = true),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _excluir,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error
                          .withValues(alpha: .4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _formularioEdicao() {
    final capacidadeInicial = widget.horario['capacidade'] as int;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome da aula'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vagas,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Vagas máximas'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1
                  ? 'Informe uma quantidade válida'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _minimo,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mínimo de participantes',
            ),
            validator: (v) {
              final min = int.tryParse(v ?? '');
              final vagas = int.tryParse(_vagas.text) ?? capacidadeInicial;
              return min == null || min < 1 || min > vagas
                  ? 'O mínimo deve ficar entre 1 e as vagas'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _escolherData,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_dataTexto(_data)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _escolherHora,
                icon: const Icon(Icons.access_time),
                label: Text(_hora.format(context)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _salvando
                      ? null
                      : () => setState(() => _editando = false),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _salvando ? null : _salvarEdicao,
                  child: const Text('Salvar alterações'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contador(String valor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      valor,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );
  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _horaTexto(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _dataTexto(DateTime d) => _formatarData(d);
}
