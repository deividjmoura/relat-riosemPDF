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

  factory RdpLine.fromMap(Map<String, dynamic> map) {
    Map<String, int> intMap(dynamic value) {
      if (value is! Map) return {};
      return value.map(
        (key, value) => MapEntry(key.toString(), value is num ? value.toInt() : int.tryParse('$value') ?? 0),
      );
    }

    return RdpLine(
      id: map['id']?.toString(),
      inicioAtiv: map['inicioAtiv']?.toString() ?? '',
      terminoAtiv: map['terminoAtiv']?.toString() ?? '',
      pnPeca: map['pnPeca']?.toString() ?? '',
      taxaPlanejada: map['taxaPlanejada']?.toString() ?? '',
      taxaReal: map['taxaReal']?.toString() ?? '',
      quantidadePecas: map['quantidadePecas']?.toString() ?? '',
      tempoMorto: intMap(map['tempoMorto']),
      tempoPerdido: intMap(map['tempoPerdido']),
      paradasProgramadas: intMap(map['paradasProgramadas']),
      scrap: intMap(map['scrap']),
    );
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'maquina': maquina,
      'operador': operador,
      'reg': reg,
      'turno': turno,
      'horaInicial': horaInicial,
      'horaFinal': horaFinal,
      'horimetroInicial': horimetroInicial,
      'horimetroFinal': horimetroFinal,
      'horimetroTotal': horimetroTotal,
      'linhas': linhas.map((linha) => linha.toMap()).toList(),
      'observacoes': observacoes,
    };
  }

  factory RdpReport.fromMap(Map<String, dynamic> map) {
    final rawLines = map['linhas'];
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((line) => RdpLine.fromMap(Map<String, dynamic>.from(line)))
            .toList()
        : <RdpLine>[];

    return RdpReport(
      id: map['id']?.toString(),
      data: map['data']?.toString() ?? '',
      maquina: map['maquina']?.toString() ?? '',
      operador: map['operador']?.toString() ?? '',
      reg: map['reg']?.toString() ?? '',
      turno: map['turno']?.toString() ?? '',
      horaInicial: map['horaInicial']?.toString() ?? '',
      horaFinal: map['horaFinal']?.toString() ?? '',
      horimetroInicial: map['horimetroInicial']?.toString() ?? '',
      horimetroFinal: map['horimetroFinal']?.toString() ?? '',
      horimetroTotal: map['horimetroTotal']?.toString() ?? '',
      linhas: lines,
      observacoes: map['observacoes']?.toString() ?? '',
    );
  }

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
