/// Definições oficiais do formulário RDP (F QUA-E 054 Rev.04).
///
/// Os rótulos canônicos reproduzem EXATAMENTE o texto impresso no formulário
/// de papel (inclusive maiúsculas/minúsculas e pontuação).
///
/// Rótulos usados por versões anteriores do app são aceitos como apelidos
/// ([RdpLabelAliases]) e normalizados para o canônico, de modo que rascunhos
/// já salvos no banco continuam funcionando sem perder os minutos lançados.

/// Grupo de armazenamento 'TM' (mapa `tempoMorto`).
/// No papel, a 1ª coluna fica sob o grupo "TR" e as 9 demais sob o "TP" esquerdo.
class TempoMortoCategories {
  /// Rótulos oficiais (cabeçalho vertical do PDF + diálogo de motivo).
  static const List<String> list = [
    'SET UP',
    'Reabast. De cabo',
    'Reabast. Terminal',
    'Reabast. FITA',
    'Ajuste de Calha',
    'Limp. conjunto de selo',
    'Ajuste de Maquina',
    'Ajuste altura de Terminal',
    'Posicionamento do Braço',
    'Prob. Alimentação de cabo',
  ];

  /// Alias mantido por compatibilidade (era o rótulo curto do PDF).
  static const List<String> short = list;
}

/// Grupo de armazenamento 'TP' (mapa `tempoPerdido`).
/// No papel, as 5 primeiras ficam sob "Tempo Morto (TM)" e as 3 últimas sob
/// "Tempo Perdido (TP)".
class TempoPerdidoCategories {
  static const List<String> list = [
    'Espera de Manutenção',
    'Manutenção de Maquina',
    'Manutenção de M.A.',
    'Manutenção de MCI/CALHA',
    'Falta de Energia/Ar Comprimido',
    'Espera de Cabo',
    'Espera de terminal',
    'Espera de Selo',
  ];

  static const List<String> short = list;
}

/// Grupo de armazenamento 'PP' (mapa `paradasProgramadas`).
/// No papel ficam sob "Paradas Programadas (PP)" com cabeçalho sombreado.
class ParadasProgramadasCategories {
  static const List<String> list = [
    'LIMPEZA',
    'INTERVALO',
    'MANUTENÇÃO PREVENTIVA',
    'REUNIÃO / TREINAMENTO',
    'DESENVOLV. ENGENHARIA / AMOSTRAS',
    'QUALIDADE',
    'FALTA DE PROGRAMAÇÃO',
    'REFEIÇÃO',
  ];

  static const List<String> short = list;
}

/// Colunas de scrap do RDP (mapa `scrap`), sob o grupo "Scrap".
class ScrapRdpColumns {
  static const List<String> list = [
    '1-Set-up',
    '2-Manutenção',
    '3-Final de Bobina',
    '6-CFA / COM',
    'Total Scrap',
  ];

  static const List<String> short = list;
}

/// Uma coluna de minutos do papel: de qual mapa ([store]) ela lê e com qual chave.
class RdpPaperColumn {
  /// 'TM' | 'TP' | 'PP' | 'SC'
  final String store;
  final String key;
  const RdpPaperColumn(this.store, this.key);
}

/// Um grupo de cabeçalho do papel (TR, TP, TM, TP, PP, Scrap).
class RdpPaperGroup {
  final String title;
  final List<RdpPaperColumn> columns;
  const RdpPaperGroup(this.title, this.columns);
}

/// Ordem e agrupamento EXATOS das colunas no formulário de papel.
class RdpPaperLayout {
  static final List<RdpPaperGroup> groups = [
    RdpPaperGroup('TR', [
      RdpPaperColumn('TM', TempoMortoCategories.list[0]),
    ]),
    RdpPaperGroup(
      'TP',
      TempoMortoCategories.list
          .sublist(1)
          .map((k) => RdpPaperColumn('TM', k))
          .toList(),
    ),
    RdpPaperGroup(
      'Tempo Morto (TM)',
      TempoPerdidoCategories.list
          .sublist(0, 5)
          .map((k) => RdpPaperColumn('TP', k))
          .toList(),
    ),
    RdpPaperGroup(
      'Tempo Perdido (TP)',
      TempoPerdidoCategories.list
          .sublist(5)
          .map((k) => RdpPaperColumn('TP', k))
          .toList(),
    ),
    RdpPaperGroup(
      'Paradas Programadas (PP)',
      ParadasProgramadasCategories.list.map((k) => RdpPaperColumn('PP', k)).toList(),
    ),
    RdpPaperGroup(
      'Scrap',
      ScrapRdpColumns.list.map((k) => RdpPaperColumn('SC', k)).toList(),
    ),
  ];

  /// As 26 colunas estreitas (TR + TP + TM + TP + PP), na ordem do papel.
  static List<RdpPaperColumn> get narrowColumns =>
      groups.sublist(0, 5).expand((g) => g.columns).toList();

  /// As 5 colunas de scrap, na ordem do papel.
  static List<RdpPaperColumn> get scrapColumns => groups[5].columns;
}

/// Apelidos (rótulos antigos) -> rótulo canônico atual do papel.
class RdpLabelAliases {
  static const Map<String, String> minuteKeys = {
    'Setup': 'SET UP',
    'Reabastecimento de cabo': 'Reabast. De cabo',
    'Reabastecimento Terminal': 'Reabast. Terminal',
    'Reabastecimento Fita': 'Reabast. FITA',
    'Reabastecimento de Fita': 'Reabast. FITA',
    'Ajuste de Guia': 'Ajuste de Calha',
    'Limpeza conjunto de selo': 'Limp. conjunto de selo',
    'Ajuste de Máquina': 'Ajuste de Maquina',
    'Posicionamento do Bloco': 'Posicionamento do Braço',
    'Troca Alimentação de Cabo': 'Prob. Alimentação de cabo',
    'Troca Alimentação de cabo': 'Prob. Alimentação de cabo',
    'Manutenção de Máquina': 'Manutenção de Maquina',
    'Manutenção de Mini Aplicador': 'Manutenção de MCI/CALHA',
    'Manutenção de Mini-Aplicador': 'Manutenção de MCI/CALHA',
    'Falta de Energia / Ar Comprimido': 'Falta de Energia/Ar Comprimido',
    'Espera de Terminal': 'Espera de terminal',
    'Limpeza': 'LIMPEZA',
    'Intervalo': 'INTERVALO',
    'Manutenção Preventiva': 'MANUTENÇÃO PREVENTIVA',
    'Reunião / Treinamento': 'REUNIÃO / TREINAMENTO',
    'Dispositivos / Ferramentas / Máquinas': 'DESENVOLV. ENGENHARIA / AMOSTRAS',
    'Dispositivos/Ferramentas/Máquinas': 'DESENVOLV. ENGENHARIA / AMOSTRAS',
    'Qualidade': 'QUALIDADE',
    'Falta de Programação': 'FALTA DE PROGRAMAÇÃO',
    'Iluminação': 'REFEIÇÃO',
    'Refeição': 'REFEIÇÃO',
  };

  static const Map<String, String> scrapKeys = {
    'Setup': '1-Set-up',
    '1-Setup': '1-Set-up',
    'Manutenção': '2-Manutenção',
    'Final de Bobina': '3-Final de Bobina',
    'CFA / COM': '6-CFA / COM',
    '4-CFA / COM': '6-CFA / COM',
  };

  static String normalizeMinuteKey(String key) => minuteKeys[key] ?? key;

  static String normalizeScrapKey(String key) => scrapKeys[key] ?? key;
}

class TimerCategoryMapper {
  static String _normalized(String reason) {
    final r = reason.trim();
    // 1) apelido exato (insensível a maiúsculas)
    for (final e in RdpLabelAliases.minuteKeys.entries) {
      if (e.key.toLowerCase() == r.toLowerCase()) return e.value;
    }
    // 2) rótulo canônico exato
    for (final list in [
      TempoMortoCategories.list,
      TempoPerdidoCategories.list,
      ParadasProgramadasCategories.list,
    ]) {
      for (final c in list) {
        if (c.toLowerCase() == r.toLowerCase()) return c;
      }
    }
    return r;
  }

  static String groupFor(String reason) {
    final canonical = _normalized(reason);
    final r = canonical.toLowerCase();

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
        r.contains('mci') ||
        r.contains('falta de energia')) {
      return 'TP';
    }
    if (r.contains('limpeza') ||
        r.contains('intervalo') ||
        r.contains('reuni') ||
        r.contains('treinamento') ||
        r.contains('qualidade') ||
        r.contains('programa') ||
        r.contains('refei') ||
        r.contains('desenvol') ||
        r.contains('amostra') ||
        r.contains('ilumina')) {
      return 'PP';
    }
    return 'TM';
  }

  static String canonicalKey(String reason) {
    final normalized = _normalized(reason);
    final r = normalized.toLowerCase();
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
    return normalized;
  }

  static bool _fuzzy(String a, String b) {
    final bb = b.toLowerCase();
    if (a.contains(bb) || bb.contains(a)) return true;
    final words = bb.split(RegExp(r'\s+')).where((w) => w.length > 3).toList();
    if (words.isEmpty) return false;
    return words.every((w) => a.contains(w));
  }
}
