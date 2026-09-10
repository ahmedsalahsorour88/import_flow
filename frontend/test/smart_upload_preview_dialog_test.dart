import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/smart_upload_button.dart';

void main() {
  group('SmartUploadResult Model Tests', () {
    test('SmartUploadResult creates from JSON and calculates confidence', () {
      final json = {
        'session_id': 101,
        'session_ref': 'SES-101',
        'module_name': 'purchase-order',
        'filename': 'PO_INV_2026.pdf',
        'file_type': 'pdf',
        'extraction_status': 'SUCCESS',
        'confidence_score': 0.95,
        'extracted_fields': {
          'po_number': 'PO-9988',
          'total_amount': '125000',
          'currency': 'USD',
          'supplier_name': 'Global Tech Ltd',
          'importer_name': 'Sorour Logistics',
        },
        'missing_fields': <String>[],
        'extraction_notes': 'Clean extraction without errors',
        'supplier_verified': true,
        'supplier_code': 'SUP-0012',
        'importer_verified': true,
        'importer_code': 'IMP-0005',
      };

      final result = SmartUploadResult.fromJson(json);
      expect(result.sessionId, 101);
      expect(result.sessionRef, 'SES-101');
      expect(result.filename, 'PO_INV_2026.pdf');
      expect(result.isSuccess, isTrue);
      expect(result.isPartial, isFalse);
      expect(result.confidencePercent, 95);
      expect(result.supplierVerified, isTrue);
      expect(result.importerVerified, isTrue);
      expect(result.supplierCode, 'SUP-0012');
      expect(result.importerCode, 'IMP-0005');
    });

    test('copyWith properly overrides fields', () {
      const initial = SmartUploadResult(
        moduleName: 'purchase-order',
        filename: 'PO.pdf',
        fileType: 'pdf',
        extractionStatus: 'PARTIAL',
        confidenceScore: 0.70,
        extractedFields: {'po_number': '123'},
        missingFields: ['total_amount'],
      );

      final updated = initial.copyWith(
        extractionStatus: 'SUCCESS',
        confidenceScore: 0.98,
        extractedFields: {'po_number': '123', 'total_amount': '500'},
      );

      expect(updated.extractionStatus, 'SUCCESS');
      expect(updated.confidencePercent, 98);
      expect(updated.extractedFields.length, 2);
      expect(updated.filename, 'PO.pdf');
    });
  });

  group('SmartUploadPreviewDialog Widget Tests', () {
    testWidgets('renders preview dialog with SelectionArea, copy buttons, and pure localized labels in Arabic', (tester) async {
      const result = SmartUploadResult(
        moduleName: 'purchase-order',
        filename: 'PO_9901.pdf',
        fileType: 'pdf',
        extractionStatus: 'SUCCESS',
        confidenceScore: 0.95,
        extractedFields: {
          'po_number': 'PO-9901',
          'total_amount': '45000',
          'supplier_name': 'Shanghai Steel Co.',
          'importer_name': 'شركة سرور للخدمات اللوجستية',
        },
        missingFields: [],
        supplierVerified: true,
        supplierCode: 'SUP-0099',
        importerVerified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SmartUploadPreviewDialog(
                  result: result,
                  onConfirm: (_) {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify SelectionArea exists
      expect(find.byType(SelectionArea), findsOneWidget);

      // Verify header components
      expect(find.text('PO_9901.pdf · نسبة الثقة: 95%'), findsOneWidget);
      expect(find.byIcon(Icons.copy_all_rounded), findsOneWidget);

      // Verify entity verification panel
      expect(find.text('المورد الأجنبي'), findsOneWidget);
      expect(find.text('Shanghai Steel Co.'), findsNWidgets(2));
      expect(find.text('الشركة المستوردة'), findsNWidgets(2));
      expect(find.text('شركة سرور للخدمات اللوجستية'), findsNWidgets(2));

      // Verify unverified party has register button in pure Arabic
      expect(find.text('سجّل'), findsOneWidget);

      // Verify field rows rendered
      expect(find.text('PO-9901'), findsOneWidget);
      expect(find.text('45000'), findsOneWidget);

      // Verify copy buttons present
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);

      // Verify actions footer
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('تعبئة النموذج'), findsOneWidget);
    });

    testWidgets('renders preview dialog properly in English mode with zero Arabic', (tester) async {
      const result = SmartUploadResult(
        moduleName: 'purchase-order',
        filename: 'PO_English.pdf',
        fileType: 'pdf',
        extractionStatus: 'SUCCESS',
        confidenceScore: 0.90,
        extractedFields: {
          'po_number': 'PO-EN-100',
        },
        missingFields: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('en'),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                body: SmartUploadPreviewDialog(
                  result: result,
                  onConfirm: (_) {},
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply to Form'), findsOneWidget);
    });
  });
}
