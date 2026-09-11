import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StopReasonDialog extends StatelessWidget {
  const StopReasonDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Junta todas as categorias possíveis
    final allReasons = [
      ...TempoMortoCategories.list,
      ...TempoPerdidoCategories.list,
      ...ParadasProgramadasCategories.list,
    ];

    return AlertDialog(
      title: const Text('Essa pausa foi de que?'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: allReasons.length,
          itemBuilder: (context, index) {
            final reason = allReasons[index];
            return ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(context, reason),
            );
          },
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
