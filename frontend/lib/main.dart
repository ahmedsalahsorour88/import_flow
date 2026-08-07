import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ImportFlowApp(),
    ),
  );
}

class ImportFlowApp extends StatelessWidget {
  const ImportFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImportFlow ERP',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
