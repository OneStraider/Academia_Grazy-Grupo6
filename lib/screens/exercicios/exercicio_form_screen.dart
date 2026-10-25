import 'package:flutter/material.dart';

import '../../models/exercicios.dart';
import '../../services/exercicios_services.dart';

class ExercicioFormScreen extends StatefulWidget {
  final Exercicio? exercicio;
  const ExercicioFormScreen({super.key, this.exercicio});
  @override
  State<ExercicioFormScreen> createState() => _ExercicioFormScreenState();
}

class _ExercicioFormScreenState extends State<ExercicioFormScreen> {
  final form = GlobalKey<FormState>();
  late final nome = TextEditingController(text: widget.exercicio?.nome);
  late final descricao = TextEditingController(
    text: widget.exercicio?.descricao,
  );
  String grupo = 'Peito';
  final service = ExercicioService();
  @override
  void initState() {
    super.initState();
    grupo = widget.exercicio?.grupoMuscular ?? 'Peito';
  }

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.exercicio == null ? 'Novo exercício' : 'Editar exercício',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: nome,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: grupo,
            decoration: const InputDecoration(labelText: 'Grupo muscular'),
            items: const [
              'Peito',
              'Costas',
              'Pernas',
              'Braços',
              'Ombros',
              'Abdômen',
            ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (v) => setState(() => grupo = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descricao,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descrição'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe a descrição' : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final e = Exercicio(
                id: widget.exercicio?.id,
                nome: nome.text.trim(),
                grupoMuscular: grupo,
                descricao: descricao.text.trim(),
              );
              if (widget.exercicio == null) {
                await service.cadastrar(e);
              } else {
                await service.editar(e);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar exercício'),
          ),
        ],
      ),
    ),
  );
}
