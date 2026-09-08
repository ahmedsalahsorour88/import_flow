import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  group('ImportFileModel primaryNameWithCode Tests', () {
    test('returns customFileNumber (importFileCode) when customFileNumber is provided', () {
      final model = ImportFileModel(
        importFileId: 4,
        importFileCode: 'IMP-2026-0004',
        customFileNumber: 'PET Stock',
        companyId: 1,
        companyName: 'SCAS Construction',
        supplierId: 10,
        supplierName: 'Global Supplier Ltd',
        shipmentMode: 'Sea',
        incotermCode: 'CIF',
        estimatedCost: 50000,
        estimatedCostCurrency: 'USD',
        currentModule: 'Customs Clearance',
        currentStage: 'Under Review',
        progressPercent: 60.0,
        nextAction: 'Review documents',
        status: 'Active',
        owner: 'Admin',
        isActive: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );

      expect(model.displayName, 'PET Stock');
      expect(model.primaryNameWithCode, 'PET Stock (IMP-2026-0004)');
    });

    test('returns importFileCode only when customFileNumber is null', () {
      final model = ImportFileModel(
        importFileId: 1,
        importFileCode: 'IMP-2026-0001',
        customFileNumber: null,
        companyId: 1,
        companyName: 'ECO Associates',
        supplierId: 10,
        supplierName: 'Global Supplier Ltd',
        shipmentMode: 'Air',
        incotermCode: 'FOB',
        estimatedCost: 20000,
        estimatedCostCurrency: 'EUR',
        currentModule: 'Cargo Shipping',
        currentStage: 'Draft',
        progressPercent: 20.0,
        nextAction: 'Request quotes',
        status: 'Draft',
        owner: 'Admin',
        isActive: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );

      expect(model.displayName, 'IMP-2026-0001');
      expect(model.primaryNameWithCode, 'IMP-2026-0001');
    });

    test('returns importFileCode only when customFileNumber equals importFileCode', () {
      final model = ImportFileModel(
        importFileId: 2,
        importFileCode: 'IMP-2026-0002',
        customFileNumber: 'IMP-2026-0002',
        companyId: 1,
        companyName: 'ECO Associates',
        supplierId: 10,
        supplierName: 'Global Supplier Ltd',
        shipmentMode: 'Air',
        incotermCode: 'FOB',
        estimatedCost: 20000,
        estimatedCostCurrency: 'EUR',
        currentModule: 'Cargo Shipping',
        currentStage: 'Draft',
        progressPercent: 20.0,
        nextAction: 'Request quotes',
        status: 'Draft',
        owner: 'Admin',
        isActive: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );

      expect(model.displayName, 'IMP-2026-0002');
      expect(model.primaryNameWithCode, 'IMP-2026-0002');
    });
  });
}
