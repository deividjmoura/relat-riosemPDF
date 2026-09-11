import 'package:flutter/material.dart';
import '../../models/rdp_report.dart';
import '../../services/pdf_service.dart';
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

  @override
  void dispose() {
    _maquinaCtrl.dispose();
    _operadorCtrl.dispose();
    _regCtrl.dispose();
    _turnoCtrl.dispose();
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
            // Aqui você distribui os minutos nas colunas da última linha ou cria uma nova
            if (report.linhas.isNotEmpty) {
              final last = report.linhas.last;
              minutosPorCategoria.forEach((categoria, minutos) {
                // Decide se é TM, TP ou PP conforme a categoria
                if (categoria.contains('Manutenção') || categoria.contains('Espera')) {
                  last.tempoPerdido[categoria] = (last.tempoPerdido[categoria] ?? 0) + minutos;
                } else if (categoria.contains('Limpeza') || categoria.contains('Intervalo')) {
                  last.paradasProgramadas[categoria] = (last.paradasProgramadas[categoria] ?? 0) + minutos;
                } else {
                  last.tempoMorto[categoria] = (last.tempoMorto[categoria] ?? 0) + minutos;
                }
              });
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Future<void> _gerarPdf() async {
    report.maquina = _maquinaCtrl.text;
    report.operador = _operadorCtrl.text;
    report.reg = _regCtrl.text;
    report.turno = _turnoCtrl.text;
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('Linhas de Setup (${report.linhas.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...report.linhas.map((linha) => Card(
                child: ListTile(
                  title: Text('PN: ${linha.pnPeca}'),
                  subtitle: Text('Qtd: ${linha.quantidadePecas} | ${linha.inicioAtiv} → ${linha.terminoAtiv}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => report.linhas.remove(linha));
                    },
                  ),
                ),
              )),

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
