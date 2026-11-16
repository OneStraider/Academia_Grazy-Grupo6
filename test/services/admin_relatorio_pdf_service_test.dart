import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:academia_grazy_grupo6/services/admin_relatorio_pdf_service.dart';
import 'package:academia_grazy_grupo6/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dados = [
    AdminPontoSerie('Semana 1', DateTime(2026, 11, 9), const {
      'Professora Ana': 3,
      'Professor Bruno': 1,
    }),
    AdminPontoSerie('Semana 2', DateTime(2026, 11, 16), const {
      'Professora Ana': 5,
      'Professor Bruno': 0,
    }),
  ];

  Future<bool> exportar(AdminRelatorioPdfService service) => service.exportar(
    titulo: 'Treinos por professor',
    dados: dados,
    series: const ['Professora Ana', 'Professor Bruno'],
    cores: const {'Professora Ana': '#06483F', 'Professor Bruno': '#E85B2A'},
    periodo: 'Novembro de 2026',
    filtro: 'Professor: Todos os professores',
    metrica: 'treinos',
    barras: true,
    geradoEm: DateTime(2026, 11, 15, 12),
  );

  test('gera PDF com nome e bytes válidos antes de despachar', () async {
    Uint8List? capturado;
    String? nome;
    final service = AdminRelatorioPdfService(
      dispatcher: (bytes, fileName) async {
        capturado = bytes;
        nome = fileName;
        return true;
      },
    );

    expect(await exportar(service), isTrue);
    expect(String.fromCharCodes(capturado!.take(5)), '%PDF-');
    expect(nome, contains('treinos_por_professor'));
    expect(nome, endsWith('.pdf'));
  });

  test('propaga cancelamento sem declarar que o arquivo foi salvo', () async {
    final service = AdminRelatorioPdfService(dispatcher: (_, _) async => false);

    expect(await exportar(service), isFalse);
  });

  test('gera PDF de comparação horizontal por professor', () async {
    Uint8List? capturado;
    final service = AdminRelatorioPdfService(
      dispatcher: (bytes, _) async {
        capturado = bytes;
        return true;
      },
    );
    final resultado = await service.exportar(
      titulo: 'Treinos por professor',
      dados: [
        AdminPontoSerie('Novembro de 2026', DateTime(2026, 11), const {
          'Professora Ana': 7,
          'Sem professor': 2,
        }),
      ],
      series: const ['Professora Ana', 'Sem professor'],
      cores: const {'Professora Ana': '#06483F', 'Sem professor': '#62716B'},
      periodo: 'Novembro de 2026',
      filtro: 'Professor: Todos os professores',
      metrica: 'treinos',
      barras: true,
      barrasHorizontais: true,
      geradoEm: DateTime(2026, 11, 15, 12),
    );

    expect(resultado, isTrue);
    expect(String.fromCharCodes(capturado!.take(5)), '%PDF-');
  });

  test('não exporta quando não há dados', () async {
    final service = AdminRelatorioPdfService(
      dispatcher: (_, _) async => fail('Não deveria abrir a impressão'),
    );

    await expectLater(
      service.exportar(
        titulo: 'Treinos por professor',
        dados: const [],
        series: const [],
        cores: const {},
        periodo: 'Novembro de 2026',
        filtro: 'Todos os professores',
        metrica: 'treinos',
        barras: false,
      ),
      throwsStateError,
    );
  });
}
