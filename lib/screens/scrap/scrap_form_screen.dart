import 'package:flutter/material.dart';
import '../../models/scrap_report.dart';
import '../../services/pdf_service.dart';
import 'barcode_scanner_screen.dart';

class ScrapFormScreen extends StatefulWidget {
  const ScrapFormScreen({super.key});

  @override
  State<ScrapFormScreen> createState() => _ScrapFormScreenState();
}

class _ScrapFormScreenState extends State<ScrapFormScreen> {
  final ScrapReport report = ScrapReport(
    data: DateTime.now().toString().substring(0, 10),
    centro: 'Corte',
  );

  final _maquinaCtrl = TextEditingController();
  final _operadorCtrl = TextEditingController();
  final _liderCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _turnoCtrl = TextEditingController();

  @override
  void dispose() {
    _maquinaCtrl.dispose();
    _operadorCtrl.dispose();
    _liderCtrl.dispose();
    _matriculaCtrl.dispose();
    _turnoCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(List<ScrapItem> targetList) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      setState(() {
        targetList.add(ScrapItem(terminal: code));
      });
    }
  }

  void _addManual(List<ScrapItem> targetList) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar item'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Código / Terminal'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => targetList.add(ScrapItem(terminal: ctrl.text.trim())));
              }
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarPdf() async {
    report.maquina = _maquinaCtrl.text;
    report.operador = _operadorCtrl.text;
    report.nomeLider = _liderCtrl.text;
    report.matricula = _matriculaCtrl.text;
    report.turno = _turnoCtrl.text;

    await PdfService.generateScrapPdf(report);
  }

  Widget _buildSection(String title, List<ScrapItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _scanBarcode(items),
                      tooltip: 'Ler código de barras',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addManual(items),
                    ),
                  ],
                ),
              ],
            ),
            if (items.isEmpty)
              const Text('Nenhum item', style: TextStyle(color: Colors.grey))
            else
              ...items.map((item) => ListTile(
                    dense: true,
                    title: Text(item.terminal),
                    subtitle: Text('Motivo: ${item.motivo.isEmpty ? "-" : item.motivo}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => setState(() => items.remove(item)),
                    ),
                    onTap: () {
                      // TODO: abrir dialog para editar quantidade + motivo
                    },
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Scrap'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _gerarPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _maquinaCtrl, decoration: const InputDecoration(labelText: 'Máquina')),
                  TextField(controller: _operadorCtrl, decoration: const InputDecoration(labelText: 'Operador')),
                  TextField(controller: _liderCtrl, decoration: const InputDecoration(labelText: 'Nome do Líder')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _matriculaCtrl, decoration: const InputDecoration(labelText: 'Matrícula'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _turnoCtrl, decoration: const InputDecoration(labelText: 'Turno'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection('TERMINAL', report.terminais),
          _buildSection('SELO', report.selos),
          _buildSection('CABO', report.cabos),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _gerarPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Gerar PDF do Scrap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE30613),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
