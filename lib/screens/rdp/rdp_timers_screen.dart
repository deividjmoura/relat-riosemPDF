import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/timer_entry.dart';
import '../../utils/constants.dart';
import '../../widgets/stop_reason_dialog.dart';

class RdpTimersScreen extends StatefulWidget {
  final Function(Map<String, int>) onTimersFinished;

  const RdpTimersScreen({super.key, required this.onTimersFinished});

  @override
  State<RdpTimersScreen> createState() => _RdpTimersScreenState();
}

class _RdpTimersScreenState extends State<RdpTimersScreen> {
  final List<TimerEntry> _activeTimers = [];
  final Map<String, int> _accumulated = {}; // categoria → minutos
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    // Atualiza a UI a cada segundo
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _startNewTimer() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const StopReasonDialog(),
    );

    if (reason != null) {
      setState(() {
        _activeTimers.add(TimerEntry(reason: reason, startTime: DateTime.now()));
      });
    }
  }

  void _stopTimer(TimerEntry timer) {
    setState(() {
      timer.endTime = DateTime.now();
      timer.isRunning = false;
      final minutos = timer.elapsedMinutes;
      _accumulated[timer.reason] = (_accumulated[timer.reason] ?? 0) + minutos;
      _activeTimers.remove(timer);
    });
  }

  void _finishAll() {
    // Para todos que ainda estão rodando
    for (var t in List.from(_activeTimers)) {
      _stopTimer(t);
    }
    widget.onTimersFinished(_accumulated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronômetros'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _accumulated.isEmpty && _activeTimers.isEmpty ? null : _finishAll,
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Botão novo timer
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

          // Lista de timers ativos
          Expanded(
            child: _activeTimers.isEmpty
                ? const Center(child: Text('Nenhum cronômetro ativo'))
                : ListView.builder(
                    itemCount: _activeTimers.length,
                    itemBuilder: (context, index) {
                      final t = _activeTimers[index];
                      final elapsed = DateTime.now().difference(t.startTime);
                      final min = elapsed.inMinutes.toString().padLeft(2, '0');
                      final sec = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.timer, color: Colors.orange, size: 32),
                          title: Text(t.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$min:$sec'),
                          trailing: IconButton(
                            icon: const Icon(Icons.stop_circle, color: Colors.red, size: 36),
                            onPressed: () => _stopTimer(t),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Resumo acumulado
          if (_accumulated.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acumulado até agora:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._accumulated.entries.map((e) => Text('${e.key}: ${e.value} min')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
