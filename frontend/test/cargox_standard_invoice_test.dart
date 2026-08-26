import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/cargox/models/cargox_model.dart';
import 'package:frontend/features/cargox/widgets/standard_invoice_hub_tab.dart';

void main() {
  group('Standard Excel Commercial Invoice Model Tests', () {
    test('StandardInvoiceLineItemModel fromJson and toJson serialization', () {
      final json = {
        'index': 1,
        'product_code': 'DSK-001',
        'manufacturer': 'Narbutas UAB',
        'brand_name': 'Nova',
        'model': 'Nova-Desk',
        'hs_code': '940310',
        'country_of_origin': 'LT',
        'description': 'Executive Office Desk',
        'quantity': 10.0,
        'qty_unit': 'SET',
        'unit_price': 300.0,
        'unit_price_basis': 'SET',
        'gross_weight_kg': 250.0,
        'net_weight_kg': 220.0,
        'total_amount': 3000.0,
      };

      final item = StandardInvoiceLineItemModel.fromJson(json);
      expect(item.index, 1);
      expect(item.productCode, 'DSK-001');
      expect(item.hsCode, '940310');
      expect(item.quantity, 10.0);
      expect(item.totalAmount, 3000.0);

      final encoded = item.toJson();
      expect(encoded['product_code'], 'DSK-001');
      expect(encoded['hs_code'], '940310');
      expect(encoded['total_amount'], 3000.0);
    });

    test('StandardInvoicePayloadModel calculations and totals', () {
      final json = {
        'seller_name': 'Narbutas International UAB',
        'seller_country_code': 'LT',
        'seller_tax_id': 'LT300591314',
        'buyer_name': 'Egyptian Import & Supply Co.',
        'buyer_tax_id': '123456789',
        'acid_number': '7595528271020210010',
        'invoice_number': 'INV-2026-009',
        'currency_code': 'EUR',
        'incoterm': 'EXW',
        'subtotal': 5000.0,
        'freight_cost': 300.0,
        'insurance_cost': 50.0,
        'other_costs': 0.0,
        'total_amount': 5350.0,
        'items': [
          {
            'index': 1,
            'product_code': 'DSK-001',
            'hs_code': '940310',
            'country_of_origin': 'LT',
            'description': 'Desk',
            'quantity': 10.0,
            'unit_price': 300.0,
            'total_amount': 3000.0,
          },
          {
            'index': 2,
            'product_code': 'CHR-002',
            'hs_code': '940130',
            'country_of_origin': 'LT',
            'description': 'Chair',
            'quantity': 20.0,
            'unit_price': 100.0,
            'total_amount': 2000.0,
          },
        ],
      };

      final payload = StandardInvoicePayloadModel.fromJson(json);
      expect(payload.sellerName, 'Narbutas International UAB');
      expect(payload.acidNumber, '7595528271020210010');
      expect(payload.items.length, 2);
      expect(payload.subtotal, 5000.0);
      expect(payload.totalAmount, 5350.0);
    });

    test('StandardInvoiceComparisonResponseModel parsing and discrepancy checks', () {
      final json = {
        'import_file_id': 1,
        'import_file_code': 'IMP-2026-009',
        'acid_number': '7595528271020210010',
        'has_discrepancies': true,
        'has_critical_mismatch': false,
        'total_discrepancies_count': 1,
        'critical_mismatches_count': 0,
        'warnings_count': 1,
        'header_comparisons': [
          {
            'field_key': 'incoterm',
            'field_label_ar': 'شرط التسليم',
            'field_label_en': 'Incoterm',
            'system_value': 'EXW',
            'supplier_value': 'FOB',
            'status': 'WARNING',
            'difference': 'EXW vs FOB',
          }
        ],
        'financial_comparisons': [],
        'line_item_comparisons': [],
        'rectification_notice_en': 'Please amend Incoterm from FOB to EXW.',
        'rectification_notice_ar': 'يرجى تعديل شرط التسليم من FOB إلى EXW.',
      };

      final comp = StandardInvoiceComparisonResponseModel.fromJson(json);
      expect(comp.hasDiscrepancies, true);
      expect(comp.hasCriticalMismatch, false);
      expect(comp.warningsCount, 1);
      expect(comp.headerComparisons.first.fieldKey, 'incoterm');
      expect(comp.rectificationNoticeEn, isNotNull);
    });

    test('StandardInvoiceSessionModel fromJson', () {
      final json = {
        'session_id': 1,
        'session_code': 'CX-INV-2026-0001',
        'import_file_id': 1,
        'import_file_code': 'IMP-2026-009',
        'acid_number': '7595528271020210010',
        'invoice_number': 'INV-2026-009',
        'total_amount': 5350.0,
        'line_items_count': 2,
        'status': 'APPROVED',
        'has_discrepancies': false,
        'has_critical_mismatch': false,
        'created_at': '2026-08-21T02:00:00Z',
        'updated_at': '2026-08-21T02:00:00Z',
      };

      final session = StandardInvoiceSessionModel.fromJson(json);
      expect(session.sessionId, 1);
      expect(session.sessionCode, 'CX-INV-2026-0001');
      expect(session.status, 'APPROVED');
      expect(session.totalAmount, 5350.0);
    });
  });

  group('StandardInvoiceHubTab Widget Tests', () {
    testWidgets('Renders Standard Commercial Invoice Hub Tab and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppLocalizationsProvider(
              locale: Locale('ar'),
              child: Scaffold(
                body: StandardInvoiceHubTab(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('الفاتورة التجارية المعيارية'), findsWidgets);
      expect(find.textContaining('توليد نموذج الإكسيل'), findsOneWidget);
      expect(find.textContaining('قراءة واستخراج فاتورة المورد'), findsOneWidget);
      expect(find.textContaining('بيانات الفاتورة المستخرجة'), findsWidgets);
      expect(find.textContaining('مصفوفة المطابقة'), findsWidgets);
      expect(find.textContaining('الاعتماد والتحكم الجمركي'), findsWidgets);
      expect(find.textContaining('سجل الفواتير المعيارية'), findsWidgets);
    });
  });
}
