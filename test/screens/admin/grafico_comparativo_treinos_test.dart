import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/screens/admin/grafico_comparativo_treinos.dart';
import 'package:academia_grazy_grupo6/services/admin_service.dart';

void main() {
  for (final size in [const Size(360, 720), const Size(1200, 900)]) {
    testWidgets('compara professores sem overflow em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final professores = [
        for (var i = 0; i < 10; i++)
          AdminTreinoProfessorTotal(
            professorId: i + 1,
            nome: 'Professor com nome extenso $i',
            total: 10 - i,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraficoComparativoTreinos(
              comparativo: AdminComparativoTreinos(
                totalPeriodo: 55,
                totalSemProfessor: 0,
                professores: professores,
              ),
              cor: const Color(0xFF06483F),
              destaque: const Color(0xFFE85B2A),
            ),
          ),
        ),
      );

      expect(find.text('55'), findsOneWidget);
      expect(find.text('Professor com nome extenso 0'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Professor com nome extenso 9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
