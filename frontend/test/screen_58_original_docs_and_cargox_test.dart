import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/import_documentation/screens/original_docs_and_cargox_screen.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _createTestDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:28080/api/v1'));
  dio.httpClientAdapter = _MockHttpClientAdapter();
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 58: OriginalDocsAndCargoXScreen Widget & Verification Tests', () {
    testWidgets('Renders in Arabic with pure Arabic headers and SelectionArea', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDio = _createTestDio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: OriginalDocsAndCargoXScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold title in Arabic
      expect(find.text('تحصيل المستندات وكارجو إكس — المرحلة 4'), findsOneWidget);

      // Verify Nav Tabs in Arabic
      expect(find.text('تحصيل أصول المستندات وتتبع الكورير'), findsOneWidget);
      expect(find.text('منظومة كارجو إكس والمانيفست الرقمي'), findsOneWidget);

      // Verify SelectionArea exists for copy enablement
      expect(find.byType(SelectionArea), findsWidgets);

      // Verify refresh button exists
      expect(find.byIcon(Icons.refresh), findsWidgets);
    });

    testWidgets('Renders in English with pure English headers and tabs', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDio = _createTestDio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('en'));
              return n;
            }),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: OriginalDocsAndCargoXScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold title in English
      expect(find.text('Original Docs Collection & CargoX Hub — Phase 4'), findsOneWidget);

      // Verify Nav Tabs in English
      expect(find.text('Original Docs Collection & Courier'), findsOneWidget);
      expect(find.text('CargoX Blockchain & ACI Hub'), findsOneWidget);

      // Verify SelectionArea exists for copy enablement
      expect(find.byType(SelectionArea), findsWidgets);
    });

    testWidgets('Can switch tabs between SubTab 0 and SubTab 1', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testDio = _createTestDio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(testDio),
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: OriginalDocsAndCargoXScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tab 1 (CargoX Hub)
      await tester.tap(find.text('منظومة كارجو إكس والمانيفست الرقمي'));
      await tester.pumpAndSettle();

      // Tap back to Tab 0
      await tester.tap(find.text('تحصيل أصول المستندات وتتبع الكورير'));
      await tester.pumpAndSettle();

      expect(find.text('تحصيل المستندات وكارجو إكس — المرحلة 4'), findsOneWidget);
    });
  });
}
