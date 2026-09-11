import 'package:uuid/uuid.dart';

/// Representa uma linha de setup + produção do RDP
class RdpLine {
  final String id;
  String inicioAtiv;
  String terminoAtiv;
  String pnPeca;
  String taxaPlanejada;
  String taxaReal;
  String quantidadePecas;

  // Tempo Morto (TM) - minutos por categoria
  Map<String, int> tempoMorto;

  // Tempo Perdido (TP)
  Map<String, int> tempoPerdido;

  // Paradas Programadas (PP)
  Map<String, int> paradasProgramadas;

  // Scrap
  Map<String, int> scrap;

  RdpLine({
    String? id,
    this.inicioAtiv = '',
    this.terminoAtiv = '',
    this.pnPeca = '',
    this.taxaPlanejada = '',
    this.taxaReal = '',
    this.quantidadePecas = '',
    Map<String, int>? tempoMorto,
    Map<String, int>? tempoPerdido,
    Map<String, int>? paradasProgramadas,
    Map<String, int>? scrap,
  })  : id = id ?? const Uuid().v4(),
        tempoMorto = tempoMorto ?? {},
        tempoPerdido = tempoPerdido ?? {},
        paradasProgramadas = paradasProgramadas ?? {},
        scrap = scrap ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inicioAtiv': inicioAtiv,
      'terminoAtiv': terminoAtiv,
      'pnPeca': pnPeca,
      'taxaPlanejada': taxaPlanejada,
      'taxaReal': taxaReal,
      'quantidadePecas': quantidadePecas,
      'tempoMorto': tempoMorto,
      'tempoPerdido': tempoPerdido,
      'paradasProgramadas': paradasProgramadas,
      'scrap': scrap,
    };
  }
}

/// Cabeçalho do RDP
class RdpReport {
  final String id;
  String data;
  String maquina;
  String operador;
  String reg;
  String turno;
  String horaInicial;
  String horaFinal;
  String horimetroInicial;
  String horimetroFinal;
  String horimetroTotal;
  List<RdpLine> linhas;
  String observacoes;

  // Totais calculados
  Map<String, int> totaisTempoMorto;
  Map<String, int> totaisTempoPerdido;
  Map<String, int> totaisParadas;
  Map<String, int> totaisScrap;

  RdpReport({
    String? id,
    this.data = '',
    this.maquina = '',
    this.operador = '',
    this.reg = '',
    this.turno = '',
    this.horaInicial = '',
    this.horaFinal = '',
    this.horimetroInicial = '',
    this.horimetroFinal = '',
    this.horimetroTotal = '',
    List<RdpLine>? linhas,
    this.observacoes = '',
    Map<String, int>? totaisTempoMorto,
    Map<String, int>? totaisTempoPerdido,
    Map<String, int>? totaisParadas,
    Map<String, int>? totaisScrap,
  })  : id = id ?? const Uuid().v4(),
        linhas = linhas ?? [],
        totaisTempoMorto = totaisTempoMorto ?? {},
        totaisTempoPerdido = totaisTempoPerdido ?? {},
        totaisParadas = totaisParadas ?? {},
        totaisScrap = totaisScrap ?? {};

  void calcularTotais() {
    totaisTempoMorto.clear();
    totaisTempoPerdido.clear();
    totaisParadas.clear();
    totaisScrap.clear();

    for (var linha in linhas) {
      linha.tempoMorto.forEach((k, v) {
        totaisTempoMorto[k] = (totaisTempoMorto[k] ?? 0) + v;
      });
      linha.tempoPerdido.forEach((k, v) {
        totaisTempoPerdido[k] = (totaisTempoPerdido[k] ?? 0) + v;
      });
      linha.paradasProgramadas.forEach((k, v) {
        totaisParadas[k] = (totaisParadas[k] ?? 0) + v;
      });
      linha.scrap.forEach((k, v) {
        totaisScrap[k] = (totaisScrap[k] ?? 0) + v;
      });
    }
  }
}
