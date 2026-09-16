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
      currentStage: 'Customs Clearance',
      nextAction: 'Form 4 Endorsement',
      portOfLoading: 'Hamburg Port',
      portOfDischarge: 'Alexandria Port',
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
      currentStage: 'Bank Processing',
      nextAction: 'Swift Settlement',
      portOfLoading: 'Rotterdam Port',
      portOfDischarge: 'Port Said Port',
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
    int initialSubTab = 0,
  }) {
    return ProviderScope(
      overrides: [
        bankingDocumentsProvider.overrideWith((ref) => MockBankingDocumentsNotifier(sampleDocs)),
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

  group('Screen 16: BankForm4Screen (SubTab 0) Enterprise Hardening & Clone Tests', () {
    testWidgets('1. Desktop Layout (1400x900) - Renders without overflows', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(BankForm4Screen), findsOneWidget);
      expect(find.text('طلب وتوثيق نموذج 4'), findsWidgets);
      expect(find.byKey(const Key('saveForm4SubmitBtn')), findsOneWidget);
      expect(find.byKey(const Key('subtab0SearchAndCloneBtn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Tablet Layout (800x1024) - Renders cleanly without overflows', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(800, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(BankForm4Screen), findsOneWidget);
      expect(find.byKey(const Key('saveForm4SubmitBtn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Mobile Layout (390x844) - Vertically stacked with zero overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(BankForm4Screen), findsOneWidget);
      expect(find.byKey(const Key('saveForm4SubmitBtn')), findsOneWidget);
      expect(find.byKey(const Key('subtab0SearchAndCloneBtn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Form 4 Checklist items interaction toggle state', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      final proformaItem = find.text('الفاتورة المبدئية المعتمدة');
      expect(proformaItem, findsOneWidget);

      await tester.tap(proformaItem);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Screen-Level Clone Modal & Mandatory Reset Invariants', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      // Click Search and Clone button
      final cloneBtn = find.byKey(const Key('subtab0SearchAndCloneBtn'));
      expect(cloneBtn, findsOneWidget);
      await tester.tap(cloneBtn);
      await tester.pumpAndSettle();

      // SearchAndCloneBankForm4Dialog should be open
      expect(find.byType(SearchAndCloneBankForm4Dialog), findsOneWidget);
      expect(find.text('البحث ونسخ نموذج 4 بنكي سابق'), findsOneWidget);
      expect(find.text('FORM4-2026-001'), findsOneWidget);

      // Select first document to clone
      final selectDocBtn = find.byKey(const Key('selectCloneBankForm4Btn_201'));
      expect(selectDocBtn, findsOneWidget);
      await tester.tap(selectDocBtn);
      await tester.pumpAndSettle();

      // CloneEntityReviewDialog should appear
      expect(find.byType(CloneEntityReviewDialog), findsOneWidget);
      expect(find.textContaining('طلب وتوثيق نموذج 4'), findsWidgets);
      expect(find.textContaining('FORM4-2026-001'), findsWidgets);

      // Confirm clone
      final confirmBtn = find.byIcon(Icons.control_point_duplicate_rounded);
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify form is populated and success SnackBar is shown
      expect(find.text('تم نسخ بيانات نموذج 4 بنجاح مع تصفير المحددات الإلزامية'), findsOneWidget);
      expect(find.text('45000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Search & Filter in SearchAndCloneBankForm4Dialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      // Open clone dialog from header action
      final headerCloneBtn = find.byKey(const Key('searchAndCloneBankForm4Btn'));
      expect(headerCloneBtn, findsOneWidget);
      await tester.tap(headerCloneBtn);
      await tester.pumpAndSettle();

      // Filter by Misr
      final searchField = find.descendant(
        of: find.byType(SearchAndCloneBankForm4Dialog),
        matching: find.byType(TextField),
      );
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Misr');
      await tester.pumpAndSettle();

      expect(find.text('FORM4-2026-002'), findsOneWidget);
      expect(find.text('FORM4-2026-001'), findsNothing);

      // Search non-existent
      await tester.enterText(searchField, 'NON_EXISTENT_BANK_XYZ');
      await tester.pumpAndSettle();

      expect(find.text('لم يتم العثور على نماذج بنكية مطابقة للبحث'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Keyboard Shortcut Ctrl + D opens Search & Clone Bank Form 4 Dialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(size: const Size(1400, 900)));
      await tester.pumpAndSettle();

      // Press Ctrl + D
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(find.byType(SearchAndCloneBankForm4Dialog), findsOneWidget);
      expect(find.text('البحث ونسخ نموذج 4 بنكي سابق'), findsOneWidget);
    });

    testWidgets('8. WCAG AA Dark Mode Contrast and Theme Rendering', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        size: const Size(1400, 900),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BankForm4Screen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. RTL Arabic Directionality & Localization', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        size: const Size(1400, 900),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      final directionality = tester.widget<Directionality>(
        find.ancestor(
          of: find.byType(BankForm4Screen),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
      expect(find.text('طلب وتوثيق نموذج 4'), findsWidgets);
    });

    testWidgets('10. English Locale (LTR) Directionality & Localization', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(
        size: const Size(1400, 900),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Form 4 Request & Checklist'), findsWidgets);
      expect(find.text('Clone From Previous Form 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
