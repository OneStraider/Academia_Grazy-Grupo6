import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_theme.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _usuarios = UsuarioService();
  bool _mostrarSenha = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _usuarios.cadastrar(
        Usuario(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          senhaHash: '',
          tipo: 'ALUNO',
        ),
        _senha.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) _mostrarMensagem('$erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              Text(
                'Faça seu cadastro',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Preencha seus dados para criar uma conta de aluno. A equipe da academia define os acessos de professor e administrador.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nome,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (valor) => (valor?.trim().length ?? 0) < 3
                              ? 'Informe seu nome completo.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (valor) {
                            final email = valor?.trim() ?? '';
                            return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(email)
                                ? null
                                : 'Informe um e-mail válido.';
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _senha,
                          obscureText: !_mostrarSenha,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Senha (mínimo 8 caracteres)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _mostrarSenha = !_mostrarSenha,
                              ),
                              tooltip: _mostrarSenha
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              icon: Icon(
                                _mostrarSenha
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (valor) => (valor?.length ?? 0) < 8
                              ? 'Use pelo menos 8 caracteres.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmacao,
                          obscureText: !_mostrarSenha,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _cadastrar(),
                          decoration: const InputDecoration(
                            labelText: 'Confirme a senha',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (valor) => valor != _senha.text
                              ? 'As senhas não coincidem.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _carregando ? null : _cadastrar,
                          child: _carregando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Criar conta'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seu cadastro será salvo neste dispositivo. A sincronização entre aparelhos depende da integração com o servidor.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
