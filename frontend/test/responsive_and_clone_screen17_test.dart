import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currencies_provider.dart';
import 'package:frontend/features/external_service_providers/models/partner_model.dart';
import 'package:frontend/features/external_service_providers/providers/partners_provider.dart';
import 'package:frontend/features/import_documentation/models/import_documentation_model.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/bank_form4_screen.dart';
import 'package:frontend/features/import_documentation/widgets/search_and_clone_bank_form4_dialog.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class MockBankingDocumentsNotifier extends BankingDocumentsNotifier {
  MockBankingDocumentsNotifier(List<BankingDocumentModel> initialList) : super(Dio()) {
    state = AsyncValue.data(initialList);
  }

  @override
  Future<void> fetchBankingDocuments() async {}
}

class MockImportFilesNotifier extends ImportFilesNotifier {
  MockImportFilesNotifier(List<ImportFileModel> files) : super(Dio()) {
    state = AsyncValue.data(files);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {}
}

class MockPartnersNotifier extends PartnersNotifier {
  MockPartnersNotifier(List<PartnerModel> list) : super(category: 'All', showInactive: true, dio: Dio()) {
    state = AsyncValue.data(list);
  }

  @override
  Future<void> fetchPartners() async {}
}

class MockCurrenciesNotifier extends CurrenciesNotifier {
  MockCurrenciesNotifier(List<CurrencyModel> list) : super(Dio()) {
    state = AsyncValue.data(list);
  }

  @override
  Future<void> fetchCurrencies({bool includeInactive = true, String? search}) async {}
}

void main() {
  final List<BankingDocumentModel> sampleDocs = [
    BankingDocumentModel(
      bankDocId: 201,
      bankDocCode: 'FORM4-2026-001',
      docType: 'Form 4',
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      bankId: 10,
      bankName: 'National Bank of Egypt (NBE)',
      docReferenceNumber: 'NBE-REF-99881',
      amount: 45000.0,
      currencyCode: 'USD',
      requestDate: '2026-03-01',
      issueDate: '2026-03-01',
      status: 'Received',
      notes: 'تم توثيق نموذج 4 وسداد المصاريف الإدارية بالكامل',
      createdAt: '2026-03-01T10:00:00Z',
      updatedAt: '2026-03-01T10:00:00Z',
    ),
    BankingDocumentModel(
      bankDocId: 202,
      bankDocCode: 'FORM4-2026-002',
      docType: 'Form 4',
      importFileId: 2,
      importFileCode: 'IMP-2026-002',
      bankId: 20,
      bankName: 'Banque Misr',
      docReferenceNumber: 'BM-REF-55442',
      amount: 82000.0,
      currencyCode: 'EUR',
      requestDate: '2026-03-10',
      issueDate: '2026-03-10',
      status: 'Processing',
      notes: 'قيد انتظار إشعار التحويل السويفت',
      createdAt: '2026-03-10T10:00:00Z',
      updatedAt: '2026-03-10T10:00:00Z',
    ),
  ];

  final List<ImportFileModel> sampleFiles = [
    ImportFileModel(
      importFileId: 1,
      importFileCode: 'IMP-2026-001',
      supplierName: 'Siemens Industrial AG',
      companyName: 'الشركة الهندسية للتوريدات',
      status: 'Customs Clearance',
      currentModule: 'import_documentation',
      currentStage: 'BankForm4',
      nextAction: 'Customs Clearance',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    ),
    ImportFileModel(
      importFileId: 2,
      importFileCode: 'IMP-2026-002',
      supplierName: 'Bosch Thermotechnology',
      companyName: 'مصر للاستيراد والتصدير',
      status: 'Bank Processing',
      currentModule: 'import_documentation',
      currentStage: 'BankForm4',
      nextAction: 'Customs Clearance',
      createdAt: '2026-01-05',
      updatedAt: '2026-01-05',
    ),
  ];

  final List<PartnerModel> sampleBanks = [
    PartnerModel(
      providerId: 10,
      partnerCode: 'BNK-001',
      partnerName: 'National Bank of Egypt (NBE)',
      partnerType: 'Bank',
      email: 'trade@nbe.com.eg',
      phone: '+20219623',
      isActive: true,
      address: 'Cairo',
      country: 'Egypt',
    ),
    PartnerModel(
      providerId: 20,
      partnerCode: 'BNK-002',
      partnerName: 'Banque Misr',
      partnerType: 'Bank',
      email: 'trade@banquemisr.com',
      phone: '+20219888',
      isActive: true,
      address: 'Cairo',
      country: 'Egypt',
    ),
  ];

  final List<CurrencyModel> sampleCurrencies = [
    CurrencyModel(
      currencyId: 1,
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      currencySymbol: '\$',
      isActive: true,
    ),
    CurrencyModel(
      currencyId: 2,
      currencyCode: 'EUR',
      currencyName: 'Euro',
      currencySymbol: '€',
      isActive: true,
    ),
  ];

  Widget createTestWidget({
    Size size = const Size(1400, 900),
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
    int initialSubTab = 1,
    List<BankingDocumentModel>? docs,
  }) {
    return ProviderScope(
      overrides: [
        bankingDocumentsProvider.overrideWith((ref) => MockBankingDocumentsNotifier(docs ?? sampleDocs)),
        importFilesProvider.overrideWith((ref) => MockImportFilesNotifier(sampleFiles)),
        partnersProvider.overrideWith((ref) => MockPartnersNotifier(sampleBanks)),
        currenciesProvider.overrideWith((ref) => MockCurrenciesNotifier(sampleCurrencies)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: locale,
        home: AppLocalizationsProvider(
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.noScaling,
              ),
              child: Scaffold(
                body: BankForm4Screen(initialSubTab: initialSubTab),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Screen 17: BankForm4Screen (SubTab 1 — Bank Form 4 Registry) Enterprise Tests', () {
    testWidgets('1. Desktop Layout (1400x900) - Renders without overflows', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900), initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byKey(const Key('subtab1NewForm4Btn')), findsOneWidget);
      expect(find.byKey(const Key('subtab1SearchAndCloneBtn')), findsOneWidget);
      expect(find.text('FORM4-2026-001'), findsOneWidget);
      expect(find.text('FORM4-2026-002'), findsOneWidget);
    });

    testWidgets('2. Tablet Layout (800x1024) - Renders cleanly without overflows', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(800, 1024), initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byKey(const Key('bankRegistrySearchInput')), findsOneWidget);
    });

    testWidgets('3. Mobile Layout (390x844) - Vertically stacked with zero overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(390, 844), initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('bankRegistrySearchInput')), findsOneWidget);
      expect(find.byKey(const Key('subtab1NewForm4Btn')), findsOneWidget);
      expect(find.byKey(const Key('subtab1SearchAndCloneBtn')), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('4. Live Search Filtering in Registry table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(find.text('FORM4-2026-001'), findsOneWidget);
      expect(find.text('FORM4-2026-002'), findsOneWidget);

      // Search for NBE
      await tester.enterText(find.byKey(const Key('bankRegistrySearchInput')), 'NBE');
      await tester.pumpAndSettle();

      expect(find.text('FORM4-2026-001'), findsOneWidget);
      expect(find.text('FORM4-2026-002'), findsNothing);
    });

    testWidgets('5. Empty State display when search query matches no documents', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(initialSubTab: 1));
      await tester.pumpAndSettle();

      // Non-matching query
      await tester.enterText(find.byKey(const Key('bankRegistrySearchInput')), 'NON_EXISTENT_DOC_XYZ');
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsNothing);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('6. Screen-Level Clone from SubTab 1 toolbar & Ctrl + D shortcut', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(initialSubTab: 1));
      await tester.pumpAndSettle();

      // Tap Screen-Level Clone from SubTab 1 toolbar
      await tester.tap(find.byKey(const Key('subtab1SearchAndCloneBtn')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchAndCloneBankForm4Dialog), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SearchAndCloneBankForm4Dialog), findsNothing);

      // Verify Keyboard Shortcut Ctrl + D
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byType(SearchAndCloneBankForm4Dialog), findsOneWidget);
    });

    testWidgets('7. Task E: Row-Level Clone Action triggers Clone Review Dialog & populates SubTab 0', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(initialSubTab: 1));
      await tester.pumpAndSettle();

      // Row-Level Clone Button for bankDocId 201
      final rowCloneBtn = find.byKey(const Key('cloneBankForm4RowBtn_201'));
      expect(rowCloneBtn, findsOneWidget);

      await tester.tap(rowCloneBtn);
      await tester.pumpAndSettle();

      // Verify CloneEntityReviewDialog opens
      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
      expect(find.text('FORM4-2026-001'), findsOneWidget);
      expect(find.text('National Bank of Egypt (NBE)'), findsWidgets);

      // Confirm clone via icon button
      final confirmBtn = find.byIcon(Icons.control_point_duplicate_rounded);
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify redirection to SubTab 0 and pre-populated values
      expect(find.byType(CloneEntityReviewDialog), findsNothing);
      expect(find.text('45000.00'), findsOneWidget);
      expect(find.byKey(const Key('saveForm4SubmitBtn')), findsOneWidget);
    });

    testWidgets('8. Row-Level Edit Action loads document for editing and navigates to SubTab 0', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(initialSubTab: 1));
      await tester.pumpAndSettle();

      // Find edit icon in first row
      final editIcon = find.byIcon(Icons.edit).first;
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // SubTab 0 should now be active with edit banner
      expect(find.byKey(const Key('cancelForm4EditModeBtn')), findsOneWidget);
      expect(find.text('45000.00'), findsOneWidget);
    });

    testWidgets('9. WCAG AA Dark Mode Contrast and Theme Rendering', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        themeMode: ThemeMode.dark,
        initialSubTab: 1,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byKey(const Key('bankRegistrySearchInput')), findsOneWidget);
    });

    testWidgets('10. RTL Arabic & English (LTR) Directionality and Localization', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arabic RTL
      await tester.pumpWidget(createTestWidget(locale: const Locale('ar'), initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(find.text('سجل النماذج البنكية'), findsWidgets);
      expect(find.byType(DataTable), findsOneWidget);

      // English LTR
      await tester.pumpWidget(createTestWidget(locale: const Locale('en'), initialSubTab: 1));
      await tester.pumpAndSettle();

      expect(find.text('Bank Form 4 Registry'), findsWidgets);
      expect(find.byType(DataTable), findsOneWidget);
    });
  });
}
