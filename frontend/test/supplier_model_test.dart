import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/suppliers/models/supplier_model.dart';

void main() {
  group('SupplierModel Unit Tests', () {
    test('fromJson should parse supplier fields accurately', () {
      final json = {
        'supplier_id': 1,
        'supplier_code': 'SUP-000001',
        'company_name': 'Zhejiang Heavy Tools Co',
        'supplier_type': 'Manufacturer',
        'registration_type': 'Factory',
        'foreign_exporter_id': 'EXP-CN-7744',
        'foreign_exporter_country': 'China',
        'foreign_exporter_country_code': 'CN',
        'address': 'Hangzhou, China',
        'phone': '+865718888',
        'email': 'sales@zhejiang.cn',
        'brands': 'Zhejiang Pro',
        'is_active': true,
      };

      final model = SupplierModel.fromJson(json);

      expect(model.supplierId, 1);
      expect(model.supplierCode, 'SUP-000001');
      expect(model.companyName, 'Zhejiang Heavy Tools Co');
      expect(model.foreignExporterId, 'EXP-CN-7744');
      expect(model.foreignExporterCountryCode, 'CN');
      expect(model.isActive, true);
    });

    test('toJson should serialize properties accurately', () {
      final model = SupplierModel(
        supplierId: 2,
        supplierCode: 'SUP-000002',
        companyName: 'Bavaria Motor Parts GMBH',
        supplierType: 'Trader',
        registrationType: 'Company',
        foreignExporterId: 'EXP-DE-9911',
        foreignExporterCountry: 'Germany',
        foreignExporterCountryCode: 'DE',
        address: 'Munich, Germany',
      );

      final json = model.toJson();

      expect(json['supplier_id'], 2);
      expect(json['supplier_code'], 'SUP-000002');
      expect(json['company_name'], 'Bavaria Motor Parts GMBH');
      expect(json['foreign_exporter_country_code'], 'DE');
    });
  });
}
