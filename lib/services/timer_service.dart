import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/timer_entry.dart';

/// Mantém os cronômetros vivos mesmo ao sair da tela.
class TimerService extends ChangeNotifier {
  static final TimerService instance = TimerService._();
  TimerService._() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active.any((t) => t.isRunning)) {
        notifyListeners();
      }
    });
  }

  final List<TimerEntry> _active = [];
  /// Minutos já finalizados, ainda não aplicados a nenhum setup: reason → minutos
  /// (usamos lista para poder ter o mesmo reason em setups diferentes)
  final List<_PendingMinutes> _pending = [];

  Timer? _ticker;

  List<TimerEntry> get activeTimers => List.unmodifiable(_active);
  List<_PendingMinutes> get pending => List.unmodifiable(_pending);
  bool get hasRunning => _active.any((t) => t.isRunning);
  int get runningCount => _active.where((t) => t.isRunning).length;

  void start({
    required String reason,
    String? setupId,
    String? setupPn,
  }) {
    _active.add(TimerEntry(
      reason: reason,
      startTime: DateTime.now(),
      setupId: setupId,
      setupPn: setupPn,
    ));
    notifyListeners();
  }

  /// Para o timer. Se [applyToSetup] for true e o timer já tiver setupId,
  /// devolve os minutos prontos para aplicar. Caso contrário, fica em pending.
  TimerEntry? stop(String timerId) {
    final idx = _active.indexWhere((t) => t.id == timerId);
    if (idx < 0) return null;
    final t = _active[idx];
    t.endTime = DateTime.now();
    t.isRunning = false;
    final minutes = t.elapsedMinutes;
    _active.removeAt(idx);

    if (minutes > 0) {
      _pending.add(_PendingMinutes(
        reason: t.reason,
        minutes: minutes,
        setupId: t.setupId,
        setupPn: t.setupPn,
      ));
    }
    notifyListeners();
    return t;
  }

  void stopAll() {
    for (final t in List<TimerEntry>.from(_active)) {
      stop(t.id);
    }
  }

  /// Remove um item pendente (já aplicado ao setup)
  void consumePending(_PendingMinutes item) {
    _pending.remove(item);
    notifyListeners();
  }

  void clearPending() {
    _pending.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

class _PendingMinutes {
  final String reason;
  final int minutes;
  String? setupId;
  String? setupPn;

  _PendingMinutes({
    required this.reason,
    required this.minutes,
    this.setupId,
    this.setupPn,
  });
}
