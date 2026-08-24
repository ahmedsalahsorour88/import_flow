import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 19: Draft COO / EUR.1 Review Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final screen19Getters = <String, List<String>>{
      'cooStage1Requirements': [ar.cooStage1Requirements, en.cooStage1Requirements],
      'cooStage2DraftInput': [ar.cooStage2DraftInput, en.cooStage2DraftInput],
      'cooStage3DiscrepancyMatrix': [ar.cooStage3DiscrepancyMatrix, en.cooStage3DiscrepancyMatrix],
      'cooStage4Registry': [ar.cooStage4Registry, en.cooStage4Registry],
      'cooDecisionEngineTitle': [ar.cooDecisionEngineTitle, en.cooDecisionEngineTitle],
      'cooDecisionEngineSub': [ar.cooDecisionEngineSub, en.cooDecisionEngineSub],
      'cooRecheckAgreementButton': [ar.cooRecheckAgreementButton, en.cooRecheckAgreementButton],
      'cooInvoiceOriginBadge': [ar.cooInvoiceOriginBadge('Germany'), en.cooInvoiceOriginBadge('Germany')],
      'cooManualChoiceRequiredBadge': [ar.cooManualChoiceRequiredBadge, en.cooManualChoiceRequiredBadge],
      'cooApprovedCertBadge': [ar.cooApprovedCertBadge('EUR.1'), en.cooApprovedCertBadge('EUR.1')],
      'cooExistingReviewBanner': [ar.cooExistingReviewBanner('COO-001', 'Verified'), en.cooExistingReviewBanner('COO-001', 'Verified')],
      'cooReviewRegistryButton': [ar.cooReviewRegistryButton, en.cooReviewRegistryButton],
      'cooGenerateDraftHeader': [ar.cooGenerateDraftHeader, en.cooGenerateDraftHeader],
      'cooSelectImportFileLabel': [ar.cooSelectImportFileLabel, en.cooSelectImportFileLabel],
      'cooSearchFileHint': [ar.cooSearchFileHint, en.cooSearchFileHint],
      'cooCertTypeLabel': [ar.cooCertTypeLabel, en.cooCertTypeLabel],
      'cooSelectCertTypeHint': [ar.cooSelectCertTypeHint, en.cooSelectCertTypeHint],
      'cooCertTypeEur1': [ar.cooCertTypeEur1, en.cooCertTypeEur1],
      'cooCertTypeChina': [ar.cooCertTypeChina, en.cooCertTypeChina],
      'cooCertTypeStandard': [ar.cooCertTypeStandard, en.cooCertTypeStandard],
      'cooCertTypeFormA': [ar.cooCertTypeFormA, en.cooCertTypeFormA],
      'cooCertTypeAgadir': [ar.cooCertTypeAgadir, en.cooCertTypeAgadir],
      'cooCertTypeGafta': [ar.cooCertTypeGafta, en.cooCertTypeGafta],
      'cooOpenVisualPreviewButton': [ar.cooOpenVisualPreviewButton, en.cooOpenVisualPreviewButton],
      'cooNextDraftInputButton': [ar.cooNextDraftInputButton, en.cooNextDraftInputButton],
      'cooOfficialDraftPreviewTitle': [ar.cooOfficialDraftPreviewTitle, en.cooOfficialDraftPreviewTitle],
      'cooAutoFillFieldsButton': [ar.cooAutoFillFieldsButton, en.cooAutoFillFieldsButton],
      'cooDraftFilledSuccess': [ar.cooDraftFilledSuccess, en.cooDraftFilledSuccess],
      'cooGenerateDraftError': [ar.cooGenerateDraftError('Net Error'), en.cooGenerateDraftError('Net Error')],
      'cooDraftInputTitle': [ar.cooDraftInputTitle, en.cooDraftInputTitle],
      'cooRunComparisonButton': [ar.cooRunComparisonButton, en.cooRunComparisonButton],
      'cooLinkedImportFileLabel': [ar.cooLinkedImportFileLabel, en.cooLinkedImportFileLabel],
      'cooSelectFileWarning': [ar.cooSelectFileWarning, en.cooSelectFileWarning],
      'cooDraftCertNumberLabel': [ar.cooDraftCertNumberLabel, en.cooDraftCertNumberLabel],
      'cooOriginCountryLabel': [ar.cooOriginCountryLabel, en.cooOriginCountryLabel],
      'cooDestinationCountryLabel': [ar.cooDestinationCountryLabel, en.cooDestinationCountryLabel],
      'cooExporterNameLabel': [ar.cooExporterNameLabel, en.cooExporterNameLabel],
      'cooExporterRegIdLabel': [ar.cooExporterRegIdLabel, en.cooExporterRegIdLabel],
      'cooImporterNameLabel': [ar.cooImporterNameLabel, en.cooImporterNameLabel],
      'cooInvoiceNumberLabel': [ar.cooInvoiceNumberLabel, en.cooInvoiceNumberLabel],
      'cooSmartUploadButtonLabel': [ar.cooSmartUploadButtonLabel, en.cooSmartUploadButtonLabel],
      'cooRawTextSectionTitle': [ar.cooRawTextSectionTitle, en.cooRawTextSectionTitle],
      'cooSmartExtractFromTextButton': [ar.cooSmartExtractFromTextButton, en.cooSmartExtractFromTextButton],
      'cooRawTextHint': [ar.cooRawTextHint, en.cooRawTextHint],
      'cooPasteTextOrUploadWarning': [ar.cooPasteTextOrUploadWarning, en.cooPasteTextOrUploadWarning],
      'cooAiExtractSuccess': [ar.cooAiExtractSuccess, en.cooAiExtractSuccess],
      'cooExtractError': [ar.cooExtractError('Parse Error'), en.cooExtractError('Parse Error')],
      'cooSelectFileFirstForComparison': [ar.cooSelectFileFirstForComparison, en.cooSelectFileFirstForComparison],
      'cooComparisonError': [ar.cooComparisonError('Timeout'), en.cooComparisonError('Timeout')],
      'cooSelectFileToViewMatrix': [ar.cooSelectFileToViewMatrix, en.cooSelectFileToViewMatrix],
      'cooBackToSelectFile': [ar.cooBackToSelectFile, en.cooBackToSelectFile],
      'cooRunComparisonPreviousStep': [ar.cooRunComparisonPreviousStep, en.cooRunComparisonPreviousStep],
      'cooBackToRunComparison': [ar.cooBackToRunComparison, en.cooBackToRunComparison],
      'cooCriticalMismatchAlert': [ar.cooCriticalMismatchAlert, en.cooCriticalMismatchAlert],
      'cooMinorDiscrepancyAlert': [ar.cooMinorDiscrepancyAlert, en.cooMinorDiscrepancyAlert],
      'cooPerfectMatchSuccess': [ar.cooPerfectMatchSuccess, en.cooPerfectMatchSuccess],
      'cooExportPdfButton': [ar.cooExportPdfButton, en.cooExportPdfButton],
      'cooExportExcelButton': [ar.cooExportExcelButton, en.cooExportExcelButton],
      'cooSaveToRegistryButton': [ar.cooSaveToRegistryButton, en.cooSaveToRegistryButton],
      'cooExportingPdfReportSnackbar': [ar.cooExportingPdfReportSnackbar, en.cooExportingPdfReportSnackbar],
      'cooExcelCopiedSnackbar': [ar.cooExcelCopiedSnackbar, en.cooExcelCopiedSnackbar],
      'cooMatrixColField': [ar.cooMatrixColField, en.cooMatrixColField],
      'cooMatrixColSystemValue': [ar.cooMatrixColSystemValue, en.cooMatrixColSystemValue],
      'cooMatrixColDraftValue': [ar.cooMatrixColDraftValue, en.cooMatrixColDraftValue],
      'cooMatrixColStatus': [ar.cooMatrixColStatus, en.cooMatrixColStatus],
      'cooMatrixColDetails': [ar.cooMatrixColDetails, en.cooMatrixColDetails],
      'cooOverrideReasonTitle': [ar.cooOverrideReasonTitle, en.cooOverrideReasonTitle],
      'cooOverrideReasonSub': [ar.cooOverrideReasonSub, en.cooOverrideReasonSub],
      'cooOverrideReasonLabel': [ar.cooOverrideReasonLabel, en.cooOverrideReasonLabel],
      'cooOverrideReasonHint': [ar.cooOverrideReasonHint, en.cooOverrideReasonHint],
      'cooSaveWithJustificationButton': [ar.cooSaveWithJustificationButton, en.cooSaveWithJustificationButton],
      'cooReturnToEditAndNotifySupplierButton': [ar.cooReturnToEditAndNotifySupplierButton, en.cooReturnToEditAndNotifySupplierButton],
      'cooMustProvideJustificationSnackbar': [ar.cooMustProvideJustificationSnackbar, en.cooMustProvideJustificationSnackbar],
      'cooSessionSavedSuccess': [ar.cooSessionSavedSuccess, en.cooSessionSavedSuccess],
      'cooSaveError': [ar.cooSaveError('Disk full'), en.cooSaveError('Disk full')],
      'cooRegistryTitle': [ar.cooRegistryTitle, en.cooRegistryTitle],
      'cooReviewNewDraftButton': [ar.cooReviewNewDraftButton, en.cooReviewNewDraftButton],
      'cooNoReviewsYet': [ar.cooNoReviewsYet, en.cooNoReviewsYet],
      'cooRegistryColCode': [ar.cooRegistryColCode, en.cooRegistryColCode],
      'cooRegistryColType': [ar.cooRegistryColType, en.cooRegistryColType],
      'cooRegistryColNumber': [ar.cooRegistryColNumber, en.cooRegistryColNumber],
      'cooRegistryColExporter': [ar.cooRegistryColExporter, en.cooRegistryColExporter],
      'cooRegistryColStatus': [ar.cooRegistryColStatus, en.cooRegistryColStatus],
      'cooRegistryColDate': [ar.cooRegistryColDate, en.cooRegistryColDate],
      'cooRegistryColActions': [ar.cooRegistryColActions, en.cooRegistryColActions],
      'cooEditSessionTooltip': [ar.cooEditSessionTooltip, en.cooEditSessionTooltip],
      'cooViewDetailsTooltip': [ar.cooViewDetailsTooltip, en.cooViewDetailsTooltip],
      'cooDownloadPdfTooltip': [ar.cooDownloadPdfTooltip, en.cooDownloadPdfTooltip],
      'cooDeleteSessionTooltip': [ar.cooDeleteSessionTooltip, en.cooDeleteSessionTooltip],
      'cooLoadedSessionForEditSnackbar': [ar.cooLoadedSessionForEditSnackbar('COO-002'), en.cooLoadedSessionForEditSnackbar('COO-002')],
      'cooDetailsDialogTitle': [ar.cooDetailsDialogTitle('COO-002'), en.cooDetailsDialogTitle('COO-002')],
      'cooDetailsCertTypeAndNumber': [ar.cooDetailsCertTypeAndNumber, en.cooDetailsCertTypeAndNumber],
      'cooDetailsExporterAndImporter': [ar.cooDetailsExporterAndImporter, en.cooDetailsExporterAndImporter],
      'cooDetailsOriginAndDestination': [ar.cooDetailsOriginAndDestination, en.cooDetailsOriginAndDestination],
      'cooDetailsOverrideReason': [ar.cooDetailsOverrideReason, en.cooDetailsOverrideReason],
      'cooDetailsMatrixTitle': [ar.cooDetailsMatrixTitle, en.cooDetailsMatrixTitle],
      'cooDeleteDialogTitle': [ar.cooDeleteDialogTitle, en.cooDeleteDialogTitle],
      'cooDeleteDialogContent': [ar.cooDeleteDialogContent('COO-001', 'CERT-123'), en.cooDeleteDialogContent('COO-001', 'CERT-123')],
      'cooDeleteSuccessSnackbar': [ar.cooDeleteSuccessSnackbar, en.cooDeleteSuccessSnackbar],
      'cooDeleteErrorSnackbar': [ar.cooDeleteErrorSnackbar('Err'), en.cooDeleteErrorSnackbar('Err')],
      'cooVisualPreviewTitle': [ar.cooVisualPreviewTitle('EUR.1'), en.cooVisualPreviewTitle('EUR.1')],
      'cooVisualRefreshTooltip': [ar.cooVisualRefreshTooltip, en.cooVisualRefreshTooltip],
      'cooVisualCopyButton': [ar.cooVisualCopyButton, en.cooVisualCopyButton],
      'cooVisualCopiedSnackbar': [ar.cooVisualCopiedSnackbar, en.cooVisualCopiedSnackbar],
      'cooVisualExcelButton': [ar.cooVisualExcelButton, en.cooVisualExcelButton],
      'cooVisualExcelReadySnackbar': [ar.cooVisualExcelReadySnackbar, en.cooVisualExcelReadySnackbar],
      'cooVisualPrintPdfButton': [ar.cooVisualPrintPdfButton, en.cooVisualPrintPdfButton],
    };

    test('All Screen 19 getters should have non-empty Arabic and English translations', () {
      expect(screen19Getters.length, greaterThanOrEqualTo(50));
      for (final entry in screen19Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: 'Arabic translation for $key is empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: 'English translation for $key is empty');
      }
    });

    test('English translations should not contain Arabic characters', () {
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      for (final entry in screen19Getters.entries) {
        final key = entry.key;
        final enVal = entry.value[1];

        expect(
          arabicRegex.hasMatch(enVal),
          isFalse,
          reason: 'English translation for "$key" contains Arabic text: "$enVal"',
        );
      }
    });

    test('Translations should not contain stacked bilingual formatting like "Arabic / English"', () {
      for (final entry in screen19Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        // Should not have combined English-Arabic slash patterns in Arabic string
        expect(arVal.contains('بلد المنشأ / Country'), isFalse, reason: 'Stacked slash detected in ar: $key');
        expect(enVal.contains('Country / بلد'), isFalse, reason: 'Stacked slash detected in en: $key');
      }
    });
  });
}
