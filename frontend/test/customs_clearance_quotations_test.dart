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
  });
}
