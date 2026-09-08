import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/customs_tariff/models/customs_tariff_model.dart';
import 'package:frontend/features/customs_tariff/providers/customs_tariff_provider.dart';
import 'package:frontend/features/import_documentation/screens/customs_declaration46_screen.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class _MockImportFilesNotifier extends ImportFilesNotifier {
  final List<ImportFileModel> initialFiles;
  _MockImportFilesNotifier(this.initialFiles) : super(Dio()) {
    state = AsyncValue.data(initialFiles);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = AsyncValue.data(initialFiles);
  }
}

class _MockCustomsTariffNotifier extends CustomsTariffNotifier {
  final List<CustomsTariffModel> initialTariffs;
  _MockCustomsTariffNotifier(this.initialTariffs)
      : super(ref: _FakeRef(), showInactive: false, search: '', dio: Dio()) {
    state = AsyncValue.data(initialTariffs);
  }

  @override
  Future<void> fetchTariffs() async {
    state = AsyncValue.data(initialTariffs);
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomsDeclaration46Screen Auto-Population & Compliance Tests', () {
    testWidgets('Renders and auto-populates ACID, Form 4, B/L, Duties, Exemption, and Approvals on file selection', (tester) async {
      final mockFile = ImportFileModel(
        importFileId: 5,
        importFileCode: 'IMP-2026-0005',
        companyId: 1,
        companyName: 'Al-Sorour Logistics',
        supplierId: 2,
        supplierName: 'Milano Industrial SpA',
        shipmentMode: 'Sea FCL',
        incotermCode: 'FOB',
        priority: 'Normal',
        shipmentCategory: 'Commercial',
        portOfLoading: 'Genoa Port (IT)',
        acidNumber: '8912345678901234567',
        form4No: 'F4-BNK-99881',
        customFileNumber: 'MEDUST-IT-0099',
        estimatedCost: 10000.0,
        estimatedCostCurrency: 'USD',
        status: 'Active',
        owner: 'Admin',
        progressPercent: 60.0,
        currentModule: 'Customs Clearance',
        currentStage: 'Declaration 46',
        nextAction: 'Submit Form 46',
        invoicesData: [
          InvoiceItemModel(invoiceNo: 'INV-IT-01', amount: 10000.0, currency: 'USD'),
        ],
        packingListsData: [],
        projectIds: [],
        skippedStages: [],
        createdAt: '2026-08-23T00:00:00Z',
        updatedAt: '2026-08-23T00:00:00Z',
      );

      final mockTariff = CustomsTariffModel(
        tariffId: 1,
        hsCode: '8471.30.00',
        hsDescription: 'آلات معالجة البيانات المحمولة الرقمية',
        customsDutyRate: 0.0, // 0% European Exemption
        vatRate: 14.0,
        scheduleTaxRate: 0.0,
        developmentFeeRate: 0.0,
        importFeeRate: 0.0,
        customsServiceFeeRate: 1.0,
        requiresCoo: true,
        requiresInspection: true,
        requiresAcid: true,
        regulatoryAuthority: 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
        priorApprovalNote: 'مطابقة قياسية وفحص مستندي',
        effectiveFrom: DateTime(2026, 1, 1),
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([mockFile])),
            customsTariffProvider.overrideWith((ref) => _MockCustomsTariffNotifier([mockTariff])),
          ],
          child: const MaterialApp(
          locale: Locale('ar'),
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: CustomsDeclaration46Screen(
                  initialSubTab: 0,
                  initialImportFileId: 5,
                ),
              ),
            ),
          ),
        ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Verify Declaration 46 Screen header and attributes
      expect(find.textContaining('الإقرار الجمركي المبدئي وشهادة 46 ك.م'), findsOneWidget);
      expect(find.text('8912345678901234567'), findsOneWidget); // ACID
      expect(find.text('F4-BNK-99881'), findsOneWidget); // Form 4
      expect(find.text('MEDUST-IT-0099'), findsOneWidget); // B/L Number

      // 2. Verify Exemption & Trade Agreement Card
      expect(find.textContaining('اتفاقية الشراكة المصرية الأوروبية'), findsOneWidget);
      expect(find.textContaining('تقديم شهادة المنشأ الأوروبية'), findsOneWidget);

      // 3. Verify Regulatory Approvals & Inspections Board
      expect(find.textContaining('الهيئة العامة للرقابة على الصادرات والواردات'), findsOneWidget);
      expect(find.textContaining('العروض والموافقات المطلوبة والاشتراطات الرقابية'), findsOneWidget);
    });

    testWidgets('Screen 24: Renders SubTab 1 Registry, KPI cards, and opens Tariff Assessment dialog', (tester) async {
      final mockFile = ImportFileModel(
        importFileId: 7,
        importFileCode: 'FILE-2026-007',
        companyId: 1,
        companyName: 'الشركة الهندسية للصناعات المتطورة',
        supplierId: 10,
        supplierName: 'Siemens Industrial Automation AG',
        shipmentMode: 'FCL',
        incotermCode: 'CIF',
        priority: 'Normal',
        shipmentCategory: 'Industrial Machinery',
        estimatedCost: 20000.0,
        estimatedCostCurrency: 'EUR',
        portOfLoading: 'IT-GOA',
        portOfDischarge: 'EG-ALX',
        acidNumber: '8912345678901234567',
        form4No: 'F4-BNK-99881',
        customFileNumber: 'MEDUST-IT-0099',
        status: 'Active',
        owner: 'Admin',
        progressPercent: 60.0,
        currentModule: 'Customs Clearance',
        currentStage: 'Declaration 46',
        nextAction: 'Submit Form 46',
        invoicesData: [
          InvoiceItemModel(
            invoiceNo: 'INV-2026-007',
            amount: 20000.0,
            currency: 'EUR',
            date: '2026-02-15',
          ),
        ],
        packingListsData: [],
        projectIds: [],
        skippedStages: [],
        createdAt: '2026-08-23T00:00:00Z',
        updatedAt: '2026-08-23T00:00:00Z',
      );

      final mockTariff = CustomsTariffModel(
        tariffId: 1,
        hsCode: '8471.30.00',
        hsDescription: 'آلات معالجة معلومات ذاتية محمولة',
        customsDutyRate: 5.0,
        vatRate: 14.0,
        developmentFeeRate: 0.0,
        scheduleTaxRate: 0.0,
        importFeeRate: 0.0,
        customsServiceFeeRate: 1.0,
        requiresInspection: true,
        requiresCoo: true,
        requiresAcid: true,
        regulatoryAuthority: 'الهيئة العامة للرقابة على الصادرات والواردات',
        priorApprovalNote: 'مطابقة قياسية وفحص مستندي',
        effectiveFrom: DateTime(2026, 1, 1),
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      tester.view.physicalSize = const Size(1400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([mockFile])),
            customsTariffProvider.overrideWith((ref) => _MockCustomsTariffNotifier([mockTariff])),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: CustomsDeclaration46Screen(
                    initialSubTab: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Verify SubTab 1 KPI Metrics Cards
      expect(find.text('إجمالي الإقرارات'), findsOneWidget);
      expect(find.text('إجمالي القيمة الجمركية (سيف)'), findsOneWidget);
      expect(find.text('إجمالي الضرائب والرسوم'), findsOneWidget);
      expect(find.text('إعفاءات الشراكة الأوروبية'), findsOneWidget);

      // 2. Verify Registry Table Columns and Data
      expect(find.text('46-ALX-FILE-2026-007'), findsOneWidget);
      expect(find.text('Siemens Industrial Automation AG'), findsOneWidget);
      expect(find.text('8471.30.00'), findsOneWidget);

      // 3. Verify Assessment Action Button and Tap to Open Dialog
      final assessmentBtn = find.byTooltip('معاينة التقييم الجمركي وبنود التعريفة');
      expect(assessmentBtn, findsOneWidget);
      await tester.ensureVisible(assessmentBtn);
      await tester.pumpAndSettle();
      await tester.tap(assessmentBtn);
      await tester.pumpAndSettle();

      // 4. Verify Assessment Dialog Content
      expect(find.text('التقييم الجمركي وبنود التعريفة — شهادة 46 ك.م'), findsOneWidget);
      expect(find.text('تفصيل وعاء القيمة للأغراض الجمركية (سيف)'), findsOneWidget);
      expect(find.text('جدول الضرائب والرسوم الجمركية المقررة'), findsOneWidget);
      expect(find.text('بيانات الشحنة والإقرار الجمركي'), findsOneWidget);
    });
  });
}
