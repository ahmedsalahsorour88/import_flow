import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_requirements/models/import_requirement_model.dart';

void main() {
  group('ImportRequirementModel 5-Pillar Unit Tests (BP-011)', () {
    test('fromJson and toJson should parse and serialize all 5 pillars accurately', () {
      final json = {
        'assessment_id': 101,
        'assessment_code': 'BP011-2026-0001',
        'import_file_id': 5,
        'import_file_code': 'IMP-2026-0005',
        'hs_code': '8415820010',
        'commodity_description': 'آلات وأجهزة تكييف أخر متضمنة وحدة تبريد',
        'country_of_origin': 'China',
        'shipment_value_usd': 45000.0,
        // Pillar 1
        'supplier_id': 3,
        'supplier_name': 'Gree Electric Appliances Inc.',
        'decree_43_applicable': true,
        'white_list_required': true,
        'white_list_verified': true,
        'factory_registration_no': 'GOEIC-REG-987654',
        // Pillar 2
        'coo_required': true,
        'coo_type': 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)',
        'coo_status': 'تم الاستلام والتحقق',
        'coo_notes': 'اتفاقية الشراكة إعفاء كامل',
        // Pillar 3
        'inspection_required': true,
        'inspection_body': 'SGS',
        'inspection_status': 'تم الفحص واجتياز المطابقة',
        'inspection_report_no': 'SGS-CN-2026-8899',
        'inspection_notes': 'مطابق للمواصفة القياسية المصرية ES 3795',
        // Pillar 4
        'import_permit_required': true,
        'permit_issuing_authority': 'جهاز شئون البيئة (EEAA)',
        'permit_number': 'EEAA-PERMIT-4421',
        'permit_status': 'تمت الموافقة والاعتماد',
        'permit_notes': 'موافقة بيئية لغاز R410A صديق للبيئة',
        // Pillar 5
        'msds_required': true,
        'msds_status': 'Obtained',
        'msds_notes': 'MSDS for Refrigerant',
        'halal_cert_required': false,
        'halal_cert_status': 'Not Required',
        'halal_cert_notes': null,
        'coa_required': true,
        'coa_status': 'Obtained',
        'coa_notes': 'Lab test COA attached',
        // Summary
        'overall_status': 'معتمد ومصرح للشحن',
        'risk_level': 'منخفض (Low)',
        'assessed_by': 'Kamal',
        'assessment_notes': 'تم استيفاء كافة الاشتراطات التنظيمية والقانونية بالكامل',
        'is_active': true,
        'created_at': '2026-08-15T10:00:00.000Z',
        'updated_at': '2026-08-15T10:30:00.000Z',
      };

      final model = ImportRequirementModel.fromJson(json);

      // Verify Pillar 1
      expect(model.decree43Applicable, true);
      expect(model.whiteListVerified, true);
      expect(model.factoryRegistrationNo, 'GOEIC-REG-987654');
      expect(model.supplierName, 'Gree Electric Appliances Inc.');

      // Verify Pillar 2
      expect(model.cooRequired, true);
      expect(model.cooType, contains('EUR.1'));
      expect(model.cooStatus, 'تم الاستلام والتحقق');

      // Verify Pillar 3
      expect(model.inspectionRequired, true);
      expect(model.inspectionBody, 'SGS');
      expect(model.inspectionReportNo, 'SGS-CN-2026-8899');

      // Verify Pillar 4
      expect(model.importPermitRequired, true);
      expect(model.permitIssuingAuthority, contains('EEAA'));
      expect(model.permitNumber, 'EEAA-PERMIT-4421');

      // Verify Pillar 5
      expect(model.msdsRequired, true);
      expect(model.coaRequired, true);

      // Verify Summary
      expect(model.overallStatus, 'معتمد ومصرح للشحن');
      expect(model.riskLevel, 'منخفض (Low)');
      expect(model.currency, 'USD');
      expect(model.shipmentValue, 45000.0);

      final serialized = model.toJson();
      expect(serialized['assessment_code'], 'BP011-2026-0001');
      expect(serialized['currency'], 'USD');
      expect(serialized['shipment_value'], 45000.0);
      expect(serialized['factory_registration_no'], 'GOEIC-REG-987654');
      expect(serialized['inspection_report_no'], 'SGS-CN-2026-8899');
      expect(serialized['permit_number'], 'EEAA-PERMIT-4421');
    });
  });
}
