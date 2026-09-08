import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 18: Draft B/L Review & Dual Approval Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final draftBlGetters = <String, List<String>>{
      'draftBlStage0ReviewSheet': [ar.draftBlStage0ReviewSheet, en.draftBlStage0ReviewSheet],
      'draftBlStage1RevisionReport': [ar.draftBlStage1RevisionReport, en.draftBlStage1RevisionReport],
      'draftBlStage2VersionBranching': [ar.draftBlStage2VersionBranching, en.draftBlStage2VersionBranching],
      'draftBlStage3DualApproval': [ar.draftBlStage3DualApproval, en.draftBlStage3DualApproval],
      'draftBlStage4FinalRegistry': [ar.draftBlStage4FinalRegistry, en.draftBlStage4FinalRegistry],
      'draftBlReviewSheetTitle': [ar.draftBlReviewSheetTitle, en.draftBlReviewSheetTitle],
      'draftBlReviewSheetSub': [ar.draftBlReviewSheetSub, en.draftBlReviewSheetSub],
      'draftBlPerfectMatchReady': [ar.draftBlPerfectMatchReady, en.draftBlPerfectMatchReady],
      'draftBlSelectImportFileLabel': [ar.draftBlSelectImportFileLabel, en.draftBlSelectImportFileLabel],
      'draftBlRefreshAndCompare': [ar.draftBlRefreshAndCompare, en.draftBlRefreshAndCompare],
      'draftBlSmartExtractorTitle': [ar.draftBlSmartExtractorTitle, en.draftBlSmartExtractorTitle],
      'draftBlSmartExtractorSub': [ar.draftBlSmartExtractorSub, en.draftBlSmartExtractorSub],
      'draftBlUploadAndExtractButton': [ar.draftBlUploadAndExtractButton, en.draftBlUploadAndExtractButton],
      'draftBlExtractingFileProgress': [ar.draftBlExtractingFileProgress, en.draftBlExtractingFileProgress],
      'draftBlExtractedBlNumberLabel': [ar.draftBlExtractedBlNumberLabel, en.draftBlExtractedBlNumberLabel],
      'draftBlCopyBlNumberTooltip': [ar.draftBlCopyBlNumberTooltip, en.draftBlCopyBlNumberTooltip],
      'draftBlEditBlNumberTitle': [ar.draftBlEditBlNumberTitle, en.draftBlEditBlNumberTitle],
      'draftBlSafetyAlertTitle': [ar.draftBlSafetyAlertTitle, en.draftBlSafetyAlertTitle],
      'draftBlSafetyAlertSub': [ar.draftBlSafetyAlertSub, en.draftBlSafetyAlertSub],
      'draftBlSmartExtractionComplete': [ar.draftBlSmartExtractionComplete, en.draftBlSmartExtractionComplete],
      'draftBlPasteRawTextTitle': [ar.draftBlPasteRawTextTitle, en.draftBlPasteRawTextTitle],
      'draftBlPasteRawTextHint': [ar.draftBlPasteRawTextHint, en.draftBlPasteRawTextHint],
      'draftBlExtractFromTextButton': [ar.draftBlExtractFromTextButton, en.draftBlExtractFromTextButton],
      'draftBlReferenceVisualSheetTitle': [ar.draftBlReferenceVisualSheetTitle, en.draftBlReferenceVisualSheetTitle],
      'draftBlExtractedVisualSheetTitle': [ar.draftBlExtractedVisualSheetTitle, en.draftBlExtractedVisualSheetTitle],
      'draftBlSwitchToGridView': [ar.draftBlSwitchToGridView, en.draftBlSwitchToGridView],
      'draftBlSwitchToVisualBl': [ar.draftBlSwitchToVisualBl, en.draftBlSwitchToVisualBl],
      'draftBlAutoSummaryTitle': [ar.draftBlAutoSummaryTitle, en.draftBlAutoSummaryTitle],
      'draftBlAutoSummarySub': [ar.draftBlAutoSummarySub, en.draftBlAutoSummarySub],
      'draftBlSummaryShipper': [ar.draftBlSummaryShipper, en.draftBlSummaryShipper],
      'draftBlSummaryConsignee': [ar.draftBlSummaryConsignee, en.draftBlSummaryConsignee],
      'draftBlSummaryNotifyParty': [ar.draftBlSummaryNotifyParty, en.draftBlSummaryNotifyParty],
      'draftBlSummaryVesselVoyage': [ar.draftBlSummaryVesselVoyage, en.draftBlSummaryVesselVoyage],
      'draftBlSummaryPorts': [ar.draftBlSummaryPorts, en.draftBlSummaryPorts],
      'draftBlSummaryFreightTerms': [ar.draftBlSummaryFreightTerms, en.draftBlSummaryFreightTerms],
      'draftBlSummaryBookingNo': [ar.draftBlSummaryBookingNo, en.draftBlSummaryBookingNo],
      'draftBlSummaryAcidNo': [ar.draftBlSummaryAcidNo, en.draftBlSummaryAcidNo],
      'draftBlSummaryImporterTaxId': [ar.draftBlSummaryImporterTaxId, en.draftBlSummaryImporterTaxId],
      'draftBlSummaryShipperReg': [ar.draftBlSummaryShipperReg, en.draftBlSummaryShipperReg],
      'draftBlSummaryContainers': [ar.draftBlSummaryContainers, en.draftBlSummaryContainers],
      'draftBlSummaryGrossWeight': [ar.draftBlSummaryGrossWeight, en.draftBlSummaryGrossWeight],
      'draftBlSummaryNetWeight': [ar.draftBlSummaryNetWeight, en.draftBlSummaryNetWeight],
      'draftBlSummaryCbm': [ar.draftBlSummaryCbm, en.draftBlSummaryCbm],
      'draftBlSummaryPackages': [ar.draftBlSummaryPackages, en.draftBlSummaryPackages],
      'draftBlChecklistSectionTitle': [ar.draftBlChecklistSectionTitle, en.draftBlChecklistSectionTitle],
      'draftBlChecklistSectionSub': [ar.draftBlChecklistSectionSub, en.draftBlChecklistSectionSub],
      'draftBlSaveSessionButton': [ar.draftBlSaveSessionButton, en.draftBlSaveSessionButton],
      'draftBlRevisionReportCarrierButton': [ar.draftBlRevisionReportCarrierButton, en.draftBlRevisionReportCarrierButton],
      'draftBlChecklistColField': [ar.draftBlChecklistColField, en.draftBlChecklistColField],
      'draftBlChecklistColSystemValue': [ar.draftBlChecklistColSystemValue, en.draftBlChecklistColSystemValue],
      'draftBlChecklistColDraftValue': [ar.draftBlChecklistColDraftValue, en.draftBlChecklistColDraftValue],
      'draftBlChecklistColStatus': [ar.draftBlChecklistColStatus, en.draftBlChecklistColStatus],
      'draftBlChecklistColRequiredAction': [ar.draftBlChecklistColRequiredAction, en.draftBlChecklistColRequiredAction],
      'draftBlChecklistColResponsibleParty': [ar.draftBlChecklistColResponsibleParty, en.draftBlChecklistColResponsibleParty],
      'draftBlChecklistColReasonNotes': [ar.draftBlChecklistColReasonNotes, en.draftBlChecklistColReasonNotes],
      'draftBlStatusCorrect': [ar.draftBlStatusCorrect, en.draftBlStatusCorrect],
      'draftBlStatusIncorrect': [ar.draftBlStatusIncorrect, en.draftBlStatusIncorrect],
      'draftBlStatusNA': [ar.draftBlStatusNA, en.draftBlStatusNA],
      'draftBlPartyShippingLine': [ar.draftBlPartyShippingLine, en.draftBlPartyShippingLine],
      'draftBlPartySupplier': [ar.draftBlPartySupplier, en.draftBlPartySupplier],
      'draftBlPartyImporter': [ar.draftBlPartyImporter, en.draftBlPartyImporter],
      'draftBlPartyCustomsBroker': [ar.draftBlPartyCustomsBroker, en.draftBlPartyCustomsBroker],
      'draftBlCopySystemValueTooltip': [ar.draftBlCopySystemValueTooltip, en.draftBlCopySystemValueTooltip],
      'draftBlEnterDraftValueHint': [ar.draftBlEnterDraftValueHint, en.draftBlEnterDraftValueHint],
      'draftBlMatchedHint': [ar.draftBlMatchedHint, en.draftBlMatchedHint],
      'draftBlEnterCorrectionHint': [ar.draftBlEnterCorrectionHint, en.draftBlEnterCorrectionHint],
      'draftBlEnterReasonHint': [ar.draftBlEnterReasonHint, en.draftBlEnterReasonHint],
      'draftBlRevisionReportTitle': [ar.draftBlRevisionReportTitle, en.draftBlRevisionReportTitle],
      'draftBlRevisionReportSub': [ar.draftBlRevisionReportSub, en.draftBlRevisionReportSub],
      'draftBlProceedToVersionHistory': [ar.draftBlProceedToVersionHistory, en.draftBlProceedToVersionHistory],
      'draftBlNoAmendmentsNeeded': [ar.draftBlNoAmendmentsNeeded, en.draftBlNoAmendmentsNeeded],
      'draftBlRevisionColItem': [ar.draftBlRevisionColItem, en.draftBlRevisionColItem],
      'draftBlRevisionColRequiredAction': [ar.draftBlRevisionColRequiredAction, en.draftBlRevisionColRequiredAction],
      'draftBlRevisionColResponsible': [ar.draftBlRevisionColResponsible, en.draftBlRevisionColResponsible],
      'draftBlRevisionColReason': [ar.draftBlRevisionColReason, en.draftBlRevisionColReason],
      'draftBlCarrierRequestLetterTitle': [ar.draftBlCarrierRequestLetterTitle, en.draftBlCarrierRequestLetterTitle],
      'draftBlCopyLetterButton': [ar.draftBlCopyLetterButton, en.draftBlCopyLetterButton],
      'draftBlLetterCopiedSnackbar': [ar.draftBlLetterCopiedSnackbar, en.draftBlLetterCopiedSnackbar],
      'draftBlVersionBranchingTitle': [ar.draftBlVersionBranchingTitle, en.draftBlVersionBranchingTitle],
      'draftBlVersionBranchingSub': [ar.draftBlVersionBranchingSub, en.draftBlVersionBranchingSub],
      'draftBlProceedToDualApproval': [ar.draftBlProceedToDualApproval, en.draftBlProceedToDualApproval],
      'draftBlImporterApprovalTitle': [ar.draftBlImporterApprovalTitle, en.draftBlImporterApprovalTitle],
      'draftBlImporterApproverNameLabel': [ar.draftBlImporterApproverNameLabel, en.draftBlImporterApproverNameLabel],
      'draftBlImporterNotesLabel': [ar.draftBlImporterNotesLabel, en.draftBlImporterNotesLabel],
      'draftBlApproveAndAcceptButton': [ar.draftBlApproveAndAcceptButton, en.draftBlApproveAndAcceptButton],
      'draftBlRejectDraftButton': [ar.draftBlRejectDraftButton, en.draftBlRejectDraftButton],
      'draftBlBrokerApprovalTitle': [ar.draftBlBrokerApprovalTitle, en.draftBlBrokerApprovalTitle],
      'draftBlBrokerApproverNameLabel': [ar.draftBlBrokerApproverNameLabel, en.draftBlBrokerApproverNameLabel],
      'draftBlBrokerNotesLabel': [ar.draftBlBrokerNotesLabel, en.draftBlBrokerNotesLabel],
      'draftBlBrokerApproveButton': [ar.draftBlBrokerApproveButton, en.draftBlBrokerApproveButton],
      'draftBlFinalRegistryTitle': [ar.draftBlFinalRegistryTitle, en.draftBlFinalRegistryTitle],
      'draftBlFinalRegistrySub': [ar.draftBlFinalRegistrySub, en.draftBlFinalRegistrySub],
      'draftBlRefreshRegistry': [ar.draftBlRefreshRegistry, en.draftBlRefreshRegistry],
      'draftBlSearchRegistryHint': [ar.draftBlSearchRegistryHint, en.draftBlSearchRegistryHint],
      'draftBlRegistryColSessionId': [ar.draftBlRegistryColSessionId, en.draftBlRegistryColSessionId],
      'draftBlRegistryColBlNumber': [ar.draftBlRegistryColBlNumber, en.draftBlRegistryColBlNumber],
      'draftBlRegistryColShippingLine': [ar.draftBlRegistryColShippingLine, en.draftBlRegistryColShippingLine],
      'draftBlRegistryColVesselVoyage': [ar.draftBlRegistryColVesselVoyage, en.draftBlRegistryColVesselVoyage],
      'draftBlRegistryColStage': [ar.draftBlRegistryColStage, en.draftBlRegistryColStage],
      'draftBlRegistryColImporterApproval': [ar.draftBlRegistryColImporterApproval, en.draftBlRegistryColImporterApproval],
      'draftBlRegistryColBrokerApproval': [ar.draftBlRegistryColBrokerApproval, en.draftBlRegistryColBrokerApproval],
      'draftBlRegistryColStatus': [ar.draftBlRegistryColStatus, en.draftBlRegistryColStatus],
      'draftBlRegistryColActions': [ar.draftBlRegistryColActions, en.draftBlRegistryColActions],
      'draftBlViewBlTooltip': [ar.draftBlViewBlTooltip, en.draftBlViewBlTooltip],
      'draftBlPrintBlTooltip': [ar.draftBlPrintBlTooltip, en.draftBlPrintBlTooltip],
      'draftBlDownloadPdfTooltip': [ar.draftBlDownloadPdfTooltip, en.draftBlDownloadPdfTooltip],
      'draftBlPrintButton': [ar.draftBlPrintButton, en.draftBlPrintButton],
      'draftBlDownloadPdfButton': [ar.draftBlDownloadPdfButton, en.draftBlDownloadPdfButton],
      'draftBlDownloadExcelButton': [ar.draftBlDownloadExcelButton, en.draftBlDownloadExcelButton],
      'draftBlSessionSavedSuccess': [ar.draftBlSessionSavedSuccess, en.draftBlSessionSavedSuccess],
      'draftBlSessionSaveError': [ar.draftBlSessionSaveError, en.draftBlSessionSaveError],
      'draftBlComparisonMatchSuccess': [ar.draftBlComparisonMatchSuccess, en.draftBlComparisonMatchSuccess],
      'draftBlFileReadError': [ar.draftBlFileReadError, en.draftBlFileReadError],
      'draftBlDualApprovalCompleted': [ar.draftBlDualApprovalCompleted, en.draftBlDualApprovalCompleted],
      'draftBlRevisionRequiredAlert': [ar.draftBlRevisionRequiredAlert, en.draftBlRevisionRequiredAlert],
      'draftBlPdfExportSuccess': [ar.draftBlPdfExportSuccess, en.draftBlPdfExportSuccess],
      'searchFileOrShipmentHint': [ar.searchFileOrShipmentHint, en.searchFileOrShipmentHint],
      'searchFileOrCompanyHint': [ar.searchFileOrCompanyHint, en.searchFileOrCompanyHint],
      'unspecified': [ar.unspecified, en.unspecified],
      'draftBlNoLetterGeneratedYet': [ar.draftBlNoLetterGeneratedYet, en.draftBlNoLetterGeneratedYet],
      'draftBlRegistryUpdatedSuccess': [ar.draftBlRegistryUpdatedSuccess, en.draftBlRegistryUpdatedSuccess],
      'draftBlComparisonMismatch': [ar.draftBlComparisonMismatch(3), en.draftBlComparisonMismatch(3)],
      'draftBlComparisonError': [ar.draftBlComparisonError('timeout'), en.draftBlComparisonError('timeout')],
      'draftBlExtractedWithCritical': [ar.draftBlExtractedWithCritical('doc.pdf'), en.draftBlExtractedWithCritical('doc.pdf')],
      'draftBlExtractedSuccess': [ar.draftBlExtractedSuccess('doc.pdf'), en.draftBlExtractedSuccess('doc.pdf')],
      'draftBlExtractionError': [ar.draftBlExtractionError('parse error'), en.draftBlExtractionError('parse error')],
      'draftBlRoleApprovalRegistered': [ar.draftBlRoleApprovalRegistered('importer'), en.draftBlRoleApprovalRegistered('importer')],
      'draftBlApprovalError': [ar.draftBlApprovalError('auth failure'), en.draftBlApprovalError('auth failure')],
      'draftBlPdfExportError': [ar.draftBlPdfExportError('disk full'), en.draftBlPdfExportError('disk full')],
      'draftBlPrintError': [ar.draftBlPrintError('offline'), en.draftBlPrintError('offline')],
      'draftBlPreviewSessionSnack': [ar.draftBlPreviewSessionSnack(10, 'BL12345'), en.draftBlPreviewSessionSnack(10, 'BL12345')],
    };

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    test('All Screen 18 getters are defined and non-empty in Arabic & English', () {
      expect(draftBlGetters.length, greaterThanOrEqualTo(100));
      for (final entry in draftBlGetters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: '$key (Arabic) must not be empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: '$key (English) must not be empty');
      }
    });

    test('English strings contain no Arabic characters and no stacked bilingual slashes', () {
      for (final entry in draftBlGetters.entries) {
        final key = entry.key;
        final enVal = entry.value[1];

        expect(
          arabicRegex.hasMatch(enVal),
          isFalse,
          reason: 'English key "$key" contains Arabic: "$enVal"',
        );

        if (enVal.contains('/') && !key.toLowerCase().contains('date') && !key.toLowerCase().contains('url')) {
          expect(
            enVal,
            isNot(contains(' / ')),
            reason: 'English key "$key" contains stacked bilingual slash: "$enVal"',
          );
        }
      }
    });

    test('Arabic strings contain Arabic characters and no dual bilingual slashes', () {
      for (final entry in draftBlGetters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];

        // Status "N/A" might be symbolic, but general strings should have Arabic
        if (key != 'draftBlStatusNA') {
          expect(
            arabicRegex.hasMatch(arVal),
            isTrue,
            reason: 'Arabic key "$key" does not contain Arabic text: "$arVal"',
          );
        }

        expect(
          arVal,
          isNot(contains(' / ')),
          reason: 'Arabic key "$key" contains stacked bilingual slash: "$arVal"',
        );
      }
    });
  });
}
