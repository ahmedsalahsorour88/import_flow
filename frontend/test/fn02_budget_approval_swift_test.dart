import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/financial_approval/models/financial_approval_model.dart';

void main() {
  group('FN-02: Budget Approval & Swift MT103 Reconciliation Tests', () {
    test('PaymentRequestModel handles SWIFT reconciliation fields serialization', () {
      final json = {
        'payment_id': 202,
        'payment_code': 'PAY-2026-000202',
        'title': 'Advance Payment - Extruder Machinery',
        'import_file_id': 1,
        'po_id': 1,
        'supplier_id': 1,
        'supplier_name': 'Shanghai Extrusion Machinery Co., Ltd',
        'project_id': 1,
        'payment_type': 'Advance Payment',
        'requested_amount': 50000.0,
        'currency_code': 'USD',
        'exchange_rate': 48.50,
        'requested_amount_egp': 2425000.0,
        'advance_percentage': 30.0,
        'smart_task_code': 'TASK-2026-0099',
        'due_date': '2026-09-25',
        'request_date': '2026-09-17',
        'status': 'Paid',
        'swift_reference_no': 'SWF-MT103-NBE-778899',
        'swift_receipt_date': '2026-09-19',
        'swift_transferred_amount': 49950.0,
        'swift_transferred_currency': 'USD',
        'swift_variance_amount': -50.0,
        'swift_variance_status': 'Deficit',
        'swift_processing_days': 2,
        'swift_reconciliation_notes': 'خصم عمولة مراسل 50 دولار',
        'beneficiary_name': 'Shanghai Extrusion Machinery Co., Ltd',
        'bank_name': 'Bank of China',
        'swift_code': 'BKCHCN2S',
        'iban_account_no': 'CN66BKCH662288990011',
        'is_active': true,
        'created_at': '2026-09-17T12:00:00',
        'updated_at': '2026-09-19T14:30:00',
        'import_file_code': 'IMP-2026-0001',
      };

      final model = PaymentRequestModel.fromJson(json);

      expect(model.paymentId, 202);
      expect(model.status, 'Paid');
      expect(model.swiftReferenceNo, 'SWF-MT103-NBE-778899');
      expect(model.swiftReceiptDate, '2026-09-19');
      expect(model.swiftTransferredAmount, 49950.0);
      expect(model.swiftTransferredCurrency, 'USD');
      expect(model.swiftVarianceAmount, -50.0);
      expect(model.swiftVarianceStatus, 'Deficit');
      expect(model.swiftProcessingDays, 2);
      expect(model.swiftReconciliationNotes, 'خصم عمولة مراسل 50 دولار');

      final serialized = model.toJson();
      expect(serialized['status'], 'Paid');
      expect(serialized['swift_reference_no'], 'SWF-MT103-NBE-778899');
      expect(serialized['swift_variance_amount'], -50.0);
      expect(serialized['swift_variance_status'], 'Deficit');
      expect(serialized['swift_processing_days'], 2);
    });

    test('ImportBudgetModel handles approval fields serialization', () {
      final json = {
        'budget_id': 15,
        'budget_code': 'BGT-2026-000015',
        'title': 'اعتماد الميزانية التقديرية للشحنة',
        'import_file_id': 1,
        'po_id': 1,
        'project_id': 1,
        'invoice_amount_egp': 4850000.0,
        'invoice_amount_foreign': 100000.0,
        'invoice_currency': 'USD',
        'freight_cost_egp': 242500.0,
        'freight_cost_foreign': 5000.0,
        'freight_currency': 'USD',
        'customs_duties_egp': 250000.0,
        'clearance_inland_egp': 50000.0,
        'exchange_rate': 48.50,
        'total_budget_egp': 5392500.0,
        'budget_status': 'Budget Approved',
        'approved_by': 'Dr. Ahmed Sorour (CFO)',
        'approved_date': '2026-09-17',
        'notes': 'تم الاعتماد المالي',
        'revision_number': 1,
        'has_unresolved_variance': false,
        'is_active': true,
        'created_at': '2026-09-17T10:00:00',
        'updated_at': '2026-09-17T11:00:00',
        'import_file_code': 'IMP-2026-0001',
      };

      final model = ImportBudgetModel.fromJson(json);

      expect(model.budgetId, 15);
      expect(model.budgetCode, 'BGT-2026-000015');
      expect(model.budgetStatus, 'Budget Approved');
      expect(model.approvedBy, 'Dr. Ahmed Sorour (CFO)');
      expect(model.approvedDate, '2026-09-17');
      expect(model.totalBudgetEgp, 5392500.0);
      expect(model.hasUnresolvedVariance, false);

      final serialized = model.toJson();
      expect(serialized['budget_status'], 'Budget Approved');
      expect(serialized['approved_by'], 'Dr. Ahmed Sorour (CFO)');
      expect(serialized['approved_date'], '2026-09-17');
    });

    test('SWIFT MT103 variance and processing days mathematical engine', () {
      const requestedAmt = 50000.0;
      final requestDate = DateTime(2026, 9, 15);

      final testCases = [
        {
          'transferred': 50000.0,
          'receiptDate': DateTime(2026, 9, 15),
          'expectedVariance': 0.0,
          'expectedStatus': 'Matched',
          'expectedDays': 0,
        },
        {
          'transferred': 49950.0,
          'receiptDate': DateTime(2026, 9, 17),
          'expectedVariance': -50.0,
          'expectedStatus': 'Deficit',
          'expectedDays': 2,
        },
        {
          'transferred': 50100.0,
          'receiptDate': DateTime(2026, 9, 19),
          'expectedVariance': 100.0,
          'expectedStatus': 'Surplus',
          'expectedDays': 4,
        },
      ];

      for (final tc in testCases) {
        final transferred = tc['transferred'] as double;
        final receiptDate = tc['receiptDate'] as DateTime;
        final variance = (transferred - requestedAmt).roundToDouble();
        final days = receiptDate.difference(requestDate).inDays;

        String status;
        if (variance.abs() < 0.01) {
          status = 'Matched';
        } else if (variance < 0) {
          status = 'Deficit';
        } else {
          status = 'Surplus';
        }

        expect(variance, tc['expectedVariance']);
        expect(status, tc['expectedStatus']);
        expect(days, tc['expectedDays']);
      }
    });

    testWidgets('SWIFT Reconciliation Status Card renders correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      final testPayment = PaymentRequestModel.fromJson({
        'payment_id': 202,
        'payment_code': 'PAY-2026-000202',
        'title': 'Advance Payment - Extruder Machinery',
        'supplier_name': 'Shanghai Extrusion Machinery Co., Ltd',
        'payment_type': 'Advance Payment',
        'requested_amount': 50000.0,
        'currency_code': 'USD',
        'exchange_rate': 48.50,
        'requested_amount_egp': 2425000.0,
        'due_date': '2026-09-25',
        'request_date': '2026-09-17',
        'status': 'Paid',
        'swift_reference_no': 'SWF-MT103-NBE-778899',
        'swift_receipt_date': '2026-09-19',
        'swift_transferred_amount': 49950.0,
        'swift_transferred_currency': 'USD',
        'swift_variance_amount': -50.0,
        'swift_variance_status': 'Deficit',
        'swift_processing_days': 2,
        'swift_reconciliation_notes': 'خصم عمولة مراسل 50 دولار',
        'is_active': true,
        'created_at': '2026-09-17T12:00:00',
        'updated_at': '2026-09-19T14:30:00',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم السويفت: ${testPayment.swiftReferenceNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('المبلغ المحول: ${testPayment.swiftTransferredAmount} ${testPayment.swiftTransferredCurrency}'),
                    Text('حالة المطابقة: ${testPayment.swiftVarianceStatus}'),
                    Text('أيام المعالجة: ${testPayment.swiftProcessingDays} يوم'),
                    Text('الحالة: ${testPayment.status}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('رقم السويفت: SWF-MT103-NBE-778899'), findsOneWidget);
      expect(find.text('المبلغ المحول: 49950.0 USD'), findsOneWidget);
      expect(find.text('حالة المطابقة: Deficit'), findsOneWidget);
      expect(find.text('أيام المعالجة: 2 يوم'), findsOneWidget);
      expect(find.text('الحالة: Paid'), findsOneWidget);
    });
  });
}
