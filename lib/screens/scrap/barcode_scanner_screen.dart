import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/barcode_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _scanned = false;
  int _scannerKey = 0;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = BarcodeService.extractItemCode(capture);
    if (code != null && code.isNotEmpty && mounted) {
      _scanned = true;
      Navigator.pop(context, code);
    }
  }

  void _retryCamera() {
    setState(() {
      _scanned = false;
      _scannerKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ler Código de Barras'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: ValueKey(_scannerKey),
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Não foi possível abrir a câmera.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _retryCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Aponte para o código de barras da etiqueta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 4)]),
            ),
          ),
        ],
      ),
    );
  }
}
