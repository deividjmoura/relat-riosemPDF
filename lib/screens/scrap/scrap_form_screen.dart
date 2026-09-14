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
      final item = ScrapItem(terminal: code);
      setState(() => targetList.add(item));
      // Abre edição logo após o scan para preencher qtd/motivo
      await _editItem(item);
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
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final item = ScrapItem(terminal: ctrl.text.trim());
                setState(() => targetList.add(item));
                Navigator.pop(context);
                await _editItem(item);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem(ScrapItem item) async {
    final qtdCtrl = TextEditingController(text: item.quantidade);
    final totalCtrl = TextEditingController(text: item.total);
    String selectedMotivo = item.motivo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text('Item: ${item.terminal}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtdCtrl,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: totalCtrl,
                    decoration: const InputDecoration(labelText: 'Total'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Motivo', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedMotivo.isEmpty ? null : selectedMotivo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: const Text('Selecione o código'),
                    items: MotivosScrap.lista.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                '${e.key} – ${e.value}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => selectedMotivo = v ?? ''),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true) {
      setState(() {
        item.quantidade = qtdCtrl.text.trim();
        item.total = totalCtrl.text.trim();
        item.motivo = selectedMotivo;
      });
    }
  }

  Future<void> _gerarPdf() async {
    report.maquina = _maquinaCtrl.text.trim();
    report.operador = _operadorCtrl.text.trim();
    report.nomeLider = _liderCtrl.text.trim();
    report.matricula = _matriculaCtrl.text.trim();
    report.turno = _turnoCtrl.text.trim();

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
                      tooltip: 'Adicionar manual',
                    ),
                  ],
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhum item', style: TextStyle(color: Colors.grey)),
              )
            else
              ...items.map((item) {
                final motivoLabel = item.motivo.isEmpty
                    ? '–'
                    : '${item.motivo} ${MotivosScrap.lista[item.motivo] ?? ''}';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.terminal, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Qtd: ${item.quantidade.isEmpty ? "–" : item.quantidade}  |  '
                      'Total: ${item.total.isEmpty ? "–" : item.total}\n'
                      'Motivo: $motivoLabel'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editItem(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => setState(() => items.remove(item)),
                      ),
                    ],
                  ),
                  onTap: () => _editItem(item),
                );
              }),
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
            tooltip: 'Gerar PDF',
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
                  TextField(
                      controller: _maquinaCtrl, decoration: const InputDecoration(labelText: 'Máquina')),
                  TextField(
                      controller: _operadorCtrl,
                      decoration: const InputDecoration(labelText: 'Operador')),
                  TextField(
                      controller: _liderCtrl,
                      decoration: const InputDecoration(labelText: 'Nome do Líder')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: _matriculaCtrl,
                            decoration: const InputDecoration(labelText: 'Matrícula')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                            controller: _turnoCtrl,
                            decoration: const InputDecoration(labelText: 'Turno')),
                      ),
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
          const SizedBox(height: 8),
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
