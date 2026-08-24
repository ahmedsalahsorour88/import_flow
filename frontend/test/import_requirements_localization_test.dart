import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 43: Regulatory Requirements & Pre-Shipment Compliance Localization Tests', () {
    const AppLocalizations ar = AppLocalizationsAr();
    const AppLocalizations en = AppLocalizationsEn();

    test('Screen 43 Getters exist and are non-empty in both AR and EN', () {
      // Screen title and tabs
      expect(ar.importRequirementsScreenTitle.isNotEmpty, isTrue);
      expect(en.importRequirementsScreenTitle.isNotEmpty, isTrue);
      expect(ar.importRequirementsFormTab.isNotEmpty, isTrue);
      expect(en.importRequirementsFormTab.isNotEmpty, isTrue);
      expect(ar.importRequirementsRegistryTab.isNotEmpty, isTrue);
      expect(en.importRequirementsRegistryTab.isNotEmpty, isTrue);

      // Editing mode banner & cancel
      expect(ar.editingRequirementBanner('REQ-001').contains('REQ-001'), isTrue);
      expect(en.editingRequirementBanner('REQ-001').contains('REQ-001'), isTrue);
      expect(ar.cancelEditingAndStartNewBtn.isNotEmpty, isTrue);
      expect(en.cancelEditingAndStartNewBtn.isNotEmpty, isTrue);

      // Lifecycle Progress Card
      expect(ar.requirementsLifecycleCardTitle.isNotEmpty, isTrue);
      expect(en.requirementsLifecycleCardTitle.isNotEmpty, isTrue);
      expect(ar.sailingStatusBadge('Pre-Sailing').contains('Pre-Sailing'), isTrue);
      expect(en.sailingStatusBadge('Pre-Sailing').contains('Pre-Sailing'), isTrue);
      expect(ar.acidIssuanceStep.isNotEmpty, isTrue);
      expect(en.acidIssuanceStep.isNotEmpty, isTrue);
      expect(ar.preShipmentInspectionStep.isNotEmpty, isTrue);
      expect(en.preShipmentInspectionStep.isNotEmpty, isTrue);
      expect(ar.approvalsAndCertsStep.isNotEmpty, isTrue);
      expect(en.approvalsAndCertsStep.isNotEmpty, isTrue);
      expect(ar.sailingClearanceStep.isNotEmpty, isTrue);
      expect(en.sailingClearanceStep.isNotEmpty, isTrue);
      expect(ar.pendingInspectionCoordination.isNotEmpty, isTrue);
      expect(en.pendingInspectionCoordination.isNotEmpty, isTrue);
      expect(ar.completedAndPassedInspection.isNotEmpty, isTrue);
      expect(en.completedAndPassedInspection.isNotEmpty, isTrue);
      expect(ar.allCertsFulfilled100.isNotEmpty, isTrue);
      expect(en.allCertsFulfilled100.isNotEmpty, isTrue);
      expect(ar.pendingApprovals.isNotEmpty, isTrue);
      expect(en.pendingApprovals.isNotEmpty, isTrue);

      // Linked Import File and Consultation
      expect(ar.linkImportFileAndConsultationHeader.isNotEmpty, isTrue);
      expect(en.linkImportFileAndConsultationHeader.isNotEmpty, isTrue);
      expect(ar.consultationStudyBadge('CNS-101', 85).contains('CNS-101'), isTrue);
      expect(en.consultationStudyBadge('CNS-101', 85).contains('85'), isTrue);
      expect(ar.linkedImportFileFieldLabel.isNotEmpty, isTrue);
      expect(en.linkedImportFileFieldLabel.isNotEmpty, isTrue);
      expect(ar.selectImportFileHint.isNotEmpty, isTrue);
      expect(en.selectImportFileHint.isNotEmpty, isTrue);
      expect(ar.selectImportFileOption.isNotEmpty, isTrue);
      expect(en.selectImportFileOption.isNotEmpty, isTrue);
      expect(ar.acidNotIssued.isNotEmpty, isTrue);
      expect(en.acidNotIssued.isNotEmpty, isTrue);
      expect(ar.pleaseSelectImportFileError.isNotEmpty, isTrue);
      expect(en.pleaseSelectImportFileError.isNotEmpty, isTrue);
      expect(ar.acidNumberFieldLabel.isNotEmpty, isTrue);
      expect(en.acidNumberFieldLabel.isNotEmpty, isTrue);
      expect(ar.acidNumberRequiredError.isNotEmpty, isTrue);
      expect(en.acidNumberRequiredError.isNotEmpty, isTrue);
      expect(ar.foreignSupplierFieldLabel.isNotEmpty, isTrue);
      expect(en.foreignSupplierFieldLabel.isNotEmpty, isTrue);
      expect(ar.foreignSupplierHint.isNotEmpty, isTrue);
      expect(en.foreignSupplierHint.isNotEmpty, isTrue);
      expect(ar.notSpecifiedOption.isNotEmpty, isTrue);
      expect(en.notSpecifiedOption.isNotEmpty, isTrue);
      expect(ar.prefillImportRequirementSuccess(3, 'IMP-001').contains('IMP-001'), isTrue);
      expect(en.prefillImportRequirementSuccess(3, 'IMP-001').contains('IMP-001'), isTrue);

      // HS Codes Selector Card
      expect(ar.hsCodesSelectorCardTitle(2).contains('2'), isTrue);
      expect(en.hsCodesSelectorCardTitle(2).contains('2'), isTrue);
      expect(ar.totalHsValueBadge('5000', 'USD').contains('5000'), isTrue);
      expect(en.totalHsValueBadge('5000', 'USD').contains('USD'), isTrue);
      expect(ar.hsItemCodeLabel('8471.30', 'LAPTOP').contains('8471.30'), isTrue);
      expect(en.hsItemCodeLabel('8471.30', 'LAPTOP').contains('LAPTOP'), isTrue);
      expect(ar.hsItemDescLabel('Computer', '5000', 'USD').contains('Computer'), isTrue);
      expect(en.hsItemDescLabel('Computer', '5000', 'USD').contains('5000'), isTrue);
      expect(ar.hsCodeFieldLabel.isNotEmpty, isTrue);
      expect(en.hsCodeFieldLabel.isNotEmpty, isTrue);
      expect(ar.hsCodeRequiredError.isNotEmpty, isTrue);
      expect(en.hsCodeRequiredError.isNotEmpty, isTrue);
      expect(ar.commodityDescFieldLabel.isNotEmpty, isTrue);
      expect(en.commodityDescFieldLabel.isNotEmpty, isTrue);
      expect(ar.commodityDescRequiredError.isNotEmpty, isTrue);
      expect(en.commodityDescRequiredError.isNotEmpty, isTrue);
      expect(ar.countryOfOriginFieldLabel.isNotEmpty, isTrue);
      expect(en.countryOfOriginFieldLabel.isNotEmpty, isTrue);
      expect(ar.countryOfOriginRequiredError.isNotEmpty, isTrue);
      expect(en.countryOfOriginRequiredError.isNotEmpty, isTrue);
      expect(ar.currencyFieldLabel.isNotEmpty, isTrue);
      expect(en.currencyFieldLabel.isNotEmpty, isTrue);
      expect(ar.valueInCurrencyFieldLabel.isNotEmpty, isTrue);
      expect(en.valueInCurrencyFieldLabel.isNotEmpty, isTrue);

      // 5 Pillars Tabs
      expect(ar.pillar1Decree43Tab.isNotEmpty, isTrue);
      expect(en.pillar1Decree43Tab.isNotEmpty, isTrue);
      expect(ar.pillar2CooTab.isNotEmpty, isTrue);
      expect(en.pillar2CooTab.isNotEmpty, isTrue);
      expect(ar.pillar3InspectionTab.isNotEmpty, isTrue);
      expect(en.pillar3InspectionTab.isNotEmpty, isTrue);
      expect(ar.pillar4PermitsTab.isNotEmpty, isTrue);
      expect(en.pillar4PermitsTab.isNotEmpty, isTrue);
      expect(ar.pillar5TechCertsTab.isNotEmpty, isTrue);
      expect(en.pillar5TechCertsTab.isNotEmpty, isTrue);

      // Pillar 1: Decree 43
      expect(ar.pillar1Header.isNotEmpty, isTrue);
      expect(en.pillar1Header.isNotEmpty, isTrue);
      expect(ar.decree43ApplicableCheck.isNotEmpty, isTrue);
      expect(en.decree43ApplicableCheck.isNotEmpty, isTrue);
      expect(ar.decree43ApplicableSub.isNotEmpty, isTrue);
      expect(en.decree43ApplicableSub.isNotEmpty, isTrue);
      expect(ar.whiteListVerifiedCheck.isNotEmpty, isTrue);
      expect(en.whiteListVerifiedCheck.isNotEmpty, isTrue);
      expect(ar.whiteListVerifiedSub.isNotEmpty, isTrue);
      expect(en.whiteListVerifiedSub.isNotEmpty, isTrue);
      expect(ar.factoryRegNumFieldLabel.isNotEmpty, isTrue);
      expect(en.factoryRegNumFieldLabel.isNotEmpty, isTrue);
      expect(ar.factoryRegNumHint.isNotEmpty, isTrue);
      expect(en.factoryRegNumHint.isNotEmpty, isTrue);

      // Pillar 2: COO
      expect(ar.pillar2Header.isNotEmpty, isTrue);
      expect(en.pillar2Header.isNotEmpty, isTrue);
      expect(ar.cooRequiredCheck.isNotEmpty, isTrue);
      expect(en.cooRequiredCheck.isNotEmpty, isTrue);
      expect(ar.cooTypeFieldLabel.isNotEmpty, isTrue);
      expect(en.cooTypeFieldLabel.isNotEmpty, isTrue);
      expect(ar.cooTypeEur1Option.isNotEmpty, isTrue);
      expect(en.cooTypeEur1Option.isNotEmpty, isTrue);
      expect(ar.cooTypeFormAOption.isNotEmpty, isTrue);
      expect(en.cooTypeFormAOption.isNotEmpty, isTrue);
      expect(ar.cooTypeGaftaOption.isNotEmpty, isTrue);
      expect(en.cooTypeGaftaOption.isNotEmpty, isTrue);
      expect(ar.cooTypeComesaOption.isNotEmpty, isTrue);
      expect(en.cooTypeComesaOption.isNotEmpty, isTrue);
      expect(ar.cooTypeStandardChamberOption.isNotEmpty, isTrue);
      expect(en.cooTypeStandardChamberOption.isNotEmpty, isTrue);
      expect(ar.cooStatusFieldLabel.isNotEmpty, isTrue);
      expect(en.cooStatusFieldLabel.isNotEmpty, isTrue);
      expect(ar.cooStatusPendingOption.isNotEmpty, isTrue);
      expect(en.cooStatusPendingOption.isNotEmpty, isTrue);
      expect(ar.cooStatusObtainedOption.isNotEmpty, isTrue);
      expect(en.cooStatusObtainedOption.isNotEmpty, isTrue);
      expect(ar.cooStatusWaivedOption.isNotEmpty, isTrue);
      expect(en.cooStatusWaivedOption.isNotEmpty, isTrue);
      expect(ar.cooNotesFieldLabel.isNotEmpty, isTrue);
      expect(en.cooNotesFieldLabel.isNotEmpty, isTrue);
      expect(ar.cooNotesHint.isNotEmpty, isTrue);
      expect(en.cooNotesHint.isNotEmpty, isTrue);

      // Pillar 3: Inspection
      expect(ar.pillar3Header.isNotEmpty, isTrue);
      expect(en.pillar3Header.isNotEmpty, isTrue);
      expect(ar.inspectionRequiredCheck.isNotEmpty, isTrue);
      expect(en.inspectionRequiredCheck.isNotEmpty, isTrue);
      expect(ar.inspectionBodyFieldLabel.isNotEmpty, isTrue);
      expect(en.inspectionBodyFieldLabel.isNotEmpty, isTrue);
      expect(ar.inspectionBodySgsOption.isNotEmpty, isTrue);
      expect(en.inspectionBodySgsOption.isNotEmpty, isTrue);
      expect(ar.inspectionBodyBvOption.isNotEmpty, isTrue);
      expect(en.inspectionBodyBvOption.isNotEmpty, isTrue);
      expect(ar.inspectionBodyTuvOption.isNotEmpty, isTrue);
      expect(en.inspectionBodyTuvOption.isNotEmpty, isTrue);
      expect(ar.inspectionBodyIntertekOption.isNotEmpty, isTrue);
      expect(en.inspectionBodyIntertekOption.isNotEmpty, isTrue);
      expect(ar.inspectionBodyQimaOption.isNotEmpty, isTrue);
      expect(en.inspectionBodyQimaOption.isNotEmpty, isTrue);
      expect(ar.inspectionBodyIlacOption.isNotEmpty, isTrue);
      expect(en.inspectionBodyIlacOption.isNotEmpty, isTrue);
      expect(ar.inspectionStatusFieldLabel.isNotEmpty, isTrue);
      expect(en.inspectionStatusFieldLabel.isNotEmpty, isTrue);
      expect(ar.inspectionStatusPendingOption.isNotEmpty, isTrue);
      expect(en.inspectionStatusPendingOption.isNotEmpty, isTrue);
      expect(ar.inspectionStatusScheduledOption.isNotEmpty, isTrue);
      expect(en.inspectionStatusScheduledOption.isNotEmpty, isTrue);
      expect(ar.inspectionStatusCompletedOption.isNotEmpty, isTrue);
      expect(en.inspectionStatusCompletedOption.isNotEmpty, isTrue);
      expect(ar.inspectionStatusRejectedOption.isNotEmpty, isTrue);
      expect(en.inspectionStatusRejectedOption.isNotEmpty, isTrue);
      expect(ar.inspectionReportNumFieldLabel.isNotEmpty, isTrue);
      expect(en.inspectionReportNumFieldLabel.isNotEmpty, isTrue);
      expect(ar.inspectionNotesFieldLabel.isNotEmpty, isTrue);
      expect(en.inspectionNotesFieldLabel.isNotEmpty, isTrue);

      // Pillar 4: Permits
      expect(ar.pillar4Header.isNotEmpty, isTrue);
      expect(en.pillar4Header.isNotEmpty, isTrue);
      expect(ar.importPermitRequiredCheck.isNotEmpty, isTrue);
      expect(en.importPermitRequiredCheck.isNotEmpty, isTrue);
      expect(ar.issuingAuthorityFieldLabel.isNotEmpty, isTrue);
      expect(en.issuingAuthorityFieldLabel.isNotEmpty, isTrue);
      expect(ar.authorityEeaaOption.isNotEmpty, isTrue);
      expect(en.authorityEeaaOption.isNotEmpty, isTrue);
      expect(ar.authorityNfsaOption.isNotEmpty, isTrue);
      expect(en.authorityNfsaOption.isNotEmpty, isTrue);
      expect(ar.authorityEdaOption.isNotEmpty, isTrue);
      expect(en.authorityEdaOption.isNotEmpty, isTrue);
      expect(ar.authorityNtraOption.isNotEmpty, isTrue);
      expect(en.authorityNtraOption.isNotEmpty, isTrue);
      expect(ar.authorityPublicSecurityOption.isNotEmpty, isTrue);
      expect(en.authorityPublicSecurityOption.isNotEmpty, isTrue);
      expect(ar.authorityChemistryOption.isNotEmpty, isTrue);
      expect(en.authorityChemistryOption.isNotEmpty, isTrue);
      expect(ar.authorityGoeicOption.isNotEmpty, isTrue);
      expect(en.authorityGoeicOption.isNotEmpty, isTrue);
      expect(ar.permitStatusFieldLabel.isNotEmpty, isTrue);
      expect(en.permitStatusFieldLabel.isNotEmpty, isTrue);
      expect(ar.permitStatusAppliedOption.isNotEmpty, isTrue);
      expect(en.permitStatusAppliedOption.isNotEmpty, isTrue);
      expect(ar.permitStatusApprovedOption.isNotEmpty, isTrue);
      expect(en.permitStatusApprovedOption.isNotEmpty, isTrue);
      expect(ar.permitStatusRejectedOption.isNotEmpty, isTrue);
      expect(en.permitStatusRejectedOption.isNotEmpty, isTrue);
      expect(ar.permitNumberFieldLabel.isNotEmpty, isTrue);
      expect(en.permitNumberFieldLabel.isNotEmpty, isTrue);
      expect(ar.permitNotesFieldLabel.isNotEmpty, isTrue);
      expect(en.permitNotesFieldLabel.isNotEmpty, isTrue);

      // Pillar 5: Tech Certs & Sailing
      expect(ar.pillar5Header.isNotEmpty, isTrue);
      expect(en.pillar5Header.isNotEmpty, isTrue);
      expect(ar.msdsRequiredCheck.isNotEmpty, isTrue);
      expect(en.msdsRequiredCheck.isNotEmpty, isTrue);
      expect(ar.halalCertRequiredCheck.isNotEmpty, isTrue);
      expect(en.halalCertRequiredCheck.isNotEmpty, isTrue);
      expect(ar.coaRequiredCheck.isNotEmpty, isTrue);
      expect(en.coaRequiredCheck.isNotEmpty, isTrue);
      expect(ar.sailingStatusFieldLabel.isNotEmpty, isTrue);
      expect(en.sailingStatusFieldLabel.isNotEmpty, isTrue);
      expect(ar.sailingStatusPreSailingOption.isNotEmpty, isTrue);
      expect(en.sailingStatusPreSailingOption.isNotEmpty, isTrue);
      expect(ar.sailingStatusClearedOption.isNotEmpty, isTrue);
      expect(en.sailingStatusClearedOption.isNotEmpty, isTrue);
      expect(ar.sailingStatusSailedOption.isNotEmpty, isTrue);
      expect(en.sailingStatusSailedOption.isNotEmpty, isTrue);
      expect(ar.sailingDateFieldLabel.isNotEmpty, isTrue);
      expect(en.sailingDateFieldLabel.isNotEmpty, isTrue);
      expect(ar.riskLevelFieldLabel.isNotEmpty, isTrue);
      expect(en.riskLevelFieldLabel.isNotEmpty, isTrue);
      expect(ar.riskLevelLowOption.isNotEmpty, isTrue);
      expect(en.riskLevelLowOption.isNotEmpty, isTrue);
      expect(ar.riskLevelMediumOption.isNotEmpty, isTrue);
      expect(en.riskLevelMediumOption.isNotEmpty, isTrue);
      expect(ar.riskLevelHighOption.isNotEmpty, isTrue);
      expect(en.riskLevelHighOption.isNotEmpty, isTrue);
      expect(ar.overallStatusDraftOption.isNotEmpty, isTrue);
      expect(en.overallStatusDraftOption.isNotEmpty, isTrue);
      expect(ar.overallStatusInProgressOption.isNotEmpty, isTrue);
      expect(en.overallStatusInProgressOption.isNotEmpty, isTrue);
      expect(ar.overallStatusCompleteOption.isNotEmpty, isTrue);
      expect(en.overallStatusCompleteOption.isNotEmpty, isTrue);
      expect(ar.overallStatusConfirmedOption.isNotEmpty, isTrue);
      expect(en.overallStatusConfirmedOption.isNotEmpty, isTrue);

      // Buttons & Actions
      expect(ar.completeAllPillarsBtn.isNotEmpty, isTrue);
      expect(en.completeAllPillarsBtn.isNotEmpty, isTrue);
      expect(ar.completeAllPillarsSuccessSnack.isNotEmpty, isTrue);
      expect(en.completeAllPillarsSuccessSnack.isNotEmpty, isTrue);
      expect(ar.saveRequirementDraftBtn.isNotEmpty, isTrue);
      expect(en.saveRequirementDraftBtn.isNotEmpty, isTrue);
      expect(ar.updateRequirementSubmitBtn.isNotEmpty, isTrue);
      expect(en.updateRequirementSubmitBtn.isNotEmpty, isTrue);
      expect(ar.saveRequirementSubmitBtn.isNotEmpty, isTrue);
      expect(en.saveRequirementSubmitBtn.isNotEmpty, isTrue);
      expect(ar.fillRequiredFieldsError.isNotEmpty, isTrue);
      expect(en.fillRequiredFieldsError.isNotEmpty, isTrue);
      expect(ar.updateRequirementSuccessSnack('REQ-001').contains('REQ-001'), isTrue);
      expect(en.updateRequirementSuccessSnack('REQ-001').contains('REQ-001'), isTrue);
      expect(ar.createRequirementSuccessSnack.isNotEmpty, isTrue);
      expect(en.createRequirementSuccessSnack.isNotEmpty, isTrue);
      expect(ar.saveRequirementErrorTitle.isNotEmpty, isTrue);
      expect(en.saveRequirementErrorTitle.isNotEmpty, isTrue);
      expect(ar.goToSavedRequirementsBtn.isNotEmpty, isTrue);
      expect(en.goToSavedRequirementsBtn.isNotEmpty, isTrue);

      // Registry & Filters
      expect(ar.searchRequirementsHint.isNotEmpty, isTrue);
      expect(en.searchRequirementsHint.isNotEmpty, isTrue);
      expect(ar.complianceStatusFilterLabel.isNotEmpty, isTrue);
      expect(en.complianceStatusFilterLabel.isNotEmpty, isTrue);
      expect(ar.riskLevelFilterLabel.isNotEmpty, isTrue);
      expect(en.riskLevelFilterLabel.isNotEmpty, isTrue);
      expect(ar.activeDeletedFilterLabel.isNotEmpty, isTrue);
      expect(en.activeDeletedFilterLabel.isNotEmpty, isTrue);
      expect(ar.allRecordsActiveAndDeleted.isNotEmpty, isTrue);
      expect(en.allRecordsActiveAndDeleted.isNotEmpty, isTrue);
      expect(ar.activeOnlyOption.isNotEmpty, isTrue);
      expect(en.activeOnlyOption.isNotEmpty, isTrue);
      expect(ar.deletedOnlyOption.isNotEmpty, isTrue);
      expect(en.deletedOnlyOption.isNotEmpty, isTrue);
      expect(ar.noRequirementsFound.isNotEmpty, isTrue);
      expect(en.noRequirementsFound.isNotEmpty, isTrue);
      expect(ar.createNewRequirementBtn.isNotEmpty, isTrue);
      expect(en.createNewRequirementBtn.isNotEmpty, isTrue);
      expect(ar.requirementsFetchError('Server error').contains('Server error'), isTrue);
      expect(en.requirementsFetchError('Server error').contains('Server error'), isTrue);

      // Row Items & Badges
      expect(ar.fallbackImportingCompany.isNotEmpty, isTrue);
      expect(en.fallbackImportingCompany.isNotEmpty, isTrue);
      expect(ar.requirementRowSubtitle('8471', 'Computer', '500', 'USD', 'Sony', 'Japan').contains('8471'), isTrue);
      expect(ar.requirementRowSubtitle('8471', 'Computer', '500', 'USD', 'Sony', 'Japan').contains('Sony'), isTrue);
      expect(ar.sailingStatusBadgeRow('Cleared').contains('Cleared'), isTrue);
      expect(en.sailingStatusBadgeRow('Cleared').contains('Cleared'), isTrue);
      expect(ar.requirementStatusBadgeRow('Draft').contains('Draft'), isTrue);
      expect(en.requirementStatusBadgeRow('Draft').contains('Draft'), isTrue);
      expect(ar.riskLevelBadgeRow('Low').contains('Low'), isTrue);
      expect(en.riskLevelBadgeRow('Low').contains('Low'), isTrue);
      expect(ar.hsItemsCountBadge(4).contains('4'), isTrue);
      expect(en.hsItemsCountBadge(4).contains('4'), isTrue);
      expect(ar.decree43VerifiedBadge.isNotEmpty, isTrue);
      expect(en.decree43VerifiedBadge.isNotEmpty, isTrue);
      expect(ar.cooObtainedBadge.isNotEmpty, isTrue);
      expect(en.cooObtainedBadge.isNotEmpty, isTrue);
      expect(ar.inspectionPassedBadge.isNotEmpty, isTrue);
      expect(en.inspectionPassedBadge.isNotEmpty, isTrue);

      // Action Tooltips & Confirmations
      expect(ar.editRequirementTooltip.isNotEmpty, isTrue);
      expect(en.editRequirementTooltip.isNotEmpty, isTrue);
      expect(ar.loadedRequirementForEditingSnack('REQ-002').contains('REQ-002'), isTrue);
      expect(en.loadedRequirementForEditingSnack('REQ-002').contains('REQ-002'), isTrue);
      expect(ar.restoreRequirementTooltip.isNotEmpty, isTrue);
      expect(en.restoreRequirementTooltip.isNotEmpty, isTrue);
      expect(ar.restoredRequirementSuccessSnack('REQ-002').contains('REQ-002'), isTrue);
      expect(en.restoredRequirementSuccessSnack('REQ-002').contains('REQ-002'), isTrue);
      expect(ar.deleteRequirementTooltip.isNotEmpty, isTrue);
      expect(en.deleteRequirementTooltip.isNotEmpty, isTrue);
      expect(ar.confirmDeleteRequirementTitle.isNotEmpty, isTrue);
      expect(en.confirmDeleteRequirementTitle.isNotEmpty, isTrue);
      expect(ar.confirmDeleteRequirementContent('REQ-002', 'IMP-001').contains('REQ-002'), isTrue);
      expect(en.confirmDeleteRequirementContent('REQ-002', 'IMP-001').contains('IMP-001'), isTrue);
      expect(ar.deletedRequirementSuccessSnack('REQ-002').contains('REQ-002'), isTrue);
      expect(en.deletedRequirementSuccessSnack('REQ-002').contains('REQ-002'), isTrue);
    });

    test('Strict Language Separation: Arabic getters must not contain Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      // List of pure Arabic static getters
      final arabicStrings = [
        ar.importRequirementsScreenTitle,
        ar.importRequirementsFormTab,
        ar.importRequirementsRegistryTab,
        ar.cancelEditingAndStartNewBtn,
        ar.requirementsLifecycleCardTitle,
        ar.acidIssuanceStep,
        ar.preShipmentInspectionStep,
        ar.approvalsAndCertsStep,
        ar.sailingClearanceStep,
        ar.pendingInspectionCoordination,
        ar.completedAndPassedInspection,
        ar.allCertsFulfilled100,
        ar.pendingApprovals,
        ar.linkImportFileAndConsultationHeader,
        ar.linkedImportFileFieldLabel,
        ar.selectImportFileHint,
        ar.selectImportFileOption,
        ar.acidNotIssued,
        ar.pleaseSelectImportFileError,
        ar.acidNumberFieldLabel,
        ar.acidNumberRequiredError,
        ar.foreignSupplierFieldLabel,
        ar.foreignSupplierHint,
        ar.notSpecifiedOption,
        ar.hsCodeFieldLabel,
        ar.hsCodeRequiredError,
        ar.commodityDescFieldLabel,
        ar.commodityDescRequiredError,
        ar.countryOfOriginFieldLabel,
        ar.countryOfOriginRequiredError,
        ar.currencyFieldLabel,
        ar.valueInCurrencyFieldLabel,
        ar.pillar1Decree43Tab,
        ar.pillar2CooTab,
        ar.pillar3InspectionTab,
        ar.pillar4PermitsTab,
        ar.pillar5TechCertsTab,
        ar.pillar1Header,
        ar.decree43ApplicableCheck,
        ar.decree43ApplicableSub,
        ar.whiteListVerifiedCheck,
        ar.whiteListVerifiedSub,
        ar.factoryRegNumFieldLabel,
        ar.factoryRegNumHint,
        ar.pillar2Header,
        ar.cooRequiredCheck,
        ar.cooTypeFieldLabel,
        ar.cooTypeEur1Option,
        ar.cooTypeFormAOption,
        ar.cooTypeGaftaOption,
        ar.cooTypeComesaOption,
        ar.cooTypeStandardChamberOption,
        ar.cooStatusFieldLabel,
        ar.cooStatusPendingOption,
        ar.cooStatusObtainedOption,
        ar.cooStatusWaivedOption,
        ar.cooNotesFieldLabel,
        ar.cooNotesHint,
        ar.pillar3Header,
        ar.inspectionRequiredCheck,
        ar.inspectionBodyFieldLabel,
        ar.inspectionBodySgsOption,
        ar.inspectionBodyBvOption,
        ar.inspectionBodyTuvOption,
        ar.inspectionBodyIntertekOption,
        ar.inspectionBodyQimaOption,
        ar.inspectionBodyIlacOption,
        ar.inspectionStatusFieldLabel,
        ar.inspectionStatusPendingOption,
        ar.inspectionStatusScheduledOption,
        ar.inspectionStatusCompletedOption,
        ar.inspectionStatusRejectedOption,
        ar.inspectionReportNumFieldLabel,
        ar.inspectionNotesFieldLabel,
        ar.pillar4Header,
        ar.importPermitRequiredCheck,
        ar.issuingAuthorityFieldLabel,
        ar.authorityEeaaOption,
        ar.authorityNfsaOption,
        ar.authorityEdaOption,
        ar.authorityNtraOption,
        ar.authorityPublicSecurityOption,
        ar.authorityChemistryOption,
        ar.authorityGoeicOption,
        ar.permitStatusFieldLabel,
        ar.permitStatusAppliedOption,
        ar.permitStatusApprovedOption,
        ar.permitStatusRejectedOption,
        ar.permitNumberFieldLabel,
        ar.permitNotesFieldLabel,
        ar.pillar5Header,
        ar.msdsRequiredCheck,
        ar.halalCertRequiredCheck,
        ar.coaRequiredCheck,
        ar.sailingStatusFieldLabel,
        ar.sailingStatusPreSailingOption,
        ar.sailingStatusClearedOption,
        ar.sailingStatusSailedOption,
        ar.sailingDateFieldLabel,
        ar.riskLevelFieldLabel,
        ar.riskLevelLowOption,
        ar.riskLevelMediumOption,
        ar.riskLevelHighOption,
        ar.overallStatusDraftOption,
        ar.overallStatusInProgressOption,
        ar.overallStatusCompleteOption,
        ar.overallStatusConfirmedOption,
        ar.completeAllPillarsBtn,
        ar.completeAllPillarsSuccessSnack,
        ar.saveRequirementDraftBtn,
        ar.updateRequirementSubmitBtn,
        ar.saveRequirementSubmitBtn,
        ar.fillRequiredFieldsError,
        ar.createRequirementSuccessSnack,
        ar.saveRequirementErrorTitle,
        ar.goToSavedRequirementsBtn,
        ar.searchRequirementsHint,
        ar.complianceStatusFilterLabel,
        ar.riskLevelFilterLabel,
        ar.activeDeletedFilterLabel,
        ar.allRecordsActiveAndDeleted,
        ar.activeOnlyOption,
        ar.deletedOnlyOption,
        ar.noRequirementsFound,
        ar.createNewRequirementBtn,
        ar.fallbackImportingCompany,
        ar.decree43VerifiedBadge,
        ar.cooObtainedBadge,
        ar.inspectionPassedBadge,
        ar.editRequirementTooltip,
        ar.restoreRequirementTooltip,
        ar.deleteRequirementTooltip,
        ar.confirmDeleteRequirementTitle,
      ];

      for (final str in arabicStrings) {
        expect(
          latinPattern.hasMatch(str),
          isFalse,
          reason: 'Arabic string contains Latin characters: "$str"',
        );
      }
    });
  });
}
