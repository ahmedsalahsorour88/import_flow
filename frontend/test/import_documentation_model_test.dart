import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';

void main() {
  group('AcidRegistrationModel Tests', () {
    test('AcidRegistrationModel.fromJson parses complete ACID data', () {
      final json = {
        'acid_id': 101,
        'acid_code': 'ACID-2026-001',
        'acid_number': '7595528271015010011',
        'import_file_id': 5,
        'import_file_code': 'IMP-2026-005',
        'po_id': 12,
        'po_number': 'PO-8899',
        'po_date': '2026-05-20',
        'importer_id': 2,
        'importer_name': 'Arki Brands for Carpet and Flooring Trading',
        'importer_tax_id': '759552827',
        'importer_address': 'القاهره المعادى 44 ش 18 المعادى',
        'supplier_id': 8,
        'exporter_name': 'Impact Acoustic Spa',
        'exporter_reg_type': 'VAT Number',
        'exporter_reg_id': 'IT04462890981',
        'exporter_country': 'ITALY',
        'exporter_country_code': 'IT',
        'exporter_address': 'Via Caldera 21 20153',
        'exporter_phone': '0',
        'cargox_id': '67a645ce-62e8-4850-a09e-a20b8ea1d917',
        'proforma_invoice_no': 'IT-DN26-0031496',
        'proforma_invoice_date': '2026-05-27',
        'invoice_date': '2026-05-31',
        'invoice_type': 'Proforma Invoice',
        'invoice_attachment_name': 'Invoice_DN26.pdf',
        'pol_name': 'Genoa',
        'pod_name': 'Alexandria',
        'customs_broker_id': 3,
        'customs_broker_name': 'Al-Ahram Customs Brokerage',
        'customs_broker_phone': '+201001234567',
        'requested_date': '2026-05-31',
        'generated_date': '2026-05-31',
        'expiry_date': '2026-11-30',
        'discrepancy_override_reason': 'Ports confirmed by customs',
        'status': 'Verified',
        'days_to_expiry': 105,
        'is_verified': true,
        'is_active': true,
        'created_at': '2026-05-31T10:41:01Z',
        'updated_at': '2026-05-31T10:41:01Z',
      };

      final model = AcidRegistrationModel.fromJson(json);

      expect(model.acidId, 101);
      expect(model.acidNumber, '7595528271015010011');
      expect(model.importerName, 'Arki Brands for Carpet and Flooring Trading');
      expect(model.exporterName, 'Impact Acoustic Spa');
      expect(model.exporterRegId, 'IT04462890981');
      expect(model.exporterCountryCode, 'IT');
      expect(model.proformaInvoiceNo, 'IT-DN26-0031496');
      expect(model.polName, 'Genoa');
      expect(model.podName, 'Alexandria');
      expect(model.cargoxId, '67a645ce-62e8-4850-a09e-a20b8ea1d917');
      expect(model.status, 'Verified');
    });

    test('AcidComparisonResult.fromJson parses comparison matrix correctly', () {
      final json = {
        'all_matched': false,
        'has_critical_error': true,
        'match_percentage': 88.5,
        'total_compared_fields': 10,
        'matched_count': 9,
        'discrepant_count': 1,
        'items': [
          {
            'field': 'pol_name',
            'label_ar': 'ميناء الشحن',
            'label_en': 'Shipping Port',
            'requested_value': 'Shanghai Port',
            'generated_value': 'Genoa Port',
            'is_matched': false,
            'severity': 'warning',
          },
          {
            'field': 'importer_tax_id',
            'label_ar': 'الرقم الضريبي للمستورد',
            'label_en': 'Importer Tax ID',
            'requested_value': '759552827',
            'generated_value': '759552827',
            'is_matched': true,
            'severity': 'error',
          }
        ],
      };

      final comp = AcidComparisonResult.fromJson(json);
      expect(comp.allMatched, false);
      expect(comp.matchedCount, 9);
      expect(comp.discrepantCount, 1);
      expect(comp.items.length, 2);
      expect(comp.items[0].field, 'pol_name');
      expect(comp.items[0].isMatched, false);
      expect(comp.items[1].isMatched, true);
    });
  });
}
