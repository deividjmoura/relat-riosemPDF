import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeService {
  /// Extrai o código principal do barcode/QR lido
  /// Exemplo de etiqueta Lear: Item E14152900
  static String? extractItemCode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      // Procura padrões comuns de item Lear (E + números ou G + números)
      final match = RegExp(r'(E\d{8,}|G\d{2,}|[A-Z0-9]{8,})').firstMatch(raw);
      if (match != null) {
        return match.group(0);
      }

      // Se não achar padrão, retorna o valor bruto
      return raw;
    }
    return null;
  }
}
