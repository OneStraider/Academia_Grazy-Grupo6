import 'package:flutter/material.dart';

import '../../services/recuperacao_senha_service.dart';
import '../../services/usuario_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  final String emailInicial;

  const RecuperarSenhaScreen({super.key, this.emailInicial = ''});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  final _recuperacao = RecuperacaoSenhaService();
  final _usuarios = UsuarioService();
  bool _codigoEnviado = false;
  bool _mostrarSenha = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    _recuperacao.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _mensagem('Informe um e-mail válido.');
      return;
    }
    setState(() => _carregando = true);
    try {
      await _recuperacao.solicitarCodigo(_email.text);
      if (!mounted) return;
      setState(() => _codigoEnviado = true);
      _mensagem(
        'Se houver uma conta para esse e-mail, enviaremos um código de recuperação.',
      );
    } catch (erro) {
      if (mounted) _mensagem('$erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmarNovaSenha() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _recuperacao.confirmarCodigoENovaSenha(
        email: _email.text,
        codigo: _codigo.text,
        novaSenha: _senha.text,
      );
      await _usuarios.atualizarSenhaDepoisRecuperacao(_email.text, _senha.text);
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) _mensagem('$erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recuperar senha')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            shrinkWrap: true,
            children: [
              Text(
                _codigoEnviado
                    ? 'Confirme sua identidade'
                    : 'Vamos recuperar sua conta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _codigoEnviado
                    ? 'Digite o código enviado ao e-mail e escolha uma nova senha.'
                    : 'Informe o e-mail cadastrado. Enviaremos um código para você criar uma nova senha.',
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
                          controller: _email,
                          enabled: !_codigoEnviado,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
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
                        if (_codigoEnviado) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _codigo,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            maxLength: 8,
                            decoration: const InputDecoration(
                              labelText: 'Código recebido por e-mail',
                              prefixIcon: Icon(Icons.mark_email_read_outlined),
                            ),
                            validator: (valor) =>
                                (valor?.trim().length ?? 0) < 6
                                ? 'Informe o código recebido.'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senha,
                            obscureText: !_mostrarSenha,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Nova senha (mínimo 8 caracteres)',
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
                            onFieldSubmitted: (_) => _confirmarNovaSenha(),
                            decoration: const InputDecoration(
                              labelText: 'Confirme a nova senha',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                            ),
                            validator: (valor) => valor != _senha.text
                                ? 'As senhas não coincidem.'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _carregando
                              ? null
                              : _codigoEnviado
                              ? _confirmarNovaSenha
                              : _solicitarCodigo,
                          child: _carregando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _codigoEnviado
                                      ? 'Salvar nova senha'
                                      : 'Enviar código',
                                ),
                        ),
                        if (_codigoEnviado)
                          TextButton(
                            onPressed: _carregando ? null : _solicitarCodigo,
                            child: const Text('Enviar outro código'),
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
