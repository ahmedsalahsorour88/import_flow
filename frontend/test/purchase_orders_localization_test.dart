import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/localization/locale_provider.dart';
import 'package:frontend/features/projects/models/project_model.dart';
import 'package:frontend/features/projects/providers/projects_provider.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';
import 'package:frontend/features/purchase_orders/screens/purchase_orders_screen.dart';

class MockPurchaseOrdersNotifier extends PurchaseOrdersNotifier {
  MockPurchaseOrdersNotifier(Ref ref, List<PurchaseOrderModel> orders) : super(Dio(), ref) {
    state = PurchaseOrdersState(
      purchaseOrders: orders,
      isLoading: false,
    );
  }

  @override
  Future<void> fetchPurchaseOrders() async {}
}

class MockProjectsNotifier extends ProjectsNotifier {
  MockProjectsNotifier(List<ProjectModel> projects) : super(Dio()) {
    state = AsyncValue.data(projects);
  }

  @override
  Future<void> fetchProjects({bool includeInactive = true, String? status, String? search}) async {}
}

void main() {
  final sampleOrders = [
    PurchaseOrderModel(
      poId: 1,
      poNumber: 'PO-2026-0001',
      proformaInvoiceNumber: 'PI-9901',
      projectId: 10,
      projectName: 'Main Hospital Expansion',
      companyId: 20,
      companyName: 'Al-Farouk Pharma',
      supplierId: 30,
      supplierName: 'Global Medtech Corp',
      incotermId: 1,
      currencyId: 1,
      totalAmountFob: 250000.0,
      totalCbm: 45.2,
      totalGrossWeightKg: 12500.0,
      status: 'Approved',
      currencyCode: 'USD',
      exchangeRate: 48.5,
      orderDate: DateTime(2026, 8, 23),
      isActive: true,
      items: [],
      packingListItems: [],
      palletPlanItems: [],
    ),
  ];

  final sampleProjects = [
    ProjectModel(
      projectId: 10,
      projectCode: 'PRJ-EXP',
      projectName: 'Main Hospital Expansion',
      projectOwner: 'Ahmed Sorour',
      companyId: 20,
      supplierId: 30,
      incotermId: 1,
      isActive: true,
      createdAt: DateTime(2026, 8, 20),
    ),
  ];

  group('PurchaseOrders Localization & Anti-Stacked Tests (Screen 2)', () {
    test('Arabic AppLocalizationsAr returns pure Arabic for PO keys', () {
      const lAr = AppLocalizationsAr();
      expect(lAr.purchaseOrdersTitle, equals('أوامر الشراء والفواتير المبدئية'));
      expect(lAr.newPurchaseOrder, equals('أمر شراء جديد'));
      expect(lAr.totalOrdersMetric, equals('إجمالي أوامر الشراء'));
      expect(lAr.totalFobMetric, equals('إجمالي قيمة البضاعة'));
      expect(lAr.poReferenceCol, equals('رقم أمر الشراء'));
      expect(lAr.discrepancyWarningTitle, equals('تنبيه: عدم تطابق بين الفاتورة المبدئية وبيان التعبئة'));
      expect(lAr.backToEdit, equals('الرجوع للتعديل'));
      expect(lAr.continueAndSave, equals('الاستمرار وحفظ أمر الشراء'));

      // Check anti-stacked: zero parentheses with English translations
      expect(lAr.purchaseOrdersTitle.contains('Purchase Orders'), isFalse);
      expect(lAr.newPurchaseOrder.contains('New PO'), isFalse);
      expect(lAr.discrepancyWarningTitle.contains('Discrepancy Alert'), isFalse);
    });

    test('English AppLocalizationsEn returns pure English for PO keys', () {
      const lEn = AppLocalizationsEn();
      expect(lEn.purchaseOrdersTitle, equals('Purchase Orders & Proforma Invoices'));
      expect(lEn.newPurchaseOrder, equals('New Purchase Order'));
      expect(lEn.totalOrdersMetric, equals('Total POs'));
      expect(lEn.totalFobMetric, equals('Total PI/PO Amount'));
      expect(lEn.poReferenceCol, equals('PO Reference'));
      expect(lEn.discrepancyWarningTitle, equals('Alert: Discrepancy Between Invoice & Packing List'));
      expect(lEn.backToEdit, equals('Back to Edit'));
      expect(lEn.continueAndSave, equals('Continue & Save PO'));

      // Check anti-stacked: zero Arabic letters
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      expect(arabicRegex.hasMatch(lEn.purchaseOrdersTitle), isFalse);
      expect(arabicRegex.hasMatch(lEn.newPurchaseOrder), isFalse);
      expect(arabicRegex.hasMatch(lEn.discrepancyWarningTitle), isFalse);
    });

    testWidgets('Renders PurchaseOrdersScreen in Arabic mode with Arabic texts only', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('ar'));
              return n;
            }),
            purchaseOrdersProvider.overrideWith((ref) => MockPurchaseOrdersNotifier(ref, sampleOrders)),
            projectsProvider.overrideWith((ref) => MockProjectsNotifier(sampleProjects)),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PurchaseOrdersScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('أوامر الشراء والفواتير المبدئية'), findsOneWidget);
      expect(find.text('أمر شراء جديد'), findsOneWidget);
      expect(find.text('إجمالي أوامر الشراء'), findsOneWidget);
      expect(find.text('إجمالي قيمة البضاعة'), findsNWidgets(2));
      expect(find.text('رقم أمر الشراء'), findsOneWidget);

      // Verify no stacked strings exist on screen
      expect(find.text('Purchase Orders & Proforma Invoices (أوامر الشراء والفواتير المبدئية)'), findsNothing);
      expect(find.text('New Purchase Order (أمر شراء جديد)'), findsNothing);
    });

    testWidgets('Renders PurchaseOrdersScreen in English mode with English texts only', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith((ref) {
              final n = LocaleNotifier();
              n.setLocale(const Locale('en'));
              return n;
            }),
            purchaseOrdersProvider.overrideWith((ref) => MockPurchaseOrdersNotifier(ref, sampleOrders)),
            projectsProvider.overrideWith((ref) => MockProjectsNotifier(sampleProjects)),
          ],
          child: const MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('en'),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: PurchaseOrdersScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Purchase Orders & Proforma Invoices'), findsOneWidget);
      expect(find.text('New Purchase Order'), findsOneWidget);
      expect(find.text('Total POs'), findsOneWidget);
      expect(find.text('Total PI/PO Amount'), findsNWidgets(2));
      expect(find.text('PO Reference'), findsOneWidget);

      // Verify no stacked strings exist on screen
      expect(find.text('Purchase Orders & Proforma Invoices (أوامر الشراء والفواتير المبدئية)'), findsNothing);
    });
  });
}
