import 'package:flutter/material.dart';
import '../../models/rdp_report.dart';
import '../../models/timer_entry.dart';
import '../../services/timer_service.dart';
import '../../widgets/stop_reason_dialog.dart';

class RdpTimersScreen extends StatefulWidget {
  final List<RdpLine> setups;

  /// Chamado quando o usuário aplica minutos pendentes a um setup
  final void Function(String setupId, String reason, int minutes) onApplyMinutes;

  const RdpTimersScreen({
    super.key,
    required this.setups,
    required this.onApplyMinutes,
  });

  @override
  State<RdpTimersScreen> createState() => _RdpTimersScreenState();
}

class _RdpTimersScreenState extends State<RdpTimersScreen> {
  final _service = TimerService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onTick);
  }

  @override
  void dispose() {
    _service.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _startNewTimer() async {
    if (widget.setups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um setup antes')),
      );
      return;
    }

    // 1) Escolher setup
    final setup = await showDialog<RdpLine>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Para qual setup?'),
        children: widget.setups
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Text(
                    'PN: ${s.pnPeca.isEmpty ? "(sem PN)" : s.pnPeca}'
                    '${s.inicioAtiv.isNotEmpty ? "  ·  ${s.inicioAtiv}" : ""}',
                  ),
                ))
            .toList(),
      ),
    );
    if (setup == null) return;

    // 2) Escolher motivo
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const StopReasonDialog(),
    );
    if (reason == null) return;

    _service.start(
      reason: reason,
      setupId: setup.id,
      setupPn: setup.pnPeca,
    );
  }

  Future<void> _stopTimer(TimerEntry timer) async {
    _service.stop(timer.id);
    // Aplica automaticamente se já tinha setup vinculado
    await _flushPending();
  }

  Future<void> _flushPending() async {
    final pending = List.of(_service.pending);
    for (final p in pending) {
      String? setupId = p.setupId;

      // Se não tem setup, pergunta
      if (setupId == null || setupId.isEmpty) {
        final setup = await showDialog<RdpLine>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text('Aplicar ${p.minutes} min de "${p.reason}" em qual setup?'),
            children: widget.setups
                .map((s) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, s),
                      child: Text('PN: ${s.pnPeca.isEmpty ? "(sem PN)" : s.pnPeca}'),
                    ))
                .toList(),
          ),
        );
        if (setup == null) continue;
        setupId = setup.id;
      }

      widget.onApplyMinutes(setupId, p.reason, p.minutes);
      _service.consumePending(p);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = _service.activeTimers;
    final pending = _service.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronômetros'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (pending.isNotEmpty)
            TextButton(
              onPressed: _flushPending,
              child: Text(
                'Aplicar (${pending.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Aviso de persistência
          Container(
            width: double.infinity,
            color: Colors.orange.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Os cronômetros continuam rodando mesmo se você sair desta tela.',
              style: TextStyle(fontSize: 13),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _startNewTimer,
              icon: const Icon(Icons.add),
              label: const Text('Iniciar novo cronômetro'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: active.isEmpty
                ? const Center(child: Text('Nenhum cronômetro ativo'))
                : ListView.builder(
                    itemCount: active.length,
                    itemBuilder: (context, index) {
                      final t = active[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.timer, color: Colors.orange, size: 32),
                          title: Text(t.reason,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${t.elapsedLabel}'
                            '${t.setupPn != null && t.setupPn!.isNotEmpty ? "  ·  PN: ${t.setupPn}" : ""}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.stop_circle, color: Colors.red, size: 36),
                            onPressed: () => _stopTimer(t),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (pending.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pendentes de aplicar:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...pending.map((e) => Text(
                        '${e.reason}: ${e.minutes} min'
                        '${e.setupPn != null ? " → PN ${e.setupPn}" : ""}',
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
