import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rdp_report.dart';
import '../models/scrap_report.dart';

class PdfService {
  /// Gera o PDF do RDP no formato mais próximo possível do formulário oficial
  static Future<void> generateRdpPdf(RdpReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Cabeçalho
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('LEAR CORPORATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('RDP - Relatório de Produção do Corte', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('DATA: ${report.data}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 8),

          // Dados da máquina / operador
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                _cell('MAQ: ${report.maquina}'),
                _cell('OPERADOR: ${report.operador}'),
                _cell('REG: ${report.reg}'),
                _cell('TURNO: ${report.turno}'),
              ]),
            ],
          ),
          pw.SizedBox(height: 10),

          // Tabela principal (simplificada – será refinada)
          pw.Text('Linhas de produção:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...report.linhas.map((linha) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PN: ${linha.pnPeca} | Início: ${linha.inicioAtiv} | Término: ${linha.terminoAtiv}'),
                  pw.Text('Qtd: ${linha.quantidadePecas} | Taxa Plan: ${linha.taxaPlanejada} | Taxa Real: ${linha.taxaReal}'),
                  if (linha.tempoMorto.isNotEmpty)
                    pw.Text('TM: ${linha.tempoMorto.entries.map((e) => "${e.key}:${e.value}").join(" | ")}'),
                  if (linha.tempoPerdido.isNotEmpty)
                    pw.Text('TP: ${linha.tempoPerdido.entries.map((e) => "${e.key}:${e.value}").join(" | ")}'),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 12),
          pw.Text('Observações: ${report.observacoes}'),
          pw.SizedBox(height: 20),
          pw.Text('Assinaturas: ________________ / ________________', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// Gera o PDF do Scrap
  static Future<void> generateScrapPdf(ScrapReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Text('LEAR CORPORATION', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('REGISTRO DE SCRAP - ÁREA CORTE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Máquina: ${report.maquina} | Centro: ${report.centro} | Turno: ${report.turno} | Data: ${report.data}'),
          pw.Text('Operador: ${report.operador} | Líder: ${report.nomeLider} | Matrícula: ${report.matricula}'),
          pw.SizedBox(height: 12),

          _buildScrapSection('TERMINAL', report.terminais),
          pw.SizedBox(height: 10),
          _buildScrapSection('SELO', report.selos),
          pw.SizedBox(height: 10),
          _buildScrapSection('CABO', report.cabos),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );

  static pw.Widget _buildScrapSection(String titulo, List<ScrapItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              _cell('Código / Terminal'),
              _cell('Qtd'),
              _cell('Total'),
              _cell('Motivo'),
            ]),
            ...items.map((item) => pw.TableRow(children: [
                  _cell(item.terminal),
                  _cell(item.quantidade),
                  _cell(item.total),
                  _cell(item.motivo),
                ])),
          ],
        ),
      ],
    );
  }
}
