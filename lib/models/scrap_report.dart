import 'package:uuid/uuid.dart';

class ScrapItem {
  final String id;
  String terminal; // ou código do item (ex: E14152900)
  String quantidade;
  String total;
  String motivo; // código (1410, 711, etc.)

  ScrapItem({
    String? id,
    this.terminal = '',
    this.quantidade = '',
    this.total = '',
    this.motivo = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'terminal': terminal,
        'quantidade': quantidade,
        'total': total,
        'motivo': motivo,
      };
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
