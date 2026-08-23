import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_tariff/models/customs_tariff_model.dart';
import 'package:frontend/features/customs_tariff/providers/customs_tariff_provider.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/customs_declaration46_screen.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/purchase_orders/models/purchase_order_model.dart';
import 'package:frontend/features/purchase_orders/providers/purchase_orders_provider.dart';

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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([mockFile])),
            customsTariffProvider.overrideWith((ref) => _MockCustomsTariffNotifier([mockTariff])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsDeclaration46Screen(
                initialSubTab: 0,
                initialImportFileId: 5,
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
      expect(find.textContaining('اتفاقية الشراكة المصرية الأوروبية (EUR.1)'), findsOneWidget);
      expect(find.textContaining('تقديم شهادة المنشأ الأوروبية'), findsOneWidget);

      // 3. Verify Regulatory Approvals & Inspections Board
      expect(find.textContaining('الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)'), findsOneWidget);
      expect(find.textContaining('العروض والموافقات المطلوبة والاشتراطات الرقابية'), findsOneWidget);
    });
  });
}
