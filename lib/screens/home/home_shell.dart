import 'package:flutter/material.dart';

import '../agendamentos/agendamentos_screen.dart';
import '../evolucao/evolucao_screen.dart';
import '../exercicios/exercicios_screen.dart';
import '../home/home_screen.dart';
import '../perfil/perfil_screen.dart';
import '../treinos/treinos_screen.dart';
import '../../services/usuario_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  bool get professor =>
      UsuarioService.usuarioLogado?.ehProfessor == true ||
      UsuarioService.usuarioLogado?.ehAdmin == true;
  List<Widget> get pages => professor
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
  List<NavigationDestination> get destinations => professor
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
  Widget build(BuildContext context) => Scaffold(
    body: pages[index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: destinations,
    ),
  );
}
