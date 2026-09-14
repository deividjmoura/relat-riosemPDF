import 'package:flutter/material.dart';
import '../../models/rdp_report.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import 'rdp_setup_dialog.dart';
import 'rdp_timers_screen.dart';

class RdpFormScreen extends StatefulWidget {
  const RdpFormScreen({super.key});

  @override
  State<RdpFormScreen> createState() => _RdpFormScreenState();
}

class _RdpFormScreenState extends State<RdpFormScreen> {
  final RdpReport report = RdpReport(
    data: DateTime.now().toString().substring(0, 10),
  );

  final _maquinaCtrl = TextEditingController();
  final _operadorCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _turnoCtrl = TextEditingController();
  final _horaInicialCtrl = TextEditingController();
  final _horaFinalCtrl = TextEditingController();
  final _horimetroInicialCtrl = TextEditingController();
  final _horimetroFinalCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  @override
  void dispose() {
    _maquinaCtrl.dispose();
    _operadorCtrl.dispose();
    _regCtrl.dispose();
    _turnoCtrl.dispose();
    _horaInicialCtrl.dispose();
    _horaFinalCtrl.dispose();
    _horimetroInicialCtrl.dispose();
    _horimetroFinalCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _addSetup() async {
    final linha = await showDialog<RdpLine>(
      context: context,
      builder: (_) => const RdpSetupDialog(),
    );
    if (linha != null) {
      setState(() {
        report.linhas.add(linha);
      });
    }
  }

  void _openTimers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RdpTimersScreen(
          onTimersFinished: (Map<String, int> minutosPorCategoria) {
            if (report.linhas.isEmpty) return;

            final last = report.linhas.last;
            minutosPorCategoria.forEach((reason, minutos) {
              if (minutos <= 0) return;
              final key = TimerCategoryMapper.canonicalKey(reason);
              final group = TimerCategoryMapper.groupFor(reason);

              switch (group) {
                case 'TP':
                  last.tempoPerdido[key] = (last.tempoPerdido[key] ?? 0) + minutos;
                  break;
                case 'PP':
                  last.paradasProgramadas[key] =
                      (last.paradasProgramadas[key] ?? 0) + minutos;
                  break;
                case 'TM':
                default:
                  last.tempoMorto[key] = (last.tempoMorto[key] ?? 0) + minutos;
                  break;
              }
            });
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _gerarPdf() async {
    report.maquina = _maquinaCtrl.text.trim();
    report.operador = _operadorCtrl.text.trim();
    report.reg = _regCtrl.text.trim();
    report.turno = _turnoCtrl.text.trim();
    report.horaInicial = _horaInicialCtrl.text.trim();
    report.horaFinal = _horaFinalCtrl.text.trim();
    report.horimetroInicial = _horimetroInicialCtrl.text.trim();
    report.horimetroFinal = _horimetroFinalCtrl.text.trim();
    report.observacoes = _observacoesCtrl.text.trim();

    // Calcula horímetro total se possível
    final hi = int.tryParse(report.horimetroInicial);
    final hf = int.tryParse(report.horimetroFinal);
    if (hi != null && hf != null && hf >= hi) {
      report.horimetroTotal = '${hf - hi}';
    }

    report.calcularTotais();
    await PdfService.generateRdpPdf(report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RDP - Produção'),
        backgroundColor: const Color(0xFFE30613),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: report.linhas.isEmpty ? null : _gerarPdf,
            tooltip: 'Gerar PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _maquinaCtrl,
                    decoration: const InputDecoration(labelText: 'Máquina (MAQ)'),
                  ),
                  TextField(
                    controller: _operadorCtrl,
                    decoration: const InputDecoration(labelText: 'Operador'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _regCtrl,
                          decoration: const InputDecoration(labelText: 'REG'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _turnoCtrl,
                          decoration: const InputDecoration(labelText: 'Turno'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaInicialCtrl,
                          decoration: const InputDecoration(labelText: 'Hora Inicial'),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _horimetroInicialCtrl,
                          decoration: const InputDecoration(labelText: 'Horímetro Inicial'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaFinalCtrl,
                          decoration: const InputDecoration(labelText: 'Hora Final'),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _horimetroFinalCtrl,
                          decoration: const InputDecoration(labelText: 'Horímetro Final'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _observacoesCtrl,
                    decoration: const InputDecoration(labelText: 'Observações'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Linhas de Setup (${report.linhas.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...report.linhas.map((linha) {
            final tmTotal = linha.tempoMorto.values.fold(0, (a, b) => a + b);
            final tpTotal = linha.tempoPerdido.values.fold(0, (a, b) => a + b);
            final ppTotal = linha.paradasProgramadas.values.fold(0, (a, b) => a + b);
            return Card(
              child: ListTile(
                title: Text('PN: ${linha.pnPeca}'),
                subtitle: Text(
                  'Qtd: ${linha.quantidadePecas} | ${linha.inicioAtiv} → ${linha.terminoAtiv}\n'
                  'TM: ${tmTotal}min  TP: ${tpTotal}min  PP: ${ppTotal}min',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => report.linhas.remove(linha));
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addSetup,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Setup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: report.linhas.isEmpty ? null : _openTimers,
            icon: const Icon(Icons.timer),
            label: const Text('Abrir Cronômetros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: report.linhas.isEmpty ? null : _gerarPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Finalizar e Gerar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE30613),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
