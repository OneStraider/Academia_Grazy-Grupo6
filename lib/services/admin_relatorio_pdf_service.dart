import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/admin/chart_axis_scale.dart';
import 'admin_service.dart';

typedef AdminPdfDispatcher = Future<bool> Function(
  Uint8List bytes,
  String fileName,
);

class AdminRelatorioPdfService {
  final AdminPdfDispatcher _dispatcher;

  AdminRelatorioPdfService({AdminPdfDispatcher? dispatcher})
    : _dispatcher = dispatcher ?? _abrirImpressao;

  Future<bool> exportar({
    required String titulo,
    required List<AdminPontoSerie> dados,
    required List<String> series,
    required Map<String, String> cores,
    required String periodo,
    required String filtro,
    required String metrica,
    required bool barras,
    bool barrasHorizontais = false,
    DateTime? geradoEm,
  }) async {
    final bytes = await criarPdf(
      titulo: titulo,
      dados: dados,
      series: series,
      cores: cores,
      periodo: periodo,
      filtro: filtro,
      metrica: metrica,
      barras: barras,
      barrasHorizontais: barrasHorizontais,
      geradoEm: geradoEm,
    );
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw StateError('O documento PDF não foi gerado corretamente.');
    }

    final seguro = titulo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final dataNome = DateFormat('yyyyMMdd_HHmm')
        .format(geradoEm ?? DateTime.now());
    return _dispatcher(bytes, 'academia_grazy_${seguro}_$dataNome.pdf');
  }

  Future<Uint8List> criarPdf({
    required String titulo,
    required List<AdminPontoSerie> dados,
    required List<String> series,
    required Map<String, String> cores,
    required String periodo,
    required String filtro,
    required String metrica,
    required bool barras,
    bool barrasHorizontais = false,
    DateTime? geradoEm,
  }) async {
    if (dados.isEmpty || series.isEmpty) {
      throw StateError('Não há dados para incluir neste relatório.');
    }

    final relatorio = pw.Document();
    final fonte = pw.Font.ttf(
      await rootBundle.load('assets/fonts/BarlowCondensed-Regular.ttf'),
    );
    final fonteNegrito = pw.Font.ttf(
      await rootBundle.load('assets/fonts/BarlowCondensed-Bold.ttf'),
    );
    final geracao = DateFormat('dd/MM/yyyy HH:mm')
        .format(geradoEm ?? DateTime.now());
    final valores = [
      for (final ponto in dados)
        for (final nome in series) ponto.valores[nome] ?? 0,
    ];
    final escala = ChartAxisScale.fromValues(valores);
    final svg = barrasHorizontais
        ? _graficoHorizontalSvg(
            dados: dados,
            series: series,
            cores: cores,
            escala: escala,
          )
        : _graficoSvg(
            dados: dados,
            series: series,
            cores: cores,
            escala: escala,
            barras: barras,
          );
    final alturaGrafico = barrasHorizontais
        ? math.max(285.0, series.length * 30.0 + 45)
        : 285.0;
    final totalExibido = barrasHorizontais
        ? series.fold<int>(
            0,
            (soma, nome) => soma + (dados.first.valores[nome] ?? 0),
          )
        : metrica == 'treinos'
        ? dados.fold<int>(
            0,
            (soma, ponto) =>
                soma +
                series.fold<int>(
                  0,
                  (subtotal, nome) => subtotal + (ponto.valores[nome] ?? 0),
                ),
          )
        : null;

    relatorio.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: fonte, bold: fonteNegrito),
        build: (context) => [
          pw.Text(
            titulo,
            style: pw.TextStyle(font: fonteNegrito, fontSize: 22),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Período: $periodo'),
          pw.Text('Filtro: $filtro'),
          pw.Text(
            'Tipo de gráfico: ${barrasHorizontais
                ? 'Barras horizontais por professor'
                : barras
                ? 'Barras por intervalo'
                : 'Linhas por intervalo'}',
          ),
          if (totalExibido != null) pw.Text('Total exibido: $totalExibido'),
          pw.Text('Gráfico: ${barras ? 'Barras' : 'Linhas'}'),
          pw.Text('Gerado em: $geracao'),
          pw.SizedBox(height: 14),
          pw.SizedBox(
            height: alturaGrafico,
            width: double.infinity,
            child: pw.SvgImage(
              svg: svg,
              fit: pw.BoxFit.contain,
              customFontLookup: (_, _, weight) =>
                  weight == 'bold' ? fonteNegrito : fonte,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Valores por intervalo',
            style: pw.TextStyle(font: fonteNegrito, fontSize: 14),
          ),
          pw.SizedBox(height: 5),
          _tabelaValores(dados, series, fonte, fonteNegrito),
        ],
      ),
    );
    return relatorio.save();
  }

  static Future<bool> _abrirImpressao(Uint8List bytes, String nome) =>
      Printing.layoutPdf(
        name: nome,
        format: PdfPageFormat.a4.landscape,
        onLayout: (_) async => bytes,
      );

  pw.Widget _tabelaValores(
    List<AdminPontoSerie> dados,
    List<String> series,
    pw.Font fonteRegular,
    pw.Font fonteNegrito,
  ) {
    final cabecalho = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF06483F)),
      children: [
        _celulaTabela('Intervalo', cor: PdfColors.white, fonte: fonteNegrito),
        _celulaTabela('Série', cor: PdfColors.white, fonte: fonteNegrito),
        _celulaTabela('Quantidade', cor: PdfColors.white, fonte: fonteNegrito),
      ],
    );
    return pw.Table(
      border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFD9E5DE)),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        cabecalho,
        for (final ponto in dados)
          for (final serie in series)
            pw.TableRow(
              children: [
                _celulaTabela(ponto.rotulo, fonte: fonteRegular),
                _celulaTabela(serie, fonte: fonteRegular),
                _celulaTabela(
                  '${ponto.valores[serie] ?? 0}',
                  fonte: fonteRegular,
                ),
              ],
            ),
      ],
    );
  }

  pw.Widget _celulaTabela(
    String texto, {
    PdfColor cor = PdfColors.black,
    pw.Font? fonte,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      texto,
      style: pw.TextStyle(color: cor, font: fonte),
    ),
  );

  String _graficoSvg({
    required List<AdminPontoSerie> dados,
    required List<String> series,
    required Map<String, String> cores,
    required ChartAxisScale escala,
    required bool barras,
  }) {
    const width = 1000.0;
    const plotLeft = 76.0;
    const plotTop = 20.0;
    const plotBottom = 300.0;
    const right = 22.0;
    const legendTop = 350.0;
    const legendColumnWidth = 450.0;
    const legendRowHeight = 25.0;
    final plotRight = width - right;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;
    final step = plotWidth / dados.length;
    final labelStride = (dados.length / 8).ceil().clamp(1, dados.length);
    final legendRows = (series.length / 2).ceil();
    final height = legendTop + legendRows * legendRowHeight + 16;
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">',
    );

    for (final tick in escala.ticks) {
      final y = plotBottom - plotHeight * tick / escala.maximum;
      buffer
        ..write(
          '<line x1="$plotLeft" y1="$y" x2="$plotRight" y2="$y" stroke="#D9E5DE"/>',
        )
        ..write(
          '<text x="${plotLeft - 10}" y="${y + 4}" text-anchor="end" font-size="12" fill="#566A64">$tick</text>',
        );
    }
    buffer.write(
      '<line x1="$plotLeft" y1="$plotBottom" x2="$plotRight" y2="$plotBottom" stroke="#06483F" stroke-width="2"/>',
    );

    if (barras) {
      final groupWidth = step * .86;
      final barWidth = groupWidth / series.length;
      for (var i = 0; i < dados.length; i++) {
        for (var j = 0; j < series.length; j++) {
          final serie = series[j];
          final value = dados[i].valores[serie] ?? 0;
          if (value == 0) continue;
          final barHeight = plotHeight * value / escala.maximum;
          final x =
              plotLeft + step * i + (step - groupWidth) / 2 + barWidth * j;
          buffer.write(
            '<rect x="$x" y="${plotBottom - barHeight}" width="${math.max(1, barWidth - 2)}" height="$barHeight" rx="2" fill="${cores[serie] ?? '#06483F'}"/>',
          );
        }
      }
    } else {
      for (final serie in series) {
        final points = <String>[];
        for (var i = 0; i < dados.length; i++) {
          final value = dados[i].valores[serie] ?? 0;
          final x = plotLeft + step * (i + .5);
          final y = plotBottom - plotHeight * value / escala.maximum;
          points.add('$x,$y');
        }
        final color = cores[serie] ?? '#06483F';
        buffer.write(
          '<polyline points="${points.join(' ')}" fill="none" stroke="$color" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>',
        );
        for (final point in points) {
          final coordinates = point.split(',');
          buffer.write(
            '<circle cx="${coordinates[0]}" cy="${coordinates[1]}" r="4" fill="$color"/>',
          );
        }
      }
    }

    for (var i = 0; i < dados.length; i += labelStride) {
      buffer.write(
        '<text x="${plotLeft + step * (i + .5)}" y="${plotBottom + 20}" text-anchor="middle" font-size="12" fill="#566A64">${_escapar(dados[i].rotulo)}</text>',
      );
    }
    for (var i = 0; i < series.length; i++) {
      final coluna = i % 2;
      final linha = i ~/ 2;
      final x = 24 + coluna * legendColumnWidth;
      final y = legendTop + linha * legendRowHeight;
      final nome = series[i];
      final total = dados.fold<int>(
        0,
        (soma, ponto) => soma + (ponto.valores[nome] ?? 0),
      );
      buffer
        ..write(
          '<circle cx="$x" cy="${y - 4}" r="5" fill="${cores[nome] ?? '#06483F'}"/>',
        )
        ..write(
          '<text x="${x + 12}" y="$y" font-size="14" fill="#173A34">${_escapar('$nome: $total')}</text>',
        );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  String _graficoHorizontalSvg({
    required List<AdminPontoSerie> dados,
    required List<String> series,
    required Map<String, String> cores,
    required ChartAxisScale escala,
  }) {
    const width = 1000.0;
    const right = 35.0;
    const top = 24.0;
    const rowHeight = 30.0;
    final height = top + series.length * rowHeight + 25;
    final maiorNome = series.fold<int>(
      0,
      (maior, nome) => math.max(maior, nome.length),
    );
    final left = math.min(500.0, math.max(190.0, maiorNome * 7.0 + 18));
    final plotWidth = width - left - right - 24;
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">',
    );
    for (final tick in escala.ticks) {
      final x = left + plotWidth * tick / escala.maximum;
      buffer
        ..write(
          '<line x1="$x" y1="$top" x2="$x" y2="${height - 12}" stroke="#D9E5DE"/>',
        )
        ..write(
          '<text x="$x" y="${height - 1}" text-anchor="middle" font-size="12" fill="#566A64">$tick</text>',
        );
    }
    for (var i = 0; i < series.length; i++) {
      final nome = series[i];
      final value = dados.first.valores[nome] ?? 0;
      final y = top + i * rowHeight;
      final largura = plotWidth * value / escala.maximum;
      buffer
        ..write(
          '<text x="${left - 10}" y="${y + 16}" text-anchor="end" font-size="14" fill="#173A34">${_escapar(nome)}</text>',
        )
        ..write(
          '<rect x="$left" y="$y" width="$largura" height="20" rx="3" fill="${cores[nome] ?? '#06483F'}"/>',
        )
        ..write(
          '<text x="${left + largura + 8}" y="${y + 15}" font-size="13" font-weight="bold" fill="#173A34">$value</text>',
        );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  String _escapar(String texto) => texto
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
