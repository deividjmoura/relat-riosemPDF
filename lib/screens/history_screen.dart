import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../services/database_service.dart';

/// Histórico de PDFs gerados: permite rever, reenviar e excluir documentos.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseService.instance;
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await _db.getGeneratedDocs();
    if (mounted) setState(() => {_docs = docs, _loading = false});
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<Uint8List?> _readBytes(Map<String, dynamic> doc) async {
    try {
      final file = File(doc['path'] as String);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _preview(Map<String, dynamic> doc) async {
    final bytes = await _readBytes(doc);
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo não encontrado no aparelho.')),
      );
      return;
    }
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: (doc['filename'] as String?) ?? 'documento',
    );
  }

  Future<void> _share(Map<String, dynamic> doc) async {
    final bytes = await _readBytes(doc);
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo não encontrado no aparelho.')),
      );
      return;
    }
    await Printing.sharePdf(
      bytes: bytes,
      filename: (doc['filename'] as String?) ?? 'documento.pdf',
    );
  }

  Future<void> _delete(Map<String, dynamic> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir do histórico?'),
        content: Text('Remover "${doc['titulo']}"? O arquivo será apagado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final file = File(doc['path'] as String);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _db.deleteGeneratedDoc(doc['id'] as String);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento excluído.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de PDFs'),
        backgroundColor: const Color(0xFFE30613),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhum PDF gerado ainda.'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _docs.length,
                  itemBuilder: (context, i) {
                    final doc = _docs[i];
                    final tipo = (doc['tipo'] as String?) ?? '';
                    final isRdp = tipo == 'RDP';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isRdp ? Colors.blue : Colors.orange)
                              .withOpacity(0.15),
                          child: Icon(
                            isRdp
                                ? Icons.precision_manufacturing
                                : Icons.qr_code_scanner,
                            color: isRdp
                                ? Colors.blue.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                        title: Text((doc['titulo'] as String?) ?? ''),
                        subtitle:
                            Text(_formatDate((doc['created_at'] as String?) ?? '')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              tooltip: 'Ver',
                              onPressed: () => _preview(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Reenviar',
                              onPressed: () => _share(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Excluir',
                              onPressed: () => _delete(doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
