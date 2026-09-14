/// Categorias oficiais de Tempo Morto (TM) do formulário RDP
/// Ordem e nomes alinhados com F QUA-E 054 Rev.04
class TempoMortoCategories {
  /// Nome curto para cabeçalho do PDF (vertical)
  static const List<String> short = [
    'SET UP',
    'Reabast.\nDe cabo',
    'Reabast.\nTerminal',
    'Reabast.\nFITA',
    'Ajuste\nde Guia',
    'Limp.\nconjunto\nde selo',
    'Ajuste de\nMáquina',
    'Ajuste altura\nde Terminal',
    'Posicionamento\ndo Bloco',
    'Troca\nAlimentação\nde Cabo',
  ];

  /// Nome completo (usado nos cronômetros e mapeamento)
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

/// Categorias de Tempo Perdido (TP)
class TempoPerdidoCategories {
  static const List<String> short = [
    'Espera de\nManutenção',
    'Manutenção\nde Máquina',
    'Manutenção\nde M.A.',
    'Manutenção de\nMini Aplicador',
    'Falta de Energia\n/ Ar Comprimido',
    'Espera\nde Cabo',
    'Espera de\nTerminal',
    'Espera\nde Selo',
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

/// Paradas Programadas (PP)
class ParadasProgramadasCategories {
  static const List<String> short = [
    'LIMPEZA',
    'INTERVALO',
    'MANUTENÇÃO\nPREVENTIVA',
    'REUNIÃO /\nTREINAMENTO',
    'DISPOSITIVOS\nFERRAMENTAS\n/ MÁQUINAS',
    'QUALIDADE',
    'FALTA DE\nPROGRAMAÇÃO',
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

/// Colunas de Scrap no RDP (código da perda)
class ScrapRdpColumns {
  static const List<String> short = [
    '1-Setup',
    '2-Manutenção',
    '3-Final\nde Bobina',
    '4-CFA / COM',
    'Total\nScrap',
  ];

  static const List<String> list = [
    'Setup',
    'Manutenção',
    'Final de Bobina',
    'CFA / COM',
    'Total Scrap',
  ];
}

/// Mapeia o texto escolhido no diálogo do cronômetro para a categoria correta
class TimerCategoryMapper {
  static String groupFor(String reason) {
    if (TempoMortoCategories.list.any((c) => c.toLowerCase() == reason.toLowerCase() || reason.toLowerCase().contains(c.toLowerCase().split(' ').first))) {
      // match mais preciso
    }
    final r = reason.toLowerCase();

    // Tempo Morto
    for (final c in TempoMortoCategories.list) {
      if (r == c.toLowerCase() || r.contains(c.toLowerCase().substring(0, (c.length > 8 ? 8 : c.length).clamp(0, c.length)))) {
        return 'TM';
      }
    }
    // Tempo Perdido
    for (final c in TempoPerdidoCategories.list) {
      if (r == c.toLowerCase() || r.contains(c.toLowerCase().substring(0, (c.length > 8 ? 8 : c.length).clamp(0, c.length)))) {
        return 'TP';
      }
    }
    // Paradas Programadas
    for (final c in ParadasProgramadasCategories.list) {
      if (r == c.toLowerCase() || r.contains(c.toLowerCase().substring(0, (c.length > 6 ? 6 : c.length).clamp(0, c.length)))) {
        return 'PP';
      }
    }
    // fallback heurístico (mantém comportamento anterior)
    if (r.contains('manuten') || r.contains('espera') || r.contains('energia') || r.contains('falta de energia')) {
      return 'TP';
    }
    if (r.contains('limpeza') || r.contains('intervalo') || r.contains('reuni') || r.contains('treinamento') || r.contains('qualidade') || r.contains('programa') || r.contains('ilumina')) {
      return 'PP';
    }
    return 'TM';
  }

  /// Retorna a chave canônica (nome da lista) que deve ser usada no Map da linha
  static String canonicalKey(String reason) {
    final r = reason.toLowerCase();
    for (final list in [TempoMortoCategories.list, TempoPerdidoCategories.list, ParadasProgramadasCategories.list]) {
      for (final c in list) {
        if (r == c.toLowerCase()) return c;
        // match parcial generoso
        if (r.contains(c.toLowerCase()) || c.toLowerCase().contains(r)) return c;
      }
    }
    return reason; // mantém original se não achar
  }
}
