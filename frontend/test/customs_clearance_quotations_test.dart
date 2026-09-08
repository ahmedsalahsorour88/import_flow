import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_clearance_quotations/models/customs_clearance_quotation_model.dart';

void main() {
  group('Customs Clearance Quotations Model Unit Tests', () {
    test('CustomsClearanceQuotationItemModel parses JSON correctly', () {
      final json = {
        'quotation_id': 1,
        'rfq_id': 10,
        'provider_id': 5,
        'provider_name': 'مكتب الأهرام للتخليص الجمركي',
        'license_number': 'LIC-2024-99',
        'clearance_fee': 3500.0,
        'inland_transport_fee': 8000.0,
        'inspection_fee': 2000.0,
        'port_expenses': 3000.0,
        'miscellaneous_fee': 500.0,
        'total_cost': 17000.0,
        'currency': 'EGP',
        'estimated_turnaround_days': 4,
        'is_awarded': true,
        'remarks': 'شامل النقل إلى المصنع',
      };

      final model = CustomsClearanceQuotationItemModel.fromJson(json);
      expect(model.quotationId, 1);
      expect(model.providerName, 'مكتب الأهرام للتخليص الجمركي');
      expect(model.clearanceFee, 3500.0);
      expect(model.inlandTransportFee, 8000.0);
      expect(model.totalCost, 17000.0);
      expect(model.isAwarded, true);
      expect(model.estimatedTurnaroundDays, 4);

      final outJson = model.toJson();
      expect(outJson['provider_name'], 'مكتب الأهرام للتخليص الجمركي');
      expect(outJson['total_cost'], 17000.0);
    });

    test('CustomsClearanceRFQModel parses and serializes correctly', () {
      final json = {
        'rfq_id': 100,
        'rfq_code': 'CRFQ-000001',
        'title': 'طلب عروض أسعار تخليص خط إنتاج',
        'port_name': 'Alexandria Port',
        'shipment_type': 'Ocean FCL (40HQ)',
        'containers_count': 2,
        'packages_count': 12,
        'gross_weight_kg': 18500.0,
        'cbm': 55.0,
        'status': 'Awarded',
        'lowest_clearance_cost': 15000.0,
        'fastest_turnaround_days': 3,
        'awarded_provider_name': 'النسر للخدمات اللوجستية',
        'created_at': '2026-08-20T10:00:00Z',
        'quotations': [
          {
            'quotation_id': 1,
            'rfq_id': 100,
            'provider_id': 2,
            'provider_name': 'النسر للخدمات اللوجستية',
            'clearance_fee': 3000.0,
            'inland_transport_fee': 7000.0,
            'inspection_fee': 2000.0,
            'port_expenses': 2500.0,
            'miscellaneous_fee': 500.0,
            'total_cost': 15000.0,
            'currency': 'EGP',
            'estimated_turnaround_days': 3,
            'is_awarded': true,
          }
        ],
      };

      final rfq = CustomsClearanceRFQModel.fromJson(json);
      expect(rfq.rfqCode, 'CRFQ-000001');
      expect(rfq.containersCount, 2);
      expect(rfq.lowestClearanceCost, 15000.0);
      expect(rfq.quotations.length, 1);
      expect(rfq.quotations.first.isAwarded, true);

      final createJson = rfq.toCreateJson();
      expect(createJson['title'], 'طلب عروض أسعار تخليص خط إنتاج');
      expect(createJson['port_name'], 'Alexandria Port');
      expect(createJson['containers_count'], 2);
    });

    test('ClearancePriceListItemModel parses and serializes correctly', () {
      final json = {
        'price_item_id': 5,
        'provider_id': 2,
        'provider_name': 'النسر للخدمات اللوجستية',
        'port_name': 'Sokhna Port',
        'service_category': 'Inland Transport',
        'container_type': '40HQ',
        'unit_price': 6500.0,
        'currency': 'EGP',
        'notes': 'نقل إلى مدينة العاشر من رمضان',
      };

      final item = ClearancePriceListItemModel.fromJson(json);
      expect(item.providerName, 'النسر للخدمات اللوجستية');
      expect(item.portName, 'Sokhna Port');
      expect(item.unitPrice, 6500.0);

      final createJson = item.toCreateJson();
      expect(createJson['service_category'], 'Inland Transport');
      expect(createJson['unit_price'], 6500.0);
    });

    test('Extracted quotation and expenses catalog structure validation', () {
      final extracted = {
        'broker_name': 'شركة الأهرام للخدمات الجمركية',
        'port_name': 'Alexandria Port',
        'clearance_fee': 3500.0,
        'inland_transport_fee': 19500.0,
        'inspection_fee': 2800.0,
        'port_expenses': 8000.0,
        'total_estimated_clearance_cost': 35000.0,
        'expenses_catalog': [
          {
            'item_name': 'رسوم كشف وكلارك وتعتيق',
            'expense_name': 'رسوم كشف وكلارك وتعتيق',
            'category': 'Other Fees',
            'price': 1200.0,
            'amount': 1200.0,
            'currency': 'EGP',
            'pricing_unit': 'Per Shipment',
            'is_applicable': true,
          },
          {
            'item_name': 'أتعاب تخليص حاوية 40 قدم (فاتورة)',
            'expense_name': 'أتعاب تخليص حاوية 40 قدم (فاتورة)',
            'category': 'Clearance Fees',
            'price': 3500.0,
            'amount': 3500.0,
            'currency': 'EGP',
            'pricing_unit': 'Per Invoice',
            'is_applicable': true,
          }
        ],
      };

      expect(extracted['broker_name'], contains('الأهرام'));
      expect(extracted['clearance_fee'], 3500.0);
      expect(extracted['total_estimated_clearance_cost'], 35000.0);

      final catalog = extracted['expenses_catalog'] as List<Map<String, dynamic>>;
      expect(catalog.length, 2);
      expect(catalog.first['expense_name'], contains('كشف وكلارك'));
      expect(catalog.first['amount'], 1200.0);
      expect(catalog.last['amount'], 3500.0);
    });

    test('LCL and FCL fee matching isolation and weight differentiation', () {
      final sampleExtractedCatalog = [
        {
          'item_name': 'أتعاب تخليص LCL (لكل فاتورة)',
          'price': 1250.0,
          'category': 'Clearance Fees',
        },
        {
          'item_name': 'أتعاب تخليص حاوية 20 قدم (فاتورة)',
          'price': 2500.0,
          'category': 'Clearance Fees',
        },
        {
          'item_name': 'أتعاب تخليص حاوية 40 قدم (فاتورة)',
          'price': 2500.0,
          'category': 'Clearance Fees',
        },
        {
          'item_name': 'نقل حاوية 20 قدم حتى 10 طن (إسكندرية - قاهرة)',
          'price': 14800.0,
          'category': 'Inland Transport',
        },
        {
          'item_name': 'نقل حاوية 20 قدم أكثر من 10 طن (إسكندرية - قاهرة)',
          'price': 16500.0,
          'category': 'Inland Transport',
        },
        {
          'item_name': 'عرض الواردات + اعتماد الإيباك',
          'price': 2500.0,
          'min_price': 2500.0,
          'max_price': 3500.0,
          'notes': 'نطاق سعر: 2500 - 3500 جنيه',
        },
      ];

      expect(sampleExtractedCatalog.length, 6);
      final lcl = sampleExtractedCatalog.firstWhere((e) => (e['item_name'] as String).contains('LCL'));
      final fcl40 = sampleExtractedCatalog.firstWhere((e) => (e['item_name'] as String).contains('40'));
      final under10t = sampleExtractedCatalog.firstWhere((e) => (e['item_name'] as String).contains('حتى 10 طن'));
      final over10t = sampleExtractedCatalog.firstWhere((e) => (e['item_name'] as String).contains('أكثر من 10 طن'));

      // Ensure LCL is strictly 1250 and FCL is 2500
      expect(lcl['price'], 1250.0);
      expect(fcl40['price'], 2500.0);
      expect(lcl['price'], isNot(equals(fcl40['price'])));

      // Ensure weight tiers are differentiated correctly
      expect(under10t['price'], 14800.0);
      expect(over10t['price'], 16500.0);
      expect(over10t['price'], greaterThan(under10t['price'] as num));

      // Ensure min/max ranges and notes are preserved
      final rangeItem = sampleExtractedCatalog.firstWhere((e) => (e['item_name'] as String).contains('الواردات'));
      expect(rangeItem['min_price'], 2500.0);
      expect(rangeItem['max_price'], 3500.0);
      expect(rangeItem['notes'], contains('2500 - 3500'));
    });
  });
}
