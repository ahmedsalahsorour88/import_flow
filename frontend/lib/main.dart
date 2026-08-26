import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:window_manager/window_manager.dart';
import 'core/constants/api_constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';

final appReloadKeyProvider = StateProvider<int>((ref) => 0);

Future<void> _ensureBackendRunning() async {
  if (!kIsWeb && Platform.isWindows) {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(milliseconds: 500)));
      await dio.get('${ApiConstants.serverUrl}/docs');
    } catch (_) {
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final backendPath = '$exeDir\\backend.exe';
        if (File(backendPath).existsSync()) {
          Process.start(backendPath, [], mode: ProcessStartMode.detached);
          await Future.delayed(const Duration(milliseconds: 1200));
        }
      } catch (_) {}
    }
  }
}

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
    await _ensureBackendRunning();
  }

  // Custom friendly error widget — prevents red screen of death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final errStr = details.exceptionAsString();
    final isNetwork = errStr.toLowerCase().contains('connection') ||
        errStr.toLowerCase().contains('socket') ||
        errStr.toLowerCase().contains('dio') ||
        errStr.toLowerCase().contains('http');

    return Material(
      color: Colors.grey.shade100,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNetwork ? Icons.cloud_off_rounded : Icons.info_outline_rounded,
                size: 54,
                color: isNetwork ? AppTheme.crimson : AppTheme.cobalt,
              ),
              const SizedBox(height: 14),
              Text(
                isNetwork ? 'Server Connection Notice' : 'Application Interface Notice',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isNetwork
                    ? 'Make sure the backend server is running on ${ApiConstants.serverUrl} then press Reload.'
                    : 'Press Reload to refresh the interface.',
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
                  'Details:\n$errStr',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.crimson,
                      fontFamily: 'monospace'),
                  textAlign: TextAlign.start,
                ),
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      await _ensureBackendRunning();
                      ref.read(appReloadKeyProvider.notifier).state++;
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Reload Application',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Custom scroll behavior: enables mouse drag scrolling on desktop
// ─────────────────────────────────────────────────────────────────────────────

class AppCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      trackVisibility: true,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root application widget
// ─────────────────────────────────────────────────────────────────────────────

class ImportFlowApp extends ConsumerStatefulWidget {
  const ImportFlowApp({super.key});

  @override
  ConsumerState<ImportFlowApp> createState() => _ImportFlowAppState();
}

class _ImportFlowAppState extends ConsumerState<ImportFlowApp>
    with WindowListener {
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
      // 1. Auto-backup dev DB on every close (5s timeout, silent)
      try {
        final dio = ref.read(dioProvider);
        await dio
            .post(
              '${ApiConstants.productionSync}/backup',
              queryParameters: {'target': 'dev'},
            )
            .timeout(const Duration(seconds: 5))
            .catchError(
                (_) => Response(requestOptions: RequestOptions(path: '')));
      } catch (_) {}

      // 2. Graceful backend shutdown
      try {
        final dio = ref.read(dioProvider);
        await dio
            .post('${ApiConstants.serverUrl}/shutdown')
            .timeout(const Duration(milliseconds: 400))
            .catchError(
                (_) => Response(requestOptions: RequestOptions(path: '')));
      } catch (_) {}

      // 3. Kill backend process
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
    final locale = ref.watch(localeProvider);
    final isRtl = locale.languageCode == 'ar';

    return KeyedSubtree(
      key: ValueKey(reloadKey),
      child: AppLocalizationsProvider(
        locale: locale,
        child: Directionality(
          // Auto RTL for Arabic, LTR for English
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ImportFlow ERP - Sorour Logistics (v1.0.48)',
            theme: AppTheme.lightTheme,
            scrollBehavior: AppCustomScrollBehavior(),
            locale: locale,
            home:
                authState.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          ),
        ),
      ),
    );
  }
}
