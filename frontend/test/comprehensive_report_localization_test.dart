import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Comprehensive Report Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('Screen and section titles are properly localized in Arabic and English', () {
      expect(ar.compReportScreenTitle, isNotEmpty);
      expect(en.compReportScreenTitle, isNotEmpty);
      expect(ar.compReportScreenTitle, isNot(equals(en.compReportScreenTitle)));

      expect(ar.compReportSecBasicInfo, isNotEmpty);
      expect(en.compReportSecBasicInfo, isNotEmpty);

      expect(ar.compReportSecDocs, isNotEmpty);
      expect(en.compReportSecDocs, isNotEmpty);

      expect(ar.compReportSecStatus, isNotEmpty);
      expect(en.compReportSecStatus, isNotEmpty);

      expect(ar.compReportSecFinancial, isNotEmpty);
      expect(en.compReportSecFinancial, isNotEmpty);

      expect(ar.compReportSecNotes, isNotEmpty);
      expect(en.compReportSecNotes, isNotEmpty);

      expect(ar.compReportSecClearance, isNotEmpty);
      expect(en.compReportSecClearance, isNotEmpty);

      expect(ar.compReportSecWarehouse, isNotEmpty);
      expect(en.compReportSecWarehouse, isNotEmpty);
    });

    test('10-Phase pipeline names are localized without empty strings', () {
      expect(ar.compReportPhase1Name, contains('التخطيط'));
      expect(en.compReportPhase1Name, contains('Planning'));

      expect(ar.compReportPhase2Name, contains('الموافقة'));
      expect(en.compReportPhase2Name, contains('Approval'));

      expect(ar.compReportPhase3Name, contains('المستندات'));
      expect(en.compReportPhase3Name, contains('Documents'));

      expect(ar.compReportPhase4Name, contains('حجز'));
      expect(en.compReportPhase4Name, contains('Booking'));

      expect(ar.compReportPhase5Name, contains('الشحن'));
      expect(en.compReportPhase5Name, contains('Shipping'));

      expect(ar.compReportPhase6Name, contains('إقرار 46'));
      expect(en.compReportPhase6Name, contains('Declaration 46'));

      expect(ar.compReportPhase7Name, contains('التخليص'));
      expect(en.compReportPhase7Name, contains('Clearance'));

      expect(ar.compReportPhase8Name, contains('المخازن'));
      expect(en.compReportPhase8Name, contains('Warehouse'));

      expect(ar.compReportPhase9Name, contains('تسوية'));
      expect(en.compReportPhase9Name, contains('Settlement'));

      expect(ar.compReportPhase10Name, contains('إغلاق'));
      expect(en.compReportPhase10Name, contains('Closure'));
    });

    test('Dynamic parameter methods work correctly in both languages', () {
      expect(ar.compReportPercentCompleted('75'), contains('75%'));
      expect(en.compReportPercentCompleted('75'), contains('75%'));

      expect(ar.compReportSecInvoices(3), contains('3'));
      expect(ar.compReportSecInvoices(3), contains('فاتورة'));
      expect(en.compReportSecInvoices(3), contains('3'));
      expect(en.compReportSecInvoices(3), contains('Invoices'));

      expect(ar.compReportSecPackingLists(2), contains('2'));
      expect(ar.compReportSecPackingLists(2), contains('قائمة'));
      expect(en.compReportSecPackingLists(2), contains('Lists'));

      expect(ar.compReportSecTimeline(5), contains('5'));
      expect(ar.compReportSecTimeline(5), contains('تحديث'));
      expect(en.compReportSecTimeline(5), contains('5'));
      expect(en.compReportSecTimeline(5), contains('Updates'));

      expect(ar.compReportPiecesUnit(120), contains('120'));
      expect(ar.compReportPiecesUnit(120), contains('قطعة'));
      expect(en.compReportPiecesUnit(120), contains('120'));
      expect(en.compReportPiecesUnit(120), contains('pcs'));

      expect(ar.compReportPackagesUnit(45), contains('45'));
      expect(ar.compReportPackagesUnit(45), contains('طرد'));
      expect(en.compReportPackagesUnit(45), contains('45'));
      expect(en.compReportPackagesUnit(45), contains('pkgs'));

      expect(ar.compReportByPrefix('Ahmed'), contains('بواسطة: Ahmed'));
      expect(en.compReportByPrefix('Ahmed'), contains('By: Ahmed'));

      expect(ar.compReportStoppedAtPhase('Phase 5'), contains('Phase 5'));
      expect(ar.compReportStoppedAtPhase('Phase 5'), contains('تم إيقاف'));
      expect(en.compReportStoppedAtPhase('Phase 5'), contains('stopped'));
    });

    test('Customs Clearance and Warehouse GRN keys are properly localized', () {
      expect(ar.compReportDutyImport, equals('ضريبة الوارد'));
      expect(en.compReportDutyImport, equals('Import Duty'));

      expect(ar.compReportDutyVat, equals('القيمة المضافة'));
      expect(en.compReportDutyVat, equals('VAT'));

      expect(ar.compReportDutySchedule, equals('ضريبة الجدول'));
      expect(en.compReportDutySchedule, equals('Schedule Tax'));

      expect(ar.compReportDutyInspection, equals('رسوم العرض'));
      expect(en.compReportDutyInspection, equals('Inspection Fee'));

      expect(ar.compReportTableColCode, equals('الكود'));
      expect(en.compReportTableColCode, equals('Code'));

      expect(ar.compReportTableColItem, equals('الصنف'));
      expect(en.compReportTableColItem, equals('Item'));

      expect(ar.compReportTableColInvoiced, equals('فواتير'));
      expect(en.compReportTableColInvoiced, equals('Invoiced'));

      expect(ar.compReportTableColAccepted, equals('مقبول'));
      expect(en.compReportTableColAccepted, equals('Accepted'));

      expect(ar.compReportTableColShortage, equals('عجز'));
      expect(en.compReportTableColShortage, equals('Shortage'));

      expect(ar.compReportTableColDamaged, equals('تالف'));
      expect(en.compReportTableColDamaged, equals('Damaged'));
    });

    test('Screen 47 export buttons and dossier copy getters are localized', () {
      expect(ar.compReportExportTsvBtn, equals('تصدير نصي مفصول'));
      expect(en.compReportExportTsvBtn, equals('Export TSV'));

      expect(ar.compReportExportExcelBtn, equals('تصدير إكسيل'));
      expect(en.compReportExportExcelBtn, equals('Export Excel'));

      expect(ar.compReportPrintPdfBtn, equals('طباعة وحفظ المستند'));
      expect(en.compReportPrintPdfBtn, equals('Print / Save PDF'));

      expect(ar.compReportCopyDossierBtn, equals('نسخ الملف الشامل'));
      expect(en.compReportCopyDossierBtn, equals('Copy Full Dossier'));

      expect(ar.compReportCopyDossierSuccess, contains('تم نسخ الملف'));
      expect(en.compReportCopyDossierSuccess, contains('copied to clipboard'));

      expect(ar.compReportExportTsvDialogTitle, isNotEmpty);
      expect(en.compReportExportTsvDialogTitle, isNotEmpty);

      expect(ar.compReportExportExcelDialogTitle, isNotEmpty);
      expect(en.compReportExportExcelDialogTitle, isNotEmpty);

      expect(ar.compReportPrintPdfDialogTitle, isNotEmpty);
      expect(en.compReportPrintPdfDialogTitle, isNotEmpty);

      expect(ar.compReportDossierHeader, isNotEmpty);
      expect(en.compReportDossierHeader, isNotEmpty);

      expect(ar.compReportPhaseLabel(5), equals('المرحلة 5'));
      expect(en.compReportPhaseLabel(5), equals('Phase 5'));

      expect(ar.compReportCopyValueTooltip('الكود'), contains('الكود'));
      expect(en.compReportCopyValueTooltip('Code'), contains('Code'));

      expect(ar.compReportCurrencyUsd, equals('دولار أمريكي'));
      expect(en.compReportCurrencyUsd, equals('USD'));

      expect(ar.compReportTsvColSection, equals('القسم'));
      expect(en.compReportTsvColSection, equals('Section'));

      expect(ar.compReportTsvColField, equals('البيان'));
      expect(en.compReportTsvColField, equals('Field'));

      expect(ar.compReportTsvColValue, equals('القيمة'));
      expect(en.compReportTsvColValue, equals('Value'));

      expect(ar.compReportTsvColDetails, equals('التفاصيل والملاحظات'));
      expect(en.compReportTsvColDetails, equals('Details / Notes'));
    });

    test('No Arabic translation strings contain bilingual slash stacking or unexpected Latin prefixes', () {
      final arabicStrings = [
        ar.compReportScreenTitle,
        ar.compReportSelectFileLabel,
        ar.compReportAddUpdateBtn,
        ar.compReportEmptyStatePrompt,
        ar.compReportCompletedPhases,
        ar.compReportRemainingPhases,
        ar.compReportPipelineTitle,
        ar.compReportSecBasicInfo,
        ar.compReportColFileCode,
        ar.compReportColCustomsFileNo,
        ar.compReportColImportCompany,
        ar.compReportColSupplier,
        ar.compReportColBroker,
        ar.compReportColShipmentMode,
        ar.compReportColCategory,
        ar.compReportSecDocs,
        ar.compReportSecFinancial,
        ar.compReportTotalInvoicesVal,
        ar.compReportEstimatedCostVal,
        ar.compReportEstimatedVariance,
        ar.compReportSecNotes,
        ar.compReportNoNotes,
        ar.compReportNoInvoices,
        ar.compReportNoPackingLists,
        ar.compReportNoTimelineLogs,
        ar.compReportNoClearanceData,
        ar.compReportNoWarehouseData,
        ar.compReportExportTsvBtn,
        ar.compReportExportExcelBtn,
        ar.compReportPrintPdfBtn,
        ar.compReportCopyDossierBtn,
        ar.compReportCopyDossierSuccess,
        ar.compReportExportTsvDialogTitle,
        ar.compReportExportExcelDialogTitle,
        ar.compReportPrintPdfDialogTitle,
        ar.compReportDossierHeader,
        ar.compReportCurrencyUsd,
        ar.compReportTsvColSection,
        ar.compReportTsvColField,
        ar.compReportTsvColValue,
        ar.compReportTsvColDetails,
      ];

      for (final str in arabicStrings) {
        expect(str.contains(' / '), isFalse, reason: 'String "$str" contains bilingual stacking separator');
      }
    });

    test('Zero Latin characters in all Arabic translations for Screen 47', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      final arabicComprehensiveReportStrings = [
        ar.compReportScreenTitle,
        ar.compReportAddUpdateBtn,
        ar.compReportSelectFileLabel,
        ar.compReportEmptyStatePrompt,
        ar.compReportPercentCompleted('50'),
        ar.compReportCompletedPhases,
        ar.compReportRemainingPhases,
        ar.compReportPipelineTitle,
        ar.compReportStoppedAtPhase('المرحلة 3'),
        ar.compReportSecBasicInfo,
        ar.compReportColFileCode,
        ar.compReportColCustomsFileNo,
        ar.compReportColImportCompany,
        ar.compReportColSupplier,
        ar.compReportColBroker,
        ar.compReportColPoNumber,
        ar.compReportColPiNumber,
        ar.compReportColShipmentMode,
        ar.compReportColIncoterm,
        ar.compReportColCategory,
        ar.compReportColScenario,
        ar.compReportColRequiredEta,
        ar.compReportColOwner,
        ar.compReportColCreatedAt,
        ar.compReportColUpdatedAt,
        ar.compReportSecDocs,
        ar.compReportAcidNumber,
        ar.compReportBankForm4,
        ar.compReportSwiftNumber,
        ar.compReportForm46Number,
        ar.compReportSecInvoices(2),
        ar.compReportNoInvoices,
        ar.compReportSecPackingLists(3),
        ar.compReportNoPackingLists,
        ar.compReportTotalPackages,
        ar.compReportTotalWeight,
        ar.compReportTotalCbm,
        ar.compReportPackagesUnit('10'),
        ar.compReportPiecesUnit('50'),
        ar.compReportSecStatus,
        ar.compReportPriorityPrefix('عالية'),
        ar.compReportStatusLabel,
        ar.compReportCurrentStageLabel,
        ar.compReportCurrentModuleLabel,
        ar.compReportNextActionLabel,
        ar.compReportTotalProgressLabel,
        ar.compReportSecFinancial,
        ar.compReportTotalInvoicesVal,
        ar.compReportEstimatedCostVal,
        ar.compReportEstimatedVariance,
        ar.compReportSecNotes,
        ar.compReportNoNotes,
        ar.compReportSecTimeline(4),
        ar.compReportNoTimelineLogs,
        ar.compReportByPrefix('أحمد'),
        ar.compReportAlertPriorityPrefix('عالية'),
        ar.compReportSecClearance,
        ar.compReportNoClearanceData,
        ar.compReportDeclarationChip('123'),
        ar.compReportReleasePermitChip('456'),
        ar.compReportDutyImport,
        ar.compReportDutyVat,
        ar.compReportDutySchedule,
        ar.compReportDutyInspection,
        ar.compReportDutyTotal,
        ar.compReportPaymentDate('2026-09-09'),
        ar.compReportReleaseDate('2026-09-09'),
        ar.compReportSecWarehouse,
        ar.compReportNoWarehouseData,
        ar.compReportGrnChip('789'),
        ar.compReportArrivalDatetime('2026-09-09'),
        ar.compReportInspectorPrefix('محمد'),
        ar.compReportQtyInvoiced,
        ar.compReportQtyAccepted,
        ar.compReportQtyShortage,
        ar.compReportQtyDamaged,
        ar.compReportTableColCode,
        ar.compReportTableColItem,
        ar.compReportTableColInvoiced,
        ar.compReportTableColAccepted,
        ar.compReportTableColShortage,
        ar.compReportTableColDamaged,
        ar.compReportPhase1Name,
        ar.compReportPhase2Name,
        ar.compReportPhase3Name,
        ar.compReportPhase4Name,
        ar.compReportPhase5Name,
        ar.compReportPhase6Name,
        ar.compReportPhase7Name,
        ar.compReportPhase8Name,
        ar.compReportPhase9Name,
        ar.compReportPhase10Name,
        ar.compReportCategoryCostAdjustment,
        ar.compReportCategoryFutureAlert,
        ar.compReportCategoryDailyCheckIn,
        ar.compReportCategoryGeneralUpdate,
        ar.compReportExportTsvBtn,
        ar.compReportExportExcelBtn,
        ar.compReportPrintPdfBtn,
        ar.compReportCopyDossierBtn,
        ar.compReportCopyDossierSuccess,
        ar.compReportExportTsvDialogTitle,
        ar.compReportExportExcelDialogTitle,
        ar.compReportPrintPdfDialogTitle,
        ar.compReportDossierHeader,
        ar.compReportPhaseLabel(1),
        ar.compReportCopyValueTooltip('الكود'),
        ar.compReportCurrencyUsd,
        ar.compReportTsvColSection,
        ar.compReportTsvColField,
        ar.compReportTsvColValue,
        ar.compReportTsvColDetails,
      ];

      for (final str in arabicComprehensiveReportStrings) {
        expect(
          latinPattern.hasMatch(str),
          isFalse,
          reason: 'Arabic string "$str" contains Latin characters: ${latinPattern.allMatches(str).map((m) => m.group(0)).toList()}',
        );
      }
    });
  });
}
