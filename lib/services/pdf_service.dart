import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rdp_report.dart';
import '../models/scrap_report.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class PdfService {
  static final _border = PdfColors.black;
  static final _headerBg = PdfColor.fromHex('#E8E8E8');
  static final _learRed = PdfColor.fromHex('#E30613');
  static final _totalBg = PdfColor.fromHex('#F5F5F5');
  static final _grayCell = PdfColor.fromHex('#D0D0D0');
  static final _ppHeaderBg = PdfColor.fromHex('#D9D9D9');

  // ===========================================================================
  // RDP — F QUA-E 054 Rev.04 (réplica fiel do formulário de papel, A4 paisagem)
  // ===========================================================================

  // ---- Larguras: somam EXATAMENTE a largura imprimível (A4 paisagem - margens).
  static const double _margin = 12.0;
  // Bloco esquerdo (8 colunas).
  static const double _wSq = 22;
  static const double _wIni = 46;
  static const double _wTer = 46;
  static const double _wPn1 = 36;
  static const double _wPn2 = 48;
  static const double _wRateP = 41;
  static const double _wRateR = 41;
  static const double _leftFixed = 280; // soma das 7 acima
  // Bloco direito: 26 colunas estreitas + 5 de scrap + visto.
  static const double _wNarrow = 14;
  static const double _narrowTotal = 364; // 26 x 14
  static const double _wS1 = 19;
  static const double _wS2 = 19;
  static const double _wS3 = 19;
  static const double _wS4 = 19;
  static const double _wST = 22;
  static const double _scrapTotal = 98;
  static const double _wVisto = 28;
  static const double _rightTotal = 490; // 364 + 98 + 28
  static const double _fixedSum = 770; // 280 + 490

  static double get _usableW =>
      PdfPageFormat.a4.landscape.width - _margin * 2;
  // A coluna QUANTIDADE absorve a sobra para fechar a largura exata.
  static double get _wQtd => _usableW - _fixedSum; // ~47.89
  static double get _leftTotal => _leftFixed + _wQtd;

  // ---- Alturas (total ~559.5pt de ~571pt úteis).
  static const double _hTitle = 28;
  static const double _hB = 34; // linha MAQ / topo do logo
  static const double _hC = 22; // linha dos grupos
  static const double _hD = 110; // rótulos verticais
  static const double _hE = 26; // setas + cabeçalhos esquerdos
  static const double _hRightMid = 158; // C + D + E
  static const double _hData = 16.5;
  static const double _hTotal = 18;
  static const int _maxRows = 15;
  static const double _hFootBand = 14; // x4 = 56
  static const double _gap = 3;

  /// Salva o PDF no aparelho e registra no historico. Nunca quebra a geracao.
  static Future<Uint8List> _recordPdf({
    required pw.Document pdf,
    required String tipo,
    required String titulo,
    required String fileName,
  }) async {
    final bytes = await pdf.save();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(dir.path + '/pdfs');
      if (!await pdfDir.exists()) await pdfDir.create(recursive: true);
      final file = File(pdfDir.path + '/' + fileName + '.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await DatabaseService.instance.saveGeneratedDoc(
        tipo: tipo,
        titulo: titulo,
        filename: fileName + '.pdf',
        path: file.path,
      );
    } catch (e) {
      debugPrint('HISTORICO: falha ao salvar PDF');
    }
    return bytes;
  }

  static Future<void> generateRdpPdf(RdpReport report) async {
    final pdf = pw.Document();
    report.calcularTotais();
    final dataFmt = _fmtData(report.data);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(_margin),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _rdpTitleRow(dataFmt),
              pw.SizedBox(height: _gap),
              _rdpHeaderBlock(report),
              pw.SizedBox(height: _gap),
              _rdpDataTable(report),
              _rdpTotalRow(report),
              pw.SizedBox(height: _gap),
              _rdpFooter(report),
              pw.SizedBox(height: 2),
              pw.Text(
                'F QUA-E 054 - Relatório de Produção do Corte - 16-06-26',
                style: const pw.TextStyle(fontSize: 5),
              ),
            ],
          );
        },
      ),
    );

    final fileName = _safeFileName(
        'RDP_${report.maquina}_${dataFmt.replaceAll('/', '-')}');
    final bytes = await _recordPdf(
      pdf: pdf,
      tipo: 'RDP',
      titulo: 'RDP MAQ ' + report.maquina + ' - ' + dataFmt,
      fileName: fileName,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: fileName,
    );
  }

  static String _safeFileName(String name) {
    final clean = name.replaceAll(RegExp(r'[^\w\-.]+'), '_').trim();
    final trimmed = clean.isEmpty ? 'relatorio' : clean;
    return '$trimmed.pdf';
  }

  /// Converte a data para o formato do papel: DD/MM/AA.
  static String _fmtData(String data) {
    final d = data.trim();
    final m1 = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(d);
    if (m1 != null) {
      return '${m1.group(3)}/${m1.group(2)}/${m1.group(1)!.substring(2)}';
    }
    final m2 = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(d);
    if (m2 != null) {
      return '${m2.group(1)}/${m2.group(2)}/${m2.group(3)!.substring(2)}';
    }
    return d;
  }

  // ---- Linha do título ------------------------------------------------------
  static pw.Widget _rdpTitleRow(String dataFmt) {
    return pw.Container(
      height: _hTitle,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.8)),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              height: _hTitle,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      right: pw.BorderSide(color: _border, width: 0.4))),
              child: pw.Text(
                'RDP - Relatório de Produção do Corte',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
          pw.Container(
            width: 90,
            height: _hTitle,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
                border: pw.Border(
                    right: pw.BorderSide(color: _border, width: 0.4))),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('DATA', style: const pw.TextStyle(fontSize: 6)),
                pw.Text(dataFmt,
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Container(
            width: 80,
            height: _hTitle,
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('F QUA-E 054',
                    style: const pw.TextStyle(fontSize: 6.5)),
                pw.Text('Rev. 04', style: const pw.TextStyle(fontSize: 6.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Bloco do cabeçalho (logo + MAQ + grupos + rótulos) -------------------
  static pw.Widget _rdpHeaderBlock(RdpReport report) {
    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.8)),
      child: pw.Row(
        children: [
          _rdpLeftBlock(),
          _rdpRightBlock(report),
        ],
      ),
    );
  }

  static pw.Widget _rdpLeftBlock() {
    return pw.Container(
      width: _leftTotal,
      child: pw.Column(
        children: [
          _rdpLogoBox(),
          _rdpLeftHeaders(),
        ],
      ),
    );
  }

  static pw.Widget _rdpLogoBox() {
    return pw.Container(
      width: _leftTotal,
      height: _hB + _hC + _hD,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(color: _border, width: 0.4),
          bottom: pw.BorderSide(color: _border, width: 0.4),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 40,
            height: 40,
            decoration:
                pw.BoxDecoration(color: _learRed, shape: pw.BoxShape.circle),
            alignment: pw.Alignment.center,
            child: pw.Text('L',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24)),
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('LEAR',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 20)),
              pw.Text('C O R P O R A T I O N',
                  style: const pw.TextStyle(fontSize: 7.5)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _rdpLeftHeaders() {
    pw.Widget h(String text, double w, {double fontSize = 5.5}) {
      return pw.Container(
        width: w,
        height: _hE,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.4)),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 2),
      );
    }

    return pw.Row(
      children: [
        h('SQ', _wSq, fontSize: 6),
        h('INÍCIO DA\nATV', _wIni),
        h('TÉRMINO DA\nATV', _wTer),
        h('PN DA PEÇA', _wPn1 + _wPn2, fontSize: 7),
        h('Rate\nplanejada', _wRateP),
        h('Rate Real', _wRateR),
        h('QUANTIDADE\nPEÇAS', _wQtd),
      ],
    );
  }

  static pw.Widget _rdpRightBlock(RdpReport report) {
    return pw.Container(
      width: _rightTotal,
      child: pw.Column(
        children: [
          _rdpMaqRow(report),
          pw.Row(
            children: [
              _rdpNarrowBlock(),
              _rdpScrapBlock(),
              _rdpVistoBlock(),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _rdpMaqRow(RdpReport report) {
    const double labelH = 11;
    const double valueH = _hB - labelH;

    pw.Widget labelBox(String label) {
      return pw.Container(
        height: labelH,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _border, width: 0.4))),
        child: pw.Text(label,
            style: const pw.TextStyle(fontSize: 5.5), maxLines: 1),
      );
    }

    pw.Widget cell(String label, String value, double w,
        {double valueSize = 8.5}) {
      return pw.Container(
        width: w,
        height: _hB,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.4)),
        child: pw.Column(
          children: [
            labelBox(label),
            pw.Container(
              height: valueH,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 1),
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: valueSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2),
            ),
          ],
        ),
      );
    }

    pw.Widget turnoCell() {
      pw.Widget num(String n) {
        final marked = report.turno.trim() == n;
        return pw.Container(
          width: 22,
          height: valueH,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
              border: pw.Border(
                  right: pw.BorderSide(color: _border, width: 0.4))),
          child: pw.Text(marked ? 'X' : n,
              style: pw.TextStyle(
                  fontSize: marked ? 11 : 9,
                  fontWeight: pw.FontWeight.bold)),
        );
      }

      final t = report.turno.trim();
      final custom = t.isNotEmpty && t != '1' && t != '2' && t != '3';
      return pw.Container(
        width: 66,
        height: _hB,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.4)),
        child: pw.Column(
          children: [
            labelBox('Turno'),
            custom
                ? pw.Container(
                    height: valueH,
                    alignment: pw.Alignment.center,
                    child: pw.Text(t,
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        maxLines: 1),
                  )
                : pw.Container(
                    height: valueH,
                    child: pw.Row(
                      children: [num('1'), num('2'), num('3')],
                    ),
                  ),
          ],
        ),
      );
    }



    const double wOper = _rightTotal - 44 - 60 - 66 - 78 - 78; // 164
    return pw.Row(children: [
      cell('MAQ', report.maquina, 44),
      cell('OPERADOR', report.operador, wOper, valueSize: 8),
      cell('REG', report.reg, 60),
      turnoCell(),
      cell('Hora Inicial', report.horaInicial, 78, valueSize: 8),
      cell('Hora Final', report.horaFinal, 78, valueSize: 8),
    ]);
  }

  static pw.Widget _rdpNarrowBlock() {
    final groups = RdpPaperLayout.groups.sublist(0, 5);
    return pw.Container(
      width: _narrowTotal,
      child: pw.Column(
        children: [
          // Linha C: grupos (TR, TP, TM, TP, PP).
          pw.Row(
            children: groups.map((g) {
              return _groupCell(g.title, g.columns.length * _wNarrow, _hC);
            }).toList(),
          ),
          // Linha D: rótulos verticais.
          pw.Row(
            children: RdpPaperLayout.narrowColumns.map((c) {
              return _vLabel(c.key,
                  w: _wNarrow,
                  h: _hD,
                  fontSize: 4.8,
                  bg: c.store == 'PP' ? _ppHeaderBg : null);
            }).toList(),
          ),
          // Linha E: setas.
          pw.Row(
            children: RdpPaperLayout.narrowColumns
                .map((c) => _upMark(w: _wNarrow, h: _hE))
                .toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _groupCell(String title, double w, double h) {
    String text = title;
    double size = 7;
    if (title == 'Tempo Perdido (TP)') {
      text = 'Tempo\nPerdido (TP)';
      size = 6;
    } else if (title == 'Tempo Morto (TM)') {
      size = 6.5;
    } else if (title == 'Paradas Programadas (PP)') {
      size = 6.5;
    } else if (title == 'TR' || title == 'TP') {
      size = 8;
    }
    return pw.Container(
      width: w,
      height: h,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.4)),
      child: pw.Text(text,
          style:
              pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
          maxLines: 2),
    );
  }

  /// Rótulo vertical (lê-se de baixo para cima, como no papel).
  static pw.Widget _vLabel(String text,
      {required double w,
      required double h,
      double fontSize = 5,
      PdfColor? bg}) {
    return pw.Container(
      width: w,
      height: h,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
          color: bg, border: pw.Border.all(color: _border, width: 0.4)),
      child: pw.Transform.rotateBox(
        angle: -math.pi / 2,
        child: pw.Container(
          width: h - 4,
          alignment: pw.Alignment.center,
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: fontSize, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
              maxLines: 1),
        ),
      ),
    );
  }

  /// Setinha impressa no papel entre o cabeçalho e os dados.
  static pw.Widget _upMark({required double w, required double h}) {
    return pw.Container(
      width: w,
      height: h,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.4)),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Transform.rotateBox(
            angle: math.pi / 4,
            child: pw.Container(
              width: 3.4,
              height: 3.4,
              decoration: pw.BoxDecoration(color: _border),
            ),
          ),
          pw.Container(
            width: 1.1,
            height: 4.5,
            decoration: pw.BoxDecoration(color: _border),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rdpScrapBlock() {
    const double hTitle = 11;
    const double hCod = 11;
    const double hLab = _hRightMid - hTitle - hCod; // 136
    final keys = RdpPaperLayout.scrapColumns;
    final widths = <double>[_wS1, _wS2, _wS3, _wS4, _wST];
    return pw.Container(
      width: _scrapTotal,
      child: pw.Column(
        children: [
          pw.Container(
            width: _scrapTotal,
            height: hTitle,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border, width: 0.4)),
            child: pw.Text('Scrap',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Row(children: [
            pw.Container(
              width: _wS1 + _wS2 + _wS3 + _wS4,
              height: hCod,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border, width: 0.4)),
              child: pw.Text('Código da perda',
                  style: const pw.TextStyle(fontSize: 6.5), maxLines: 1),
            ),
            pw.Container(
              width: _wST,
              height: hCod,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border, width: 0.4)),
            ),
          ]),
          pw.Row(
            children: List.generate(keys.length, (i) {
              return _vLabel(keys[i].key,
                  w: widths[i], h: hLab, fontSize: 5.5);
            }),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rdpVistoBlock() {
    return _vLabel('VISTO', w: _wVisto, h: _hRightMid, fontSize: 11);
  }

  // ---- Tabela de dados (15 linhas) ------------------------------------------
  static pw.Widget _rdpDataTable(RdpReport report) {
    final narrow = RdpPaperLayout.narrowColumns;
    final scrap = RdpPaperLayout.scrapColumns;

    Map<int, pw.TableColumnWidth> colWidths() {
      final fixed = <double>[
        _wSq,
        _wIni,
        _wTer,
        _wPn1,
        _wPn2,
        _wRateP,
        _wRateR,
        _wQtd,
        ...List.filled(narrow.length, _wNarrow),
        _wS1,
        _wS2,
        _wS3,
        _wS4,
        _wST,
        _wVisto,
      ];
      final map = <int, pw.TableColumnWidth>{};
      for (var i = 0; i < fixed.length; i++) {
        map[i] = pw.FixedColumnWidth(fixed[i]);
      }
      return map;
    }

    pw.Widget d(String text, {double fontSize = 7}) {
      return pw.Container(
        height: _hData,
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 1),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: fontSize),
            textAlign: pw.TextAlign.center,
            maxLines: 1),
      );
    }

    int minFor(RdpLine l, RdpPaperColumn c) {
      switch (c.store) {
        case 'TM':
          return l.tempoMorto[c.key] ?? 0;
        case 'TP':
          return l.tempoPerdido[c.key] ?? 0;
        case 'PP':
          return l.paradasProgramadas[c.key] ?? 0;
        default:
          return 0;
      }
    }

    final rows = <pw.TableRow>[];
    for (var i = 0; i < _maxRows; i++) {
      final linha = i < report.linhas.length ? report.linhas[i] : null;
      final cells = <pw.Widget>[];
      if (linha == null) {
        cells.add(d('${i + 1}'));
        for (var k = 0; k < 39; k++) {
          cells.add(d(''));
        }
      } else {
        final pn = linha.pnPartes;
        cells.addAll([
          d('${i + 1}'),
          d(linha.inicioAtiv),
          d(linha.terminoAtiv),
          d(pn[0]),
          d(pn[1]),
          d(linha.taxaPlanejada),
          d(linha.taxaReal),
          d(linha.quantidadePecas, fontSize: 7.5),
        ]);
        for (final c in narrow) {
          final v = minFor(linha, c);
          cells.add(d(v > 0 ? '$v'.padLeft(2, '0') : ''));
        }
        for (final c in scrap) {
          final v = linha.scrap[c.key] ?? 0;
          cells.add(d(v > 0 ? '$v' : ''));
        }
        cells.add(d('')); // visto
      }
      rows.add(pw.TableRow(children: cells));
    }

    return pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: _border, width: 0.8),
        right: pw.BorderSide(color: _border, width: 0.8),
        top: pw.BorderSide(color: _border, width: 0.8),
        bottom: pw.BorderSide(color: _border, width: 0.4),
        horizontalInside: pw.BorderSide(color: _border, width: 0.4),
        verticalInside: pw.BorderSide(color: _border, width: 0.4),
      ),
      columnWidths: colWidths(),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  // ---- Linha de TOTAL (células mescladas como no papel) ---------------------
  static pw.Widget _rdpTotalRow(RdpReport report) {
    final narrow = RdpPaperLayout.narrowColumns;
    final scrap = RdpPaperLayout.scrapColumns;

    int totalQtd = 0;
    for (final l in report.linhas) {
      totalQtd += int.tryParse(l.quantidadePecas) ?? 0;
    }

    int totFor(RdpPaperColumn c) {
      switch (c.store) {
        case 'TM':
          return report.totaisTempoMorto[c.key] ?? 0;
        case 'TP':
          return report.totaisTempoPerdido[c.key] ?? 0;
        case 'PP':
          return report.totaisParadas[c.key] ?? 0;
        case 'SC':
          return report.totaisScrap[c.key] ?? 0;
        default:
          return 0;
      }
    }

    pw.Widget t(String text, double w, {double fontSize = 7}) {
      return pw.Container(
        width: w,
        height: _hTotal,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.4)),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: fontSize, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 1),
      );
    }

    final cells = <pw.Widget>[
      t('TOTAL:', _wSq + _wIni + _wTer),
      t(report.linhas.isEmpty ? '' : '${report.linhas.length}'.padLeft(2, '0'),
          _wPn1 + _wPn2),
      t('', _wRateP),
      t('', _wRateR),
      t(totalQtd > 0 ? '$totalQtd' : '', _wQtd, fontSize: 7.5),
    ];
    for (final c in narrow) {
      final v = totFor(c);
      cells.add(t(v > 0 ? '$v'.padLeft(2, '0') : '', _wNarrow));
    }
    final scrapW = <double>[_wS1, _wS2, _wS3, _wS4, _wST];
    for (var i = 0; i < scrap.length; i++) {
      final v = totFor(scrap[i]);
      cells.add(t(v > 0 ? '$v' : '', scrapW[i]));
    }
    cells.add(t('', _wVisto));

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: _border, width: 0.8),
          right: pw.BorderSide(color: _border, width: 0.8),
          bottom: pw.BorderSide(color: _border, width: 0.8),
        ),
      ),
      child: pw.Row(children: cells),
    );
  }

  // ---- Rodapé (observações + grade de áreas) --------------------------------
  static pw.Widget _rdpFooter(RdpReport report) {
    final obsW = _usableW * 0.64;
    final gridW = _usableW - obsW;
    final colW = gridW / 6;
    const labels = ['REABAST', 'LOG', 'MANUT', 'TI', 'ENG', 'QUALI'];

    pw.Widget obsBand(String text, {bool isLabel = false}) {
      return pw.Container(
        width: obsW,
        height: _hFootBand,
        alignment: pw.Alignment.topLeft,
        padding: const pw.EdgeInsets.only(left: 3, top: 1),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.4)),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: isLabel ? 6.5 : 6,
                fontWeight:
                    isLabel ? pw.FontWeight.bold : pw.FontWeight.normal),
            maxLines: 2),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border, width: 0.8)),
      child: pw.Row(
        children: [
          pw.Container(
            width: obsW,
            child: pw.Column(
              children: [
                obsBand(
                    report.observacoes.isEmpty
                        ? 'OBSERVAÇÕES:'
                        : 'OBSERVAÇÕES: ${report.observacoes}',
                    isLabel: true),
                obsBand(''),
                obsBand(''),
                obsBand(''),
              ],
            ),
          ),
          pw.Container(
            width: gridW,
            child: pw.Column(
              children: [
                pw.Row(
                  children: labels.map((lab) {
                    return pw.Container(
                      width: colW,
                      height: _hFootBand * 3,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _border, width: 0.4)),
                      child: pw.Text(lab,
                          style: pw.TextStyle(
                              fontSize: 6, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                    );
                  }).toList(),
                ),
                pw.Row(
                  children: List.generate(6, (i) {
                    return pw.Container(
                      width: colW,
                      height: _hFootBand,
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _border, width: 0.4)),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCRAP — F QUA-E 102 Rev.04
  // ===========================================================================
  static Future<void> generateScrapPdf(ScrapReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _scrapTopHeader(report),
              pw.SizedBox(height: 6),
              _scrapSectionDual(
                titleLeft: 'TERMINAL',
                titleRight: 'TERMINAL',
                items: report.terminais,
                leftCount: 15,
                rightStart: 16,
                rightCount: 15,
              ),
              pw.SizedBox(height: 6),
              _scrapSectionDual(
                titleLeft: 'SELO',
                titleRight: 'SELO',
                items: report.selos,
                leftCount: 7,
                rightStart: 1,
                rightCount: 7,
              ),
              pw.SizedBox(height: 6),
              _scrapSectionDual(
                titleLeft: 'CABO',
                titleRight: 'CABO',
                items: report.cabos,
                leftCount: 23,
                rightStart: 1,
                rightCount: 23,
                compact: true,
              ),
              pw.Spacer(),
              pw.SizedBox(height: 4),
              _scrapMotivosFooter(),
              pw.SizedBox(height: 3),
              pw.Text(
                'F QUA-E 102 - Registro de scrap para corte - 03-03-26',
                style: const pw.TextStyle(fontSize: 5.5),
              ),
            ],
          );
        },
      ),
    );

    final fileName = _safeFileName(
        'Scrap_${report.maquina}_${report.data.replaceAll('/', '-')}');
    final bytes = await _recordPdf(
      pdf: pdf,
      tipo: 'Scrap',
      titulo: 'Scrap MAQ ' + report.maquina + ' - ' + report.data,
      fileName: fileName,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: fileName,
    );
  }

  static pw.Widget _scrapTopHeader(ScrapReport report) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.8)),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Container(
                    width: 18,
                    height: 18,
                    decoration: pw.BoxDecoration(color: _learRed, shape: pw.BoxShape.circle),
                    child: pw.Center(
                      child: pw.Text('L',
                          style: pw.TextStyle(
                              color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text('LEAR',
                      style: pw.TextStyle(
                          color: _learRed, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ]),
                pw.Text('REGISTRO DE SCRAP - ÁREA CORTE',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('F QUA-E 102', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Rev. 04', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ],
            ),
          ),
          pw.Table(
            border: pw.TableBorder(
              top: pw.BorderSide(color: _border, width: 0.5),
              left: pw.BorderSide.none,
              right: pw.BorderSide.none,
              bottom: pw.BorderSide(color: _border, width: 0.5),
              horizontalInside: pw.BorderSide(color: _border, width: 0.4),
              verticalInside: pw.BorderSide(color: _border, width: 0.4),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(children: [
                _scrapFieldCell('Máquina:', report.maquina),
                _scrapFieldCell('Centro:', report.centro),
                _scrapFieldCell('Turno:', report.turno),
                _scrapFieldCell('Data:', report.data),
              ]),
              pw.TableRow(children: [
                _scrapFieldCell('Matrícula:', report.matricula),
                _scrapFieldCell('Operador:', report.operador),
                _scrapFieldCell('Nome do líder:', report.nomeLider),
                _scrapFieldCell('', ''),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _scrapFieldCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label ', style: const pw.TextStyle(fontSize: 7)),
            pw.TextSpan(
              text: value.isEmpty ? ' ' : value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _scrapSectionDual({
    required String titleLeft,
    required String titleRight,
    required List<ScrapItem> items,
    required int leftCount,
    required int rightStart,
    required int rightCount,
    bool compact = false,
  }) {
    final fontSize = compact ? 5.5 : 6.5;
    final rowH = compact ? 9.0 : 11.0;

    pw.Widget sideTable({
      required String title,
      required int startNum,
      required int count,
      required int itemOffset,
    }) {
      final rows = <pw.TableRow>[
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _headerBg),
          children: [
            _sCell(title, bold: true, fontSize: fontSize, bg: _headerBg),
            _sCell('QUANTIDADE', bold: true, fontSize: fontSize - 0.5, bg: _headerBg),
            _sCell('TOTAL', bold: true, fontSize: fontSize - 0.5, bg: _headerBg),
            _sCell('MOTIVO', bold: true, fontSize: fontSize - 0.5, bg: _headerBg),
          ],
        ),
      ];

      for (var i = 0; i < count; i++) {
        final idx = itemOffset + i;
        final num = startNum + i;
        final item = idx < items.length ? items[idx] : null;
        rows.add(pw.TableRow(children: [
          _sCell(
            item != null && item.terminal.isNotEmpty ? '$num  ${item.terminal}' : '$num',
            fontSize: fontSize,
            alignLeft: true,
            height: rowH,
          ),
          _sCell(item?.quantidade ?? '', fontSize: fontSize, height: rowH, bg: _grayCell),
          _sCell(item?.total ?? '', fontSize: fontSize, height: rowH, bg: _grayCell),
          _sCell(item?.motivo ?? '', fontSize: fontSize, height: rowH),
        ]));
      }

      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: _totalBg),
        children: [
          _sCell('TOTAL', bold: true, fontSize: fontSize, bg: _totalBg),
          _sCell('', fontSize: fontSize, bg: _totalBg),
          _sCell('', fontSize: fontSize, bg: _totalBg),
          _sCell('', fontSize: fontSize, bg: _totalBg),
        ],
      ));

      return pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(3.2),
          1: const pw.FlexColumnWidth(1.1),
          2: const pw.FlexColumnWidth(0.9),
          3: const pw.FlexColumnWidth(1.2),
        },
        children: rows,
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: sideTable(
            title: titleLeft,
            startNum: 1,
            count: leftCount,
            itemOffset: 0,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: sideTable(
            title: titleRight,
            startNum: rightStart,
            count: rightCount,
            itemOffset: leftCount,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sCell(
    String text, {
    bool bold = false,
    double fontSize = 7,
    PdfColor? bg,
    bool alignLeft = false,
    double? height,
  }) {
    return pw.Container(
      color: bg,
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: 1,
      ),
    );
  }

  static pw.Widget _scrapMotivosFooter() {
    final entries = MotivosScrap.lista.entries.toList();
    final mid = (entries.length / 2).ceil();
    final left = entries.sublist(0, mid);
    final right = entries.sublist(mid);

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.5)),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CENTRO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
          pw.SizedBox(height: 2),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: left
                      .map((e) => pw.Text('${e.key} ${e.value}',
                          style: const pw.TextStyle(fontSize: 5)))
                      .toList(),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: right
                      .map((e) => pw.Text('${e.key} ${e.value}',
                          style: const pw.TextStyle(fontSize: 5)))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
