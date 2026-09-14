/// Memória (em sessão) do estado aberto/fechado das seções retráteis.
///
/// Como a navegação recria as telas, os ExpansionTiles voltariam sempre
/// expandidos. Este store estático preserva a escolha do usuário enquanto
/// o app estiver aberto.
class ExpansionMemory {
  static bool rdpHeader = true;
  static bool rdpSetups = true;
  static bool scrapHeader = true;
  static final Map<String, bool> _scrapSections = {};

  static bool scrapSection(String title) => _scrapSections[title] ?? true;

  static void setScrapSection(String title, bool expanded) =>
      _scrapSections[title] = expanded;

  /// Volta tudo ao padrão (usado ao limpar os dados do dia).
  static void resetRdp() {
    rdpHeader = true;
    rdpSetups = true;
  }

  static void resetScrap() {
    scrapHeader = true;
    _scrapSections.clear();
  }
}
