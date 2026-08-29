import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/widgets/searchable_dropdown_field.dart';
import 'package:frontend/features/import_companies/models/import_company_model.dart';
import 'package:frontend/features/import_companies/providers/import_companies_provider.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/widgets/import_file_form_dialog.dart';
import 'package:frontend/features/suppliers/models/supplier_model.dart';
import 'package:frontend/features/suppliers/providers/suppliers_provider.dart';
import 'package:frontend/features/projects/providers/projects_provider.dart';
import 'package:frontend/features/external_service_providers/providers/partners_provider.dart';
import 'package:frontend/features/incoterms/providers/incoterms_provider.dart';
import 'package:frontend/features/currencies/providers/currencies_provider.dart';

class MockImportCompaniesNotifier extends ImportCompaniesNotifier {
  MockImportCompaniesNotifier(List<ImportCompanyModel> list)
      : super(showInactive: true, dio: Dio()) {
    state = AsyncValue.data(list);
  }
  @override
  Future<void> fetchCompanies() async {}
}

class MockSuppliersNotifier extends SuppliersNotifier {
  MockSuppliersNotifier(List<SupplierModel> list)
      : super(showInactive: true, dio: Dio()) {
    state = AsyncValue.data(list);
  }
  @override
  Future<void> fetchSuppliers() async {}
}

class MockProjectsNotifier extends ProjectsNotifier {
  MockProjectsNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchProjects({bool includeInactive = true, String? status, String? search}) async {}
}

class MockCurrenciesNotifier extends CurrenciesNotifier {
  MockCurrenciesNotifier() : super(Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchCurrencies({bool includeInactive = true, String? search}) async {}
}

class MockPartnersNotifier extends PartnersNotifier {
  MockPartnersNotifier() : super(category: 'ALL', showInactive: true, dio: Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchPartners() async {}
}

class MockIncotermsNotifier extends IncotermsNotifier {
  MockIncotermsNotifier(Ref ref) : super(ref: ref, showInactive: true, dio: Dio()) {
    state = const AsyncValue.data([]);
  }
  @override
  Future<void> fetchIncoterms() async {}
}

void main() {
  final sampleCompanies = [
    ImportCompanyModel(
      companyId: 1,
      importerName: 'SCAS For Construction And Finishing',
      address: 'Cairo, Egypt',
      country: 'Egypt',
      importerId: 'IMP-1122',
      importerIdExpiry: DateTime.now().add(const Duration(days: 365)),
      vatId: '123456789',
      vatIdExpiry: DateTime.now().add(const Duration(days: 365)),
      registrationNumber: '98765',
      registrationExpiry: DateTime.now().add(const Duration(days: 365)),
    ),
    ImportCompanyModel(
      companyId: 2,
      importerName: 'ECO ASSOCIATES for Trading',
      address: 'Alexandria, Egypt',
      country: 'Egypt',
      importerId: 'IMP-3344',
      importerIdExpiry: DateTime.now().add(const Duration(days: 365)),
      vatId: '987654321',
      vatIdExpiry: DateTime.now().add(const Duration(days: 365)),
      registrationNumber: '54321',
      registrationExpiry: DateTime.now().add(const Duration(days: 365)),
    ),
  ];

  final sampleSuppliers = [
    SupplierModel(
      supplierId: 10,
      supplierCode: 'SUP-001',
      companyName: 'G.I. Industrial Holding S.p.A.',
      supplierType: 'Manufacturer',
      registrationType: 'Company',
      foreignExporterId: 'EXP-101',
      foreignExporterCountry: 'Italy',
      foreignExporterCountryCode: 'IT',
      address: 'Via Roma 1, Milan',
    ),
  ];

  final existingFile = ImportFileModel(
    importFileId: 1,
    importFileCode: 'IMP-2026-0001',
    customFileNumber: '6701068100',
    companyId: 1,
    companyName: 'SCAS For Construction And Finishing',
    supplierId: 10,
    supplierName: 'G.I. Industrial Holding S.p.A.',
    poNumber: 'PO-1001',
    piNumber: 'PI-889',
    estimatedCost: 43704.0,
    estimatedCostCurrency: 'USD',
    owner: 'SCAS For Construction And Finishing',
    currentModule: 'Phase 1',
    currentStage: 'Phase 1',
    nextAction: 'Review',
    createdAt: '2026-08-22',
    updatedAt: '2026-08-22',
  );

  testWidgets('ImportFileFormDialog renders owner as SearchableDropdownField from importing companies', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importCompaniesProvider.overrideWith((ref) => MockImportCompaniesNotifier(sampleCompanies)),
          suppliersProvider.overrideWith((ref) => MockSuppliersNotifier(sampleSuppliers)),
          projectsProvider.overrideWith((ref) => MockProjectsNotifier()),
          partnersProvider.overrideWith((ref) => MockPartnersNotifier()),
          incotermsProvider.overrideWith((ref) => MockIncotermsNotifier(ref)),
          currenciesProvider.overrideWith((ref) => MockCurrenciesNotifier()),
        ],
        child: MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: ImportFileFormDialog(fileToEdit: existingFile),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text('تعديل وتحديث بيانات ملف الاستيراد: IMP-2026-0001'), findsOneWidget);

    // Verify owner dropdown exists and displays the company name
    expect(find.byType(SearchableDropdownField<String?>), findsWidgets);
    expect(find.text('SCAS For Construction And Finishing'), findsWidgets);
  });
}
