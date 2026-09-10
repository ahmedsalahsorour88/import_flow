import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/core/widgets/clone_entity_review_dialog.dart';
import 'package:frontend/features/customs_consultation/models/customs_consultation_model.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UX-CLONE-011 Universal Clone Localization Tests', () {
    test('Arabic AppLocalizationsAr has pure Arabic with 0 Latin characters for all clone keys', () {
      const lAr = AppLocalizationsAr();
      final latinPattern = RegExp(r'[a-zA-Z]');

      // All keys must be purely Arabic
      expect(latinPattern.hasMatch(lAr.cloneRowTooltip), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneEntityDialogTitle('شحنة')), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneEntityDialogSubtitle), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneSourceReferenceLabel('')), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneNewCodeLabel), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneNewCodeRequiredError), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneCopiedFieldsHeader), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneResetFieldsHeader), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneFieldStatusDraftBadge), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneFieldCustomsClearedReset), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneFieldFinancialReset), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneCopyInvoicesCheckbox), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneCopyAttachmentsCheckbox), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneConfirmAndCreateBtn), isFalse);
      expect(latinPattern.hasMatch(lAr.clonedFromBadge('')), isFalse);
      expect(latinPattern.hasMatch(lAr.clonedSuccessfullyToast('')), isFalse);
      expect(latinPattern.hasMatch(lAr.clonePriceListDialogTitle), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneImportFileDialogTitle), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneConsultationDialogTitle), isFalse);
      expect(latinPattern.hasMatch(lAr.clonePriceListActionTooltip), isFalse);
      expect(latinPattern.hasMatch(lAr.cloneRowActionTooltip), isFalse);

      // No bilingual stacked slashes
      expect(lAr.cloneRowTooltip.contains('/'), isFalse);
      expect(lAr.cloneFieldStatusDraftBadge.contains('/'), isFalse);
      expect(lAr.cloneCopyAttachmentsCheckbox.contains('/'), isFalse);
    });

    test('English AppLocalizationsEn returns expected English strings', () {
      const lEn = AppLocalizationsEn();
      expect(lEn.cloneRowTooltip, equals('Clone Row (Ctrl+D)'));
      expect(lEn.clonePriceListDialogTitle, equals('Clone Broker Price List'));
      expect(lEn.cloneImportFileDialogTitle, equals('Clone Import File'));
      expect(lEn.cloneConfirmAndCreateBtn, equals('Confirm Clone & Create Record'));
    });
  });

  group('UX-CLONE-011 Model ClonedFrom Field Tests', () {
    test('ImportFileModel parses and serializes clonedFromId and clonedFromCode', () {
      final json = {
        'import_file_id': 101,
        'import_file_code': 'IMP-2026-0001-CLONE',
        'company_name': 'شركة الأمل للاستيراد',
        'supplier_name': 'Global Trading Ltd',
        'shipment_mode': 'Sea',
        'incoterm_code': 'CIF',
        'priority': 'Normal',
        'shipment_category': 'Standard',
        'current_module': 'Customs',
        'current_stage': 'Draft',
        'progress_percent': 0.0,
        'next_action': 'Upload Docs',
        'skipped_stages': [],
        'status': 'Draft',
        'owner': 'Admin',
        'is_active': true,
        'cloned_from_id': 55,
        'cloned_from_code': 'IMP-2026-0001',
      };

      final model = ImportFileModel.fromJson(json);
      expect(model.clonedFromId, equals(55));
      expect(model.clonedFromCode, equals('IMP-2026-0001'));
      expect(model.toJson()['cloned_from_id'], equals(55));
      expect(model.toJson()['cloned_from_code'], equals('IMP-2026-0001'));
    });

    test('BrokerPriceListModel parses and serializes clonedFromId and clonedFromCode', () {
      final json = {
        'price_list_id': 202,
        'price_list_code': 'PL-ALX-01-CLONE',
        'broker_id': 12,
        'broker_name': 'مكتب الإسكندرية للتخليص',
        'title': 'قائمة أسعار الإسكندرية 2026',
        'effective_from': '2026-01-01',
        'version': 1,
        'is_active': true,
        'cloned_from_id': 100,
        'cloned_from_code': 'PL-ALX-01',
        'items': [],
      };

      final model = BrokerPriceListModel.fromJson(json);
      expect(model.clonedFromId, equals(100));
      expect(model.clonedFromCode, equals('PL-ALX-01'));
      expect(model.toJson()['cloned_from_id'], equals(100));
      expect(model.toJson()['cloned_from_code'], equals('PL-ALX-01'));
    });

    test('CustomsConsultationModel parses and serializes clonedFromId and clonedFromCode', () {
      final json = {
        'consultation_id': 303,
        'consultation_code': 'CS-2026-001-CLONE',
        'title': 'دراسة جمركية مستنسخة',
        'broker_id': 12,
        'is_active': true,
        'cloned_from_id': 88,
        'cloned_from_code': 'CS-2026-001',
      };

      final model = CustomsConsultationModel.fromJson(json);
      expect(model.clonedFromId, equals(88));
      expect(model.clonedFromCode, equals('CS-2026-001'));
      expect(model.toJson()['cloned_from_id'], equals(88));
      expect(model.toJson()['cloned_from_code'], equals('CS-2026-001'));
    });
  });

  group('UX-CLONE-011 CloneEntityReviewDialog Widget Tests', () {
    testWidgets('Renders review dialog, validates new code, and invokes onConfirm callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? confirmedNewCode;
      bool? confirmedCopyLines;
      bool? confirmedCopyAttachments;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                onPressed: () {
                  CloneEntityReviewDialog.show(
                    context,
                    entityType: 'ملف استيراد',
                    sourceCode: 'IMP-2026-0001',
                    suggestedNewCode: 'IMP-2026-0001-CLONE',
                    sourceTitle: 'شحنة ماكينات صناعية',
                    copiedFieldsSummary: {
                      'الشركة المستوردة': 'الشركة الدولية للاستيراد',
                      'المورد الأجنبي': 'Siemens AG',
                    },
                    mandatorilyResetFields: [
                      'الحالة التشغيلية: تعود إلى مسودة',
                      'تصفير رقم وتاريخ ACID',
                    ],
                    allowCopyLineItems: true,
                    allowCopyAttachments: true,
                    initialCopyLineItems: true,
                    initialCopyAttachments: false,
                    onConfirm: ({
                      required String newCode,
                      required String newTitle,
                      required bool copyLineItems,
                      required bool copyAttachments,
                      String? notes,
                    }) async {
                      confirmedNewCode = newCode;
                      confirmedCopyLines = copyLineItems;
                      confirmedCopyAttachments = copyAttachments;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify header and fields
      expect(find.textContaining('استنساخ ملف استيراد'), findsOneWidget);
      expect(find.textContaining('IMP-2026-0001'), findsWidgets);
      expect(find.text('الشركة الدولية للاستيراد'), findsOneWidget);
      expect(find.text('Siemens AG'), findsOneWidget);
      expect(find.text('الحالة التشغيلية: تعود إلى مسودة'), findsOneWidget);

      // Check default checkbox state: line items true, attachments false
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, equals(2));
      expect(checkboxes[0].value, isTrue); // copy line items
      expect(checkboxes[1].value, isFalse); // copy attachments

      // Toggle attachments checkbox
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();

      // Submit clone
      final confirmBtn = find.text('تأكيد الاستنساخ وإنشاء السجل');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify callback arguments
      expect(confirmedNewCode, equals('IMP-2026-0001-CLONE'));
      expect(confirmedCopyLines, isTrue);
      expect(confirmedCopyAttachments, isTrue);
    });
  });
}
