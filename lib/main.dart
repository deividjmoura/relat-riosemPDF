import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseService.instance),
        ChangeNotifierProvider(create: (_) => TimerService.instance),
      ],
      child: const RelatoriosApp(),
    ),
  );
}
