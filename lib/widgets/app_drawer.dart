import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/history_screen.dart';
import '../screens/rdp/rdp_form_screen.dart';
import '../screens/scrap/scrap_form_screen.dart';
import '../utils/app_theme.dart';

/// Menu lateral de navegação do app.
///
/// A navegação sempre volta ao Início antes de abrir a seção destino,
/// então a pilha nunca passa de 2 telas e o botão voltar é previsível.
class AppDrawer extends StatelessWidget {
  /// Tela atual: 'home', 'rdp', 'scrap' ou 'history'.
  final String current;

  const AppDrawer({super.key, required this.current});

  void _go(BuildContext context, String target, Widget Function() page) {
    final nav = Navigator.of(context);
    nav.pop(); // fecha o drawer
    if (target == current) return;
    nav.popUntil((route) => route.isFirst);
    if (target == 'home') return;
    nav.push(MaterialPageRoute(builder: (_) => page()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.learRed, AppTheme.learRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assessment,
                      size: 28,
                      color: AppTheme.learRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Relatórios Lear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Produção do Corte',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            _item(
              context,
              id: 'home',
              icon: Icons.home,
              title: 'Início',
              onTap: () => _go(context, 'home', () => const SizedBox()),
            ),
            _item(
              context,
              id: 'rdp',
              icon: Icons.precision_manufacturing,
              title: 'RDP - Produção',
              color: Colors.blue.shade700,
              onTap: () => _go(context, 'rdp', () => const RdpFormScreen()),
            ),
            _item(
              context,
              id: 'scrap',
              icon: Icons.qr_code_scanner,
              title: 'Registro de Scrap',
              color: Colors.orange.shade800,
              onTap: () => _go(context, 'scrap', () => const ScrapFormScreen()),
            ),
            _item(
              context,
              id: 'history',
              icon: Icons.history,
              title: 'Histórico de PDFs',
              color: Colors.green.shade700,
              onTap: () => _go(context, 'history', () => const HistoryScreen()),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '100% offline • Dados no aparelho',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final selected = id == current;
    final c = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: selected ? c : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : null,
          color: selected ? c : null,
        ),
      ),
      selected: selected,
      selectedTileColor: c.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
