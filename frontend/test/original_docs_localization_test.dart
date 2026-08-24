import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 57: Original Documents Collection & Courier Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 57 getters return non-empty strings and no missing translations', () {
      // Titles and tabs
      expect(ar.originalDocsAndCargoXScaffoldTitle.isNotEmpty, true);
      expect(en.originalDocsAndCargoXScaffoldTitle.isNotEmpty, true);
      expect(ar.originalDocsCollectionTabTitle.isNotEmpty, true);
      expect(en.originalDocsCollectionTabTitle.isNotEmpty, true);
      expect(ar.cargoxBlockchainTabTitle.isNotEmpty, true);
      expect(en.cargoxBlockchainTabTitle.isNotEmpty, true);
      expect(ar.refreshDataTooltip.isNotEmpty, true);
      expect(en.refreshDataTooltip.isNotEmpty, true);

      // Header & Hub info
      expect(ar.originalDocsHubTitle.isNotEmpty, true);
      expect(en.originalDocsHubTitle.isNotEmpty, true);
      expect(ar.originalDocsHubSubtitle.isNotEmpty, true);
      expect(en.originalDocsHubSubtitle.isNotEmpty, true);
      expect(ar.savedSessionBadge('DOC-001'), contains('DOC-001'));
      expect(en.savedSessionBadge('DOC-001'), contains('DOC-001'));

      // File selector
      expect(ar.selectImportFileLabel.isNotEmpty, true);
      expect(en.selectImportFileLabel.isNotEmpty, true);
      expect(ar.selectImportFileHint.isNotEmpty, true);
      expect(en.selectImportFileHint.isNotEmpty, true);
      expect(ar.errorFetchingImportFiles('Err'), contains('Err'));
      expect(en.errorFetchingImportFiles('Err'), contains('Err'));
      expect(ar.errorFetchingArchiveData('Err'), contains('Err'));
      expect(en.errorFetchingArchiveData('Err'), contains('Err'));

      // Statistics cards
      expect(ar.statTotalRequiredDocs.isNotEmpty, true);
      expect(en.statTotalRequiredDocs.isNotEmpty, true);
      expect(ar.statReceivedOriginals.isNotEmpty, true);
      expect(en.statReceivedOriginals.isNotEmpty, true);
      expect(ar.statVerifiedDocs.isNotEmpty, true);
      expect(en.statVerifiedDocs.isNotEmpty, true);
      expect(ar.statPendingDocs.isNotEmpty, true);
      expect(en.statPendingDocs.isNotEmpty, true);
      expect(ar.statReadinessRate.isNotEmpty, true);
      expect(en.statReadinessRate.isNotEmpty, true);

      // Courier packages
      expect(ar.courierDispatchPackagesHeader.isNotEmpty, true);
      expect(en.courierDispatchPackagesHeader.isNotEmpty, true);
      expect(ar.addCourierAwbBtn.isNotEmpty, true);
      expect(en.addCourierAwbBtn.isNotEmpty, true);
      expect(ar.noCouriersRegisteredMsg.isNotEmpty, true);
      expect(en.noCouriersRegisteredMsg.isNotEmpty, true);
      expect(ar.courierTrackingNoField.isNotEmpty, true);
      expect(en.courierTrackingNoField.isNotEmpty, true);
      expect(ar.courierCompanyField.isNotEmpty, true);
      expect(en.courierCompanyField.isNotEmpty, true);
      expect(ar.dispatchDateField.isNotEmpty, true);
      expect(en.dispatchDateField.isNotEmpty, true);
      expect(ar.isReceivedCheckbox.isNotEmpty, true);
      expect(en.isReceivedCheckbox.isNotEmpty, true);
      expect(ar.receivedByNameField.isNotEmpty, true);
      expect(en.receivedByNameField.isNotEmpty, true);
      expect(ar.deleteCourierTooltip.isNotEmpty, true);
      expect(en.deleteCourierTooltip.isNotEmpty, true);

      // Verification Matrix Table
      expect(ar.physicalDocsVerificationMatrixHeader.isNotEmpty, true);
      expect(en.physicalDocsVerificationMatrixHeader.isNotEmpty, true);
      expect(ar.addCustomDocBtn.isNotEmpty, true);
      expect(en.addCustomDocBtn.isNotEmpty, true);
      expect(ar.defaultNewCustomDocName.isNotEmpty, true);
      expect(en.defaultNewCustomDocName.isNotEmpty, true);
      expect(ar.selectCourierPlaceholder.isNotEmpty, true);
      expect(en.selectCourierPlaceholder.isNotEmpty, true);
      expect(ar.colCourierNo.isNotEmpty, true);
      expect(en.colCourierNo.isNotEmpty, true);
      expect(ar.colDocCategory.isNotEmpty, true);
      expect(en.colDocCategory.isNotEmpty, true);
      expect(ar.colDocName.isNotEmpty, true);
      expect(en.colDocName.isNotEmpty, true);
      expect(ar.colRequirement.isNotEmpty, true);
      expect(en.colRequirement.isNotEmpty, true);
      expect(ar.colResponsibleParty.isNotEmpty, true);
      expect(en.colResponsibleParty.isNotEmpty, true);
      expect(ar.colPhysicalReceived.isNotEmpty, true);
      expect(en.colPhysicalReceived.isNotEmpty, true);
      expect(ar.colReceivedDate.isNotEmpty, true);
      expect(en.colReceivedDate.isNotEmpty, true);
      expect(ar.colVerified.isNotEmpty, true);
      expect(en.colVerified.isNotEmpty, true);
      expect(ar.colAuditor.isNotEmpty, true);
      expect(en.colAuditor.isNotEmpty, true);
      expect(ar.colDocStatus.isNotEmpty, true);
      expect(en.colDocStatus.isNotEmpty, true);
      expect(ar.colRemarks.isNotEmpty, true);
      expect(en.colRemarks.isNotEmpty, true);
      expect(ar.colAction.isNotEmpty, true);
      expect(en.colAction.isNotEmpty, true);
      expect(ar.hintAuditor.isNotEmpty, true);
      expect(en.hintAuditor.isNotEmpty, true);
      expect(ar.hintRemarks.isNotEmpty, true);
      expect(en.hintRemarks.isNotEmpty, true);

      // Badges
      expect(ar.reqBadgeYes.isNotEmpty, true);
      expect(en.reqBadgeYes.isNotEmpty, true);
      expect(ar.reqBadgeConditional.isNotEmpty, true);
      expect(en.reqBadgeConditional.isNotEmpty, true);
      expect(ar.reqBadgeNo.isNotEmpty, true);
      expect(en.reqBadgeNo.isNotEmpty, true);
      expect(ar.statusBadgeVerified.isNotEmpty, true);
      expect(en.statusBadgeVerified.isNotEmpty, true);
      expect(ar.statusBadgeReceived.isNotEmpty, true);
      expect(en.statusBadgeReceived.isNotEmpty, true);
      expect(ar.statusBadgeInTransit.isNotEmpty, true);
      expect(en.statusBadgeInTransit.isNotEmpty, true);
      expect(ar.statusBadgeDiscrepant.isNotEmpty, true);
      expect(en.statusBadgeDiscrepant.isNotEmpty, true);
      expect(ar.statusBadgePending.isNotEmpty, true);
      expect(en.statusBadgePending.isNotEmpty, true);

      // Notes & Override
      expect(ar.sessionNotesLabel.isNotEmpty, true);
      expect(en.sessionNotesLabel.isNotEmpty, true);
      expect(ar.overrideReasonLabel.isNotEmpty, true);
      expect(en.overrideReasonLabel.isNotEmpty, true);

      // Actions Toolbar & feedback
      expect(ar.saveDraftSessionBtn.isNotEmpty, true);
      expect(en.saveDraftSessionBtn.isNotEmpty, true);
      expect(ar.completeCollectionBtn.isNotEmpty, true);
      expect(en.completeCollectionBtn.isNotEmpty, true);
      expect(ar.exportExcelBtn.isNotEmpty, true);
      expect(en.exportExcelBtn.isNotEmpty, true);
      expect(ar.unverifiedMandatoryDocsWarning.isNotEmpty, true);
      expect(en.unverifiedMandatoryDocsWarning.isNotEmpty, true);
      expect(ar.sessionSavedSuccess('SESS-1'), contains('SESS-1'));
      expect(en.sessionSavedSuccess('SESS-1'), contains('SESS-1'));
      expect(ar.sessionSaveError('Err'), contains('Err'));
      expect(en.sessionSaveError('Err'), contains('Err'));
      expect(ar.excelExportSuccess(1024), contains('1024'));
      expect(en.excelExportSuccess(1024), contains('1024'));
      expect(ar.excelExportError('Err'), contains('Err'));
      expect(en.excelExportError('Err'), contains('Err'));

      // Registry Section
      expect(ar.collectionRegistryHeader.isNotEmpty, true);
      expect(en.collectionRegistryHeader.isNotEmpty, true);
      expect(ar.searchRegistryHint.isNotEmpty, true);
      expect(en.searchRegistryHint.isNotEmpty, true);
      expect(ar.filterStatusAll.isNotEmpty, true);
      expect(en.filterStatusAll.isNotEmpty, true);
      expect(ar.filterStatusDraft.isNotEmpty, true);
      expect(en.filterStatusDraft.isNotEmpty, true);
      expect(ar.filterStatusPartiallyReceived.isNotEmpty, true);
      expect(en.filterStatusPartiallyReceived.isNotEmpty, true);
      expect(ar.filterStatusFullyReceived.isNotEmpty, true);
      expect(en.filterStatusFullyReceived.isNotEmpty, true);
      expect(ar.filterStatusFullyVerified.isNotEmpty, true);
      expect(en.filterStatusFullyVerified.isNotEmpty, true);
      expect(ar.noRegisteredSessionsFound.isNotEmpty, true);
      expect(en.noRegisteredSessionsFound.isNotEmpty, true);
      expect(ar.errorFetchingRegistry('Err'), contains('Err'));
      expect(en.errorFetchingRegistry('Err'), contains('Err'));

      expect(ar.colSessionCode.isNotEmpty, true);
      expect(en.colSessionCode.isNotEmpty, true);
      expect(ar.colImportFile.isNotEmpty, true);
      expect(en.colImportFile.isNotEmpty, true);
      expect(ar.colAcidNumber.isNotEmpty, true);
      expect(en.colAcidNumber.isNotEmpty, true);
      expect(ar.colSupplierName.isNotEmpty, true);
      expect(en.colSupplierName.isNotEmpty, true);
      expect(ar.colTotalDocs.isNotEmpty, true);
      expect(en.colTotalDocs.isNotEmpty, true);
      expect(ar.colReceivedDocs.isNotEmpty, true);
      expect(en.colReceivedDocs.isNotEmpty, true);
      expect(ar.colVerifiedDocs.isNotEmpty, true);
      expect(en.colVerifiedDocs.isNotEmpty, true);
      expect(ar.colCompletionPercentage.isNotEmpty, true);
      expect(en.colCompletionPercentage.isNotEmpty, true);
      expect(ar.colUpdatedAt.isNotEmpty, true);
      expect(en.colUpdatedAt.isNotEmpty, true);

      // Categories & Parties
      expect(ar.docCatCommercial.isNotEmpty, true);
      expect(en.docCatCommercial.isNotEmpty, true);
      expect(ar.docCatCertificate.isNotEmpty, true);
      expect(en.docCatCertificate.isNotEmpty, true);
      expect(ar.docCatShipping.isNotEmpty, true);
      expect(en.docCatShipping.isNotEmpty, true);
      expect(ar.docCatEgyptImport.isNotEmpty, true);
      expect(en.docCatEgyptImport.isNotEmpty, true);
      expect(ar.docCatBanking.isNotEmpty, true);
      expect(en.docCatBanking.isNotEmpty, true);
      expect(ar.docCatRegulatory.isNotEmpty, true);
      expect(en.docCatRegulatory.isNotEmpty, true);
      expect(ar.docCatOther.isNotEmpty, true);
      expect(en.docCatOther.isNotEmpty, true);

      expect(ar.courierCompanyHandDelivery.isNotEmpty, true);
      expect(en.courierCompanyHandDelivery.isNotEmpty, true);
      expect(ar.courierCompanyOther.isNotEmpty, true);
      expect(en.courierCompanyOther.isNotEmpty, true);

      expect(ar.partySupplier.isNotEmpty, true);
      expect(en.partySupplier.isNotEmpty, true);
      expect(ar.partyFreightForwarder.isNotEmpty, true);
      expect(en.partyFreightForwarder.isNotEmpty, true);
      expect(ar.partyCustomsBroker.isNotEmpty, true);
      expect(en.partyCustomsBroker.isNotEmpty, true);
      expect(ar.partyBank.isNotEmpty, true);
      expect(en.partyBank.isNotEmpty, true);
      expect(ar.partyImporter.isNotEmpty, true);
      expect(en.partyImporter.isNotEmpty, true);
      expect(ar.partyCarrier.isNotEmpty, true);
      expect(en.partyCarrier.isNotEmpty, true);
    });

    test('Arabic strings must NOT contain English characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      expect(latinPattern.hasMatch(ar.originalDocsAndCargoXScaffoldTitle), false);
      expect(latinPattern.hasMatch(ar.originalDocsCollectionTabTitle), false);
      expect(latinPattern.hasMatch(ar.cargoxBlockchainTabTitle), false);
      expect(latinPattern.hasMatch(ar.refreshDataTooltip), false);
      expect(latinPattern.hasMatch(ar.originalDocsHubTitle), false);
      expect(latinPattern.hasMatch(ar.originalDocsHubSubtitle), false);
      expect(latinPattern.hasMatch(ar.selectImportFileLabel), false);
      expect(latinPattern.hasMatch(ar.selectImportFileHint), false);
      expect(latinPattern.hasMatch(ar.statTotalRequiredDocs), false);
      expect(latinPattern.hasMatch(ar.statReceivedOriginals), false);
      expect(latinPattern.hasMatch(ar.statVerifiedDocs), false);
      expect(latinPattern.hasMatch(ar.statPendingDocs), false);
      expect(latinPattern.hasMatch(ar.statReadinessRate), false);
      expect(latinPattern.hasMatch(ar.courierDispatchPackagesHeader), false);
      expect(latinPattern.hasMatch(ar.addCourierAwbBtn), false);
      expect(latinPattern.hasMatch(ar.noCouriersRegisteredMsg), false);
      expect(latinPattern.hasMatch(ar.courierTrackingNoField), false);
      expect(latinPattern.hasMatch(ar.courierCompanyField), false);
      expect(latinPattern.hasMatch(ar.dispatchDateField), false);
      expect(latinPattern.hasMatch(ar.isReceivedCheckbox), false);
      expect(latinPattern.hasMatch(ar.receivedByNameField), false);
      expect(latinPattern.hasMatch(ar.deleteCourierTooltip), false);
      expect(latinPattern.hasMatch(ar.physicalDocsVerificationMatrixHeader), false);
      expect(latinPattern.hasMatch(ar.addCustomDocBtn), false);
      expect(latinPattern.hasMatch(ar.defaultNewCustomDocName), false);
      expect(latinPattern.hasMatch(ar.selectCourierPlaceholder), false);
      expect(latinPattern.hasMatch(ar.colCourierNo), false);
      expect(latinPattern.hasMatch(ar.colDocCategory), false);
      expect(latinPattern.hasMatch(ar.colDocName), false);
      expect(latinPattern.hasMatch(ar.colRequirement), false);
      expect(latinPattern.hasMatch(ar.colResponsibleParty), false);
      expect(latinPattern.hasMatch(ar.colPhysicalReceived), false);
      expect(latinPattern.hasMatch(ar.colReceivedDate), false);
      expect(latinPattern.hasMatch(ar.colVerified), false);
      expect(latinPattern.hasMatch(ar.colAuditor), false);
      expect(latinPattern.hasMatch(ar.colDocStatus), false);
      expect(latinPattern.hasMatch(ar.colRemarks), false);
      expect(latinPattern.hasMatch(ar.colAction), false);
      expect(latinPattern.hasMatch(ar.hintAuditor), false);
      expect(latinPattern.hasMatch(ar.hintRemarks), false);
      expect(latinPattern.hasMatch(ar.reqBadgeYes), false);
      expect(latinPattern.hasMatch(ar.reqBadgeConditional), false);
      expect(latinPattern.hasMatch(ar.reqBadgeNo), false);
      expect(latinPattern.hasMatch(ar.statusBadgeVerified), false);
      expect(latinPattern.hasMatch(ar.statusBadgeReceived), false);
      expect(latinPattern.hasMatch(ar.statusBadgeInTransit), false);
      expect(latinPattern.hasMatch(ar.statusBadgeDiscrepant), false);
      expect(latinPattern.hasMatch(ar.statusBadgePending), false);
      expect(latinPattern.hasMatch(ar.saveDraftSessionBtn), false);
      expect(latinPattern.hasMatch(ar.completeCollectionBtn), false);
      expect(latinPattern.hasMatch(ar.exportExcelBtn), false);
      expect(latinPattern.hasMatch(ar.unverifiedMandatoryDocsWarning), false);
      expect(latinPattern.hasMatch(ar.collectionRegistryHeader), false);
      expect(latinPattern.hasMatch(ar.searchRegistryHint), false);
      expect(latinPattern.hasMatch(ar.filterStatusAll), false);
      expect(latinPattern.hasMatch(ar.filterStatusDraft), false);
      expect(latinPattern.hasMatch(ar.filterStatusPartiallyReceived), false);
      expect(latinPattern.hasMatch(ar.filterStatusFullyReceived), false);
      expect(latinPattern.hasMatch(ar.filterStatusFullyVerified), false);
      expect(latinPattern.hasMatch(ar.noRegisteredSessionsFound), false);
      expect(latinPattern.hasMatch(ar.colSessionCode), false);
      expect(latinPattern.hasMatch(ar.colImportFile), false);
      expect(latinPattern.hasMatch(ar.colAcidNumber), false);
      expect(latinPattern.hasMatch(ar.colSupplierName), false);
      expect(latinPattern.hasMatch(ar.colTotalDocs), false);
      expect(latinPattern.hasMatch(ar.colReceivedDocs), false);
      expect(latinPattern.hasMatch(ar.colVerifiedDocs), false);
      expect(latinPattern.hasMatch(ar.colCompletionPercentage), false);
      expect(latinPattern.hasMatch(ar.colUpdatedAt), false);
      expect(latinPattern.hasMatch(ar.docCatCommercial), false);
      expect(latinPattern.hasMatch(ar.docCatCertificate), false);
      expect(latinPattern.hasMatch(ar.docCatShipping), false);
      expect(latinPattern.hasMatch(ar.docCatEgyptImport), false);
      expect(latinPattern.hasMatch(ar.docCatBanking), false);
      expect(latinPattern.hasMatch(ar.docCatRegulatory), false);
      expect(latinPattern.hasMatch(ar.docCatOther), false);
      expect(latinPattern.hasMatch(ar.courierCompanyHandDelivery), false);
      expect(latinPattern.hasMatch(ar.courierCompanyOther), false);
      expect(latinPattern.hasMatch(ar.partySupplier), false);
      expect(latinPattern.hasMatch(ar.partyFreightForwarder), false);
      expect(latinPattern.hasMatch(ar.partyCustomsBroker), false);
      expect(latinPattern.hasMatch(ar.partyBank), false);
      expect(latinPattern.hasMatch(ar.partyImporter), false);
      expect(latinPattern.hasMatch(ar.partyCarrier), false);
      expect(latinPattern.hasMatch(ar.sessionNotesLabel), false);
      expect(latinPattern.hasMatch(ar.overrideReasonLabel), false);
    });

    test('Zero stacked bilingual text in Arabic or English getters', () {
      final stackedPattern = RegExp(r'[\u0600-\u06FF].*[a-zA-Z]|[a-zA-Z].*[\u0600-\u06FF]');

      // All Screen 57 Arabic getters must not contain stacked English
      expect(stackedPattern.hasMatch(ar.originalDocsAndCargoXScaffoldTitle), false);
      expect(stackedPattern.hasMatch(ar.originalDocsCollectionTabTitle), false);
      expect(stackedPattern.hasMatch(ar.cargoxBlockchainTabTitle), false);
      expect(stackedPattern.hasMatch(ar.originalDocsHubTitle), false);
      expect(stackedPattern.hasMatch(ar.originalDocsHubSubtitle), false);
      expect(stackedPattern.hasMatch(ar.courierDispatchPackagesHeader), false);
      expect(stackedPattern.hasMatch(ar.physicalDocsVerificationMatrixHeader), false);
      expect(stackedPattern.hasMatch(ar.collectionRegistryHeader), false);

      // All Screen 57 English getters must not contain stacked Arabic
      expect(stackedPattern.hasMatch(en.originalDocsAndCargoXScaffoldTitle), false);
      expect(stackedPattern.hasMatch(en.originalDocsCollectionTabTitle), false);
      expect(stackedPattern.hasMatch(en.cargoxBlockchainTabTitle), false);
      expect(stackedPattern.hasMatch(en.originalDocsHubTitle), false);
      expect(stackedPattern.hasMatch(en.originalDocsHubSubtitle), false);
      expect(stackedPattern.hasMatch(en.courierDispatchPackagesHeader), false);
      expect(stackedPattern.hasMatch(en.physicalDocsVerificationMatrixHeader), false);
      expect(stackedPattern.hasMatch(en.collectionRegistryHeader), false);
    });
  });
}
