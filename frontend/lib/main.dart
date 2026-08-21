import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/api_constants.dart';
import 'features/home/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';

final appReloadKeyProvider = StateProvider<int>((ref) => 0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow(null, () async {
        await windowManager.setPreventClose(true);
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }

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
                'تأكد من تشغيل سيرفر الباك إند على ${ApiConstants.serverUrl} ثم اضغط على زر إعادة المحاولة أدناه.',
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
              Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      ref.read(appReloadKeyProvider.notifier).state++;
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('إعادة المحاولة وتحديث البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                },
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

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      trackVisibility: true,
      child: child,
    );
  }
}

class ImportFlowApp extends ConsumerStatefulWidget {
  const ImportFlowApp({super.key});

  @override
  ConsumerState<ImportFlowApp> createState() => _ImportFlowAppState();
}

class _ImportFlowAppState extends ConsumerState<ImportFlowApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final dio = Dio();
        await dio.post('${ApiConstants.baseUrl}/shutdown').timeout(const Duration(milliseconds: 300)).catchError((_) {});
      } catch (_) {}
      try {
        await Process.run('taskkill', ['/F', '/IM', 'backend.exe', '/T']);
      } catch (_) {}
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reloadKey = ref.watch(appReloadKeyProvider);
    final authState = ref.watch(authProvider);

    return KeyedSubtree(
      key: ValueKey(reloadKey),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ImportFlow ERP - Sorour Logistics (v1.0.0)',
        theme: AppTheme.lightTheme,
        scrollBehavior: AppCustomScrollBehavior(),
        home: authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
