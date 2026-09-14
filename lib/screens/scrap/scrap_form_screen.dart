import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/scrap_report.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/input_helpers.dart';
import 'barcode_scanner_screen.dart';
import '../history_screen.dart';
import '../../widgets/app_drawer.dart';

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

  late final TextEditingController _dataCtrl;
  final _maquinaCtrl = TextEditingController();
  final _operadorCtrl = TextEditingController();
  final _liderCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _turnoCtrl = TextEditingController();
  final _database = DatabaseService.instance;
  bool _loadingDraft = true;
  bool _gerandoPdf = false;

  @override
  void initState() {
    super.initState();
    _dataCtrl = TextEditingController(text: report.data);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final saved = await _database.getScrapDraft();
    if (!mounted) return;

    if (saved != null) {
      report.maquina = saved.maquina;
      report.centro = saved.centro;
      report.turno = saved.turno;
      report.data = saved.data;
      report.matricula = saved.matricula;
      report.operador = saved.operador;
      report.nomeLider = saved.nomeLider;
      report.terminais = saved.terminais;
      report.selos = saved.selos;
      report.cabos = saved.cabos;

      _dataCtrl.text = report.data;
      _maquinaCtrl.text = report.maquina;
      _operadorCtrl.text = report.operador;
      _liderCtrl.text = report.nomeLider;
      _matriculaCtrl.text = report.matricula;
      _turnoCtrl.text = report.turno;
    }

    setState(() => _loadingDraft = false);
  }

  Future<void> _saveDraft() async {
    if (_loadingDraft) return;
    await _database.saveScrapDraft(report);
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _maquinaCtrl.dispose();
    _operadorCtrl.dispose();
    _liderCtrl.dispose();
    _matriculaCtrl.dispose();
    _turnoCtrl.dispose();
    super.dispose();
  }

  void _syncHeader() {
    report.data = _dataCtrl.text.trim();
    report.maquina = _maquinaCtrl.text.trim();
    report.operador = _operadorCtrl.text.trim();
    report.nomeLider = _liderCtrl.text.trim();
    report.matricula = _matriculaCtrl.text.trim();
    report.turno = _turnoCtrl.text.trim();
  }

  Future<void> _headerChanged(String _) async {
    _syncHeader();
    if (mounted) setState(() {});
    await _saveDraft();
  }

  String _headerSummary() {
    final parts = <String>[];
    if (report.maquina.isNotEmpty) parts.add('MAQ ${report.maquina}');
    if (report.turno.isNotEmpty) parts.add('Turno ${report.turno}');
    if (report.data.isNotEmpty) parts.add(report.data);
    return parts.isEmpty ? 'Toque para preencher' : parts.join(' \u2022 ');
  }

  Future<void> _scanBarcode(List<ScrapItem> targetList) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (code != null && code.isNotEmpty) {
      final item = ScrapItem(terminal: code);
      setState(() => targetList.add(item));
      await _saveDraft();
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
          decoration: const InputDecoration(labelText: 'Código / Item'),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [UpperCaseTextFormatter()],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                final item = ScrapItem(terminal: ctrl.text.trim().toUpperCase());
                setState(() => targetList.add(item));
                Navigator.pop(context);
                await _saveDraft();
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

  /// Seletor de motivo do scrap com busca (código ou descrição).
  Future<String?> _pickMotivo(BuildContext parentCtx, String current) {
    final entries = MotivosScrap.lista.entries.toList();
    final searchCtrl = TextEditingController();
    String query = '';
    String norm(String v) {
      const from = 'àáâãäåèéêëìíîïòóôõöùúûüçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ';
      const to = 'aaaaaaaaeeeeiiiiooooouuuucnAAAAAAAAEEEEIIIIOOOOOUUUUCN';
      final buf = StringBuffer();
      for (var i = 0; i < v.length; i++) {
        final idx = from.indexOf(v[i]);
        buf.write(idx < 0 ? v[i] : to[idx]);
      }
      return buf.toString().toLowerCase();
    }
    return showDialog<String>(
      context: parentCtx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final q = norm(query.trim());
          final filtered = q.isEmpty
              ? entries
              : entries.where((e) => norm(e.key + ' ' + e.value).contains(q)).toList();
          return AlertDialog(
            title: const Text('Motivo do scrap'),
            content: SizedBox(
              width: double.maxFinite,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar código ou motivo...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Nenhum motivo encontrado'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final e = filtered[index];
                              return ListTile(
                                title: Text(e.key + ' – ' + e.value, style: const TextStyle(fontSize: 13)),
                                trailing: e.key == current ? const Icon(Icons.check, color: Colors.green) : null,
                                onTap: () => Navigator.pop(ctx, e.key),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ],
          );
        },
      ),
    ).whenComplete(searchCtrl.dispose);
  }

  Future<void> _editItem(ScrapItem item) async {
    final qtdCtrl = TextEditingController(text: item.quantidade);
    final pesoCtrl = TextEditingController(
      text: item.pesoGramas > 0 ? '${item.pesoGramas}' : '',
    );
    String selectedMotivo = item.motivo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final peso = int.tryParse(pesoCtrl.text) ?? 0;
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pesoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Peso do scrap (gramas)',
                      hintText: 'Ex.: 300',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setLocal(() {}),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Equivale a ${(peso / 1000).toStringAsFixed(3)} kg',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Motivo', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickMotivo(ctx, selectedMotivo);
                      if (picked != null) setLocal(() => selectedMotivo = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedMotivo.isEmpty
                                  ? 'Selecione o código'
                                  : selectedMotivo + ' – ' + (MotivosScrap.lista[selectedMotivo] ?? ''),
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedMotivo.isEmpty ? Colors.grey.shade600 : null,
                              ),
                            ),
                          ),
                          const Icon(Icons.search, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
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
        item.pesoGramas = int.tryParse(pesoCtrl.text.trim()) ?? 0;
        item.motivo = selectedMotivo;
      });
      await _saveDraft();
    }

    qtdCtrl.dispose();
    pesoCtrl.dispose();
  }

  Future<void> _gerarPdf() async {
    if (_gerandoPdf) return;
    setState(() => _gerandoPdf = true);
    try {
      _syncHeader();
      await _saveDraft();
      final saved = await PdfService.generateScrapPdf(report);

      // saved=false = usuário cancelou a impressão -> sem notificação.
      if (saved && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('PDF salvo no histórico.'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VER',
              onPressed: () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('ERRO AO GERAR PDF DO SCRAP: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $error'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  Widget _buildSection(String title, List<ScrapItem> items) {
    final totalGramas = items.fold<int>(0, (sum, item) => sum + item.pesoGramas);
    final totalKg = (totalGramas / 1000).toStringAsFixed(3);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Expanded(
              child: Text('$title (${items.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
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
        subtitle: Text('Total: $totalGramas g ($totalKg kg)'),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Nenhum item',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...items.map((item) {
              final motivoLabel = item.motivo.isEmpty
                  ? '\u2013'
                  : '${item.motivo} ${MotivosScrap.lista[item.motivo] ?? ''}';
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                title: Text(item.terminal,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Qtd: ${item.quantidade.isEmpty ? "\u2013" : item.quantidade}  |  '
                  'Peso: ${item.pesoGramas} g (${item.pesoKgFormatado} kg)\n'
                  'Motivo: $motivoLabel',
                ),
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
                      onPressed: () async {
                        setState(() => items.remove(item));
                        await _saveDraft();
                      },
                    ),
                  ],
                ),
                onTap: () => _editItem(item),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(current: 'scrap'),
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
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.badge),
              title: const Text('Cabeçalho do turno',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_headerSummary()),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                  TextField(
                    controller: _dataCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Data', suffixIcon: Icon(Icons.calendar_today)),
                    onTap: () async {
                      final picked = await pickDate(context, initial: _dataCtrl.text);
                      if (picked != null) {
                        setState(() => _dataCtrl.text = picked);
                        await _headerChanged(picked);
                      }
                    },
                  ),
                  TextField(
                    controller: _maquinaCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Máquina'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  TextField(
                    controller: _operadorCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Operador'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  TextField(
                    controller: _liderCtrl,
                    onChanged: _headerChanged,
                    decoration: const InputDecoration(labelText: 'Nome do Líder'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [UpperCaseTextFormatter()],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _matriculaCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'Matrícula'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _turnoCtrl,
                          onChanged: _headerChanged,
                          decoration: const InputDecoration(labelText: 'Turno'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
