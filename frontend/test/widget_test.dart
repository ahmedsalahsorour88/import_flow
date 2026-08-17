import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/import_companies/models/import_company_model.dart';
import 'package:frontend/features/import_companies/providers/import_companies_provider.dart';
import 'package:frontend/features/import_companies/screens/import_companies_screen.dart';

void main() {
  testWidgets('ImportCompaniesScreen renders header and company list correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockCompanies = [
      ImportCompanyModel(
        companyId: 1,
        importerName: 'Pharaohs Importers',
        address: 'Cairo, Egypt',
        country: 'Egypt',
        importerId: 'IMP-100',
        importerIdExpiry: DateTime.now().add(const Duration(days: 90)),
        vatId: 'VAT-100',
        vatIdExpiry: DateTime.now().add(const Duration(days: 90)),
        registrationNumber: 'REG-100',
        registrationExpiry: DateTime.now().add(const Duration(days: 90)),
        isActive: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importCompaniesProvider.overrideWith((ref) {
            return MockImportCompaniesNotifier(mockCompanies);
          }),
        ],
        child: const MaterialApp(
          home: ImportCompaniesScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Egyptian Import Companies'), findsOneWidget);
    expect(find.text('Add Importer Company'), findsOneWidget);
    expect(find.text('Pharaohs Importers'), findsOneWidget);
  });
}

class MockImportCompaniesNotifier extends ImportCompaniesNotifier {
  MockImportCompaniesNotifier(List<ImportCompanyModel> initialData)
      : super(showInactive: true) {
    state = AsyncValue.data(initialData);
  }

  @override
  Future<void> fetchCompanies() async {
    // No-op for mock
  }
}
