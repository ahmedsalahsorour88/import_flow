import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 64: Warehouse Received Shipments Detailed Report Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 64 getters return non-empty strings and no missing translations', () {
      // Titles and Errors
      expect(ar.whReportTabTitle.isNotEmpty, true);
      expect(en.whReportTabTitle.isNotEmpty, true);
      expect(ar.whReportScaffoldTitle.isNotEmpty, true);
      expect(en.whReportScaffoldTitle.isNotEmpty, true);
      expect(ar.whReportErrorFetchingData('Err').contains('Err'), true);
      expect(en.whReportErrorFetchingData('Err').contains('Err'), true);

      // Info Banner
      expect(ar.whReportInfoBannerTitle.isNotEmpty, true);
      expect(en.whReportInfoBannerTitle.isNotEmpty, true);
      expect(ar.whReportInfoBannerSubtitle.isNotEmpty, true);
      expect(en.whReportInfoBannerSubtitle.isNotEmpty, true);
      expect(ar.whReportExportExcelBtn.isNotEmpty, true);
      expect(en.whReportExportExcelBtn.isNotEmpty, true);
      expect(ar.whReportExportSuccessMsg.isNotEmpty, true);
      expect(en.whReportExportSuccessMsg.isNotEmpty, true);

      // New Export & Copy Actions
      expect(ar.whReportExportTsvBtn.isNotEmpty, true);
      expect(en.whReportExportTsvBtn.isNotEmpty, true);
      expect(ar.whReportPrintPdfBtn.isNotEmpty, true);
      expect(en.whReportPrintPdfBtn.isNotEmpty, true);
      expect(ar.whReportCopyDossierBtn.isNotEmpty, true);
      expect(en.whReportCopyDossierBtn.isNotEmpty, true);
      expect(ar.whReportCopiedTsvSuccess.isNotEmpty, true);
      expect(en.whReportCopiedTsvSuccess.isNotEmpty, true);
      expect(ar.whReportCopiedExcelSuccess.isNotEmpty, true);
      expect(en.whReportCopiedExcelSuccess.isNotEmpty, true);
      expect(ar.whReportCopiedDossierSuccess.isNotEmpty, true);
      expect(en.whReportCopiedDossierSuccess.isNotEmpty, true);
      expect(ar.whReportCopyRowSummaryBtn.isNotEmpty, true);
      expect(en.whReportCopyRowSummaryBtn.isNotEmpty, true);
      expect(ar.whReportCopyRowSummarySuccess.isNotEmpty, true);
      expect(en.whReportCopyRowSummarySuccess.isNotEmpty, true);
      expect(ar.whReportCopyFieldTooltip.isNotEmpty, true);
      expect(en.whReportCopyFieldTooltip.isNotEmpty, true);
      expect(ar.whReportSearchCopied.isNotEmpty, true);
      expect(en.whReportSearchCopied.isNotEmpty, true);
      expect(ar.whReportColActions.isNotEmpty, true);
      expect(en.whReportColActions.isNotEmpty, true);
      expect(ar.whReportColWarehouse.isNotEmpty, true);
      expect(en.whReportColWarehouse.isNotEmpty, true);
      expect(ar.whReportColArrivalDate.isNotEmpty, true);
      expect(en.whReportColArrivalDate.isNotEmpty, true);
      expect(ar.whReportCopyBadgeSuccess('ملف', '101'), contains('101'));
      expect(en.whReportCopyBadgeSuccess('File', '101'), contains('101'));

      // Dossier & PDF headers
      expect(ar.whReportPdfTitle.isNotEmpty, true);
      expect(en.whReportPdfTitle.isNotEmpty, true);
      expect(ar.whReportPdfSubtitle.isNotEmpty, true);
      expect(en.whReportPdfSubtitle.isNotEmpty, true);
      expect(ar.whReportDossierHeader.isNotEmpty, true);
      expect(en.whReportDossierHeader.isNotEmpty, true);
      expect(ar.whReportDossierKpiSummary.isNotEmpty, true);
      expect(en.whReportDossierKpiSummary.isNotEmpty, true);
      expect(ar.whReportDossierRecordsDetails.isNotEmpty, true);
      expect(en.whReportDossierRecordsDetails.isNotEmpty, true);
      expect(ar.whReportDossierFooter.isNotEmpty, true);
      expect(en.whReportDossierFooter.isNotEmpty, true);

      // KPI Metrics
      expect(ar.whReportKpiInvoicedQty.isNotEmpty, true);
      expect(en.whReportKpiInvoicedQty.isNotEmpty, true);
      expect(ar.whReportKpiReceivedQty.isNotEmpty, true);
      expect(en.whReportKpiReceivedQty.isNotEmpty, true);
      expect(ar.whReportKpiDamagedQty.isNotEmpty, true);
      expect(en.whReportKpiDamagedQty.isNotEmpty, true);
      expect(ar.whReportKpiShortageQty.isNotEmpty, true);
      expect(en.whReportKpiShortageQty.isNotEmpty, true);
      expect(ar.whReportKpiSamplesQty.isNotEmpty, true);
      expect(en.whReportKpiSamplesQty.isNotEmpty, true);
      expect(ar.whReportKpiVarianceQty.isNotEmpty, true);
      expect(en.whReportKpiVarianceQty.isNotEmpty, true);
      expect(ar.whReportUnitsValue(150), contains('150'));
      expect(en.whReportUnitsValue(150), contains('150'));

      // Search & Table Headers
      expect(ar.whReportSearchHint.isNotEmpty, true);
      expect(en.whReportSearchHint.isNotEmpty, true);
      expect(ar.whReportTableSectionHeader.isNotEmpty, true);
      expect(en.whReportTableSectionHeader.isNotEmpty, true);
      expect(ar.whReportNoDataFound.isNotEmpty, true);
      expect(en.whReportNoDataFound.isNotEmpty, true);
      expect(ar.whReportColImportFile.isNotEmpty, true);
      expect(en.whReportColImportFile.isNotEmpty, true);
      expect(ar.whReportColPoNumber.isNotEmpty, true);
      expect(en.whReportColPoNumber.isNotEmpty, true);
      expect(ar.whReportColContainerAndTruck.isNotEmpty, true);
      expect(en.whReportColContainerAndTruck.isNotEmpty, true);
      expect(ar.whReportColItemAndDescription.isNotEmpty, true);
      expect(en.whReportColItemAndDescription.isNotEmpty, true);
      expect(ar.whReportColInvoicedQty.isNotEmpty, true);
      expect(en.whReportColInvoicedQty.isNotEmpty, true);
      expect(ar.whReportColShortageQty.isNotEmpty, true);
      expect(en.whReportColShortageQty.isNotEmpty, true);
      expect(ar.whReportColDamagedQty.isNotEmpty, true);
      expect(en.whReportColDamagedQty.isNotEmpty, true);
      expect(ar.whReportColSamplesQty.isNotEmpty, true);
      expect(en.whReportColSamplesQty.isNotEmpty, true);
      expect(ar.whReportColReceivedQty.isNotEmpty, true);
      expect(en.whReportColReceivedQty.isNotEmpty, true);
      expect(ar.whReportColVarianceQty.isNotEmpty, true);
      expect(en.whReportColVarianceQty.isNotEmpty, true);
      expect(ar.whReportColReceiptStatus.isNotEmpty, true);
      expect(en.whReportColReceiptStatus.isNotEmpty, true);
      expect(ar.whReportStatusApprovedAndReceived.isNotEmpty, true);
      expect(en.whReportStatusApprovedAndReceived.isNotEmpty, true);
    });

    test('Arabic translations contain pure Arabic text without Latin characters', () {
      final latinRegex = RegExp(r'[a-zA-Z]');

      final pureArabicStaticStrings = [
        ar.whReportTabTitle,
        ar.whReportScaffoldTitle,
        ar.whReportInfoBannerTitle,
        ar.whReportInfoBannerSubtitle,
        ar.whReportExportExcelBtn,
        ar.whReportExportSuccessMsg,
        ar.whReportExportTsvBtn,
        ar.whReportPrintPdfBtn,
        ar.whReportCopyDossierBtn,
        ar.whReportCopiedTsvSuccess,
        ar.whReportCopiedExcelSuccess,
        ar.whReportCopiedDossierSuccess,
        ar.whReportCopyRowSummaryBtn,
        ar.whReportCopyRowSummarySuccess,
        ar.whReportCopyFieldTooltip,
        ar.whReportSearchCopied,
        ar.whReportColActions,
        ar.whReportColWarehouse,
        ar.whReportColArrivalDate,
        ar.whReportPdfTitle,
        ar.whReportPdfSubtitle,
        ar.whReportDossierHeader,
        ar.whReportDossierKpiSummary,
        ar.whReportDossierRecordsDetails,
        ar.whReportDossierFooter,
        ar.whReportKpiInvoicedQty,
        ar.whReportKpiReceivedQty,
        ar.whReportKpiDamagedQty,
        ar.whReportKpiShortageQty,
        ar.whReportKpiSamplesQty,
        ar.whReportKpiVarianceQty,
        ar.whReportSearchHint,
        ar.whReportTableSectionHeader,
        ar.whReportNoDataFound,
        ar.whReportColImportFile,
        ar.whReportColPoNumber,
        ar.whReportColContainerAndTruck,
        ar.whReportColItemAndDescription,
        ar.whReportColInvoicedQty,
        ar.whReportColShortageQty,
        ar.whReportColDamagedQty,
        ar.whReportColSamplesQty,
        ar.whReportColReceivedQty,
        ar.whReportColVarianceQty,
        ar.whReportColReceiptStatus,
        ar.whReportStatusApprovedAndReceived,
      ];

      for (final text in pureArabicStaticStrings) {
        expect(
          latinRegex.hasMatch(text),
          false,
          reason: 'String "$text" contains English/Latin characters!',
        );
      }
    });

    test('No stacked bilingual text is present in static labels', () {
      expect(ar.whReportScaffoldTitle.contains('('), false);
      expect(ar.whReportInfoBannerTitle.contains('('), false);
      expect(ar.whReportInfoBannerSubtitle.contains('('), false);
      expect(ar.whReportTableSectionHeader.contains('('), false);
      expect(ar.whReportColPoNumber.contains('('), false);
      expect(ar.whReportColVarianceQty.contains('('), false);
      expect(ar.whReportStatusApprovedAndReceived.contains('('), false);
      expect(ar.whReportExportTsvBtn.contains('/'), false);
      expect(ar.whReportPrintPdfBtn.contains('/'), false);
      expect(ar.whReportCopyDossierBtn.contains('/'), false);
    });
  });
}
