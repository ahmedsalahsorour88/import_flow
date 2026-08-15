import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/financial_approval/models/financial_approval_model.dart';

void main() {
  group('Financial Approval & Budget Models Tests (BP-012 & BP-013)', () {
    test('PaymentRequestModel serialization and deserialization', () {
      final json = {
        'payment_id': 1,
        'payment_code': 'PAY-2026-001',
        'title': 'Advance Payment 30% for Shipment',
        'import_file_id': 10,
        'po_id': 5,
        'supplier_id': 2,
        'supplier_name': 'Shanghai Machinery Ltd',
        'project_id': 1,
        'payment_type': 'Advance Payment',
        'requested_amount': 15000.0,
        'currency_code': 'USD',
        'exchange_rate': 50.0,
        'requested_amount_egp': 750000.0,
        'due_date': '2026-09-01',
        'request_date': '2026-08-15',
        'status': 'Draft',
        'beneficiary_name': 'Shanghai Machinery Ltd',
        'bank_name': 'Bank of China',
        'swift_code': 'BKCHCN2S',
        'iban_account_no': 'CN987654321',
        'bank_country': 'China',
        'swift_reference_no': 'SWIFT-998877',
        'notes': 'Urgent transfer',
        'is_active': true,
        'created_at': '2026-08-15T00:00:00',
        'updated_at': '2026-08-15T00:00:00',
        'import_file_code': 'IMP-2026-010',
      };

      final model = PaymentRequestModel.fromJson(json);

      expect(model.paymentId, 1);
      expect(model.paymentCode, 'PAY-2026-001');
      expect(model.requestedAmount, 15000.0);
      expect(model.requestedAmountEgp, 750000.0);
      expect(model.bankName, 'Bank of China');
      expect(model.swiftCode, 'BKCHCN2S');
      expect(model.ibanAccountNo, 'CN987654321');

      final serialized = model.toJson();
      expect(serialized['payment_id'], 1);
      expect(serialized['swift_code'], 'BKCHCN2S');
      expect(serialized['bank_name'], 'Bank of China');
    });

    test('ImportBudgetModel multi-currency fields serialization', () {
      final json = {
        'budget_id': 1,
        'budget_code': 'BGT-2026-001',
        'title': 'Total Import Budget for Machinery',
        'import_file_id': 10,
        'invoice_amount_foreign': 50000.0,
        'invoice_currency': 'USD',
        'invoice_amount_egp': 2500000.0,
        'freight_cost_foreign': 3500.0,
        'freight_currency': 'USD',
        'freight_cost_egp': 175000.0,
        'customs_duties_egp': 650000.0,
        'clearance_inland_egp': 45000.0,
        'exchange_rate': 50.0,
        'total_budget_egp': 3370000.0,
        'budget_status': 'Budget Approved',
        'approved_by': 'CFO',
        'approved_date': '2026-08-15',
        'notes': 'Approved without reserve',
        'is_active': true,
        'created_at': '2026-08-15T00:00:00',
        'updated_at': '2026-08-15T00:00:00',
        'import_file_code': 'IMP-2026-010',
      };

      final model = ImportBudgetModel.fromJson(json);

      expect(model.budgetId, 1);
      expect(model.budgetCode, 'BGT-2026-001');
      expect(model.invoiceAmountForeign, 50000.0);
      expect(model.invoiceCurrency, 'USD');
      expect(model.freightCostForeign, 3500.0);
      expect(model.customsDutiesEgp, 650000.0);
      expect(model.totalBudgetEgp, 3370000.0);
      expect(model.budgetStatus, 'Budget Approved');
      expect(model.approvedBy, 'CFO');
    });

    test('BudgetPrefillModel and LinkedPOItemModel deserialization', () {
      final json = {
        'import_file_id': 10,
        'import_file_code': 'IMP-2026-010',
        'import_file_title': 'Machinery Shipment Batch A',
        'incoterm': 'FOB',
        'supplier_id': 2,
        'supplier_name': 'Shanghai Machinery Ltd',
        'beneficiary_name': 'Shanghai Machinery Ltd',
        'bank_name': 'Industrial and Commercial Bank of China',
        'swift_code': 'ICBKCNBJ',
        'account_number': '6222000011112222',
        'iban': 'CN99ICBK6222000011112222',
        'payment_terms_summary': 'متعدد (PO-001 (Advance 30%), PO-002 (CAD))',
        'linked_pos': [
          {
            'po_id': 1,
            'po_number': 'PO-001',
            'pi_number': 'PI-9901',
            'project_id': 1,
            'project_name': 'Factory Line',
            'payment_terms': 'Advance 30%',
            'currency': 'USD',
            'total_amount': 20000.0,
            'status': 'Approved',
          },
          {
            'po_id': 2,
            'po_number': 'PO-002',
            'pi_number': 'PI-9902',
            'project_id': 1,
            'project_name': 'Factory Line',
            'payment_terms': 'CAD 70%',
            'currency': 'USD',
            'total_amount': 30000.0,
            'status': 'Approved',
          }
        ],
        'total_invoice_amount': 50000.0,
        'invoice_currency': 'USD',
        'total_invoice_amount_egp': 2500000.0,
        'estimated_freight_cost': 4000.0,
        'freight_currency': 'USD',
        'estimated_freight_cost_egp': 200000.0,
        'estimated_customs_duties_egp': 600000.0,
        'estimated_clearance_fees_egp': 50000.0,
        'estimated_grand_total_egp': 3350000.0,
        'exchange_rate': 50.0,
      };

      final prefill = BudgetPrefillModel.fromJson(json);

      expect(prefill.importFileId, 10);
      expect(prefill.supplierName, 'Shanghai Machinery Ltd');
      expect(prefill.swiftCode, 'ICBKCNBJ');
      expect(prefill.linkedPos.length, 2);
      expect(prefill.linkedPos[0].poNumber, 'PO-001');
      expect(prefill.linkedPos[0].paymentTerms, 'Advance 30%');
      expect(prefill.linkedPos[1].poNumber, 'PO-002');
      expect(prefill.totalInvoiceAmount, 50000.0);
      expect(prefill.estimatedGrandTotalEgp, 3350000.0);
    });

    test('PaymentRequestModel SWIFT reconciliation fields serialization', () {
      final json = {
        'payment_id': 101,
        'payment_code': 'PAY-2026-101',
        'title': 'Advance Payment with SWIFT Confirmation',
        'import_file_id': 15,
        'supplier_name': 'German Heavy Machinery AG',
        'payment_type': 'Advance Payment',
        'requested_amount': 25000.0,
        'currency_code': 'EUR',
        'exchange_rate': 55.0,
        'requested_amount_egp': 1375000.0,
        'due_date': '2026-08-30',
        'request_date': '2026-08-10',
        'status': 'Paid',
        'swift_reference_no': 'SWIFT-DE-889900',
        'swift_receipt_date': '2026-08-13',
        'swift_transferred_amount': 25000.0,
        'swift_transferred_currency': 'EUR',
        'swift_variance_amount': 0.0,
        'swift_variance_status': 'Matched',
        'swift_processing_days': 3,
        'swift_reconciliation_notes': 'Transferred fully via Deutsche Bank',
        'is_active': true,
        'created_at': '2026-08-10T00:00:00',
        'updated_at': '2026-08-13T00:00:00',
        'import_file_code': 'IMP-2026-015',
      };

      final model = PaymentRequestModel.fromJson(json);

      expect(model.paymentId, 101);
      expect(model.swiftReferenceNo, 'SWIFT-DE-889900');
      expect(model.swiftReceiptDate, '2026-08-13');
      expect(model.swiftTransferredAmount, 25000.0);
      expect(model.swiftVarianceAmount, 0.0);
      expect(model.swiftVarianceStatus, 'Matched');
      expect(model.swiftProcessingDays, 3);
      expect(model.swiftReconciliationNotes, 'Transferred fully via Deutsche Bank');

      final serialized = model.toJson();
      expect(serialized['swift_reference_no'], 'SWIFT-DE-889900');
      expect(serialized['swift_processing_days'], 3);
      expect(serialized['swift_variance_status'], 'Matched');
    });
  });
}
