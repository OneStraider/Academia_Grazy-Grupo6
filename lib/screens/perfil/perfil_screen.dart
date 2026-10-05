import 'package:flutter/material.dart';

import '../alunos_mock.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: ListView(
          children: [
            Text('Perfil', style: tema.headlineMedium),
            Text(
              'Área de testes: simule quem está logado',
              style: tema.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: ValueListenableBuilder<Papel>(
                  valueListenable: papelAtual,
                  builder: (context, papel, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Usuário simulado', style: tema.titleMedium),
                        const SizedBox(height: 12),
                        SegmentedButton<Papel>(
                          segments: const [
                            ButtonSegment(
                              value: Papel.professor,
                              label: Text('Professor'),
                              icon: Icon(Icons.school_outlined),
                            ),
                            ButtonSegment(
                              value: Papel.aluno,
                              label: Text('Aluno'),
                              icon: Icon(Icons.person_outline),
                            ),
                          ],
                          selected: {papel},
                          onSelectionChanged: (selecao) {
                            papelAtual.value = selecao.first;
                          },
                        ),
                        if (papel == Papel.aluno) ...[
                          const SizedBox(height: 12),
                          ValueListenableBuilder<int>(
                            valueListenable: alunoLogadoId,
                            builder: (context, id, _) {
                              return DropdownButtonFormField<int>(
                                initialValue: id,
                                decoration:
                                    const InputDecoration(labelText: 'Aluno'),
                                items: [
                                  for (final e in alunosTeste.entries)
                                    DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) alunoLogadoId.value = v;
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}