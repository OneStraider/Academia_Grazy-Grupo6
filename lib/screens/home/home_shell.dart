import 'package:flutter/material.dart';

import '../perfil/perfil_screen.dart';
import '../treinos/treinos_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  Widget _tela() {
    switch (_indice) {
      case 1:
        return const TreinosScreen();
      case 2:
        return const Center(child: Text('Agenda (em breve)'));
      case 3:
        return const PerfilScreen();
      default:
        return const Center(child: Text('Academia Grazy'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tela(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center), label: 'Treinos'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined), label: 'Agenda'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
