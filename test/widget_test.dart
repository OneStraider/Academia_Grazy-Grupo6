import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/main.dart';

void main() {
  testWidgets('Academia Grazy inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const AcademiaGrazyApp());

    expect(find.text('Academia Grazy'), findsOneWidget);
  });
}