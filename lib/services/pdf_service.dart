import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rdp_report.dart';
import '../models/scrap_report.dart';
import '../utils/constants.dart';

class PdfService {
  // Cores aproximadas do formulário
  static final _border = PdfColor.fromHex('#333333');
  static final _headerBg = PdfColor.fromHex('#E8E8E8');
  static final _learRed = PdfColor.fromHex('#E30613');
  static final _totalBg = PdfColor.fromHex('#F5F5F5');

  /// Gera o PDF do RDP no formato o mais próximo possível de F QUA-E 054 Rev.04
  static Future<void> generateRdpPdf(RdpReport report) async {
    final pdf = pw.Document();

    // Garante totais atualizados
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

  // ---------------------------------------------------------------------------
  // CABEÇALHO
  // ---------------------------------------------------------------------------
  static pw.Widget _buildRdpHeader(RdpReport report) {
    return pw.Column(
      children: [
        // Linha superior: título + data + código do formulário
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.8),
          ),
          child: pw.Row(
            children: [
              // Logo + título
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 22,
                        height: 22,
                        decoration: pw.BoxDecoration(
                          color: _learRed,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'L',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        'LEAR',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: _learRed,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Text(
                        'CORPORATION',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        'RDP - Relatório de Produção do Corte',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Data
              pw.Container(
                width: 90,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: _border, width: 0.6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('DATA', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text(report.data, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              // Código do formulário
              pw.Container(
                width: 70,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: _border, width: 0.6)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('F QUA-E 054', style: const pw.TextStyle(fontSize: 6)),
                    pw.Text('Rev. 04', style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Linha de dados da máquina / operador / horímetro
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _border, width: 0.8),
              right: pw.BorderSide(color: _border, width: 0.8),
              bottom: pw.BorderSide(color: _border, width: 0.8),
            ),
          ),
          child: pw.Row(
            children: [
              _headerField('MAQ', report.maquina, flex: 2),
              _headerField('OPERADOR', report.operador, flex: 4),
              _headerField('REG', report.reg, flex: 3),
              _headerField('Turno', report.turno, flex: 2),
              _headerField('Horímetro Inicial', '${report.horaInicial}  ${report.horimetroInicial}', flex: 3),
              _headerField('Horímetro Final', '${report.horaFinal}  ${report.horimetroFinal}', flex: 3),
              _headerField('Horímetro Total', report.horimetroTotal, flex: 2),
            ],
          ),
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
          border: pw.Border(right: pw.BorderSide(color: _border, width: 0.4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 5.5)),
            pw.Text(
              value.isEmpty ? ' ' : value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABELA PRINCIPAL
  // ---------------------------------------------------------------------------
  static pw.Widget _buildRdpMainTable(RdpReport report) {
    final tm = TempoMortoCategories.list;
    final tp = TempoPerdidoCategories.list;
    final pp = ParadasProgramadasCategories.list;
    final scrap = ScrapRdpColumns.list;

    // Larguras relativas (aproximação do formulário)
    // Seq + Início + Término + PN + TaxaPlan + TaxaReal + Qtd = 7 colunas fixas
    // + 10 TM + 8 TP + 8 PP + 5 Scrap + Visto = 38 colunas de dados + 7 fixas

    final headerRow1 = _buildGroupHeaderRow();
    final headerRow2 = _buildColumnHeaderRow();

    final dataRows = <pw.TableRow>[];
    final maxRows = 15; // formulário tem ~15 linhas

    for (var i = 0; i < maxRows; i++) {
      if (i < report.linhas.length) {
        dataRows.add(_buildDataRow(i + 1, report.linhas[i], tm, tp, pp, scrap));
      } else {
        dataRows.add(_buildEmptyRow(i + 1, tm.length, tp.length, pp.length, scrap.length));
      }
    }

    // Linha de TOTAL
    dataRows.add(_buildTotalRow(report, tm, tp, pp, scrap));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: _columnWidths(tm.length, tp.length, pp.length, scrap.length),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        headerRow1,
        headerRow2,
        ...dataRows,
      ],
    );
  }

  static Map<int, pw.TableColumnWidth> _columnWidths(int tm, int tp, int pp, int scrap) {
    // Índices: 0=Seq, 1=Início, 2=Término, 3=PN, 4=TaxaP, 5=TaxaR, 6=Qtd,
    // depois TM, TP, PP, Scrap, Visto
    final map = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(14), // Seq
      1: const pw.FixedColumnWidth(28), // Início
      2: const pw.FixedColumnWidth(28), // Término
      3: const pw.FixedColumnWidth(42), // PN
      4: const pw.FixedColumnWidth(26), // Taxa Plan
      5: const pw.FixedColumnWidth(26), // Taxa Real
      6: const pw.FixedColumnWidth(32), // Qtd
    };
    int idx = 7;
    for (var i = 0; i < tm; i++) {
      map[idx++] = const pw.FixedColumnWidth(16);
    }
    for (var i = 0; i < tp; i++) {
      map[idx++] = const pw.FixedColumnWidth(16);
    }
    for (var i = 0; i < pp; i++) {
      map[idx++] = const pw.FixedColumnWidth(16);
    }
    for (var i = 0; i < scrap; i++) {
      map[idx++] = const pw.FixedColumnWidth(18);
    }
    map[idx] = const pw.FixedColumnWidth(22); // Visto
    return map;
  }

  static pw.TableRow _buildGroupHeaderRow() {
    final tmCount = TempoMortoCategories.list.length;
    final tpCount = TempoPerdidoCategories.list.length;
    final ppCount = ParadasProgramadasCategories.list.length;
    final scrapCount = ScrapRdpColumns.list.length;

    pw.Widget groupCell(String text, int span, {PdfColor? bg}) {
      return pw.Container(
        color: bg ?? _headerBg,
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    // Como Table do pdf não tem colspan nativo de forma simples,
    // usamos uma linha com células mescladas via containers de largura proporcional.
    // Abordagem prática: uma única célula por grupo com texto centrado.
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _headerBg),
      children: [
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        _cell('', bold: true, fontSize: 5),
        // TM
        for (var i = 0; i < tmCount; i++)
          _cell(i == 0 ? 'Tempo Morto (TM)' : '', bold: true, fontSize: 5.5, bg: _headerBg),
        // TP
        for (var i = 0; i < tpCount; i++)
          _cell(i == 0 ? 'Tempo Perdido (TP)' : '', bold: true, fontSize: 5.5, bg: _headerBg),
        // PP
        for (var i = 0; i < ppCount; i++)
          _cell(i == 0 ? 'Paradas Programadas (PP)' : '', bold: true, fontSize: 5.5, bg: _headerBg),
        // Scrap
        for (var i = 0; i < scrapCount; i++)
          _cell(i == 0 ? 'Scrap' : '', bold: true, fontSize: 5.5, bg: _headerBg),
        _cell('VISTO', bold: true, fontSize: 5.5, bg: _headerBg),
      ],
    );
  }

  static pw.TableRow _buildColumnHeaderRow() {
    final cells = <pw.Widget>[
      _cell('Seq', bold: true, fontSize: 5),
      _cell('INÍCIO\nDA ATIV', bold: true, fontSize: 4.5),
      _cell('TÉRMINO\nDA ATIV', bold: true, fontSize: 4.5),
      _cell('PN DA PEÇA', bold: true, fontSize: 5),
      _cell('Taxa\nPlanejada', bold: true, fontSize: 4.5),
      _cell('Taxa\nReal', bold: true, fontSize: 4.5),
      _cell('QUANTIDADE\nPEÇAS', bold: true, fontSize: 4.5),
    ];

    // TM short labels
    for (final label in TempoMortoCategories.short) {
      cells.add(_cell(label, bold: true, fontSize: 3.8));
    }
    // TP
    for (final label in TempoPerdidoCategories.short) {
      cells.add(_cell(label, bold: true, fontSize: 3.8));
    }
    // PP
    for (final label in ParadasProgramadasCategories.short) {
      cells.add(_cell(label, bold: true, fontSize: 3.8));
    }
    // Scrap
    for (final label in ScrapRdpColumns.short) {
      cells.add(_cell(label, bold: true, fontSize: 3.8));
    }
    cells.add(_cell('', bold: true, fontSize: 5)); // Visto

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: _headerBg),
      children: cells,
    );
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
    cells.add(_cell('', fontSize: 6)); // Visto (assinatura manual)

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
    // Soma quantidade de peças
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

  // ---------------------------------------------------------------------------
  // RODAPÉ (observações + assinaturas)
  // ---------------------------------------------------------------------------
  static pw.Widget _buildRdpFooter(RdpReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Observações
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.6),
          ),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('OBSERVAÇÕES: ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(
                  report.observacoes.isEmpty ? ' ' : report.observacoes,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        // Caixas de assinatura / totais por área
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _border, width: 0.6),
          ),
          child: pw.Row(
            children: [
              _signBox('REABAST'),
              _signBox('LOG'),
              _signBox('MANUT'),
              _signBox('TI'),
              _signBox('ENG'),
              _signBox('QUALI'),
            ],
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'F QUA-E 054 - Relatório de Produção do Corte - 16-06-26',
          style: const pw.TextStyle(fontSize: 5),
          textAlign: pw.TextAlign.left,
        ),
      ],
    );
  }

  static pw.Widget _signBox(String label) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border(right: pw.BorderSide(color: _border, width: 0.4)),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('_______', style: const pw.TextStyle(fontSize: 7)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    double fontSize = 7,
    PdfColor? bg,
  }) {
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

  // ===========================================================================
  // PDF SCRAP (mantido + pequeno aprimoramento)
  // ===========================================================================
  static Future<void> generateScrapPdf(ScrapReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          // Cabeçalho
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(children: [
                        pw.Container(
                          width: 18,
                          height: 18,
                          decoration: pw.BoxDecoration(color: _learRed, shape: pw.BoxShape.circle),
                          child: pw.Center(
                            child: pw.Text('L', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text('LEAR', style: pw.TextStyle(color: _learRed, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ]),
                      pw.Text('REGISTRO DE SCRAP - ÁREA CORTE',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Column(children: [
                        pw.Text('F QUA-E 102', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('Rev. 04', style: const pw.TextStyle(fontSize: 7)),
                      ]),
                    ],
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(children: [
                      _scrapHeaderCell('Máquina: ${report.maquina}'),
                      _scrapHeaderCell('Centro: ${report.centro}'),
                      _scrapHeaderCell('Turno: ${report.turno}'),
                      _scrapHeaderCell('Data: ${report.data}'),
                    ]),
                    pw.TableRow(children: [
                      _scrapHeaderCell('Matrícula: ${report.matricula}'),
                      _scrapHeaderCell('Operador: ${report.operador}'),
                      _scrapHeaderCell('Nome do líder: ${report.nomeLider}', span: 2),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          _buildScrapSection('TERMINAL', report.terminais),
          pw.SizedBox(height: 8),
          _buildScrapSection('SELO', report.selos),
          pw.SizedBox(height: 8),
          _buildScrapSection('CABO', report.cabos),
          pw.SizedBox(height: 12),
          pw.Text('CENTRO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.SizedBox(height: 4),
          _buildMotivosList(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Scrap_${report.maquina}_${report.data}.pdf',
    );
  }

  static pw.Widget _scrapHeaderCell(String text, {int span = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _buildScrapSection(String titulo, List<ScrapItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _headerBg),
              children: [
                _cell('Código / Terminal', bold: true, fontSize: 7),
                _cell('Qtd', bold: true, fontSize: 7),
                _cell('Total', bold: true, fontSize: 7),
                _cell('Motivo', bold: true, fontSize: 7),
              ],
            ),
            ...items.map((item) => pw.TableRow(children: [
                  _cell(item.terminal, fontSize: 7),
                  _cell(item.quantidade, fontSize: 7),
                  _cell(item.total, fontSize: 7),
                  _cell(item.motivo, fontSize: 7),
                ])),
            // linhas vazias para ficar parecido com o formulário
            if (items.length < 5)
              for (var i = items.length; i < 5; i++)
                pw.TableRow(children: [
                  _cell(' ', fontSize: 7),
                  _cell(' ', fontSize: 7),
                  _cell(' ', fontSize: 7),
                  _cell(' ', fontSize: 7),
                ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMotivosList() {
    final entries = MotivosScrap.lista.entries.toList();
    final mid = (entries.length / 2).ceil();
    final left = entries.sublist(0, mid);
    final right = entries.sublist(mid);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: left
                .map((e) => pw.Text('${e.key} ${e.value}', style: const pw.TextStyle(fontSize: 5.5)))
                .toList(),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: right
                .map((e) => pw.Text('${e.key} ${e.value}', style: const pw.TextStyle(fontSize: 5.5)))
                .toList(),
          ),
        ),
      ],
    );
  }
}
