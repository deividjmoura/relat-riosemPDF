import 'package:uuid/uuid.dart';

class TimerEntry {
  final String id;
  final String reason; // Ex: "Manutenção de Máquina", "Logística", etc.
  final DateTime startTime;
  DateTime? endTime;
  bool isRunning;

  TimerEntry({
    String? id,
    required this.reason,
    required this.startTime,
    this.endTime,
    this.isRunning = true,
  }) : id = id ?? const Uuid().v4();

  int get elapsedMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isRunning': isRunning ? 1 : 0,
    };
  }

  factory TimerEntry.fromMap(Map<String, dynamic> map) {
    return TimerEntry(
      id: map['id'],
      reason: map['reason'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      isRunning: map['isRunning'] == 1,
    );
  }
}
