import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_documentation/widgets/draft_bl_review_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/core/localization/app_localizations.dart';

void main() {
  group('SH-02: Draft B/L Dual Review Tool Model & Parsing Tests', () {
    test('DraftBLReviewModel parses dual approval fields correctly from JSON', () {
      final json = {
        'bl_review_id': 101,
        'bl_review_code': 'BL-REV-2026-0001',
        'import_file_id': 5,
        'draft_bl_number': 'MSCU1234567',
        'shipping_line': 'MSC',
        'vessel_name': 'MSC OSCAR',
        'stage': 'Stage 4: Dual Approval',
        'status': 'DRAFT',
        'importer_approval_status': 'Approved',
        'importer_approved_by': 'Kamal (Import Manager)',
        'importer_approved_at': '2026-09-18T10:00:00Z',
        'broker_approval_status': 'Pending',
        'broker_approved_by': null,
        'broker_approved_at': null,
        'has_blocking_mismatch': false,
        'open_discrepancies_count': 0,
        'created_at': '2026-09-18T09:00:00Z',
        'updated_at': '2026-09-18T10:00:00Z',
      };

      final model = DraftBLReviewModel.fromJson(json);

      expect(model.blReviewId, 101);
      expect(model.blReviewCode, 'BL-REV-2026-0001');
      expect(model.draftBlNumber, 'MSCU1234567');
      expect(model.stage, 'Stage 4: Dual Approval');
      expect(model.importerApprovalStatus, 'Approved');
      expect(model.importerApprovedBy, 'Kamal (Import Manager)');
      expect(model.brokerApprovalStatus, 'Pending');
      expect(model.brokerApprovedBy, isNull);
      expect(model.hasBlockingMismatch, false);
      expect(model.openDiscrepanciesCount, 0);
    });

    test('DraftBLChecklistItemModel verifies 20 parameters and mismatch status', () {
      final item = DraftBLChecklistItemModel(
        fieldKey: 'shipper',
        fieldLabelAr: 'اسم المصدر / الشاحن',
        fieldLabelEn: 'Shipper / Exporter Name',
        sourceEntity: 'Purchase Order / Invoice',
        systemValue: 'ABC Industrial Corp, Shanghai',
        draftValue: 'ABC Industrial Corp, Beijing',
        status: 'Incorrect',
        requiredCorrection: 'تعديل العنوان إلى Shanghai ليطابق الفاتورة التجارية وأمر الشراء',
        responsibleParty: 'Shipper / Line',
      );

      expect(item.fieldKey, 'shipper');
      expect(item.status, 'Incorrect');
      expect(item.systemValue, isNot(equals(item.draftValue)));

      final json = item.toJson();
      expect(json['field_key'], 'shipper');
      expect(json['status'], 'Incorrect');
      expect(json['required_correction'], contains('Shanghai'));
    });
  });

  group('SH-02: DraftBLReviewDialog Widget Tests', () {
    testWidgets('DraftBLReviewDialog renders header title, file badge, and close button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: options.path.contains('draft-bl/compare')
                  ? {
                      'stage': 'Stage 1: Comparison',
                      'system_data': {},
                      'draft_data': {},
                      'matrix': [],
                      'checklist': [],
                      'revision_report': [],
                      'has_blocking_mismatch': false,
                      'open_discrepancies_count': 0,
                      'blocking_reasons': [],
                    }
                  : [],
            ));
          },
        ),
      );

      final dummyFile = ImportFileModel(
        importFileId: 5,
        importFileCode: 'IMP-2026-0005',
        customFileNumber: 'Industrial Machines',
        companyName: 'Al-Amal Import Co',
        supplierName: 'ABC Industrial Corp',
        currentModule: 'ImportFiles',
        currentStage: 'Phase 5 - Sailing & CargoX',
        nextAction: 'Review Draft BL',
        createdAt: '2026-09-18T00:00:00Z',
        updatedAt: '2026-09-18T00:00:00Z',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(mockDio),
          ],
          child: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: MaterialApp(
              locale: const Locale('ar'),
              home: Scaffold(
                body: DraftBLReviewDialog(file: dummyFile),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('مراجعة مسودة بوليصة الشحن والاعتماد المزدوج (SH-02)'), findsOneWidget);
      expect(find.text('Industrial Machines (IMP-2026-0005)'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.fact_check_rounded), findsWidgets);
    });
  });
}
