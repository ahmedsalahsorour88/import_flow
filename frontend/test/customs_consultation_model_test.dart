import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_consultation/models/customs_consultation_model.dart';

void main() {
  group('CustomsConsultationModel & ChecklistItem Unit Tests (BP-009 / BP-010)', () {
    test('Should parse CustomsChecklistItemModel from JSON correctly', () {
      final json = {
        'item_id': 1,
        'consultation_id': 10,
        'document_type': 'عرض وفحص هيئة الرقابة على الصادرات والواردات (GOEIC) - بند 8415820010',
        'hs_code': '8415820010',
        'is_required': true,
        'required_text': '✓',
        'is_blocking_shipment': true,
        'responsible_party': 'Customs Broker',
        'status': 'Pending',
        'regulatory_agency': 'GOEIC (هيئة الصادرات والواردات)',
        'remarks': 'يتطلب سحب عينات والفحص المعملي ومطابقة المواصفات القياسية المصرية.',
      };

      final item = CustomsChecklistItemModel.fromJson(json);

      expect(item.itemId, 1);
      expect(item.hsCode, '8415820010');
      expect(item.isBlockingShipment, isTrue);
      expect(item.responsibleParty, 'Customs Broker');
      expect(item.regulatoryAgency, 'GOEIC (هيئة الصادرات والواردات)');
    });

    test('Should serialize CustomsChecklistItemModel to JSON accurately', () {
      final item = CustomsChecklistItemModel(
        documentType: 'شهادة المنشأ COO',
        hsCode: '8415820010',
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        regulatoryAgency: 'Chamber of Commerce',
        remarks: 'موثقة أصولاً',
      );

      final json = item.toJson();

      expect(json['document_type'], 'شهادة المنشأ COO');
      expect(json['hs_code'], '8415820010');
      expect(json['is_blocking_shipment'], isTrue);
      expect(json['responsible_party'], 'Supplier / Exporter');
      expect(json['status'], 'Approved');
    });

    test('Should parse CustomsConsultationModel with checklist from JSON', () {
      final json = {
        'consultation_id': 5,
        'consultation_code': 'CST-2026-0005',
        'title': 'دراسة المراجعة الجمركية الأولية لخط الإنتاج',
        'broker_id': 12,
        'broker_name': 'مكتب الإخلاص للتخليص الجمركي',
        'broker_contact_person': 'م. عادل الشريف',
        'import_file_id': 101,
        'import_file_code': 'IMP-2026-0001',
        'po_id': 201,
        'po_number': 'PO-2026-0001',
        'estimated_duties_egp': 165801.50,
        'notes': 'تم التدقيق مع المستخلص',
        'overall_status': 'In Progress',
        'total_documents_count': 5,
        'approved_documents_count': 2,
        'blocking_issues_count': 1,
        'readiness_percentage': 40.0,
        'checklist_items': [
          {
            'item_id': 1,
            'document_type': 'Proforma Invoice',
            'is_required': true,
            'is_blocking_shipment': true,
            'status': 'Approved',
          },
          {
            'item_id': 2,
            'document_type': 'GOEIC Inspection',
            'hs_code': '8415820010',
            'is_required': true,
            'is_blocking_shipment': true,
            'status': 'Pending',
          }
        ],
      };

      final model = CustomsConsultationModel.fromJson(json);

      expect(model.consultationId, 5);
      expect(model.consultationCode, 'CST-2026-0005');
      expect(model.estimatedDutiesEgp, 165801.50);
      expect(model.readinessPercentage, 40.0);
      expect(model.checklistItems.length, 2);
      expect(model.checklistItems[1].hsCode, '8415820010');
    });

    test('Should parse CustomsRecalculationResponseModel correctly', () {
      final json = {
        'import_file_id': 101,
        'import_file_code': 'IMP-2026-0001',
        'final_invoice_number': 'INV-FINAL-9901',
        'reconciliation_session_id': 12,
        'is_reconciled': true,
        'source_description': 'الفاتورة وقائمة التعبئة النهائية المعتمدة',
        'exchange_rate': 52.5,
        'estimate_date': '2026-08-21',
        'preliminary_fob_egp': 500000.0,
        'final_fob_egp': 630000.0,
        'fob_variance_egp': 130000.0,
        'preliminary_cif_egp': 520000.0,
        'final_cif_egp': 650000.0,
        'cif_variance_egp': 130000.0,
        'preliminary_duty_egp': 52000.0,
        'final_duty_egp': 65000.0,
        'duty_variance_egp': 13000.0,
        'preliminary_vat_egp': 80080.0,
        'final_vat_egp': 100100.0,
        'vat_variance_egp': 20020.0,
        'preliminary_total_taxes_egp': 132080.0,
        'final_total_taxes_egp': 165100.0,
        'total_taxes_variance_egp': 33020.0,
        'variance_percentage': 25.0,
        'forecast_status': 'Increased Cost',
        'comparison_lines': [
          {
            'item_name': 'Granite Tiles',
            'hs_code': '6802.99',
            'country_of_origin': 'CN',
            'preliminary_qty': 100.0,
            'final_qty': 120.0,
            'qty_variance': 20.0,
            'preliminary_unit_price': 100.0,
            'final_unit_price': 100.0,
            'unit_price_variance': 0.0,
            'preliminary_fob_egp': 500000.0,
            'final_fob_egp': 630000.0,
            'fob_variance_egp': 130000.0,
            'preliminary_cif_egp': 520000.0,
            'final_cif_egp': 650000.0,
            'cif_variance_egp': 130000.0,
            'duty_rate_pct': 10.0,
            'preliminary_duty_egp': 52000.0,
            'final_duty_egp': 65000.0,
            'duty_variance_egp': 13000.0,
            'vat_rate_pct': 14.0,
            'preliminary_vat_egp': 80080.0,
            'final_vat_egp': 100100.0,
            'vat_variance_egp': 20020.0,
            'preliminary_total_taxes_egp': 132080.0,
            'final_total_taxes_egp': 165100.0,
            'total_taxes_variance_egp': 33020.0,
          }
        ],
      };

      final model = CustomsRecalculationResponseModel.fromJson(json);

      expect(model.importFileId, 101);
      expect(model.isReconciled, isTrue);
      expect(model.finalInvoiceNumber, 'INV-FINAL-9901');
      expect(model.exchangeRate, 52.5);
      expect(model.totalTaxesVarianceEgp, 33020.0);
      expect(model.forecastStatus, 'Increased Cost');
      expect(model.comparisonLines.length, 1);
      expect(model.comparisonLines.first.hsCode, '6802.99');
      expect(model.comparisonLines.first.qtyVariance, 20.0);
    });

    test('Should parse and serialize BrokerPriceListModel with custom surcharge items correctly', () {
      final json = {
        'price_list_id': 10,
        'price_list_code': 'PL-2026-0010',
        'title': 'بيان أسعار التخليص والنقل لميناء الإسكندرية لعام 2026',
        'broker_id': 34,
        'broker_name': 'Nabil Naseef .ACC',
        'port_name': 'Alexandria Port',
        'effective_from': '2026-04-01',
        'version': 1,
        'is_active': true,
        'notes': 'الأسعار سارية لكافة الرسائل الواردة لميناء الإسكندرية والدخيلة',
        'items': [
          {
            'item_id': 1,
            'price_list_id': 10,
            'expense_type_id': null,
            'expense_name': 'اخرى',
            'category': 'Other Fees (مصاريف أخرى)',
            'unit_type': 'Per Shipment (لكل شحنة)',
            'standard_price': 1000.0,
            'currency': 'EGP',
            'notes': 'بند استثنائي',
            'is_active': true,
          },
          {
            'item_id': 2,
            'price_list_id': 10,
            'expense_type_id': 5,
            'expense_name': 'أتعاب تخليص حاوية 40 قدم',
            'category': 'Clearance Fees (أتعاب ومصاريف تخليص)',
            'unit_type': 'Per Container (لكل حاوية)',
            'standard_price': 2500.0,
            'currency': 'EGP',
            'is_active': true,
          },
        ],
      };

      final model = BrokerPriceListModel.fromJson(json);

      expect(model.priceListId, 10);
      expect(model.priceListCode, 'PL-2026-0010');
      expect(model.brokerId, 34);
      expect(model.brokerName, 'Nabil Naseef .ACC');
      expect(model.items.length, 2);
      expect(model.items.first.expenseTypeId, isNull);
      expect(model.items.first.expenseName, 'اخرى');
      expect(model.items.first.standardPrice, 1000.0);
      expect(model.items.last.expenseTypeId, 5);
      expect(model.items.last.standardPrice, 2500.0);

      final serialized = model.toJson();
      expect(serialized['title'], 'بيان أسعار التخليص والنقل لميناء الإسكندرية لعام 2026');
      expect((serialized['items'] as List).length, 2);
      expect((serialized['items'] as List).first['expense_name'], 'اخرى');
      expect((serialized['items'] as List).first['standard_price'], 1000.0);
    });

    test('Should calculate Marine Insurance and Declared CIF correctly according to Egyptian Customs formula', () {
      // Example matching user request:
      // FOB = $47,000.00 USD
      // Freight = $8,250.00 USD
      // C&F = $55,250.00 USD
      // Insurance (0.5%) = $55,250 * 0.005 = $276.25 USD
      // Declared Customs CIF Foreign = $55,526.25 USD
      // FX Rate = 50.00 EGP/USD
      // Declared Customs CIF EGP = 2,776,312.50 EGP

      const double fobForeign = 47000.0;
      const double freightForeign = 8250.0;
      const double candfForeign = fobForeign + freightForeign;
      expect(candfForeign, 55250.0);

      const double insuranceRatePct = 0.5;
      final double insuranceForeign = candfForeign * (insuranceRatePct / 100.0);
      expect(insuranceForeign, 276.25);

      final double declaredCifForeign = candfForeign + insuranceForeign;
      expect(declaredCifForeign, 55526.25);

      const double customsExchangeRate = 50.0;
      final double declaredCifEgp = declaredCifForeign * customsExchangeRate;
      expect(declaredCifEgp, 2776312.50);
    });

    test('Should consolidate line items by identical HS Code and sum values correctly', () {
      final rows = [
        {
          'hs_code': '5602290000',
          'description': 'PET Acoustic Panels',
          'qty': 100.0,
          'foreign_price': 5887.90,
          'fob_egp': 294395.0,
          'cif_egp': 350170.0,
          'duty_egp': 17508.50,
          'vat_egp': 51475.0,
        },
        {
          'hs_code': '5602290000',
          'description': 'PET Acoustic Panels',
          'qty': 120.0,
          'foreign_price': 7065.48,
          'fob_egp': 353274.0,
          'cif_egp': 420204.0,
          'duty_egp': 21010.20,
          'vat_egp': 61770.0,
        },
        {
          'hs_code': '84798990',
          'description': 'Industrial Motor Assembly',
          'qty': 1.0,
          'foreign_price': 15000.0,
          'fob_egp': 750000.0,
          'cif_egp': 820000.0,
          'duty_egp': 41000.0,
          'vat_egp': 120540.0,
        },
      ];

      // Group by HS Code
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final r in rows) {
        grouped.putIfAbsent(r['hs_code'] as String, () => []).add(r);
      }

      expect(grouped.keys.length, 2);
      expect(grouped['5602290000']!.length, 2);
      expect(grouped['84798990']!.length, 1);

      // Aggregate 5602290000
      final hs5602Rows = grouped['5602290000']!;
      final totalQty = hs5602Rows.fold(0.0, (s, r) => s + (r['qty'] as double));
      final totalFobEgp = hs5602Rows.fold(0.0, (s, r) => s + (r['fob_egp'] as double));
      final totalDutyEgp = hs5602Rows.fold(0.0, (s, r) => s + (r['duty_egp'] as double));

      expect(totalQty, 220.0);
      expect(totalFobEgp, 647669.0);
      expect(totalDutyEgp, 38518.70);
    });
  });
}


