import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/features/import_documentation/providers/import_documentation_provider.dart';
import 'package:frontend/features/import_documentation/screens/central_docs_archive_screen.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/import_files/providers/import_files_provider.dart';

class _MockImportFilesNotifier extends ImportFilesNotifier {
  final List<ImportFileModel> initialFiles;
  _MockImportFilesNotifier(this.initialFiles) : super(Dio()) {
    state = AsyncValue.data(initialFiles);
  }

  @override
  Future<void> fetchImportFiles({
    bool includeInactive = false,
    String? search,
    int? companyId,
    int? supplierId,
    String? status,
    String? owner,
  }) async {
    state = AsyncValue.data(initialFiles);
  }
}

void main() {
  testWidgets('CentralDocsArchiveScreen renders empty placeholder when no file selected',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([])),
        ],
        child: const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: CentralDocsArchiveScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('الأرشيف المركزي لمستندات'), findsOneWidget);
    expect(find.textContaining('يرجى اختيار ملف شحنة'), findsOneWidget);
  });

  testWidgets('CentralDocsArchiveScreen renders full archive with mock data',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockImportFile = ImportFileModel(
      importFileId: 42,
      importFileCode: 'IMP-2026-0042',
      customFileNumber: 'CUST-8812',
      companyId: 1,
      companyName: 'Archi brands for corpet and floor trading',
      supplierId: 1,
      supplierName: 'UAB Narbutas International',
      acidNumber: '7595528271020210010',
      portOfLoading: 'Klaipeda',
      portOfDischarge: 'Alexandria',
      estimatedCostCurrency: 'EUR',
      estimatedCost: 15375.50,
      currentModule: 'Import Documentation',
      currentStage: 'Draft Documents Review',
      nextAction: 'Review Drafts',
      status: 'In Progress',
      createdAt: '2026-08-20T10:00:00',
      updatedAt: '2026-08-20T12:00:00',
    );

    final mockArchiveData = <String, dynamic>{
      'import_file_id': 42,
      'import_file_code': 'IMP-2026-0042',
      'custom_file_number': 'CUST-8812',
      'importer_name': 'Archi brands for corpet and floor trading',
      'supplier_name': 'UAB Narbutas International',
      'acid_number': '7595528271020210010',
      'port_of_loading': 'Klaipeda',
      'port_of_discharge': 'Alexandria',
      'total_packages': 141,
      'total_gross_weight_kg': 1774.514,
      'currency': 'EUR',
      'fob_or_cif_amount': 15375.50,
      'readiness_status': 'READY_FOR_RELEASE',
      'readiness_score': 100.0,
      'tariff_exemption_alert': '⚠️ فرصة إعفاء جمركي: الشحنة مؤهلة لإعفاء كامل (0% ضريبة وارد) بموجب الشراكة المصرية الأوروبية بشرط تقديم شهادة EUR.1 مدوناً بها عبارة REVISED RULES.',
      'import_requirements_summary': {
        'has_assessment': true,
        'assessment_code': 'BP011-2026-0042',
        'hs_code': '9403.10',
        'commodity_description': 'Metal office furniture',
        'country_of_origin': 'Lithuania',
        'coo_required': true,
        'coo_type': 'EUR.1',
        'coo_status': 'Required',
        'inspection_required': false,
        'inspection_status': 'Waived',
        'decree_43_applicable': true,
        'white_list_verified': true,
        'factory_registration_no': 'FAC-REG-8812',
      },
      'final_invoice': {
        'document_type': 'FINAL_COMMERCIAL_INVOICE',
        'title_ar': 'الفاتورة التجارية النهائية المعتمدة',
        'is_available': true,
        'is_mandatory': true,
        'is_waived': false,
        'status': 'APPROVED',
        'document_reference': 'IN053328',
        'details': {'total_amount': 15375.50, 'currency': 'EUR'},
        'discrepancies': [],
      },
      'final_packing_list': {
        'document_type': 'FINAL_PACKING_LIST',
        'title_ar': 'قائمة التعبئة النهائية المعتمدة',
        'is_available': true,
        'is_mandatory': true,
        'is_waived': false,
        'status': 'APPROVED',
        'document_reference': 'PL-IN053328',
        'details': {'total_packages': 141, 'total_gross_weight_kg': 1774.514},
        'discrepancies': [],
      },
      'draft_bl': {
        'document_type': 'DRAFT_BL',
        'title_ar': 'مسودة بوليصة الشحن البحرية (Draft Bill of Lading)',
        'is_available': true,
        'is_mandatory': true,
        'is_waived': false,
        'status': 'APPROVED',
        'document_reference': 'MEDURE910647',
        'details': {'shipping_line': 'MSC', 'vessel_name': 'MSC LEANNE'},
        'discrepancies': [],
      },
      'certificate_of_origin': {
        'document_type': 'CERTIFICATE_OF_ORIGIN',
        'title_ar': 'درافت شهادة المنشأ / يورو 1 (Draft Certificate of Origin / EUR.1)',
        'is_available': true,
        'is_mandatory': true,
        'is_waived': false,
        'status': 'APPROVED',
        'document_reference': 'A-084188',
        'details': {'country_of_origin': 'Lithuania', 'certificate_type': 'EUR.1'},
        'discrepancies': [],
      },
      'inspection_certificate': {
        'document_type': 'INSPECTION_CERTIFICATE',
        'title_ar': 'درافت شهادة الفحص والمطابقة النوعية (Draft Inspection / VoC / COC)',
        'is_available': false,
        'is_mandatory': false,
        'is_waived': true,
        'waive_reason': 'الصنف غير خاضع لرقابة الصادرات والواردات (GOEIC) ولا يتطلب فحص ما قبل الشحن',
        'status': 'WAIVED',
        'document_reference': 'غير مطلوب',
        'details': {'inspection_agency': 'COTECNA'},
        'discrepancies': [],
      },
      'total_critical_discrepancies': 0,
      'total_warning_discrepancies': 0,
      'all_rectifications_checklist': [],
      'supplier_email_rectification_text': 'Subject: URGENT Notice\nDear Supplier...',
      'supplier_whatsapp_rectification_text': '*إشعار تعديلات المستندات*',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importFilesProvider.overrideWith((ref) => _MockImportFilesNotifier([mockImportFile])),
          centralArchiveProvider(42).overrideWith((ref) => Future.value(mockArchiveData)),
        ],
        child: const MaterialApp(
          home: AppLocalizationsProvider(
            locale: Locale('ar'),
            child: CentralDocsArchiveScreen(initialImportFileId: 42),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Header information
    expect(find.textContaining('كود الملف: IMP-2026-0042'), findsOneWidget);
    expect(find.textContaining('CUST-8812'), findsOneWidget);
    expect(find.textContaining('7595528271020210010'), findsOneWidget);

    // Verify BP-011 compliance card
    expect(find.textContaining('تقرير مطابقة متطلبات الاستيراد'), findsOneWidget);
    expect(find.textContaining('REVISED RULES'), findsOneWidget);

    // Verify Badges and Action buttons
    expect(find.textContaining('إلزام'), findsWidgets);
    expect(find.textContaining('نسخ إيميل التعديلات'), findsOneWidget);
    expect(find.textContaining('نسخ رسالة واتساب'), findsOneWidget);
  });
}
