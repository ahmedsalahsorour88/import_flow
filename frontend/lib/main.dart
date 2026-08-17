import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom friendly error widget preventing red screen of death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.grey.shade100,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: AppTheme.crimson),
              const SizedBox(height: 14),
              const Text(
                'تنبيه: تعذر الاتصال بسيرفر النظام أو جلب البيانات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'تأكد من تشغيل سيرفر الباك إند (FastAPI) على http://127.0.0.1:8000 ثم قم بعمل تحديث للصفحة (F5).',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: SelectableText(
                  'تفاصيل الخطأ:\n${details.exceptionAsString()}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.crimson, fontFamily: 'monospace'),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () {},
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('تحديث الصفحة (F5)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: ImportFlowApp(),
    ),
  );
}

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class ImportFlowApp extends StatelessWidget {
  const ImportFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImportFlow ERP',
      theme: AppTheme.lightTheme,
      scrollBehavior: AppCustomScrollBehavior(),
      home: const HomeScreen(),
    );
  }
}
