import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/copyable_data_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CopyableDataHelper Unit & Widget Tests', () {
    testWidgets('CopyHelper.copy sets ClipboardData and shows confirmation SnackBar', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => CopyHelper.copy(context, 'IMP-2026-0001'),
                    child: const Text('Copy Test'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Copy Test'));
      await tester.pumpAndSettle();

      expect(copiedText, 'IMP-2026-0001');
      expect(find.text('تم النسخ إلى الحافظة بنجاح'), findsOneWidget);
    });

    testWidgets('CopyableText copies on double-tap and renders correctly', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('en'),
            child: Scaffold(
              body: CopyableText(
                'BKG-2026-0099',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      expect(find.text('BKG-2026-0099'), findsOneWidget);

      await tester.tap(find.text('BKG-2026-0099'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('BKG-2026-0099'));
      await tester.pumpAndSettle();

      expect(copiedText, 'BKG-2026-0099');
      expect(find.text('Copied to clipboard successfully'), findsOneWidget);
    });

    testWidgets('CopyableTableCell handles right-click context menu and copying', (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Scaffold(
              body: CopyableTableCell(
                value: '100,000 USD',
                rowSummary: 'PO-001\t100,000 USD\tSupplier A',
                child: Text('100,000 USD'),
              ),
            ),
          ),
        ),
      );

      // Trigger secondary tap (right click)
      await tester.tap(find.text('100,000 USD'), buttons: 2);
      await tester.pumpAndSettle();

      expect(find.text('نسخ القيمة'), findsOneWidget);
      expect(find.text('نسخ بيانات السطر'), findsOneWidget);

      await tester.tap(find.text('نسخ القيمة'));
      await tester.pumpAndSettle();

      expect(copiedText, '100,000 USD');
    });
  });
}
