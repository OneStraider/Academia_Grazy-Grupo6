import 'package:flutter/material.dart';

import '../../brand/grazi_logo.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';
import '../home/home_shell.dart';

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
        _emailController.text,
        _senhaController.text,
      );

      if (!mounted) return;

      if (usuario == null) {
        _mostrarMensagem('E-mail ou senha inválidos.');
        return;
      }

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ContaInativaException catch (erro) {
      if (mounted) _mostrarMensagem(erro.mensagem);
    } catch (_) {
      if (mounted) {
        _mostrarMensagem('Não foi possível realizar o login.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirCadastro() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
    if (!mounted || criado != true) return;
    _mostrarMensagem('Conta criada. Entre com seu e-mail e sua senha.');
  }

  Future<void> _recuperarSenha() async {
    final alterada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecuperarSenhaScreen(emailInicial: _emailController.text.trim()),
      ),
    );
    if (!mounted || alterada != true) return;
    _senhaController.clear();
    _mostrarMensagem('Senha atualizada. Entre com sua nova senha.');
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/brand/grazi_gradient.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          ColoredBox(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xAA08110F)
                : const Color(0x12001918),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final alturaMinima = constraints.maxHeight > 36
                    ? constraints.maxHeight - 36
                    : constraints.maxHeight;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: alturaMinima),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        const _MarcaGrazi(),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface
                                  .withValues(alpha: .97),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: .65),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .2),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: _formulario(context),
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
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acesse sua conta',
            style: tema.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Seus treinos e sua evolução começam aqui.',
            style: tema.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            textInputAction: TextInputAction.next,
            autocorrect: false,
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
          const SizedBox(height: 14),
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
                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                icon: Icon(
                  _mostrarSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (valor) =>
                (valor?.isEmpty ?? true) ? 'Informe sua senha' : null,
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 4),
          TextButton(
            onPressed: _carregando ? null : _recuperarSenha,
            child: const Text('Esqueci minha senha'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Ainda não tem conta?'),
              TextButton(
                onPressed: _carregando ? null : _abrirCadastro,
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarcaGrazi extends StatelessWidget {
  const _MarcaGrazi();

  @override
  Widget build(BuildContext context) {
    final sombra = [
      const Shadow(
        color: Color(0x66000000),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ];

    return Column(
      children: [
        const GraziSimbolo(size: 66, color: Colors.white),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'ACADEMIA GRAZI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.familiaFonte,
              fontSize: 42,
              height: 1.05,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              shadows: sombra,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'T R E I N O   P E R S O N A L I Z A D O',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTheme.familiaFonte,
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w500,
            shadows: sombra,
          ),
        ),
      ],
    );
  }
}
