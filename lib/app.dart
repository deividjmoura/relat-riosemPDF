import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

class RelatoriosApp extends StatelessWidget {
  const RelatoriosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relatórios Lear',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
