import 'package:flutter/material.dart';

import '../agendamentos/agendamentos_screen.dart';
import '../evolucao/evolucao_screen.dart';
import '../exercicios/exercicios_screen.dart';
import '../home/home_screen.dart';
import '../perfil/perfil_screen.dart';
import '../treinos/treinos_screen.dart';
import '../../services/usuario_service.dart';
import '../../services/database_events.dart';
import '../../services/admin_service.dart';
import '../admin/admin_prototype_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DatabaseEvents.changed();
    }
  }

  void _selecionarAba(int novoIndice) {
    if (novoIndice == index) {
      DatabaseEvents.changed();
      return;
    }
    _pageController.animateToPage(
      novoIndice,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
    );
  }

  void _paginaAlterada(int novoIndice) {
    if (novoIndice == index) return;
    setState(() => index = novoIndice);
  }

  bool get professor =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;
  bool get administrador =>
      AdminPermissoes.podeAcessar(UsuarioService.usuarioLogado);
  List<Widget> get pages => administrador
      ? const [AdminPrototypeScreen()]
      : professor
      ? const [
          HomeScreen(),
          ExerciciosScreen(),
          TreinosScreen(),
          AgendamentosScreen(),
          PerfilScreen(),
        ]
      : const [
          HomeScreen(),
          TreinosScreen(),
          AgendamentosScreen(),
          EvolucaoScreen(),
          PerfilScreen(),
        ];
  List<NavigationDestination> get destinations => administrador
      ? const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Pessoas',
          ),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Treinos'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ]
      : professor
      ? const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Exercícios',
          ),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Treinos'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ]
      : const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Treinos'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Evolução',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ];
  @override
  Widget build(BuildContext context) {
    if (administrador) return const AdminPrototypeScreen();
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _paginaAlterada,
        physics: const PageScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _selecionarAba,
        destinations: destinations,
      ),
    );
  }
}
