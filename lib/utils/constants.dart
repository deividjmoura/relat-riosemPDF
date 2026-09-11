/// Categorias oficiais de Tempo Morto (TM) do formulário RDP
class TempoMortoCategories {
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

/// Scrap codes (já estão no modelo ScrapReport)
class ScrapCodes {
  // Ver MotivosScrap no modelo
}
