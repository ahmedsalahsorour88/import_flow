import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/copyable_data_helper.dart';
import 'package:frontend/features/warehouse_receiving/models/goods_in_transit_model.dart';
import 'package:frontend/features/warehouse_receiving/providers/goods_in_transit_provider.dart';
import 'package:frontend/features/warehouse_receiving/screens/goods_in_transit_screen.dart';

class _MockGoodsInTransitNotifier extends GoodsInTransitNotifier {
  final List<GitLineItemModel> mockItems;
  _MockGoodsInTransitNotifier(this.mockItems) {
    state = AsyncValue.data(mockItems);
  }

  @override
  void initLedger() {
    state = AsyncValue.data(mockItems);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockGitItem1 = GitLineItemModel(
    importFileId: 1,
    importFileCode: 'IMP-2026-001',
    poId: 101,
    poNumber: 'PO-2026-IT-001',
    itemCode: 'ITM-SR-101',
    itemName: 'Enterprise Cloud Rack Servers',
    invoicedQty: 250.0,
    packagesCount: 125,
    packageType: 'CT - Carton',
    containersCount: 2,
    containerType: '40ft High Cube',
    certifiedDate: '2026-08-20',
    isDeliveredToWarehouse: false,
  );

  final mockGitItem2 = GitLineItemModel(
    importFileId: 2,
    importFileCode: 'IMP-2026-002',
    poId: 102,
    poNumber: 'PO-2026-MED-002',
    itemCode: 'ITM-SR-202',
    itemName: 'Digital Ultrasound Probes',
    invoicedQty: 60.0,
    packagesCount: 30,
    packageType: 'BX - Box',
    containersCount: 1,
    containerType: '20ft Standard',
    certifiedDate: '2026-08-25',
    isDeliveredToWarehouse: true,
  );

  String? lastCopiedText;

  setUp(() {
    lastCopiedText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          lastCopiedText = (methodCall.arguments as Map)['text'] as String?;
          return null;
        }
        return null;
      },
    );
  });

  Widget buildTestScreen({
    Locale locale = const Locale('ar'),
    List<GitLineItemModel>? items,
  }) {
    final ledgerItems = items ?? [mockGitItem1, mockGitItem2];
    return ProviderScope(
      overrides: [
        goodsInTransitProvider.overrideWith((ref) => _MockGoodsInTransitNotifier(ledgerItems)),
      ],
      child: AppLocalizationsProvider(
        locale: locale,
        child: MaterialApp(
          home: Directionality(
            textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: const Scaffold(
              body: GoodsInTransitScreen(),
            ),
          ),
        ),
      ),
    );
  }

  group('Screen 63: GoodsInTransitScreen Widget & Copy Tests', () {
    testWidgets('Renders with SelectionArea and 4 export toolbar buttons (Arabic)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // 1. Verify SelectionArea exists
      expect(find.byType(SelectionArea), findsWidgets);

      // 2. Verify 4 export buttons in top banner
      expect(find.text('نسخ ملف البيانات'), findsOneWidget);
      expect(find.text('طباعة تقرير'), findsOneWidget);
      expect(find.text('تصدير مجدول'), findsOneWidget);
      expect(find.text('تصدير إكسيل'), findsOneWidget);

      // 3. Verify KPI cards
      expect(find.text('الشحنات في الطريق'), findsOneWidget);
      expect(find.text('أوامر الشراء'), findsOneWidget);
      expect(find.text('إجمالي العدد بالفاتورة'), findsOneWidget);

      // 4. Verify Table headers including Actions
      expect(find.text('رقم ملف الشحنة'), findsOneWidget);
      expect(find.text('رقم أمر الشراء'), findsOneWidget);
      expect(find.text('كود الصنف'), findsOneWidget);
      expect(find.text('اسم وبيان الصنف'), findsOneWidget);
      expect(find.text('العدد بالفاتورة'), findsOneWidget);
      expect(find.text('عدد الكراتين والطرود'), findsOneWidget);
      expect(find.text('عدد الحاويات ونوعها'), findsOneWidget);
      expect(find.text('تاريخ الاعتماد'), findsOneWidget);
      expect(find.text('حالة الرصيد'), findsOneWidget);
      expect(find.text('الإجراءات'), findsOneWidget);
    });

    testWidgets('Clickable copy badges on File Code, PO Number, and Item Code', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Verify CopyableTableCell is present for cells
      expect(find.byType(CopyableTableCell), findsWidgets);

      // Verify item codes rendered
      final fileCodeFinder = find.text('IMP-2026-001');
      expect(fileCodeFinder, findsWidgets);

      await tester.ensureVisible(fileCodeFinder.last);
      await tester.pumpAndSettle();

      // Tap on file code badge
      await tester.tap(fileCodeFinder.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify clipboard was set
      expect(lastCopiedText, 'IMP-2026-001');

      // Verify SnackBar confirmation appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('IMP-2026-001'), findsWidgets);

      // Tap on PO Number badge
      final poFinder = find.text('PO-2026-IT-001');
      await tester.ensureVisible(poFinder);
      await tester.pumpAndSettle();
      await tester.tap(poFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(lastCopiedText, 'PO-2026-IT-001');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Quick row summary copy button copies row details', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // Find quick row copy buttons
      final copyRowButtons = find.byIcon(Icons.copy_rounded);
      expect(copyRowButtons, findsWidgets);

      await tester.ensureVisible(copyRowButtons.first);
      await tester.pumpAndSettle();

      // Tap the first row copy action
      await tester.tap(copyRowButtons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify clipboard contains row details
      expect(lastCopiedText != null, true);
      expect(lastCopiedText!.contains('IMP-2026-001'), true);
      expect(lastCopiedText!.contains('PO-2026-IT-001'), true);

      // Verify SnackBar confirmation
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('تم نسخ ملخص بند البضاعة في الطريق إلى الحافظة بنجاح'), findsOneWidget);
    });

    testWidgets('Search field displays copy button when text is entered and clears text', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Initially empty: clear and copy buttons not visible
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter search query
      await tester.enterText(searchField, 'Cloud');
      await tester.pumpAndSettle();

      // Verify clear icon and copy icon appear
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap copy button in search field
      final copyFieldBtn = find.byTooltip('نسخ القيمة');
      expect(copyFieldBtn, findsOneWidget);
      await tester.tap(copyFieldBtn);
      await tester.pumpAndSettle();

      expect(lastCopiedText, 'Cloud');
      expect(find.byType(SnackBar), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Verify search is cleared
      expect(find.text('Cloud'), findsNothing);
    });

    testWidgets('English locale renders correctly with 4 export buttons and English columns', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Copy Dossier'), findsOneWidget);
      expect(find.text('Print PDF'), findsOneWidget);
      expect(find.text('Export TSV'), findsOneWidget);
      expect(find.text('Export Excel'), findsOneWidget);

      expect(find.text('In-Transit Shipments'), findsOneWidget);
      expect(find.text('Purchase Orders'), findsOneWidget);
      expect(find.text('Import File Code'), findsOneWidget);
      expect(find.text('PO Number'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
    });
  });
}
