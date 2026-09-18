import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/models/original_documents_collection_model.dart';
import 'package:frontend/features/import_documentation/widgets/original_documents_collection_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('SH-04: Original Documents Receipt Models & Serialization Tests', () {
    test('ImportFileModel parses original documents synchronization columns correctly', () {
      final json = {
        'import_file_id': 40,
        'import_file_code': 'IMP-2026-0040',
        'custom_file_number': 'Textiles Cargo',
        'company_name': 'Al-Sorour Textiles Co',
        'supplier_name': 'Bursa Cotton Corp',
        'acid_number': '7595528271020210020',
        'current_module': 'STEP_12 استخراج واعتماد نموذج 4 البنكي',
        'current_stage': 'Phase 5 - Sailing & CargoX',
        'progress_percent': 75.0,
        'next_action': 'تعيين المخلص الجمركي والتفويض الإلكتروني (CS-01)',
        'original_documents_status': 'FULLY_RECEIVED',
        'original_documents_received_at': '2026-09-18T12:00:00Z',
        'original_documents_courier_no': 'DHL-9988112233, FEDEX-44332211',
        'original_documents_session_code': 'DOC-COL-2026-0040',
        'created_at': '2026-09-18T08:00:00Z',
        'updated_at': '2026-09-18T12:00:00Z',
      };

      final file = ImportFileModel.fromJson(json);

      expect(file.importFileId, 40);
      expect(file.importFileCode, 'IMP-2026-0040');
      expect(file.originalDocumentsStatus, 'FULLY_RECEIVED');
      expect(file.originalDocumentsReceivedAt, '2026-09-18T12:00:00Z');
      expect(file.originalDocumentsCourierNo, contains('DHL-9988112233'));
      expect(file.originalDocumentsSessionCode, 'DOC-COL-2026-0040');

      final serialized = file.toJson();
      expect(serialized['original_documents_status'], 'FULLY_RECEIVED');
      expect(serialized['original_documents_received_at'], '2026-09-18T12:00:00Z');
      expect(serialized['original_documents_courier_no'], contains('FEDEX-44332211'));
      expect(serialized['original_documents_session_code'], 'DOC-COL-2026-0040');
    });

    test('OriginalDocumentsCollectionSessionModel parses couriers and document matrix correctly', () {
      final json = {
        'collection_id': 12,
        'collection_code': 'DOC-COL-2026-0012',
        'import_file_id': 40,
        'import_file_code': 'IMP-2026-0040',
        'acid_number': '7595528271020210020',
        'importer_name': 'Al-Sorour Textiles Co',
        'supplier_name': 'Bursa Cotton Corp',
        'status': 'FULLY_RECEIVED',
        'total_documents_count': 3,
        'received_documents_count': 3,
        'verified_documents_count': 3,
        'pending_documents_count': 0,
        'completion_percentage': 100.0,
        'couriers_list': [
          {
            'courier_no': 'DHL-9988112233',
            'courier_company': 'DHL',
            'dispatch_date': '2026-09-15',
            'is_received': true,
            'received_date': '2026-09-18',
            'received_by': 'Kamal',
            'status': 'DELIVERED',
          }
        ],
        'documents_list': [
          {
            'category': 'Commercial',
            'document_name': 'Commercial Invoice',
            'is_required': 'Yes',
            'courier_no': 'DHL-9988112233',
            'is_received': true,
            'is_verified': true,
            'status': 'Verified',
          },
          {
            'category': 'Commercial',
            'document_name': 'Packing List',
            'is_required': 'Yes',
            'courier_no': 'DHL-9988112233',
            'is_received': true,
            'is_verified': true,
            'status': 'Verified',
          },
        ],
        'is_active': true,
        'created_at': '2026-09-18T09:00:00Z',
        'updated_at': '2026-09-18T12:00:00Z',
      };

      final session = OriginalDocumentsCollectionSessionModel.fromJson(json);

      expect(session.collectionId, 12);
      expect(session.collectionCode, 'DOC-COL-2026-0012');
      expect(session.status, 'FULLY_RECEIVED');
      expect(session.completionPercentage, 100.0);
      expect(session.couriersList.length, 1);
      expect(session.couriersList.first.isReceived, true);
      expect(session.documentsList.length, 2);
      expect(session.documentsList.every((d) => d.isReceived), true);
    });
  });

  group('SH-04: OriginalDocumentsCollectionDialog Widget Tests', () {
    testWidgets('OriginalDocumentsCollectionDialog renders header title, ACID badge, and close button', (tester) async {
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
              data: options.path.contains('auto-populate')
                  ? {
                      'import_file_id': 40,
                      'import_file_code': 'IMP-2026-0040',
                      'acid_number': '7595528271020210020',
                      'importer_name': 'Al-Sorour Textiles Co',
                      'supplier_name': 'Bursa Cotton Corp',
                      'default_couriers': [],
                      'required_documents': [],
                      'existing_session': null,
                    }
                  : [],
            ));
          },
        ),
      );

      final sampleFile = ImportFileModel(
        importFileId: 40,
        importFileCode: 'IMP-2026-0040',
        customFileNumber: 'Textiles Cargo',
        companyName: 'Al-Sorour Textiles Co',
        supplierName: 'Bursa Cotton Corp',
        acidNumber: '7595528271020210020',
        currentModule: 'STEP_11',
        currentStage: 'Phase 5 - Sailing & CargoX',
        progressPercent: 70.0,
        nextAction: 'استلام وتوثيق أصول المستندات البنكية (SH-04)',
        createdAt: '2026-09-18T08:00:00Z',
        updatedAt: '2026-09-18T10:00:00Z',
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
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => OriginalDocumentsCollectionDialog.show(context, sampleFile),
                    child: const Text('Open Original Docs Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Original Docs Dialog'));
      await tester.pumpAndSettle();

      // Verify Header, Title, and Badges
      expect(find.text('استلام وتوثيق أصول المستندات البنكية (SH-04)'), findsOneWidget);
      expect(find.text('Textiles Cargo (IMP-2026-0040)'), findsOneWidget);
      expect(find.text('ACID: 7595528271020210020'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('استلام وتوثيق أصول المستندات البنكية (SH-04)'), findsNothing);
    });
  });
}
