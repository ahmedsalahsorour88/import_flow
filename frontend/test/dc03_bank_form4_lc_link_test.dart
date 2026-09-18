import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('DC-03: Bank Form 4 / LC Link Model & Serialization Tests', () {
    test('BankingDocumentModel parses Form 4 request and received state', () {
      final json = {
        'bank_doc_id': 15,
        'bank_doc_code': 'FORM4-2026-0015',
        'doc_type': 'Form 4',
        'import_file_id': 1,
        'import_file_code': 'IMP-2026-0033',
        'bank_name': 'Commercial International Bank (CIB)',
        'amount': 85000.0,
        'currency_code': 'USD',
        'request_date': '2026-09-10',
        'received_date': '2026-09-14',
        'execution_days': 4,
        'issue_date': '2026-09-10',
        'doc_reference_number': 'F4-EG-2026-993311',
        'status': 'Received',
        'importer_name': 'El-Araby Group',
        'supplier_name': 'Hitachi Global Tokyo',
        'notes': 'Form 4 endorsed by CIB Mohandessin branch',
        'is_active': true,
        'created_at': '2026-09-10T10:00:00Z',
        'updated_at': '2026-09-14T12:00:00Z',
      };

      final doc = BankingDocumentModel.fromJson(json);

      expect(doc.bankDocId, 15);
      expect(doc.bankDocCode, 'FORM4-2026-0015');
      expect(doc.docType, 'Form 4');
      expect(doc.importFileId, 1);
      expect(doc.docReferenceNumber, 'F4-EG-2026-993311');
      expect(doc.executionDays, 4);
      expect(doc.status, 'Received');
      expect(doc.bankName, 'Commercial International Bank (CIB)');

      final serialized = doc.toJson();
      expect(serialized['doc_type'], 'Form 4');
      expect(serialized['doc_reference_number'], 'F4-EG-2026-993311');
      expect(serialized['execution_days'], 4);
      expect(serialized['status'], 'Received');
    });

    test('BankingDocumentModel parses Letter of Credit (L/C) document', () {
      final json = {
        'bank_doc_id': 22,
        'bank_doc_code': 'FORM4-2026-0022',
        'doc_type': 'Letter of Credit (L/C)',
        'import_file_id': 3,
        'import_file_code': 'IMP-2026-0055',
        'bank_name': 'National Bank of Egypt (NBE)',
        'amount': 150000.0,
        'currency_code': 'EUR',
        'request_date': '2026-09-01',
        'received_date': '2026-09-08',
        'execution_days': 7,
        'issue_date': '2026-09-01',
        'doc_reference_number': 'LC-NBE-2026-7788',
        'status': 'Received',
        'importer_name': 'Fresh Electric',
        'supplier_name': 'Samsung Electronics',
        'notes': 'Irrevocable confirmed L/C at sight',
        'is_active': true,
        'created_at': '2026-09-01T08:00:00Z',
        'updated_at': '2026-09-08T14:00:00Z',
      };

      final doc = BankingDocumentModel.fromJson(json);

      expect(doc.bankDocId, 22);
      expect(doc.docType, 'Letter of Credit (L/C)');
      expect(doc.docReferenceNumber, 'LC-NBE-2026-7788');
      expect(doc.executionDays, 7);
      expect(doc.currencyCode, 'EUR');
      expect(doc.amount, 150000.0);
    });

    test('ImportFileModel parses Form 4 and LC linkage fields', () {
      final json = {
        'import_file_id': 1,
        'import_file_code': 'IMP-2026-0033',
        'form4_no': 'F4-EG-2026-993311',
        'form4_request_date': '2026-09-10',
        'form4_received_date': '2026-09-14',
        'form4_execution_days': 4,
        'company_name': 'El-Araby Group',
        'supplier_name': 'Hitachi Global Tokyo',
        'current_module': 'STEP_13 Declaration 46 Preparation',
        'current_stage': 'Customs Procedures',
        'progress_percent': 65.0,
      };

      final file = ImportFileModel.fromJson(json);

      expect(file.importFileId, 1);
      expect(file.form4No, 'F4-EG-2026-993311');
      expect(file.form4RequestDate, '2026-09-10');
      expect(file.form4ReceivedDate, '2026-09-14');
      expect(file.form4ExecutionDays, 4);
      expect(file.progressPercent, 65.0);

      final map = file.toJson();
      expect(map['form4_no'], 'F4-EG-2026-993311');
      expect(map['form4_received_date'], '2026-09-14');
      expect(map['form4_execution_days'], 4);
    });
  });
}
