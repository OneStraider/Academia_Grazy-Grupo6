import 'package:flutter/material.dart';

import '../../models/treino.dart';
import '../../services/treino_services.dart';
import '../../services/database_events.dart';
import '../../services/preferencias_app_service.dart';
import '../../services/usuario_service.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../evolucao/evolucao_screen.dart';
import '../exercicios/exercicios_screen.dart';
import '../login/login_screen.dart';
import '../treinos/treinos_screen.dart';
import '../treinos/detalhes_treino_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? _professorResponsavel;
  Treino? _meuTreino;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_onDatabaseChanged);
    _carregarProfessor();
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_onDatabaseChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    if (mounted) _carregarProfessor();
  }

  Future<void> _carregarProfessor() async {
    final usuario = UsuarioService.usuarioLogado;
    if (usuario == null || !usuario.ehAluno) return;
    final treinos = await TreinoService().listarPorAluno(usuario.id!);
    if (!mounted) return;
    final hoje = DateUtils.dateOnly(DateTime.now());
    final treino = treinos
        .where(
          (t) =>
              t.status == 'ATIVO' &&
              !DateUtils.dateOnly(t.validade).isBefore(hoje),
        )
        .firstOrNull;
    if (treino == null) {
      if (mounted) {
        setState(() {
          _meuTreino = null;
          _professorResponsavel = null;
        });
      }
      return;
    }
    final professor = await UsuarioService().buscarPorId(treino.professorId);
    if (mounted) {
      setState(() {
        _meuTreino = treino;
        _professorResponsavel = professor?.nome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioService.usuarioLogado;
    final cores = Theme.of(context).colorScheme;
    final nome = usuario?.nome ?? 'Sessão encerrada';
    final tipo = usuario?.ehProfessor == true
        ? 'Professor'
        : usuario?.ehAdmin == true
        ? 'Administrador'
        : 'Aluno';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Text('Perfil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 26),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: cores.primaryContainer,
                  child: Text(
                    nome.isEmpty ? '?' : nome[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ).copyWith(color: cores.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 12),
                Text(nome, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cores.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tipo,
                    style: TextStyle(
                      color: cores.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Dados da conta', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _linhaConta('Nome', nome),
                const Divider(height: 1),
                _linhaConta('Email', usuario?.email ?? '—'),
                const Divider(height: 1),
                _linhaConta('Perfil', tipo),
                if (usuario?.ehAluno == true) ...[
                  const Divider(height: 1),
                  _linhaConta(
                    'Professor responsável',
                    _professorResponsavel ?? 'A definir',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: PreferenciasAppService.modoEscuro,
              builder: (context, modoEscuro, _) => SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Modo escuro'),
                subtitle: const Text('Tema confortável para ambientes escuros'),
                value: modoEscuro,
                onChanged: PreferenciasAppService.definirModoEscuro,
              ),
            ),
          ),
          if (usuario?.ehAdmin != true) ...[
            const SizedBox(height: 22),
            Text('Atalhos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Card(child: Column(children: _atalhos(usuario?.ehAluno == true))),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _sair,
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              foregroundColor: cores.error,
              side: BorderSide(color: cores.error.withValues(alpha: .35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaConta(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    child: Row(
      children: [
        Expanded(
          child: Text(rotulo, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  List<Widget> _atalhos(bool aluno) {
    final itens = aluno
        ? [
            ('Meu treino', Icons.fitness_center, () => _abrirMeuTreino()),
            (
              'Minha evolução',
              Icons.monitor_heart_outlined,
              () => _navegar(const EvolucaoScreen()),
            ),
            (
              'Meus agendamentos',
              Icons.calendar_month_outlined,
              () => _navegar(const AgendamentosScreen()),
            ),
          ]
        : [
            (
              'Exercícios',
              Icons.tune,
              () => _navegar(const ExerciciosScreen()),
            ),
            (
              'Treinos dos alunos',
              Icons.fitness_center,
              () => _navegar(const TreinosScreen()),
            ),
            (
              'Agenda de aulas',
              Icons.calendar_month_outlined,
              () => _navegar(const AgendamentosScreen()),
            ),
          ];
    return [
      for (var i = 0; i < itens.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 74),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              itens[i].$2,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            itens[i].$1,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: itens[i].$3,
        ),
      ],
    ];
  }

  Future<void> _abrirMeuTreino() async {
    if (_meuTreino != null) {
      await _navegar(DetalhesTreinoScreen(treino: _meuTreino!));
    } else {
      await _navegar(const TreinosScreen());
    }
  }

  Future<void> _navegar(Widget tela) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  void _sair() {
    UsuarioService().sair();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
