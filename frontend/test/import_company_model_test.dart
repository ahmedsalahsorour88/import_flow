import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_companies/models/import_company_model.dart';

void main() {
  group('ImportCompanyModel Unit Tests', () {
    test('fromJson should parse dates and properties correctly', () {
      final json = {
        'company_id': 1,
        'importer_name': 'Test Egyptian Importer',
        'address': 'Cairo, Egypt',
        'country': 'Egypt',
        'importer_id': 'IMP-778899',
        'importer_id_expiry': '2030-01-01',
        'vat_id': 'VAT-112233',
        'vat_id_expiry': '2030-01-01',
        'registration_number': 'REG-445566',
        'registration_expiry': '2030-01-01',
        'phone': '01000000000',
        'email': 'info@importer.eg',
        'is_active': true,
        'notes': 'Unit test model',
      };

      final model = ImportCompanyModel.fromJson(json);

      expect(model.companyId, 1);
      expect(model.importerName, 'Test Egyptian Importer');
      expect(model.importerId, 'IMP-778899');
      expect(model.isActive, true);
      expect(model.daysUntilImporterIdExpiry, greaterThan(0));
    });

    test('toJson should serialize properties accurately', () {
      final model = ImportCompanyModel(
        companyId: 5,
        importerName: 'Nile Imports',
        address: 'Alexandria',
        country: 'Egypt',
        importerId: 'IMP-555',
        importerIdExpiry: DateTime(2028, 5, 10),
        vatId: 'VAT-555',
        vatIdExpiry: DateTime(2028, 5, 10),
        registrationNumber: 'REG-555',
        registrationExpiry: DateTime(2028, 5, 10),
      );

      final json = model.toJson();

      expect(json['company_id'], 5);
      expect(json['importer_name'], 'Nile Imports');
      expect(json['importer_id_expiry'], '2028-05-10');
    });
  });
}
