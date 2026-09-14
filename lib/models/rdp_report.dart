import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

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
    Map<String, int> intMap(dynamic value, String Function(String) normalize) {
      if (value is! Map) return {};
      final result = <String, int>{};
      value.forEach((key, val) {
        final norm = normalize(key.toString());
        final v = val is num ? val.toInt() : int.tryParse('$val') ?? 0;
        result[norm] = (result[norm] ?? 0) + v;
      });
      return result;
    }

    return RdpLine(
      id: map['id']?.toString(),
      inicioAtiv: map['inicioAtiv']?.toString() ?? '',
      terminoAtiv: map['terminoAtiv']?.toString() ?? '',
      pnPeca: map['pnPeca']?.toString() ?? '',
      taxaPlanejada: map['taxaPlanejada']?.toString() ?? '',
      taxaReal: map['taxaReal']?.toString() ?? '',
      quantidadePecas: map['quantidadePecas']?.toString() ?? '',
      tempoMorto: intMap(map['tempoMorto'], RdpLabelAliases.normalizeMinuteKey),
      tempoPerdido:
          intMap(map['tempoPerdido'], RdpLabelAliases.normalizeMinuteKey),
      paradasProgramadas:
          intMap(map['paradasProgramadas'], RdpLabelAliases.normalizeMinuteKey),
      scrap: intMap(map['scrap'], RdpLabelAliases.normalizeScrapKey),
    );
  }

  /// Divide o PN em 2 partes para as 2 sub-colunas do papel ("G15 3340").
  List<String> get pnPartes {
    final parts = pnPeca
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return const ['', ''];
    if (parts.length == 1) return [parts.first, ''];
    return [parts.first, parts.sublist(1).join(' ')];
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
