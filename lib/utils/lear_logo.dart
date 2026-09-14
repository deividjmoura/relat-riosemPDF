import 'dart:convert';
import 'dart:typed_data';

/// Logo oficial da Lear fornecido para o formulário RDP.
/// Mantido como bytes para que o PDF possa ser gerado offline.
const String learLogoBase64 = 'PLACEHOLDER';

Uint8List get learLogoBytes => base64Decode(learLogoBase64);
