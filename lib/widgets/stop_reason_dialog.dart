import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Diálogo de escolha do motivo da pausa, com campo de busca.
class StopReasonDialog extends StatefulWidget {
  const StopReasonDialog({super.key});

  @override
  State<StopReasonDialog> createState() => _StopReasonDialogState();
}

class _StopReasonDialogState extends State<StopReasonDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<String> _allReasons = [
    ...TempoMortoCategories.list,
    ...TempoPerdidoCategories.list,
    ...ParadasProgramadasCategories.list,
  ];

  /// Normaliza para a busca ignorar maiúsculas e acentos.
  static String _norm(String s) {
    const from = 'àáâãäåèéêëìíîïòóôõöùúûüçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ';
    const to = 'aaaaaaaaeeeeiiiiooooouuuucnAAAAAAAAEEEEIIIIOOOOOUUUUCN';
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idx = from.indexOf(s[i]);
      buf.write(idx < 0 ? s[i] : to[idx]);
    }
    return buf.toString().toLowerCase();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _norm(_query.trim());
    final filtered = q.isEmpty
        ? _allReasons
        : _allReasons.where((r) => _norm(r).contains(q)).toList();

    return AlertDialog(
      title: const Text('Essa pausa foi de que?'),
      content: SizedBox(
        width: double.maxFinite,
        height: 440,
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar motivo...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Nenhum motivo encontrado'),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final reason = filtered[index];
                        return ListTile(
                          title: Text(reason),
                          onTap: () => Navigator.pop(context, reason),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
