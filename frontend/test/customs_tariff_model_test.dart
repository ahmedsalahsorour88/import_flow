import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customs_tariff/models/customs_tariff_model.dart';
import 'package:frontend/features/customs_tariff/models/preferential_agreement_model.dart';

void main() {
  group('CustomsTariffModel & PreferentialAgreementModel Unit Tests (MD-008)', () {
    test('Should parse CustomsTariffModel from JSON correctly', () {
      final json = {
        'tariff_id': 101,
        'hs_code': '8415820010',
        'hs_description': 'آلات وأجهزة تكييف أخر متضمنة وحدة تبريد ، وحدات كاملة',
        'customs_category': 'أجهزة تكييف',
        'customs_duty_rate': 60.0,
        'vat_rate': 14.0,
        'schedule_tax_rate': 8.0,
        'development_fee_rate': 0.0,
        'import_fee_rate': 0.0,
        'requires_coo': true,
        'requires_inspection': true,
        'requires_acid': true,
        'regulatory_authority': 'الهيئة العامة للرقابة على الصادرات والواردات',
        'prior_approval_note': 'لا يصرح باستيراد صنف إلا بموافقة مختومة بخاتم شعار الجمهورية من هـ.ع.ص',
        'effective_from': '2026-01-01',
        'is_active': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final model = CustomsTariffModel.fromJson(json);

      expect(model.tariffId, 101);
      expect(model.hsCode, '8415820010');
      expect(model.customsDutyRate, 60.0);
      expect(model.vatRate, 14.0);
      expect(model.scheduleTaxRate, 8.0);
      expect(model.requiresCoo, isTrue);
      expect(model.requiresInspection, isTrue);
      expect(model.priorApprovalNote, contains('خاتم شعار الجمهورية'));
    });

    test('Should parse PreferentialAgreementModel from JSON correctly', () {
      final json = {
        'agreement_id': 6722,
        'hs_code': '8415820010',
        'agreement_name': 'اتفاقية صربيا',
        'reduction_type': 'percentage_of_duty',
        'reduction_percentage': 0.10,
        'origin_countries': 'RS',
        'conditions_note': 'تخفيض 10%',
        'effective_from': '2026-01-01',
      };

      final model = PreferentialAgreementModel.fromJson(json);

      expect(model.agreementId, 6722);
      expect(model.hsCode, '8415820010');
      expect(model.agreementName, 'اتفاقية صربيا');
      expect(model.reductionPercentage, 0.10);
      expect(model.originCountries, 'RS');
    });
  });
}
