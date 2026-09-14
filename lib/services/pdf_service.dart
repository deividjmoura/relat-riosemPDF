import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rdp_report.dart';
import '../models/scrap_report.dart';
import '../utils/constants.dart';

class PdfService {
  static final _border = PdfColor.fromHex('#333333');
  static final _headerBg = PdfColor.fromHex('#E8E8E8');
  static final _learRed = PdfColor.fromHex('#E30613');
  static final _totalBg = PdfColor.fromHex('#F5F5F5');
  static final _grayCell = PdfColor.fromHex('#D0D0D0');

  // ===========================================================================
  // RDP
  // ===========================================================================
  static Future<void> generateRdpPdf(RdpReport report) async {
    final pdf = pw.Document();
    report.calcularTotais();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildRdpHeader(report),
              pw.SizedBox(height: 4),
              _buildRdpMainTable(report),
              pw.SizedBox(height: 4),
              _buildRdpFooter(report),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'RDP_${report.maquina}_${report.data}.pdf',
    );
  }

  static pw.Widget _buildRdpHeader(RdpReport report) {
    return pw.Column(
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.8)),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 22,
                        height: 22,
                        decoration: pw.BoxDecoration(color: _learRed, shape: pw.BoxShape.circle),
                        child: pw.Center(
                          child: pw.Text('L',
                              style: pw.TextStyle(
                                  color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text('LEAR',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11, color: _learRed)),
                      pw.SizedBox(width: 4),
                      pw.Text('CORPORATION', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(width: 16),
                      pw.Text('RDP - Relatório de Produção do Corte',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 90,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: _border, width: 0.6))),
                child: pw.Column(children: [
                  pw.Text('DATA', style: const pw.TextStyle(fontSize: 6)),
                  pw.Text(report.data,
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
              ),
              pw.Container(
                width: 70,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: _border, width: 0.6))),
                child: pw.Column(children: [
                  pw.Text('F QUA-E 054', style: const pw.TextStyle(fontSize: 6)),
                  pw.Text('Rev. 04', style: const pw.TextStyle(fontSize: 6)),
                ]),
              ),
            ],
          ),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _border, width: 0.8),
              right: pw.BorderSide(color: _border, width: 0.8),
              bottom: pw.BorderSide(color: _border, width: 0.8),
            ),
          ),
          child: pw.Row(children: [
            _headerField('MAQ', report.maquina, flex: 2),
            _headerField('OPERADOR', report.operador, flex: 4),
            _headerField('REG', report.reg, flex: 3),
            _headerField('Turno', report.turno, flex: 2),
            _headerField(
                'Horímetro Inicial', '${report.horaInicial}  ${report.horimetroInicial}', flex: 3),
            _headerField(
                'Horímetro Final', '${report.horaFinal}  ${report.horimetroFinal}', flex: 3),
            _headerField('Horímetro Total', report.horimetroTotal, flex: 2),
          ]),
        ),
      ],
    );
  }

  static pw.Widget _headerField(String label, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(color: _border, width: 0.4))),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 5.5)),
            pw.Text(value.isEmpty ? ' ' : value,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildRdpMainTable(RdpReport report) {
    final tm = TempoMortoCategories.list;
    final tp = TempoPerdidoCategories.list;
    final pp = ParadasProgramadasCategories.list;
    final scrap = ScrapRdpColumns.list;

    final dataRows = <pw.TableRow>[];
    const maxRows = 15;
    for (var i = 0; i < maxRows; i++) {
      if (i < report.linhas.length) {
        dataRows.add(_buildDataRow(i + 1, report.linhas[i], tm, tp, pp, scrap));
      } else {
        dataRows.add(_buildEmptyRow(i + 1, tm.length, tp.length, pp.length, scrap.length));
      }
    }
    dataRows.add(_buildTotalRow(report, tm, tp, pp, scrap));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: _columnWidths(tm.length, tp.length, pp.length, scrap.length),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        _buildGroupHeaderRow(),
        _buildColumnHeaderRow(),
        ...dataRows,
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> _columnWidths(int tm, int tp, int pp, int scrap) {
    final map = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(14),
      1: const pw.FixedColumnWidth(28),
      2: const pw.FixedColumnWidth(28),
      3: const pw.FixedColumnWidth(42),
      4: const pw.FixedColumnWidth(26),
      5: const pw.FixedColumnWidth(26),
      6: const pw.FixedColumnWidth(32),
    };
    int idx = 7;
    for (var i = 0; i < tm; i++) map[idx++] = const pw.FixedColumnWidth(16);
    for (var i = 0; i < tp; i++) map[idx++] = const pw.FixedColumnWidth(16);
    for (var i = 0; i < pp; i++) map[idx++] = const pw.FixedColumnWidth(16);
    for (var i = 0; i < scrap; i++) map[idx++] = const pw.FixedColumnWidth(18);
    map[idx] = const pw.FixedColumnWidth(22);
    return map;
  }

  static pw.TableRow _buildGroupHeaderRow() {
    final tmCount = TempoMortoCategories.list.length;
    final tpCount = TempoPerdidoCategories.list.length;
    final ppCount = ParadasProgramadasCategories.list.length;
    final scrapCount = ScrapRdpColumns.list.length;
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _headerBg),
      children: [
        for (var i = 0; i < 7; i++) _cell('', bold: true, fontSize: 5),
        for (var i = 0; i < tmCount; i++)
          _cell(i == 0 ? 'TM' : '', bold: true, fontSize: 6, bg: _headerBg),
        for (var i = 0; i < tpCount; i++)
          _cell(i == 0 ? 'TP' : '', bold: true, fontSize: 6, bg: _headerBg),
        for (var i = 0; i < ppCount; i++)
          _cell(i == 0 ? 'PP' : '', bold: true, fontSize: 6, bg: _headerBg),
        for (var i = 0; i < scrapCount; i++)
          _cell(i == 0 ? 'Scrap' : '', bold: true, fontSize: 5.5, bg: _headerBg),
        _cell('VISTO', bold: true, fontSize: 5.5, bg: _headerBg),
      ],
    );
  }

  static pw.TableRow _buildColumnHeaderRow() {
    final cells = <pw.Widget>[
      _cell('Seq', bold: true, fontSize: 5, bg: _headerBg),
      _cell('INÍCIO\nDA ATIV', bold: true, fontSize: 4.5, bg: _headerBg),
      _cell('TÉRMINO\nDA ATIV', bold: true, fontSize: 4.5, bg: _headerBg),
      _cell('PN DA PEÇA', bold: true, fontSize: 5, bg: _headerBg),
      _cell('Taxa\nPlanejada', bold: true, fontSize: 4.5, bg: _headerBg),
      _cell('Taxa\nReal', bold: true, fontSize: 4.5, bg: _headerBg),
      _cell('QUANTIDADE\nPEÇAS', bold: true, fontSize: 4.5, bg: _headerBg),
    ];
    // TM / TP / PP / Scrap — texto vertical como no formulário oficial
    for (final label in TempoMortoCategories.short) {
      cells.add(_vCell(label));
    }
    for (final label in TempoPerdidoCategories.short) {
      cells.add(_vCell(label));
    }
    for (final label in ParadasProgramadasCategories.short) {
      cells.add(_vCell(label));
    }
    for (final label in ScrapRdpColumns.short) {
      cells.add(_vCell(label));
    }
    cells.add(_cell('VISTO', bold: true, fontSize: 5, bg: _headerBg));
    return pw.TableRow(decoration: pw.BoxDecoration(color: _headerBg), children: cells);
  }

  static pw.TableRow _buildDataRow(
    int seq,
    RdpLine linha,
    List<String> tm,
    List<String> tp,
    List<String> pp,
    List<String> scrap,
  ) {
    final cells = <pw.Widget>[
      _cell('$seq', fontSize: 6),
      _cell(linha.inicioAtiv, fontSize: 6),
      _cell(linha.terminoAtiv, fontSize: 6),
      _cell(linha.pnPeca, fontSize: 6),
      _cell(linha.taxaPlanejada, fontSize: 6),
      _cell(linha.taxaReal, fontSize: 6),
      _cell(linha.quantidadePecas, fontSize: 6),
    ];
    for (final key in tm) {
      final v = linha.tempoMorto[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', fontSize: 6));
    }
    for (final key in tp) {
      final v = linha.tempoPerdido[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', fontSize: 6));
    }
    for (final key in pp) {
      final v = linha.paradasProgramadas[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', fontSize: 6));
    }
    for (final key in scrap) {
      final v = linha.scrap[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', fontSize: 6));
    }
    cells.add(_cell('', fontSize: 6));
    return pw.TableRow(children: cells);
  }

  static pw.TableRow _buildEmptyRow(int seq, int tm, int tp, int pp, int scrap) {
    final totalCols = 7 + tm + tp + pp + scrap + 1;
    return pw.TableRow(
      children: List.generate(totalCols, (i) {
        if (i == 0) return _cell('$seq', fontSize: 6);
        return _cell('', fontSize: 6);
      }),
    );
  }

  static pw.TableRow _buildTotalRow(
    RdpReport report,
    List<String> tm,
    List<String> tp,
    List<String> pp,
    List<String> scrap,
  ) {
    int totalQtd = 0;
    for (final l in report.linhas) {
      totalQtd += int.tryParse(l.quantidadePecas) ?? 0;
    }
    final cells = <pw.Widget>[
      _cell('', fontSize: 6, bg: _totalBg),
      _cell('', fontSize: 6, bg: _totalBg),
      _cell('', fontSize: 6, bg: _totalBg),
      _cell('TOTAL:', bold: true, fontSize: 6, bg: _totalBg),
      _cell('', fontSize: 6, bg: _totalBg),
      _cell('', fontSize: 6, bg: _totalBg),
      _cell(totalQtd > 0 ? '$totalQtd' : '', bold: true, fontSize: 6, bg: _totalBg),
    ];
    for (final key in tm) {
      final v = report.totaisTempoMorto[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', bold: true, fontSize: 6, bg: _totalBg));
    }
    for (final key in tp) {
      final v = report.totaisTempoPerdido[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', bold: true, fontSize: 6, bg: _totalBg));
    }
    for (final key in pp) {
      final v = report.totaisParadas[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', bold: true, fontSize: 6, bg: _totalBg));
    }
    for (final key in scrap) {
      final v = report.totaisScrap[key];
      cells.add(_cell(v != null && v > 0 ? '$v' : '', bold: true, fontSize: 6, bg: _totalBg));
    }
    cells.add(_cell('', fontSize: 6, bg: _totalBg));
    return pw.TableRow(children: cells);
  }

  static pw.Widget _buildRdpFooter(RdpReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.6)),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('OBSERVAÇÕES: ',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(report.observacoes.isEmpty ? ' ' : report.observacoes,
                    style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.6)),
          child: pw.Row(children: [
            _signBox('REABAST'),
            _signBox('LOG'),
            _signBox('MANUT'),
            _signBox('TI'),
            _signBox('ENG'),
            _signBox('QUALI'),
          ]),
        ),
        pw.SizedBox(height: 2),
        pw.Text('F QUA-E 054 - Relatório de Produção do Corte - 16-06-26',
            style: const pw.TextStyle(fontSize: 5)),
      ],
    );
  }

  static pw.Widget _signBox(String label) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: pw.BoxDecoration(
            border: pw.Border(right: pw.BorderSide(color: _border, width: 0.4))),
        child: pw.Column(children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('_______', style: const pw.TextStyle(fontSize: 7)),
        ]),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, double fontSize = 7, PdfColor? bg}) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 1.5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 3,
      ),
    );
  }

  /// Célula com texto vertical (como no formulário oficial)
  static pw.Widget _vCell(String text, {double height = 55, PdfColor? bg}) {
    return pw.Container(
      color: bg ?? _headerBg,
      height: height,
      alignment: pw.Alignment.center,
      child: pw.Transform.rotateBox(
        angle: -math.pi / 2,
        child: pw.Container(
          width: height - 2,
          alignment: pw.Alignment.center,
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 4.2, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 4,
          ),
        ),
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
              // TERMINAL (duas colunas: 1-15 | 16-30)
              _scrapSectionDual(
                titleLeft: 'TERMINAL',
                titleRight: 'TERMINAL',
                items: report.terminais,
                leftCount: 15,
                rightStart: 16,
                rightCount: 15,
              ),
              pw.SizedBox(height: 6),
              // SELO (duas colunas: 1-7 | 1-7)
              _scrapSectionDual(
                titleLeft: 'SELO',
                titleRight: 'SELO',
                items: report.selos,
                leftCount: 7,
                rightStart: 1,
                rightCount: 7,
              ),
              pw.SizedBox(height: 6),
              // CABO (duas colunas: 1-23 | 1-23)
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

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Scrap_${report.maquina}_${report.data}.pdf',
    );
  }

  static pw.Widget _scrapTopHeader(ScrapReport report) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _border, width: 0.8)),
      child: pw.Column(
        children: [
          // Título
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
          // Linha 1
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
                _scrapFieldCell('Nome do líder:', report.nomeLider, colSpanHint: true),
                _scrapFieldCell('', ''),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _scrapFieldCell(String label, String value, {bool colSpanHint = false}) {
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

  /// Seção com duas tabelas lado a lado (como no formulário oficial)
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
        // header
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
            item != null && item.terminal.isNotEmpty
                ? '$num  ${item.terminal}'
                : '$num',
            fontSize: fontSize,
            alignLeft: true,
            height: rowH,
          ),
          _sCell(item?.quantidade ?? '', fontSize: fontSize, height: rowH, bg: _grayCell),
          _sCell(item?.total ?? '', fontSize: fontSize, height: rowH, bg: _grayCell),
          _sCell(item?.motivo ?? '', fontSize: fontSize, height: rowH),
        ]));
      }

      // linha TOTAL
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
