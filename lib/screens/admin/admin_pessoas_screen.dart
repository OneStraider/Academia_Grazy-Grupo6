import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/admin_service.dart';
import '../../services/database_events.dart';
import '../../theme/app_theme.dart';
import 'admin_access_guard.dart';

class AdminPessoasScreen extends StatefulWidget {
  const AdminPessoasScreen({super.key});

  @override
  State<AdminPessoasScreen> createState() => _AdminPessoasScreenState();
}

class _AdminPessoasScreenState extends State<AdminPessoasScreen> {
  final _service = AdminService();
  final _busca = TextEditingController();
  String _tipo = 'ALUNO';
  late Future<List<Usuario>> _pessoas;

  @override
  void initState() {
    super.initState();
    DatabaseEvents.revision.addListener(_recarregarPorEvento);
    _pessoas = _service.listarPessoas(tipo: _tipo);
  }

  @override
  void dispose() {
    DatabaseEvents.revision.removeListener(_recarregarPorEvento);
    _busca.dispose();
    super.dispose();
  }

  void _recarregarPorEvento() {
    if (mounted) _recarregar();
  }

  void _recarregar() {
    setState(() {
      _pessoas = _service.listarPessoas(tipo: _tipo, busca: _busca.text);
    });
  }

  Future<void> _abrirFormulario({Usuario? pessoa}) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _PessoaFormDialog(service: _service, tipo: _tipo, pessoa: pessoa),
    );
    if (salvo == true && mounted) _recarregar();
  }

  Future<void> _mostrarDetalhes(Usuario pessoa) async {
    try {
      final detalhes = await _service.detalhes(pessoa.id!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detalhes.usuario.nome),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detalhes.usuario.email),
              const SizedBox(height: 8),
              Text(detalhes.usuario.ehAluno ? 'Aluno' : 'Professor'),
              const SizedBox(height: 8),
              Text(
                detalhes.usuario.ativo
                    ? (detalhes.usuario.ehAluno ? 'Status: Ativo' : 'Na equipe')
                    : (detalhes.usuario.ehAluno
                          ? 'Inativo · orientar a procurar a secretaria'
                          : 'Fora da equipe'),
              ),
              const Divider(height: 24),
              Text('Treinos relacionados: ${detalhes.treinos}'),
              if (detalhes.usuario.ehAluno)
                Text('Avaliações: ${detalhes.avaliacoes}'),
              if (detalhes.usuario.criadoEm != null)
                Text('Cadastro: ${_data(detalhes.usuario.criadoEm!)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(context);
                _abrirFormulario(pessoa: detalhes.usuario);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ],
        ),
      );
    } catch (erro) {
      _mostrarErro('$erro');
    }
  }

  Future<void> _alterarAtivo(Usuario pessoa) async {
    final ativoNovo = !pessoa.ativo;
    final acao = ativoNovo ? 'reativar' : 'desativar';
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${acao[0].toUpperCase()}${acao.substring(1)} conta?'),
        content: Text(
          ativoNovo
              ? 'A pessoa voltará a acessar o aplicativo.'
              : pessoa.ehAluno
              ? 'O acesso será bloqueado e o aluno receberá orientação para procurar a secretaria. O histórico será preservado.'
              : 'O acesso será bloqueado e o professor aparecerá como fora da equipe. O histórico será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ativoNovo ? 'Reativar' : 'Desativar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await _service.definirAtivo(pessoa.id!, ativoNovo);
      if (mounted) _recarregar();
    } catch (erro) {
      _mostrarErro('$erro');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _data(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  @override
  Widget build(BuildContext context) => AdminAccessGuard(
    child: Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(_tipo == 'ALUNO' ? 'Novo aluno' : 'Novo professor'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pessoas',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Cadastros e situação da equipe',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'ALUNO', label: Text('Alunos')),
                  ButtonSegment(value: 'PROFESSOR', label: Text('Professores')),
                ],
                selected: {_tipo},
                onSelectionChanged: (selecionados) {
                  setState(() {
                    _tipo = selecionados.first;
                    _pessoas = _service.listarPessoas(
                      tipo: _tipo,
                      busca: _busca.text,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busca,
                onChanged: (_) => _recarregar(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'Buscar por nome ou e-mail',
                  suffixIcon: _busca.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _busca.clear();
                            _recarregar();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Usuario>>(
                  future: _pessoas,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          _busca.text.isEmpty
                              ? 'Nenhum cadastro nesta lista.'
                              : 'Nenhuma pessoa encontrada.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 6, bottom: 96),
                      itemCount: snapshot.data!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pessoa = snapshot.data![index];
                        final status = !pessoa.ativo
                            ? (pessoa.ehAluno
                                  ? 'Inativo · procurar secretaria'
                                  : 'Fora da equipe')
                            : (pessoa.ehAluno ? 'Ativo' : 'Na equipe');
                        return Card(
                          child: ListTile(
                            onTap: () => _mostrarDetalhes(pessoa),
                            leading: CircleAvatar(
                              backgroundColor: pessoa.ativo
                                  ? AppTheme.primariaSuave
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                              child: Icon(
                                pessoa.ehAluno
                                    ? Icons.person_outline
                                    : Icons.sports_outlined,
                                color: pessoa.ativo
                                    ? AppTheme.primaria
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                              ),
                            ),
                            title: Text(pessoa.nome),
                            subtitle: Text('${pessoa.email}\n$status'),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (acao) {
                                if (acao == 'editar') {
                                  _abrirFormulario(pessoa: pessoa);
                                } else {
                                  _alterarAtivo(pessoa);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'editar',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'status',
                                  child: Text(
                                    pessoa.ativo
                                        ? 'Excluir / desativar'
                                        : 'Reativar',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PessoaFormDialog extends StatefulWidget {
  final AdminService service;
  final Usuario? pessoa;
  final String tipo;

  const _PessoaFormDialog({
    required this.service,
    required this.tipo,
    this.pessoa,
  });

  @override
  State<_PessoaFormDialog> createState() => _PessoaFormDialogState();
}

class _PessoaFormDialogState extends State<_PessoaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  final _senha = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.pessoa?.nome ?? '');
    _email = TextEditingController(text: widget.pessoa?.email ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await widget.service.salvarPessoa(
        id: widget.pessoa?.id,
        nome: _nome.text,
        email: _email.text,
        tipo: widget.pessoa?.tipo ?? widget.tipo,
        senha: _senha.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.pessoa != null;
    final tipo = widget.pessoa?.tipo ?? widget.tipo;
    return AlertDialog(
      title: Text(
        '${editando ? 'Editar' : 'Cadastrar'} ${tipo == 'ALUNO' ? 'aluno' : 'professor'}',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Informe o nome.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (valor) => valor == null || !valor.contains('@')
                    ? 'Informe um e-mail válido.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _senha,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: editando
                      ? 'Nova senha (opcional)'
                      : 'Senha inicial',
                ),
                validator: (valor) =>
                    !editando && (valor == null || valor.isEmpty)
                    ? 'Informe a senha inicial.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
