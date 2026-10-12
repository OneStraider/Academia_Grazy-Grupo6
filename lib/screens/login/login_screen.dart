import 'package:flutter/material.dart';

import '../../services/usuario_service.dart';
import '../home/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _usuarioService = UsuarioService();

  bool _mostrarSenha = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final usuario = await _usuarioService.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;

      if (usuario == null) {
        _mostrarErro('E-mail ou senha inválidos.');
        return;
      }

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (_) {
      if (mounted) {
        _mostrarErro('Não foi possível realizar o login.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.fitness_center, size: 52),
                    const SizedBox(height: 20),
                    Text(
                      'Academia Grazy',
                      textAlign: TextAlign.center,
                      style: tema.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entre para acessar seus treinos',
                      textAlign: TextAlign.center,
                      style: tema.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (valor) {
                        final email = valor?.trim() ?? '';
                        if (email.isEmpty) return 'Informe seu e-mail';
                        if (!email.contains('@')) return 'Informe um e-mail válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_mostrarSenha,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                          onPressed: () => setState(
                            () => _mostrarSenha = !_mostrarSenha,
                          ),
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (valor) => (valor?.isEmpty ?? true)
                          ? 'Informe sua senha'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
