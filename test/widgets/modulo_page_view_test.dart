import 'package:academia_grazy_grupo6/widgets/modulo_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('troca de módulo com swipe longo e ignora gesto curto', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var paginaAtual = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModuloPageView(
            controller: controller,
            onPageChanged: (pagina) => paginaAtual = pagina,
            children: const [
              Center(child: Text('Módulo inicial')),
              Center(child: Text('Módulo seguinte')),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.text('Módulo inicial'), const Offset(-35, 0));
    await tester.pumpAndSettle();
    expect(paginaAtual, 0);
    expect(find.text('Módulo inicial'), findsOneWidget);

    await tester.drag(find.text('Módulo inicial'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(paginaAtual, 1);
    expect(find.text('Módulo seguinte'), findsOneWidget);
  });

  testWidgets('arraste vertical não muda o módulo', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var paginaAtual = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModuloPageView(
            controller: controller,
            onPageChanged: (pagina) => paginaAtual = pagina,
            children: [
              ListView(
                children: [
                  for (var i = 0; i < 30; i++)
                    SizedBox(height: 60, child: Text('Linha $i')),
                ],
              ),
              const Center(child: Text('Outro módulo')),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.text('Linha 0'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(paginaAtual, 0);
    expect(find.text('Outro módulo'), findsNothing);
    expect(find.text('Linha 0'), findsNothing);
  });
}
