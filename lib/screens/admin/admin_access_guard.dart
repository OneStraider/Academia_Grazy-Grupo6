import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/usuario_service.dart';

class AdminAccessGuard extends StatelessWidget {
  final Widget child;

  const AdminAccessGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AdminPermissoes.podeAcessar(UsuarioService.usuarioLogado)) return child;
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso restrito')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Este painel é exclusivo para administradores autenticados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
