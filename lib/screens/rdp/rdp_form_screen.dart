import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/rdp_report.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../services/timer_service.dart';
import '../../utils/constants.dart';
import '../../utils/input_helpers.dart';
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

  late final TextEditingController _dataCtrl;
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
  final _database = DatabaseService.instance;
  bool _loadingDraft = true;
  bool _gerandoPdf = false;

  @override
  void initState() {
    super.initState();
    _dataCtrl = TextEditingController(text: report.data);
    _timerService.addListener(_onTimersChanged);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final saved = await _database.getRdpDraft();
    if (!mounted) return;

    if (saved != null) {
      report.data = saved.data;
      report.maquina = saved.maquina;
      report.operador = saved.operador;
      report.reg = saved.reg;
      report.turno = saved.turno;
      report.horaInicial = saved.horaInicial;
      report.horaFinal = saved.horaFinal;
      report.horimetroInicial = saved.horimetroInicial;
      report.horimetroFinal = saved.horimetroFinal;
      report.horimetroTotal = saved.horimetroTotal;
      report.observacoes = saved.observacoes;
      report.linhas = saved.linhas;

      _dataCtrl.text = report.data;
      _maquinaCtrl.text = report.maquina;
      _operadorCtrl.text = report.operador;
      _regCtrl.text = report.reg;
      _turnoCtrl.text = report.turno;
      _horaInicialCtrl.text = report.horaInicial;
      _horaFinalCtrl.text = report.horaFinal;
      _horimetroInicialCtrl.text = report.horimetroInicial;
      _horimetroFinalCtrl.text = report.horimetroFinal;
      _observacoesCtrl.text = report.observacoes;
    }

    setState(() => _loadingDraft = false);
  }

  Future<void> _saveDraft() async {
    if (_loadingDraft) return;
    await _database.saveRdpDraft(report);
  }

  void _onTimersChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimersChanged);
    _dataCtrl.dispose();
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

  void _syncHeader() {
    report.data = _dataCtrl.text.trim();
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
  }

  Future<void> _headerChanged(String _) async {
    _syncHeader();
    await _saveDraft();
  }

  Future<void> _addSetup() async {
    final linha = await showDialog<RdpLine>(
      context: context,
      builder: (_) => const RdpSetupDialog(),
    );
    if (linha != null) {
      setState(() => report.linhas.add(linha));
      await _saveDraft();
    }
  }

  Future<void> _editSetup(RdpLine linha) async {
    final updated = await showDialog<RdpLine>(
      context: context,
      builder: (_) => RdpSetupDialog(existing: linha),
    );
    if (updated != null) {
      setState(() {});
      await _saveDraft();
    }
  }

  Future<void> _applyMinutes(String setupId, String reason, int minutes) async {
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
    await _saveDraft();
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
    if (_gerandoPdf) return;

    setState(() => _gerandoPdf = true);
    try {
      _syncHeader();
      await _saveDraft();
      report.calcularTotais();
      await PdfService.generateRdpPdf(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF do RDP gerado com sucesso.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('ERRO AO GERAR PDF DO RDP: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $error'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'FECHAR',
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
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
            icon: _gerandoPdf
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _gerandoPdf ? null : _gerarPdf,
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
                    controller: _dataCtrl,
                    readOnly: true,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await pickDate(context, initial: _dataCtrl.text);
                      if (picked != null) {
                        setState(() => _dataCtrl.text = picked);
                        await _headerChanged(picked);
                      }
                    },
                  ),
                  TextField(
                    controller: _maquinaCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Máquina (MAQ)'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  TextField(
                    controller: _operadorCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Operador'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _regCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'REG'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _turnoCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'Turno'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
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
                          readOnly: true,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(
                            labelText: 'Hora Inicial',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final t = await pickTime(context, initial: _horaInicialCtrl.text);
                            if (t != null) {
                              setState(() => _horaInicialCtrl.text = t);
                              await _headerChanged(t);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _horimetroInicialCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'Horímetro Inicial'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _horaFinalCtrl,
                          readOnly: true,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(
                            labelText: 'Hora Final',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final t = await pickTime(context, initial: _horaFinalCtrl.text);
                            if (t != null) {
                              setState(() => _horaFinalCtrl.text = t);
                              await _headerChanged(t);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _horimetroFinalCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'Horímetro Final'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _observacoesCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Observações'),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Linhas de Setup (${report.linhas.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Toque em um setup para editar (hora de término, qtd, etc.)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          ...report.linhas.map((linha) {
            final tmTotal = linha.tempoMorto.values.fold(0, (a, b) => a + b);
            final tpTotal = linha.tempoPerdido.values.fold(0, (a, b) => a + b);
            final ppTotal = linha.paradasProgramadas.values.fold(0, (a, b) => a + b);
            return Card(
              child: ListTile(
                onTap: () => _editSetup(linha),
                title: Text('PN: ${linha.pnPeca}'),
                subtitle: Text('Qtd: ${linha.quantidadePecas.isEmpty ? "–" : linha.quantidadePecas}  |  ${linha.inicioAtiv.isEmpty ? "??:??" : linha.inicioAtiv} → ${linha.terminoAtiv.isEmpty ? "??:??" : linha.terminoAtiv}\nTM: ${tmTotal}min  TP: ${tpTotal}min  PP: ${ppTotal}min'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editSetup(linha)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () async {
                        setState(() => report.linhas.remove(linha));
                        await _saveDraft();
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: report.linhas.isEmpty ? null : _openTimers,
            icon: Badge(isLabelVisible: running > 0, label: Text('$running'), child: const Icon(Icons.timer)),
            label: Text(running > 0 ? 'Cronômetros ($running ativos)' : 'Abrir Cronômetros'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _gerandoPdf ? null : _gerarPdf,
            icon: _gerandoPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_gerandoPdf ? 'Gerando PDF...' : 'Finalizar e Gerar PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE30613), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}