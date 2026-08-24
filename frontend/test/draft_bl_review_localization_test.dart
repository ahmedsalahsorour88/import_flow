import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 18: Draft B/L Review Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final screen18Getters = <String, List<String>>{
      'draftBlStage0ReviewSheet': [ar.draftBlStage0ReviewSheet, en.draftBlStage0ReviewSheet],
      'draftBlStage1RevisionReport': [ar.draftBlStage1RevisionReport, en.draftBlStage1RevisionReport],
      'draftBlStage2VersionBranching': [ar.draftBlStage2VersionBranching, en.draftBlStage2VersionBranching],
      'draftBlStage3DualApproval': [ar.draftBlStage3DualApproval, en.draftBlStage3DualApproval],
      'draftBlStage4FinalRegistry': [ar.draftBlStage4FinalRegistry, en.draftBlStage4FinalRegistry],
      'draftBlReviewSheetTitle': [ar.draftBlReviewSheetTitle, en.draftBlReviewSheetTitle],
      'draftBlReviewSheetSub': [ar.draftBlReviewSheetSub, en.draftBlReviewSheetSub],
      'draftBlDownloadPdfButton': [ar.draftBlDownloadPdfButton, en.draftBlDownloadPdfButton],
      'draftBlDownloadExcelButton': [ar.draftBlDownloadExcelButton, en.draftBlDownloadExcelButton],
      'draftBlMismatchesFound': [ar.draftBlMismatchesFound(3), en.draftBlMismatchesFound(3)],
      'draftBlPerfectMatchReady': [ar.draftBlPerfectMatchReady, en.draftBlPerfectMatchReady],
      'draftBlSelectImportFileLabel': [ar.draftBlSelectImportFileLabel, en.draftBlSelectImportFileLabel],
      'draftBlRefreshAndCompare': [ar.draftBlRefreshAndCompare, en.draftBlRefreshAndCompare],
      'draftBlSmartExtractorTitle': [ar.draftBlSmartExtractorTitle, en.draftBlSmartExtractorTitle],
      'draftBlSmartExtractorSub': [ar.draftBlSmartExtractorSub, en.draftBlSmartExtractorSub],
      'draftBlExtractingFileProgress': [ar.draftBlExtractingFileProgress, en.draftBlExtractingFileProgress],
      'draftBlUploadAndExtractButton': [ar.draftBlUploadAndExtractButton, en.draftBlUploadAndExtractButton],
      'draftBlFileExtractedSuccess': [ar.draftBlFileExtractedSuccess('test.pdf', '150.2'), en.draftBlFileExtractedSuccess('test.pdf', '150.2')],
      'draftBlReuploadTooltip': [ar.draftBlReuploadTooltip, en.draftBlReuploadTooltip],
      'draftBlExtractedBlNumberLabel': [ar.draftBlExtractedBlNumberLabel, en.draftBlExtractedBlNumberLabel],
      'draftBlCopiedBlNumberSnackbar': [ar.draftBlCopiedBlNumberSnackbar('MEDU987654'), en.draftBlCopiedBlNumberSnackbar('MEDU987654')],
      'draftBlCopyBlNumberTooltip': [ar.draftBlCopyBlNumberTooltip, en.draftBlCopyBlNumberTooltip],
      'draftBlEditBlNumberTitle': [ar.draftBlEditBlNumberTitle, en.draftBlEditBlNumberTitle],
      'draftBlSafetyAlertTitle': [ar.draftBlSafetyAlertTitle, en.draftBlSafetyAlertTitle],
      'draftBlSafetyAlertSub': [ar.draftBlSafetyAlertSub, en.draftBlSafetyAlertSub],
      'draftBlSmartExtractionComplete': [ar.draftBlSmartExtractionComplete, en.draftBlSmartExtractionComplete],
      'draftBlPasteRawTextTitle': [ar.draftBlPasteRawTextTitle, en.draftBlPasteRawTextTitle],
      'draftBlPasteRawTextHint': [ar.draftBlPasteRawTextHint, en.draftBlPasteRawTextHint],
      'draftBlExtractFromTextButton': [ar.draftBlExtractFromTextButton, en.draftBlExtractFromTextButton],
      'draftBlReferenceVisualSheetTitle': [ar.draftBlReferenceVisualSheetTitle, en.draftBlReferenceVisualSheetTitle],
      'draftBlReferenceVisualSheetSub': [ar.draftBlReferenceVisualSheetSub, en.draftBlReferenceVisualSheetSub],
      'draftBlSwitchToGridView': [ar.draftBlSwitchToGridView, en.draftBlSwitchToGridView],
      'draftBlAutoSummaryTitle': [ar.draftBlAutoSummaryTitle, en.draftBlAutoSummaryTitle],
      'draftBlAutoSummarySub': [ar.draftBlAutoSummarySub, en.draftBlAutoSummarySub],
      'draftBlSwitchToVisualBl': [ar.draftBlSwitchToVisualBl, en.draftBlSwitchToVisualBl],
      'draftBlPrintButton': [ar.draftBlPrintButton, en.draftBlPrintButton],
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
      'draftBlSelectFileToStartChecklist': [ar.draftBlSelectFileToStartChecklist, en.draftBlSelectFileToStartChecklist],
      'draftBlChecklistColField': [ar.draftBlChecklistColField, en.draftBlChecklistColField],
      'draftBlChecklistColSystemValue': [ar.draftBlChecklistColSystemValue, en.draftBlChecklistColSystemValue],
      'draftBlChecklistColDraftValue': [ar.draftBlChecklistColDraftValue, en.draftBlChecklistColDraftValue],
      'draftBlChecklistColStatus': [ar.draftBlChecklistColStatus, en.draftBlChecklistColStatus],
      'draftBlChecklistColRequiredAction': [ar.draftBlChecklistColRequiredAction, en.draftBlChecklistColRequiredAction],
      'draftBlChecklistColResponsibleParty': [ar.draftBlChecklistColResponsibleParty, en.draftBlChecklistColResponsibleParty],
      'draftBlChecklistColReasonNotes': [ar.draftBlChecklistColReasonNotes, en.draftBlChecklistColReasonNotes],
      'draftBlEnterDraftValueHint': [ar.draftBlEnterDraftValueHint, en.draftBlEnterDraftValueHint],
      'draftBlCopySystemValueTooltip': [ar.draftBlCopySystemValueTooltip, en.draftBlCopySystemValueTooltip],
      'draftBlStatusCorrect': [ar.draftBlStatusCorrect, en.draftBlStatusCorrect],
      'draftBlStatusIncorrect': [ar.draftBlStatusIncorrect, en.draftBlStatusIncorrect],
      'draftBlStatusNA': [ar.draftBlStatusNA, en.draftBlStatusNA],
      'draftBlMatchedHint': [ar.draftBlMatchedHint, en.draftBlMatchedHint],
      'draftBlEnterCorrectionHint': [ar.draftBlEnterCorrectionHint, en.draftBlEnterCorrectionHint],
      'draftBlPartyShippingLine': [ar.draftBlPartyShippingLine, en.draftBlPartyShippingLine],
      'draftBlPartySupplier': [ar.draftBlPartySupplier, en.draftBlPartySupplier],
      'draftBlPartyImporter': [ar.draftBlPartyImporter, en.draftBlPartyImporter],
      'draftBlPartyCustomsBroker': [ar.draftBlPartyCustomsBroker, en.draftBlPartyCustomsBroker],
      'draftBlEnterReasonHint': [ar.draftBlEnterReasonHint, en.draftBlEnterReasonHint],
      'draftBlExtractedVisualSheetTitle': [ar.draftBlExtractedVisualSheetTitle, en.draftBlExtractedVisualSheetTitle],
      'draftBlExtractedVisualSheetSub': [ar.draftBlExtractedVisualSheetSub, en.draftBlExtractedVisualSheetSub],
      'draftBlSelectFileToViewRevision': [ar.draftBlSelectFileToViewRevision, en.draftBlSelectFileToViewRevision],
      'draftBlBackToSelectFile': [ar.draftBlBackToSelectFile, en.draftBlBackToSelectFile],
      'draftBlRevisionReportTitle': [ar.draftBlRevisionReportTitle, en.draftBlRevisionReportTitle],
      'draftBlProceedToVersionHistory': [ar.draftBlProceedToVersionHistory, en.draftBlProceedToVersionHistory],
      'draftBlRevisionReportSub': [ar.draftBlRevisionReportSub, en.draftBlRevisionReportSub],
      'draftBlNoAmendmentsNeeded': [ar.draftBlNoAmendmentsNeeded, en.draftBlNoAmendmentsNeeded],
      'draftBlRevisionColItem': [ar.draftBlRevisionColItem, en.draftBlRevisionColItem],
      'draftBlRevisionColRequiredAction': [ar.draftBlRevisionColRequiredAction, en.draftBlRevisionColRequiredAction],
      'draftBlRevisionColResponsible': [ar.draftBlRevisionColResponsible, en.draftBlRevisionColResponsible],
      'draftBlRevisionColReason': [ar.draftBlRevisionColReason, en.draftBlRevisionColReason],
      'draftBlCarrierRequestLetterTitle': [ar.draftBlCarrierRequestLetterTitle, en.draftBlCarrierRequestLetterTitle],
      'draftBlCopyLetterButton': [ar.draftBlCopyLetterButton, en.draftBlCopyLetterButton],
      'draftBlLetterCopiedSnackbar': [ar.draftBlLetterCopiedSnackbar, en.draftBlLetterCopiedSnackbar],
      'draftBlSelectFileToViewVersions': [ar.draftBlSelectFileToViewVersions, en.draftBlSelectFileToViewVersions],
      'draftBlVersionBranchingTitle': [ar.draftBlVersionBranchingTitle, en.draftBlVersionBranchingTitle],
      'draftBlProceedToDualApproval': [ar.draftBlProceedToDualApproval, en.draftBlProceedToDualApproval],
      'draftBlVersionBranchingSub': [ar.draftBlVersionBranchingSub, en.draftBlVersionBranchingSub],
      'draftBlActiveVersionBanner': [ar.draftBlActiveVersionBanner('v1', 'Stage 1', 12), en.draftBlActiveVersionBanner('v1', 'Stage 1', 12)],
      'draftBlSelectFileToCompleteApproval': [ar.draftBlSelectFileToCompleteApproval, en.draftBlSelectFileToCompleteApproval],
      'draftBlApprovalBlockedTitle': [ar.draftBlApprovalBlockedTitle, en.draftBlApprovalBlockedTitle],
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
      'draftBlRefreshRegistry': [ar.draftBlRefreshRegistry, en.draftBlRefreshRegistry],
      'draftBlFinalRegistrySub': [ar.draftBlFinalRegistrySub, en.draftBlFinalRegistrySub],
      'draftBlSearchRegistryHint': [ar.draftBlSearchRegistryHint, en.draftBlSearchRegistryHint],
      'draftBlNoRegistriesFound': [ar.draftBlNoRegistriesFound, en.draftBlNoRegistriesFound],
      'draftBlNoRegistriesYet': [ar.draftBlNoRegistriesYet, en.draftBlNoRegistriesYet],
      'draftBlTryDifferentSearch': [ar.draftBlTryDifferentSearch, en.draftBlTryDifferentSearch],
      'draftBlExtractNewDraftHint': [ar.draftBlExtractNewDraftHint, en.draftBlExtractNewDraftHint],
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
    };

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    test('All Screen 18 getters are defined and non-empty in Arabic & English', () {
      expect(screen18Getters.length, greaterThanOrEqualTo(80));
      for (final entry in screen18Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: '$key (Arabic) must not be empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: '$key (English) must not be empty');
      }
    });

    test('English strings must never contain Arabic characters', () {
      for (final entry in screen18Getters.entries) {
        final key = entry.key;
        final enVal = entry.value[1];
        expect(
          arabicRegex.hasMatch(enVal),
          isFalse,
          reason: 'English key "$key" contains Arabic text: "$enVal"',
        );
      }
    });

    test('No getters contain stacked bilingual text patterns', () {
      final stackedBilingualPatterns = [
        '(Review Sheet & Checklist)',
        '(Revision Report)',
        '(Version Branching)',
        '(Dual Approval Workspace)',
        '(Final Certified B/L)',
        '(Draft B/L Document Review Sheet)',
        '(Auto Generated Shipment Summary)',
        '(Shipper)',
        '(Consignee)',
        '(Notify Party)',
        '(Vessel/Voyage)',
        '(Freight Terms)',
        '(Booking No)',
        '(ACID No)',
        '(Shipper Reg)',
        '(Containers)',
        '(Gross Weight)',
        '(Net Weight)',
        '(Field Name)',
        '(System Value)',
        '(Draft Value)',
        '(Status)',
        '(Importer Approval)',
        '(Broker Approval)',
        '(B/L No.)',
        '(Final Certified Registry)',
      ];

      for (final entry in screen18Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        for (final pattern in stackedBilingualPatterns) {
          expect(arVal.contains(pattern), isFalse, reason: 'Arabic key "$key" contains stacked pattern "$pattern"');
          expect(enVal.contains(pattern), isFalse, reason: 'English key "$key" contains stacked pattern "$pattern"');
        }
      }
    });
  });
}
