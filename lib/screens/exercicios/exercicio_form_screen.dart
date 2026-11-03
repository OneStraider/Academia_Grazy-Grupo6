import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

import '../../models/exercicios.dart';
import '../../services/exercicios_services.dart';
import '../../theme/app_theme.dart';

class ExercicioFormScreen extends StatefulWidget {
  final Exercicio? exercicio;

  const ExercicioFormScreen({super.key, this.exercicio});

  @override
  State<ExercicioFormScreen> createState() => _ExercicioFormScreenState();
}

class _ExercicioFormScreenState extends State<ExercicioFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _picker = ImagePicker();
  final _service = ExercicioService();

  late String _grupo;
  String? _imagemPath;
  bool _salvando = false;
  bool _ajustandoImagem = false;

  @override
  void initState() {
    super.initState();
    _nome.text = widget.exercicio?.nome ?? '';
    _descricao.text = widget.exercicio?.descricao ?? '';
    _grupo = widget.exercicio?.grupoMuscular ?? 'Peito';
    _imagemPath = widget.exercicio?.imagemUrl;
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _selecionarImagem() async {
    if (_ajustandoImagem) return;
    setState(() => _ajustandoImagem = true);
    try {
      final arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (arquivo == null || !mounted) return;

      final extensao = p
          .extension(arquivo.name.isEmpty ? arquivo.path : arquivo.name)
          .toLowerCase();
      final tipo = arquivo.mimeType?.toLowerCase() ?? '';
      final formatoPermitido =
          const {'.jpg', '.jpeg', '.png', '.gif'}.contains(extensao) ||
          const {'image/jpeg', 'image/png', 'image/gif'}.contains(tipo);
      if (!formatoPermitido) {
        _mensagem('Escolha uma imagem JPG, PNG ou GIF.');
        return;
      }

      final png = extensao == '.png' || tipo == 'image/png';
      final ajustada = await ImageCropper().cropImage(
        sourcePath: arquivo.path,
        maxWidth: 1200,
        maxHeight: 675,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        compressFormat: png ? ImageCompressFormat.png : ImageCompressFormat.jpg,
        compressQuality: 86,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar imagem',
            toolbarColor: AppTheme.primaria,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
          IOSUiSettings(
            title: 'Ajustar imagem',
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          ),
        ],
      );
      if (ajustada == null || !mounted) return;

      final diretorio = Directory(
        p.join(await getDatabasesPath(), 'imagens_exercicios'),
      );
      await diretorio.create(recursive: true);
      final saida = p.join(
        diretorio.path,
        'exercicio_${DateTime.now().microsecondsSinceEpoch}.${png ? 'png' : 'jpg'}',
      );
      await File(ajustada.path).copy(saida);
      if (!mounted) return;
      setState(() => _imagemPath = saida);
    } catch (erro) {
      if (mounted) _mensagem('Não foi possível ajustar a imagem: $erro');
    } finally {
      if (mounted) setState(() => _ajustandoImagem = false);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate() || _salvando) return;
    setState(() => _salvando = true);
    final exercicio = Exercicio(
      id: widget.exercicio?.id,
      nome: _nome.text.trim(),
      grupoMuscular: _grupo,
      descricao: _descricao.text.trim(),
      imagemUrl: _imagemPath,
    );
    try {
      if (widget.exercicio == null) {
        await _service.cadastrar(exercicio);
      } else {
        await _service.editar(exercicio);
      }

      final imagemAntiga = widget.exercicio?.imagemUrl;
      if (imagemAntiga != null &&
          imagemAntiga != _imagemPath &&
          !imagemAntiga.startsWith('http')) {
        final arquivoAntigo = File(imagemAntiga);
        if (await arquivoAntigo.exists()) await arquivoAntigo.delete();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) _mensagem('Não foi possível salvar o exercício: $erro');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _imagemPreview() {
    final caminho = _imagemPath;
    if (caminho == null || caminho.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 42,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }
    if (caminho.startsWith('http')) {
      return Image.network(
        caminho,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagemIndisponivel(),
      );
    }
    return Image.file(
      File(caminho),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagemIndisponivel(),
    );
  }

  Widget _imagemIndisponivel() => Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    alignment: Alignment.center,
    child: Icon(
      Icons.broken_image_outlined,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.exercicio == null ? 'Novo exercício' : 'Editar exercício',
      ),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _grupo,
            decoration: const InputDecoration(labelText: 'Grupo muscular'),
            items: const [
              'Peito',
              'Costas',
              'Pernas',
              'Braços',
              'Ombros',
              'Abdômen',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _grupo = v);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descricao,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descrição'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe a descrição' : null,
          ),
          const SizedBox(height: 20),
          Text(
            'Imagem de demonstração',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(aspectRatio: 16 / 9, child: _imagemPreview()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_ajustandoImagem || _salvando)
                      ? null
                      : _selecionarImagem,
                  icon: _ajustandoImagem
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _imagemPath == null ? 'Escolher imagem' : 'Trocar imagem',
                  ),
                ),
              ),
              if (_imagemPath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remover imagem',
                  onPressed: (_ajustandoImagem || _salvando)
                      ? null
                      : () => setState(() => _imagemPath = null),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 20),
            child: Text('JPG, PNG ou GIF · ajuste em 16:9 · até 1200 × 675 px'),
          ),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar exercício'),
          ),
        ],
      ),
    ),
  );
}
