import 'package:flutter/material.dart';
import '../../models/rdp_report.dart';

class RdpSetupDialog extends StatefulWidget {
  const RdpSetupDialog({super.key});

  @override
  State<RdpSetupDialog> createState() => _RdpSetupDialogState();
}

class _RdpSetupDialogState extends State<RdpSetupDialog> {
  final _pnCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _terminoCtrl = TextEditingController();
  final _taxaPlanCtrl = TextEditingController();
  final _taxaRealCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();

  @override
  void dispose() {
    _pnCtrl.dispose();
    _inicioCtrl.dispose();
    _terminoCtrl.dispose();
    _taxaPlanCtrl.dispose();
    _taxaRealCtrl.dispose();
    _qtdCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_pnCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PN da peça é obrigatório')),
      );
      return;
    }

    final linha = RdpLine(
      pnPeca: _pnCtrl.text.trim(),
      inicioAtiv: _inicioCtrl.text.trim(),
      terminoAtiv: _terminoCtrl.text.trim(),
      taxaPlanejada: _taxaPlanCtrl.text.trim(),
      taxaReal: _taxaRealCtrl.text.trim(),
      quantidadePecas: _qtdCtrl.text.trim(),
    );

    Navigator.pop(context, linha);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Setup'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pnCtrl,
              decoration: const InputDecoration(labelText: 'PN da Peça *'),
              autofocus: true,
            ),
            TextField(
              controller: _inicioCtrl,
              decoration: const InputDecoration(labelText: 'Início da Atividade (HH:MM)'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: _terminoCtrl,
              decoration: const InputDecoration(labelText: 'Término da Atividade (HH:MM)'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: _taxaPlanCtrl,
              decoration: const InputDecoration(labelText: 'Taxa Planejada'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _taxaRealCtrl,
              decoration: const InputDecoration(labelText: 'Taxa Real'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _qtdCtrl,
              decoration: const InputDecoration(labelText: 'Quantidade de Peças'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvar,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
