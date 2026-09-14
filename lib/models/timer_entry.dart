import 'package:uuid/uuid.dart';

class TimerEntry {
  final String id;
  String reason;
  final DateTime startTime;
  DateTime? endTime;
  bool isRunning;

  /// ID da linha de setup (RdpLine.id) à qual este timer pertence
  String? setupId;

  /// PN da peça (só para exibição)
  String? setupPn;

  TimerEntry({
    String? id,
    required this.reason,
    required this.startTime,
    this.endTime,
    this.isRunning = true,
    this.setupId,
    this.setupPn,
  }) : id = id ?? const Uuid().v4();

  int get elapsedMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  String get elapsedLabel {
    final end = endTime ?? DateTime.now();
    final d = end.difference(startTime);
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isRunning': isRunning ? 1 : 0,
      'setupId': setupId,
      'setupPn': setupPn,
    };
  }

  factory TimerEntry.fromMap(Map<String, dynamic> map) {
    return TimerEntry(
      id: map['id'],
      reason: map['reason'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      isRunning: map['isRunning'] == 1,
      setupId: map['setupId'],
      setupPn: map['setupPn'],
    );
  }
}
