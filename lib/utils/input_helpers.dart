import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
/// Força tudo em maiúsculas enquanto digita.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
/// Formata HH:mm
String formatTimeOfDay(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
/// Abre o seletor de hora estilo relógio (dial).
Future<String?> pickTime(
  BuildContext context, {
  String? initial,
}) async {
  TimeOfDay initialTime = TimeOfDay.now();
  if (initial != null && initial.contains(':')) {
    final parts = initial.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    initialTime = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }
  final picked = await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      );
    },
    initialEntryMode: TimePickerEntryMode.dial, // relógio com ponteiros
  );
  if (picked == null) return null;
  return formatTimeOfDay(picked);
}
/// Abre calendário e retorna yyyy-MM-dd
Future<String?> pickDate(
  BuildContext context, {
  String? initial,
}) async {
  DateTime initialDate = DateTime.now();
  if (initial != null && initial.isNotEmpty) {
    try {
      initialDate = DateTime.parse(initial);
    } catch (_) {}
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (picked == null) return null;
  return DateFormat('yyyy-MM-dd').format(picked);
}
