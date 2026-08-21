import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cargox/models/cargox_model.dart';
import 'package:frontend/features/cargox/providers/cargox_provider.dart';
import 'package:frontend/features/cargox/screens/cargox_hub_screen.dart';
import 'package:frontend/features/import_companies/models/import_company_model.dart';
import 'package:frontend/features/import_companies/providers/import_companies_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';
import 'package:frontend/features/suppliers/models/supplier_model.dart';
import 'package:frontend/features/suppliers/providers/suppliers_provider.dart';

class _MockCargoXNotifier extends CargoXNotifier {
  final List<CargoXEnvelopeModel> initialEnvelopes;
  _MockCargoXNotifier(this.initialEnvelopes) : super(Dio()) {
    state = AsyncValue.data(initialEnvelopes);
  }

  @override
  Future<void> fetchEnvelopes({
    String? search,
    String? status,
    int? importFileId,
    int? supplierId,
    bool includeInactive = false,
  }) async {
    state = AsyncValue.data(initialEnvelopes);
  }

  @override
  Future<DigitalManifestModel> fetchDigitalManifest(int envelopeId) async {
    return DigitalManifestModel(
      envelopeId: envelopeId,
      envelopeCode: 'CGX-ENV-2026-0001',
      acidNumber: '7595528271020210010',
      manifestJson: {'manifest_id': 'MTS-001'},
      exportedAt: DateTime.now(),
      formattedSummary: 'Summary',
    );
  }
}

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

class _MockSuppliersNotifier extends SuppliersNotifier {
  final List<SupplierModel> initialSuppliers;
  _MockSuppliersNotifier(this.initialSuppliers) : super(showInactive: true, dio: Dio()) {
    state = AsyncValue.data(initialSuppliers);
  }

  @override
  Future<void> fetchSuppliers({
    bool includeInactive = false,
    String? search,
    String? country,
    String? currency,
    String? productCategory,
  }) async {
    state = AsyncValue.data(initialSuppliers);
  }
}

class _MockImportCompaniesNotifier extends ImportCompaniesNotifier {
  final List<ImportCompanyModel> initialCompanies;
  _MockImportCompaniesNotifier(this.initialCompanies) : super(showInactive: true, dio: Dio()) {
    state = AsyncValue.data(initialCompanies);
  }

  @override
  Future<void> fetchCompanies({
    bool includeInactive = false,
    String? search,
    String? legalForm,
  }) async {
    state = AsyncValue.data(initialCompanies);
  }
}

class _MockStandardInvoiceNotifier extends StandardInvoiceNotifier {
  _MockStandardInvoiceNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> fetchSessions({
    String? search,
    String? status,
    int? importFileId,
  }) async {
    state = const AsyncValue.data([]);
  }
}

void main() {
  group('CargoX & ACI Dispatch Hub Models & Unit Tests', () {
    test('CargoXEnvelopeModel JSON serialization and deserialization', () {
      final sampleJson = {
        'envelope_id': 101,
        'envelope_code': 'CGX-ENV-2026-0001',
        'import_file_id': 1,
        'import_file_code': 'IMP-2026-001',
        'acid_number': '7595528271020210010',
        'importer_company_id': 1,
        'importer_company_name': 'Al-Sorour Logistics',
        'importer_tax_number': '100-294-812',
        'supplier_id': 1,
        'supplier_name': 'Suzhou Textile Co.',
        'supplier_cargox_id': 'CX-SUZ-9901',
        'bl_number': 'MEDUST982145',
        'status': 'ACCEPTED_BY_CUSTOMS',
        'blockchain_tx_hash': '0x7f83b123456789abcdef',
        'pki_signature': 'SIG-ECA-PKI-001',
        'is_acid_verified': true,
        'all_documents_sealed': true,
        'transferred_to_customs_at': '2026-08-20T18:00:00.000Z',
        'customs_confirmation_receipt': 'MTS-REC-88912',
        'notes': 'Test CargoX Envelope',
        'is_active': true,
        'created_at': '2026-08-20T17:00:00.000Z',
        'created_by': 'ADMIN',
        'updated_at': '2026-08-20T18:00:00.000Z',
        'updated_by': 'ADMIN',
        'documents': [
          {
            'doc_id': 1,
            'envelope_id': 101,
            'doc_type': 'Commercial Invoice',
            'doc_number': 'INV-2026-01',
            'file_name': 'invoice.pdf',
            'file_hash': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            'file_size_kb': 250.0,
            'is_mandatory': true,
            'is_uploaded': true,
            'uploaded_at': '2026-08-20T17:30:00.000Z',
            'verified_against_acid': true,
            'pki_signature': 'SIG-DOC-001',
            'is_active': true,
            'created_at': '2026-08-20T17:30:00.000Z',
          }
        ],
      };

      final model = CargoXEnvelopeModel.fromJson(sampleJson);
      expect(model.envelopeId, 101);
      expect(model.envelopeCode, 'CGX-ENV-2026-0001');
      expect(model.acidNumber, '7595528271020210010');
      expect(model.supplierCargoxId, 'CX-SUZ-9901');
      expect(model.status, 'ACCEPTED_BY_CUSTOMS');
      expect(model.isAcidVerified, isTrue);
      expect(model.documents.length, 1);
      expect(model.documents.first.docType, 'Commercial Invoice');

      final serialized = model.toJson();
      expect(serialized['envelope_code'], 'CGX-ENV-2026-0001');
      expect(serialized['acid_number'], '7595528271020210010');
    });

    test('DigitalManifestModel JSON serialization', () {
      final manifestJson = {
        'envelope_id': 101,
        'envelope_code': 'CGX-ENV-2026-0001',
        'acid_number': '7595528271020210010',
        'manifest_json': {
          'manifest_id': 'MTS-MAN-2026-0001',
          'importer': {'company_name': 'Al-Sorour'},
        },
        'exported_at': '2026-08-20T18:00:00.000Z',
        'formatted_summary': 'SUMMARY',
      };

      final manifest = DigitalManifestModel.fromJson(manifestJson);
      expect(manifest.envelopeCode, 'CGX-ENV-2026-0001');
      expect(manifest.manifestJson['manifest_id'], 'MTS-MAN-2026-0001');
    });

    testWidgets('CargoXHubScreen UI renders properly in Embedded mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final mockEnvelope = CargoXEnvelopeModel(
        envelopeId: 1,
        envelopeCode: 'CGX-ENV-2026-0001',
        importFileId: 1,
        importFileCode: 'IMP-2026-001',
        acidNumber: '7595528271020210010',
        importerCompanyName: 'Al-Sorour Logistics',
        supplierName: 'Suzhou Textile Co.',
        supplierCargoxId: 'CX-SUZ-9901',
        blNumber: 'MEDUST982145',
        status: 'ACCEPTED_BY_CUSTOMS',
        blockchainTxHash: '0x7f83b123456789abcdef',
        pkiSignature: 'SIG-ECA-PKI-001',
        isAcidVerified: true,
        allDocumentsSealed: true,
        customsConfirmationReceipt: 'MTS-REC-88912',
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: 'ADMIN',
        updatedAt: DateTime.now(),
        updatedBy: 'ADMIN',
        documents: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cargoxEnvelopesProvider.overrideWith((ref) => _MockCargoXNotifier([mockEnvelope])),
            importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([])),
            suppliersProvider.overrideWith((ref) => _MockSuppliersNotifier([])),
            importCompaniesProvider.overrideWith((ref) => _MockImportCompaniesNotifier([])),
            standardInvoiceSessionsProvider.overrideWith((ref) => _MockStandardInvoiceNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CargoXHubScreen(
                isEmbedded: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CargoXHubScreen), findsOneWidget);
      expect(find.textContaining('منظومة كارجو إكس والبلوك تشين'), findsOneWidget);
      expect(find.textContaining('تجهيز المظروف'), findsAtLeastNWidgets(1));
      expect(find.textContaining('تتبع البلوك تشين'), findsAtLeastNWidgets(1));
      expect(find.textContaining('المانيفست الرقمي'), findsAtLeastNWidgets(1));
    });
  });
}
