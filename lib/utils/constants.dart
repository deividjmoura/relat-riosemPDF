/// Categorias oficiais alinhadas com F QUA-E 054 Rev.04
class TempoMortoCategories {
  /// Rótulos curtos para cabeçalho vertical do PDF
  static const List<String> short = [
    'SET UP',
    'Reabast. De cabo',
    'Reabast. Terminal',
    'Reabast. FITA',
    'Ajuste de Guia',
    'Limp. conjunto de selo',
    'Ajuste de Máquina',
    'Ajuste altura de Terminal',
    'Posicionamento do Bloco',
    'Troca Alimentação de Cabo',
  ];

  static const List<String> list = [
    'Setup',
    'Reabastecimento de cabo',
    'Reabastecimento Terminal',
    'Reabastecimento Fita',
    'Ajuste de Guia',
    'Limpeza conjunto de selo',
    'Ajuste de Máquina',
    'Ajuste altura de Terminal',
    'Posicionamento do Bloco',
    'Troca Alimentação de Cabo',
  ];
}

class TempoPerdidoCategories {
  static const List<String> short = [
    'Espera de Manutenção',
    'Manutenção de Máquina',
    'Manutenção de M.A.',
    'Manutenção de Mini Aplicador',
    'Falta de Energia / Ar Comprimido',
    'Espera de Cabo',
    'Espera de Terminal',
    'Espera de Selo',
  ];

  static const List<String> list = [
    'Espera de Manutenção',
    'Manutenção de Máquina',
    'Manutenção de M.A.',
    'Manutenção de Mini Aplicador',
    'Falta de Energia / Ar Comprimido',
    'Espera de Cabo',
    'Espera de Terminal',
    'Espera de Selo',
  ];
}

class ParadasProgramadasCategories {
  static const List<String> short = [
    'LIMPEZA',
    'INTERVALO',
    'MANUTENÇÃO PREVENTIVA',
    'REUNIÃO / TREINAMENTO',
    'DISPOSITIVOS / FERRAMENTAS / MÁQUINAS',
    'QUALIDADE',
    'FALTA DE PROGRAMAÇÃO',
    'ILUMINAÇÃO',
  ];

  static const List<String> list = [
    'Limpeza',
    'Intervalo',
    'Manutenção Preventiva',
    'Reunião / Treinamento',
    'Dispositivos / Ferramentas / Máquinas',
    'Qualidade',
    'Falta de Programação',
    'Iluminação',
  ];
}

class ScrapRdpColumns {
  static const List<String> short = [
    '1-Setup',
    '2-Manutenção',
    '3-Final de Bobina',
    '4-CFA / COM',
    'Total Scrap',
  ];

  static const List<String> list = [
    'Setup',
    'Manutenção',
    'Final de Bobina',
    'CFA / COM',
    'Total Scrap',
  ];
}

class TimerCategoryMapper {
  static String groupFor(String reason) {
    final r = reason.toLowerCase();

    for (final c in TempoPerdidoCategories.list) {
      if (r == c.toLowerCase() || _fuzzy(r, c)) return 'TP';
    }
    for (final c in ParadasProgramadasCategories.list) {
      if (r == c.toLowerCase() || _fuzzy(r, c)) return 'PP';
    }
    for (final c in TempoMortoCategories.list) {
      if (r == c.toLowerCase() || _fuzzy(r, c)) return 'TM';
    }

    if (r.contains('manuten') ||
        r.contains('espera') ||
        r.contains('energia') ||
        r.contains('falta de energia')) {
      return 'TP';
    }
    if (r.contains('limpeza') ||
        r.contains('intervalo') ||
        r.contains('reuni') ||
        r.contains('treinamento') ||
        r.contains('qualidade') ||
        r.contains('programa') ||
        r.contains('ilumina')) {
      return 'PP';
    }
    return 'TM';
  }

  static String canonicalKey(String reason) {
    final r = reason.toLowerCase();
    for (final list in [
      TempoMortoCategories.list,
      TempoPerdidoCategories.list,
      ParadasProgramadasCategories.list,
    ]) {
      for (final c in list) {
        if (r == c.toLowerCase()) return c;
        if (_fuzzy(r, c)) return c;
      }
    }
    return reason;
  }

  static bool _fuzzy(String a, String b) {
    final bb = b.toLowerCase();
    if (a.contains(bb) || bb.contains(a)) return true;
    final words = bb.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    if (words.isEmpty) return false;
    return words.every((w) => a.contains(w));
  }
}
