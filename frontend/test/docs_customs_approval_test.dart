import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/import_documentation/models/docs_customs_approval_model.dart';
import 'package:frontend/features/import_documentation/providers/docs_customs_approval_provider.dart';
import 'package:frontend/features/import_documentation/widgets/customs_document_approval_tab.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockImportFilesNotifier extends StateNotifier<AsyncValue<List<ImportFileModel>>>
    implements ImportFilesNotifier {
  MockImportFilesNotifier()
      : super(
          AsyncValue.data([
            ImportFileModel(
              importFileId: 10,
              importFileCode: 'IMP-2026-001',
              customFileNumber: 'FILE-001',
              companyName: 'Al-Ahram Trading',
              supplierName: 'Shanghai Machinery Corp',
              status: 'In Progress',
              invoicesData: [],
              packingListsData: [],
              projectIds: [],
              shipmentMode: 'Sea',
              priority: 'Normal',
              shipmentCategory: 'Commercial',
              currentModule: 'Import Documentation',
              currentStage: 'STAGE_05_DRAFT_DOCS',
              nextAction: 'Review Drafts',
              progressPercent: 50.0,
              isCustomsReleased: false,
              isActive: true,
              createdAt: DateTime.now().toString(),
              updatedAt: DateTime.now().toString(),
            )
          ]),
        );

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? currentStage,
    bool? isCustomsReleased,
    String? owner,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDocsApprovalNotifier extends StateNotifier<AsyncValue<List<CustomsDocumentApprovalModel>>>
    implements DocsCustomsApprovalNotifier {
  MockDocsApprovalNotifier()
      : super(
          AsyncValue.data([
            CustomsDocumentApprovalModel(
              approvalId: 1,
              approvalCode: 'CDA-2026-0001',
              importFileId: 10,
              documentType: 'Commercial Invoice',
              documentReferenceNo: 'INV-9901',
              commercialStatus: 'Approved',
              customsStatus: 'Approved',
              overallStatus: 'Approved for Clearance',
              createdAt: '2026-08-20',
              updatedAt: '2026-08-20',
            ),
          ]),
        );

  @override
  Future<void> fetchApprovals({int? importFileId, String? overallStatus, String? search}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDiscrepancyTicketsNotifier extends StateNotifier<AsyncValue<List<DiscrepancyRectificationTicketModel>>>
    implements DiscrepancyTicketsNotifier {
  MockDiscrepancyTicketsNotifier()
      : super(
          AsyncValue.data([
            DiscrepancyRectificationTicketModel(
              ticketId: 101,
              ticketCode: 'RECT-2026-0001',
              importFileId: 10,
              issueCategory: 'HS Code Mismatch',
              severity: 'Major',
              description: 'HS Code mismatch between PO and BL',
              status: 'Open',
              createdAt: '2026-08-20',
              updatedAt: '2026-08-20',
            ),
          ]),
        );

  @override
  Future<void> fetchTickets({int? importFileId, String? status, String? severity, String? search}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Docs Customs Approval Hub (DCA-001) Models & Serialization Tests', () {
    test('CustomsDocumentApprovalModel serialization and status mapping', () {
      final json = {
        'approval_id': 1,
        'approval_code': 'CDA-2026-0001',
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-001',
        'po_id': 5,
        'document_type': 'Commercial Invoice',
        'document_reference_no': 'INV-9901',
        'document_date': '2026-08-20',
        'commercial_status': 'Approved',
        'commercial_reviewed_by': 'Finance Lead',
        'commercial_reviewed_at': '2026-08-20T10:00:00Z',
        'commercial_notes': 'All terms verified',
        'customs_status': 'Approved',
        'customs_reviewed_by': 'Broker Legal',
        'customs_reviewed_at': '2026-08-20T10:15:00Z',
        'customs_broker_name': 'Nile Brokerage LLC',
        'customs_notes': 'Tariff schedule checked',
        'overall_status': 'Approved for Clearance',
        'is_active': true,
        'created_at': '2026-08-20T09:00:00Z',
        'updated_at': '2026-08-20T10:15:00Z',
      };

      final model = CustomsDocumentApprovalModel.fromJson(json);
      expect(model.approvalId, 1);
      expect(model.approvalCode, 'CDA-2026-0001');
      expect(model.documentType, 'Commercial Invoice');
      expect(model.commercialStatus, 'Approved');
      expect(model.customsStatus, 'Approved');
      expect(model.overallStatus, 'Approved for Clearance');

      final serialized = model.toJson();
      expect(serialized['approval_code'], 'CDA-2026-0001');
      expect(serialized['document_type'], 'Commercial Invoice');
    });

    test('DiscrepancyRectificationTicketModel serialization and lifecycle', () {
      final json = {
        'ticket_id': 101,
        'ticket_code': 'RECT-2026-0001',
        'approval_id': 1,
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-001',
        'issue_category': 'HS Code Mismatch',
        'severity': 'Critical',
        'description': 'Invoice HS code 8415.90 differs from PO and ACID 8415.10',
        'expected_value': '8415.10',
        'found_value': '8415.90',
        'supplier_action_required': 'Reissue draft invoice',
        'status': 'Open',
        'is_active': true,
        'created_at': '2026-08-20T10:00:00Z',
        'updated_at': '2026-08-20T10:00:00Z',
      };

      final model = DiscrepancyRectificationTicketModel.fromJson(json);
      expect(model.ticketId, 101);
      expect(model.ticketCode, 'RECT-2026-0001');
      expect(model.issueCategory, 'HS Code Mismatch');
      expect(model.severity, 'Critical');
      expect(model.status, 'Open');
    });

    test('CrossDocumentMatrixResultModel parsed correctly', () {
      final json = {
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-001',
        'overall_compliance': 'Fully Compliant',
        'total_checks': 6,
        'passed_checks': 6,
        'failed_checks': 0,
        'checks': [
          {
            'parameter': 'ACID Number (19 Digits)',
            'status': 'Match',
            'acid_val': '1234567890123456789',
            'notes': 'Verified on Nafeza',
          }
        ],
        'recommendations': [],
        'open_tickets_count': 0,
      };

      final res = CrossDocumentMatrixResultModel.fromJson(json);
      expect(res.overallCompliance, 'Fully Compliant');
      expect(res.totalChecks, 6);
      expect(res.passedChecks, 6);
      expect(res.checks.length, 1);
      expect(res.checks.first.status, 'Match');
    });
  });

  group('CustomsDocumentApprovalTab Widget Rendering Tests', () {
    testWidgets('CustomsDocumentApprovalTab renders toolbar and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            importFilesProvider.overrideWith((ref) => MockImportFilesNotifier()),
            docsCustomsApprovalProvider.overrideWith((ref) => MockDocsApprovalNotifier()),
            discrepancyTicketsProvider.overrideWith((ref) => MockDiscrepancyTicketsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomsDocumentApprovalTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Toolbar Buttons
      expect(find.text('فحص متقاطع ذكي (AI Matrix Audit)'), findsOneWidget);
      expect(find.text('توليد القائمة القياسية'), findsOneWidget);
      expect(find.text('تذكرة استدراك للمورد'), findsOneWidget);

      // Verify Dual-Tier Section Titles
      expect(find.text('مصفوفة اعتماد المستندات الجمركية (Dual-Tier Sign-off)'), findsOneWidget);
      expect(find.text('سجل تذاكر الاستدراك والاستفسارات'), findsOneWidget);
    });
  });
}
