import 'package:uuid/uuid.dart';

class ScrapItem {
  final String id;
  String terminal; // código do item (ex: E14152900)
  String quantidade; // quantidade de peças/unidades descartadas
  int pesoGramas; // peso real do scrap; unidade interna: gramas
  String motivo; // código (1410, 711, etc.)

  ScrapItem({
    String? id,
    this.terminal = '',
    this.quantidade = '',
    this.pesoGramas = 0,
    this.motivo = '',
  }) : id = id ?? const Uuid().v4();

  String get pesoKgFormatado => (pesoGramas / 1000).toStringAsFixed(2);

  /// Compatibilidade com a geração de PDF existente: "TOTAL" representa kg.
  String get total => pesoGramas > 0 ? pesoKgFormatado.replaceAll('.', ',') : '';

  Map<String, dynamic> toMap() => {
        'id': id,
        'terminal': terminal,
        'quantidade': quantidade,
        'pesoGramas': pesoGramas,
        'motivo': motivo,
      };

  factory ScrapItem.fromMap(Map<String, dynamic> map) {
    final rawPeso = map['pesoGramas'];
    int peso;
    if (rawPeso is num) {
      peso = rawPeso.round();
    } else {
      peso = int.tryParse('$rawPeso') ?? 0;
    }

    // Compatibilidade com registros antigos que usavam "total" em kg.
    if (peso == 0 && map['total'] != null) {
      final legacy = double.tryParse('${map['total']}'.replaceAll(',', '.'));
      if (legacy != null) peso = (legacy * 1000).round();
    }

    return ScrapItem(
      id: map['id']?.toString(),
      terminal: map['terminal']?.toString() ?? '',
      quantidade: map['quantidade']?.toString() ?? '',
      pesoGramas: peso,
      motivo: map['motivo']?.toString() ?? '',
    );
  }
}

class ScrapReport {
  final String id;
  String maquina;
  String centro;
  String turno;
  String data;
  String matricula;
  String operador;
  String nomeLider;

  List<ScrapItem> terminais;
  List<ScrapItem> selos;
  List<ScrapItem> cabos;

  ScrapReport({
    String? id,
    this.maquina = '',
    this.centro = 'Corte',
    this.turno = '',
    this.data = '',
    this.matricula = '',
    this.operador = '',
    this.nomeLider = '',
    List<ScrapItem>? terminais,
    List<ScrapItem>? selos,
    List<ScrapItem>? cabos,
  })  : id = id ?? const Uuid().v4(),
        terminais = terminais ?? [],
        selos = selos ?? [],
        cabos = cabos ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'maquina': maquina,
        'centro': centro,
        'turno': turno,
        'data': data,
        'matricula': matricula,
        'operador': operador,
        'nomeLider': nomeLider,
        'terminais': terminais.map((e) => e.toMap()).toList(),
        'selos': selos.map((e) => e.toMap()).toList(),
        'cabos': cabos.map((e) => e.toMap()).toList(),
      };

  factory ScrapReport.fromMap(Map<String, dynamic> map) {
    List<ScrapItem> readItems(dynamic value) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((item) => ScrapItem.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return ScrapReport(
      id: map['id']?.toString(),
      maquina: map['maquina']?.toString() ?? '',
      centro: map['centro']?.toString() ?? 'Corte',
      turno: map['turno']?.toString() ?? '',
      data: map['data']?.toString() ?? '',
      matricula: map['matricula']?.toString() ?? '',
      operador: map['operador']?.toString() ?? '',
      nomeLider: map['nomeLider']?.toString() ?? '',
      terminais: readItems(map['terminais']),
      selos: readItems(map['selos']),
      cabos: readItems(map['cabos']),
    );
  }
}

/// Lista oficial de motivos de scrap (códigos)
class MotivosScrap {
  static const Map<String, String> lista = {
    '1410': 'TERMINAL ERRADO',
    '1411': 'TERMINAL TORTO / DOBRADO / DEFORMADO',
    '1412': 'TERMINAL FÊMEA COM CONTATO ABERTO',
    '1413': 'TERMINAL COM ALTURA DA GARRA DO CONDUTOR ERRADA',
    '1414': 'TERMINAL COM LARGURA DA GARRA DO CONDUTOR ERRADA',
    '1415': 'TERMINAL COM ALTURA DA GARRA DO ISOLANTE ERRADA',
    '1416': 'TERMINAL COM LARGURA DA GARRA DO ISOLANTE ERRADA',
    '1417': 'TERMINAL APLICADO SOMENTE NO ISOLANTE',
    '1418': 'TERMINAL COM ISOLANTE PRESO NA GARRA DO CONDUTOR',
    '1419': 'TERMINAL COM FILAMENTO SOLTOS (FORA DA ÁREA DE APLICAÇÃO)',
    '1420': 'TERMINAL COM GARRA DO ISOLANTE TORTA OU AMASSADA',
    '1421': 'TERMINAL COM REBARBA NA GARRA DO CONDUTOR',
    '1422': 'TERMINAL COM EXCESSO OU SEM TESTEMUNHO DE CORTE',
    '1423': 'TERMINAL COM TRAVA DANIFICADA',
    '711': 'SETUP',
    '1425': 'TERMINAL DANIFICADO',
    '1505': 'M. APLICADOR (BIG) - MANUTENÇÃO',
    '1506': 'FACA - MANUTENÇÃO',
    '1501': 'DEFEITO DE MATÉRIA PRIMA',
    '1427': 'TERMINAL COM BOCA DE SINO FALTANTE / INVERTIDA',
    '1428': 'TERMINAL COM BOCA DE SINO TORTA / INCORRETO',
    '1502': 'PARÂMETRO DA MÁQUINA - ENGENHARIA',
    '1430': 'TERMINAL COM VARIAÇÃO NO CORTE DE TRANSIÇÃO',
    '1503': 'PARÂMETRO DA FERRAMENTA - ENGENHARIA',
    '1432': 'TERMINAL COM REBARBA NO TESTEMUNHO DE CORTE',
    '1433': 'TERMINAL COM EXCESSO OU SEM JANELA',
    '1434': 'TERMINAL COM ÁREA DE CONTATO DANIFICADA',
    '1435': 'TERMINAL INCLINADO',
    '1436': 'TERMINAL FORA DO AVANÇO (TORTO)',
    '1437': 'TERMINAL MARCADO PELO MINI APLICADOR',
    '710': 'FINAL DE BOBINA',
    '1439': 'TERMINAL COM EXCESSO OU SEM VASSOURA',
    '1496': 'REPROVA CABO COM MEMÓRIA',
    '1497': 'REPROVA DE CRIMPAGEM',
    '1504': 'MINI APLICADOR (GRAMPEADOR) - MANUTENÇÃO',
    '1509': 'MÁQUINA - MANUTENÇÃO',
  };
}
