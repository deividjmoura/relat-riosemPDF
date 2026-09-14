import 'package:flutter/material.dart';
import '../../models/rdp_report.dart';
import '../../services/pdf_service.dart';
import '../../services/timer_service.dart';
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

  final _timerService = TimerService.instance;

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onTimersChanged);
  }

  void _onTimersChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimersChanged);
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

  Future<void> _addSetup() async {
    final linha = await showDialog<RdpLine>(
      context: context,
      builder: (_) => const RdpSetupDialog(),
    );
    if (linha != null) {
      setState(() => report.linhas.add(linha));
    }
  }

  Future<void> _editSetup(RdpLine linha) async {
    final updated = await showDialog<RdpLine>(
      context: context,
      builder: (_) => RdpSetupDialog(existing: linha),
    );
    if (updated != null) {
      setState(() {}); // já mutou o objeto
    }
  }

  void _applyMinutes(String setupId, String reason, int minutes) {
    final linha = report.linhas.cast<RdpLine?>().firstWhere(
          (l) => l!.id == setupId,
          orElse: () => null,
        );
    if (linha == null) return;

    final key = TimerCategoryMapper.canonicalKey(reason);
    final group = TimerCategoryMapper.groupFor(reason);

    switch (group) {
      case 'TP':
        linha.tempoPerdido[key] = (linha.tempoPerdido[key] ?? 0) + minutes;
        break;
      case 'PP':
        linha.paradasProgramadas[key] =
            (linha.paradasProgramadas[key] ?? 0) + minutes;
        break;
      case 'TM':
      default:
        linha.tempoMorto[key] = (linha.tempoMorto[key] ?? 0) + minutes;
        break;
    }
    setState(() {});
  }

  void _openTimers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RdpTimersScreen(
          setups: report.linhas,
          onApplyMinutes: _applyMinutes,
        ),
      ),
    ).then((_) => setState(() {}));
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
    final running = _timerService.runningCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RDP - Produção'),
        backgroundColor: const Color(0xFFE30613),
        foregroundColor: Colors.white,
        actions: [
          if (running > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.timer, size: 16, color: Colors.white),
                  label: Text('$running', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.orange.shade800,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
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
                          decoration:
                              const InputDecoration(labelText: 'Horímetro Inicial'),
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
                          decoration:
                              const InputDecoration(labelText: 'Horímetro Final'),
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
          const SizedBox(height: 4),
          const Text(
            'Toque em um setup para editar (hora de término, qtd, etc.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          ...report.linhas.map((linha) {
            final tmTotal = linha.tempoMorto.values.fold(0, (a, b) => a + b);
            final tpTotal = linha.tempoPerdido.values.fold(0, (a, b) => a + b);
            final ppTotal =
                linha.paradasProgramadas.values.fold(0, (a, b) => a + b);
            return Card(
              child: ListTile(
                onTap: () => _editSetup(linha),
                title: Text('PN: ${linha.pnPeca}'),
                subtitle: Text(
                  'Qtd: ${linha.quantidadePecas.isEmpty ? "–" : linha.quantidadePecas}'
                  '  |  ${linha.inicioAtiv.isEmpty ? "??:??" : linha.inicioAtiv}'
                  ' → ${linha.terminoAtiv.isEmpty ? "??:??" : linha.terminoAtiv}\n'
                  'TM: ${tmTotal}min  TP: ${tpTotal}min  PP: ${ppTotal}min',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editSetup(linha),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        setState(() => report.linhas.remove(linha));
                      },
                    ),
                  ],
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
            icon: Badge(
              isLabelVisible: running > 0,
              label: Text('$running'),
              child: const Icon(Icons.timer),
            ),
            label: Text(running > 0
                ? 'Cronômetros ($running ativos)'
                : 'Abrir Cronômetros'),
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
