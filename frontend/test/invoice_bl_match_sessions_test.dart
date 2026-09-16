import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/models/invoice_bl_match_session_model.dart';
import 'package:frontend/features/import_documentation/models/docs_customs_approval_session_model.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/widgets/invoice_bl_matcher_tab.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier() : super(Dio()) {
    state = AsyncValue.data([
      ImportFileModel(
        importFileId: 101,
        importFileCode: 'IMP-2026-001',
        companyName: 'ARCHI Brands',
        supplierName: 'Shaw Europe Limited',
        piNumber: '35220',
        status: 'Draft Documents',
        invoicesData: [],
        packingListsData: [],
        projectIds: [],
        shipmentMode: 'Sea',
        incotermCode: 'EXW',
        priority: 'Normal',
        shipmentCategory: 'Commercial',
        estimatedCost: 85060.57,
        estimatedCostCurrency: 'USD',
        currentModule: 'Import Documentation',
        currentStage: 'Draft Documents',
        progressPercent: 65.0,
        nextAction: 'Reconcile B/L',
        isCustomsReleased: false,
        isActive: true,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString(),
      ),
    ]);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {}
}

class MockInvoiceBLMatchSessionsNotifier extends InvoiceBLMatchSessionsNotifier {
  MockInvoiceBLMatchSessionsNotifier() : super(Dio()) {
    state = AsyncValue.data([
      InvoiceBLMatchSessionModel(
        sessionId: 1,
        sessionCode: 'SESS-202609-0001',
        importFileId: 101,
        importFileCode: 'IMP-2026-001',
        sessionTitle: 'جلسة مطابقة سريعة تجريبية',
        isDraft: false,
        matchScore: 95.5,
        isSafeForCertification: true,
        hasCriticalDiscrepancies: false,
        discrepancyCount: 0,
        comparisonMatrix: [
          {
            'field_name_ar': 'رقم ACID الجمركي',
            'field_name_en': 'ACID Number',
            'invoice_value': '7595528271019210013',
            'bl_value': '7595528271019210013',
            'match_status': 'MATCH',
            'details': 'مطابق تماماً',
          }
        ],
        createdAt: '2026-09-16 10:00:00',
        updatedAt: '2026-09-16 10:00:00',
      ),
      InvoiceBLMatchSessionModel(
        sessionId: 2,
        sessionCode: 'SESS-202609-0002',
        importFileId: 101,
        importFileCode: 'IMP-2026-001',
        sessionTitle: 'مسودة فحص أولي غير مكتملة',
        isDraft: true,
        matchScore: 68.0,
        isSafeForCertification: false,
        hasCriticalDiscrepancies: true,
        discrepancyCount: 2,
        comparisonMatrix: [],
        createdAt: '2026-09-16 10:15:00',
        updatedAt: '2026-09-16 10:15:00',
      ),
    ]);
  }

  @override
  Future<void> fetchSessions({int? importFileId, bool? isDraft, String? search}) async {}
}

void main() {
  group('InvoiceBLMatchSessionModel and DocsCustomsApprovalSessionModel Unit Tests', () {
    test('InvoiceBLMatchSessionModel serialization and deserialization', () {
      final model = InvoiceBLMatchSessionModel(
        sessionId: 10,
        sessionCode: 'SESS-202609-0010',
        importFileId: 50,
        importFileCode: 'IMP-2026-0050',
        sessionTitle: 'جلسة فحص شاملة',
        isDraft: true,
        matchScore: 88.5,
        isSafeForCertification: true,
        hasCriticalDiscrepancies: false,
        discrepancyCount: 1,
        invoiceRawText: 'Sample Invoice Text',
        blRawText: 'Sample B/L Text',
        sessionNotes: 'ملاحظات تدقيق',
        createdAt: '2026-09-16 10:00:00',
        updatedAt: '2026-09-16 10:00:00',
      );

      final json = model.toJson();
      expect(json['session_id'], 10);
      expect(json['session_code'], 'SESS-202609-0010');
      expect(json['is_draft'], true);
      expect(json['match_score'], 88.5);

      final restored = InvoiceBLMatchSessionModel.fromJson(json);
      expect(restored.sessionId, 10);
      expect(restored.sessionCode, 'SESS-202609-0010');
      expect(restored.isDraft, true);
      expect(restored.sessionNotes, 'ملاحظات تدقيق');
    });

    test('DocsCustomsApprovalSessionModel serialization and deserialization', () {
      final model = DocsCustomsApprovalSessionModel(
        sessionId: 5,
        sessionCode: 'CUSTAPPR-202609-0005',
        importFileId: 50,
        importFileCode: 'IMP-2026-0050',
        sessionTitle: 'اعتماد المستندات الجمركية',
        isDraft: false,
        overallCompliance: 'Fully Compliant',
        totalChecks: 10,
        passedChecks: 10,
        failedChecks: 0,
        sessionNotes: 'معتمد للإفراج',
        createdAt: '2026-09-16 10:00:00',
        updatedAt: '2026-09-16 10:00:00',
      );

      final json = model.toJson();
      expect(json['session_id'], 5);
      expect(json['overall_compliance'], 'Fully Compliant');

      final restored = DocsCustomsApprovalSessionModel.fromJson(json);
      expect(restored.sessionId, 5);
      expect(restored.sessionCode, 'CUSTAPPR-202609-0005');
      expect(restored.isDraft, false);
      expect(restored.passedChecks, 10);
    });
  });

  group('InvoiceBLMatcherTab Sessions Registry Widget Tests', () {
    testWidgets('Renders view mode switcher and toggles to Sessions Registry', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
            invoiceBLMatchSessionsProvider.overrideWith((ref) => MockInvoiceBLMatchSessionsNotifier()),
          ],
          child: const AppLocalizationsProvider(
            locale: Locale('ar'),
            child: MaterialApp(
              home: Scaffold(
                body: InvoiceBLMatcherTab(selectedImportFileId: 101),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify top switcher tabs exist
      expect(find.text('⚡ فحص ومطابقة الفاتورة والبوليصة'), findsOneWidget);
      expect(find.text('📋 سجل جلسات المطابقة السابقة'), findsOneWidget);

      // Verify session count badge displays '2'
      expect(find.text('2'), findsWidgets);

      // Switch to Sessions Registry View
      await tester.tap(find.text('📋 سجل جلسات المطابقة السابقة'));
      await tester.pumpAndSettle();

      // Verify Sessions Table and KPI headers rendered
      expect(find.text('إجمالي الجلسات'), findsOneWidget);
      expect(find.text('الجلسات المعتمدة'), findsOneWidget);
      expect(find.text('المسودات المؤقتة'), findsOneWidget);

      // Verify sessions are rendered in table
      expect(find.text('SESS-202609-0001'), findsOneWidget);
      expect(find.text('SESS-202609-0002'), findsOneWidget);
      expect(find.text('معتمدة نهائية'), findsOneWidget);
      expect(find.text('مسودة مؤقتة'), findsOneWidget);
    });
  });
}
