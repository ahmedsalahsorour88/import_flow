import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/cargox/models/cargox_model.dart';
import 'package:frontend/features/cargox/widgets/cargox_hub_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/core/localization/app_localizations.dart';

void main() {
  group('SH-03: CargoX Digital Transfer Models & Synchronization Tests', () {
    test('ImportFileModel parses CargoX synchronization columns correctly', () {
      final json = {
        'import_file_id': 30,
        'import_file_code': 'IMP-2026-0030',
        'custom_file_number': 'Silk Cargo',
        'company_name': 'Al-Sorour Import Co',
        'supplier_name': 'Suzhou Silk Industrial Ltd',
        'acid_number': '7595528271020210010',
        'current_module': 'STEP_11 تحصيل واستلام أصول المستندات',
        'current_stage': 'Phase 5 - Sailing & CargoX',
        'progress_percent': 70.0,
        'next_action': 'استلام وتوثيق أصول المستندات البنكية (SH-04)',
        'cargox_envelope_id': 99,
        'cargox_envelope_code': 'CGX-ENV-2026-0099',
        'cargox_envelope_status': 'ACCEPTED_BY_CUSTOMS',
        'cargox_transferred_at': '2026-09-18T10:00:00Z',
        'created_at': '2026-09-18T08:00:00Z',
        'updated_at': '2026-09-18T10:00:00Z',
      };

      final file = ImportFileModel.fromJson(json);

      expect(file.importFileId, 30);
      expect(file.importFileCode, 'IMP-2026-0030');
      expect(file.acidNumber, '7595528271020210010');
      expect(file.cargoxEnvelopeId, 99);
      expect(file.cargoxEnvelopeCode, 'CGX-ENV-2026-0099');
      expect(file.cargoxEnvelopeStatus, 'ACCEPTED_BY_CUSTOMS');
      expect(file.cargoxTransferredAt, '2026-09-18T10:00:00Z');

      final serialized = file.toJson();
      expect(serialized['cargox_envelope_id'], 99);
      expect(serialized['cargox_envelope_code'], 'CGX-ENV-2026-0099');
      expect(serialized['cargox_envelope_status'], 'ACCEPTED_BY_CUSTOMS');
      expect(serialized['cargox_transferred_at'], '2026-09-18T10:00:00Z');
    });

    test('CargoXEnvelopeModel parses envelope documents and blockchain transfer data', () {
      final json = {
        'envelope_id': 42,
        'envelope_code': 'CGX-ENV-2026-0042',
        'import_file_id': 30,
        'import_file_code': 'IMP-2026-0030',
        'acid_number': '7595528271020210010',
        'importer_company_name': 'Al-Sorour Import Co',
        'supplier_name': 'Suzhou Silk Industrial Ltd',
        'status': 'ACCEPTED_BY_CUSTOMS',
        'is_acid_verified': true,
        'blockchain_tx_hash': '0x7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
        'pki_signature': 'SIG-ECDSA-EGY-CUST-883921',
        'customs_confirmation_receipt': 'EGY-CUST-2026-0042',
        'total_documents': 3,
        'verified_documents_count': 3,
        'documents': [
          {
            'doc_id': 1,
            'envelope_id': 42,
            'doc_type': 'Commercial Invoice',
            'doc_number': 'INV-2026-901',
            'file_name': 'Commercial_Invoice.pdf',
            'is_mandatory': true,
            'verified_against_acid': true,
          },
          {
            'doc_id': 2,
            'envelope_id': 42,
            'doc_type': 'Packing List',
            'doc_number': 'PL-2026-901',
            'file_name': 'Packing_List.pdf',
            'is_mandatory': true,
            'verified_against_acid': true,
          },
          {
            'doc_id': 3,
            'envelope_id': 42,
            'doc_type': 'Draft B/L',
            'doc_number': 'MEDUST991122',
            'file_name': 'Bill_of_Lading.pdf',
            'is_mandatory': true,
            'verified_against_acid': true,
          },
        ],
        'is_active': true,
        'created_at': '2026-09-18T09:00:00Z',
        'updated_at': '2026-09-18T10:00:00Z',
      };

      final envelope = CargoXEnvelopeModel.fromJson(json);

      expect(envelope.envelopeId, 42);
      expect(envelope.envelopeCode, 'CGX-ENV-2026-0042');
      expect(envelope.acidNumber, '7595528271020210010');
      expect(envelope.status, 'ACCEPTED_BY_CUSTOMS');
      expect(envelope.isAcidVerified, true);
      expect(envelope.blockchainTxHash, startsWith('0x7f83'));
      expect(envelope.customsConfirmationReceipt, 'EGY-CUST-2026-0042');
      expect(envelope.documents.length, 3);
      expect(envelope.documents.every((d) => d.verifiedAgainstAcid), true);
    });
  });

  group('SH-03: CargoXHubDialog Widget Tests', () {
    testWidgets('CargoXHubDialog renders header title, ACID badge, and close button', (tester) async {
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
              data: [],
            ));
          },
        ),
      );

      final sampleFile = ImportFileModel(
        importFileId: 30,
        importFileCode: 'IMP-2026-0030',
        customFileNumber: 'Silk Cargo',
        companyName: 'Al-Sorour Import Co',
        supplierName: 'Suzhou Silk Industrial Ltd',
        acidNumber: '7595528271020210010',
        currentModule: 'STEP_10',
        currentStage: 'Phase 5 - Sailing & CargoX',
        progressPercent: 65.0,
        nextAction: 'Review CargoX Envelope Documents (SH-03)',
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
                    onPressed: () => CargoXHubDialog.show(context, sampleFile),
                    child: const Text('Open CargoX Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open CargoX Dialog'));
      await tester.pumpAndSettle();

      // Verify Header and Badges
      expect(find.text('منصة النقل الرقمي CargoX واعتماد الملفات (SH-03)'), findsOneWidget);
      expect(find.text('Silk Cargo (IMP-2026-0030)'), findsOneWidget);
      expect(find.text('ACID: 7595528271020210010'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('منصة النقل الرقمي CargoX واعتماد الملفات (SH-03)'), findsNothing);
    });
  });
}
