import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

/// Compara os totais do período; a lista rola sem mover os filtros do cartão.
class GraficoComparativoTreinos extends StatelessWidget {
  final AdminComparativoTreinos comparativo;
  final Color cor;
  final Color destaque;

  const GraficoComparativoTreinos({
    super.key,
    required this.comparativo,
    required this.cor,
    required this.destaque,
  });

  @override
  Widget build(BuildContext context) {
    final barras = comparativo.barrasOrdenadas;
    final maximo = barras.fold<int>(
      0,
      (atual, barra) => math.max(atual, barra.total),
    );
    final maiorId = barras.isEmpty ? null : barras.first.professorId;
    final tema = Theme.of(context);

    if (barras.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(child: Text('Nenhum professor cadastrado.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Totais por professor no período',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${comparativo.totalPeriodo}',
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(child: Text('treinos criados no período')),
          ],
        ),
        if (comparativo.totalSemProfessor > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${comparativo.totalSemProfessor} sem professor associado; incluído na comparação.',
            style: tema.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: math.min(320.0, math.max(108.0, barras.length * 46.0)),
          child: ListView.separated(
            primary: false,
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: barras.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final barra = barras[index];
              final corBarra = barra.semProfessor
                  ? tema.colorScheme.outline
                  : barra.professorId == maiorId
                  ? destaque
                  : cor;
              return SizedBox(
                height: 36,
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        barra.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.labelMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              Container(
                                height: 20,
                                color: tema.colorScheme.surfaceContainerHighest,
                              ),
                              Container(
                                width: maximo == 0
                                    ? 0
                                    : constraints.maxWidth *
                                          barra.total /
                                          maximo,
                                height: 20,
                                color: corBarra,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${barra.total}',
                        textAlign: TextAlign.end,
                        style: tema.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
