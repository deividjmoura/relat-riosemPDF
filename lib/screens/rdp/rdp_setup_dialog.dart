import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/rdp_report.dart';
import '../../utils/input_helpers.dart';

class RdpSetupDialog extends StatefulWidget {
  /// Se informado, abre em modo edição
  final RdpLine? existing;

  const RdpSetupDialog({super.key, this.existing});

  @override
  State<RdpSetupDialog> createState() => _RdpSetupDialogState();
}

class _RdpSetupDialogState extends State<RdpSetupDialog> {
  late final TextEditingController _pnCtrl;
  late final TextEditingController _inicioCtrl;
  late final TextEditingController _terminoCtrl;
  late final TextEditingController _taxaPlanCtrl;
  late final TextEditingController _taxaRealCtrl;
  late final TextEditingController _qtdCtrl;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _pnCtrl = TextEditingController(text: e?.pnPeca ?? '');
    _inicioCtrl = TextEditingController(text: e?.inicioAtiv ?? '');
    _terminoCtrl = TextEditingController(text: e?.terminoAtiv ?? '');
    _taxaPlanCtrl = TextEditingController(text: e?.taxaPlanejada ?? '');
    _taxaRealCtrl = TextEditingController(text: e?.taxaReal ?? '');
    _qtdCtrl = TextEditingController(text: e?.quantidadePecas ?? '');
  }

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
    if (_pnCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PN da peça é obrigatório')),
      );
      return;
    }

    if (isEditing) {
      final e = widget.existing!;
      e.pnPeca = _pnCtrl.text.trim();
      e.inicioAtiv = _inicioCtrl.text.trim();
      e.terminoAtiv = _terminoCtrl.text.trim();
      e.taxaPlanejada = _taxaPlanCtrl.text.trim();
      e.taxaReal = _taxaRealCtrl.text.trim();
      e.quantidadePecas = _qtdCtrl.text.trim();
      Navigator.pop(context, e);
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Editar Setup' : 'Adicionar Setup'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pnCtrl,
              decoration: const InputDecoration(labelText: 'PN da Peça *'),
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            TextField(
              controller: _inicioCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Início da Atividade (HH:MM)',
                hintText: 'Toque para escolher',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                final t = await pickTime(context, initial: _inicioCtrl.text);
                if (t != null) setState(() => _inicioCtrl.text = t);
              },
            ),
            TextField(
              controller: _terminoCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Término da Atividade (HH:MM)',
                hintText: 'Pode preencher depois',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () async {
                final t = await pickTime(context, initial: _terminoCtrl.text);
                if (t != null) setState(() => _terminoCtrl.text = t);
              },
            ),
            TextField(
              controller: _taxaPlanCtrl,
              decoration: const InputDecoration(labelText: 'Taxa Planejada'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: _taxaRealCtrl,
              decoration: const InputDecoration(labelText: 'Taxa Real'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: _qtdCtrl,
              decoration: const InputDecoration(labelText: 'Quantidade de Peças'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
