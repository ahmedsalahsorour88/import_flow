import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 48: Lifecycle Kanban Board Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 48 getters should return non-empty strings in Arabic and English', () {
      expect(ar.lifecycleBoardTitle, isNotEmpty);
      expect(en.lifecycleBoardTitle, isNotEmpty);
      expect(ar.lifecycleBoardSubtitle, isNotEmpty);
      expect(en.lifecycleBoardSubtitle, isNotEmpty);
      expect(ar.refreshLiveBoardTooltip, isNotEmpty);
      expect(en.refreshLiveBoardTooltip, isNotEmpty);
      expect(ar.lifecycleBoardError('network error'), contains('network error'));
      expect(en.lifecycleBoardError('network error'), contains('network error'));
      expect(ar.majorPhasesHeader, isNotEmpty);
      expect(en.majorPhasesHeader, isNotEmpty);
      expect(ar.totalActiveShipmentsCount(10, 25), contains('10'));
      expect(en.totalActiveShipmentsCount(10, 25), contains('10'));
      expect(ar.showAllPhasesBtn, isNotEmpty);
      expect(en.showAllPhasesBtn, isNotEmpty);
      expect(ar.allShipmentsAllPhases, isNotEmpty);
      expect(en.allShipmentsAllPhases, isNotEmpty);
      expect(ar.searchLifecycleTableHint, isNotEmpty);
      expect(en.searchLifecycleTableHint, isNotEmpty);
      expect(ar.shipmentsCountFormatted(5), contains('5'));
      expect(en.shipmentsCountFormatted(5), contains('5'));

      // Table columns
      expect(ar.colShipmentCode, isNotEmpty);
      expect(en.colShipmentCode, isNotEmpty);
      expect(ar.colCurrentStep, isNotEmpty);
      expect(en.colCurrentStep, isNotEmpty);
      expect(ar.colImportCompany, isNotEmpty);
      expect(en.colImportCompany, isNotEmpty);
      expect(ar.colForeignSupplier, isNotEmpty);
      expect(en.colForeignSupplier, isNotEmpty);
      expect(ar.colPurchaseOrder, isNotEmpty);
      expect(en.colPurchaseOrder, isNotEmpty);
      expect(ar.colModeAndIncoterm, isNotEmpty);
      expect(en.colModeAndIncoterm, isNotEmpty);
      expect(ar.colEstimatedValue, isNotEmpty);
      expect(en.colEstimatedValue, isNotEmpty);
      expect(ar.colNotesAndActivities, isNotEmpty);
      expect(en.colNotesAndActivities, isNotEmpty);
      expect(ar.colActionsAndAdvance, isNotEmpty);
      expect(en.colActionsAndAdvance, isNotEmpty);
      expect(ar.notesUnderFollowupFallback, isNotEmpty);
      expect(en.notesUnderFollowupFallback, isNotEmpty);
      expect(ar.executeAndAdvanceStepBtn, isNotEmpty);
      expect(en.executeAndAdvanceStepBtn, isNotEmpty);
      expect(ar.noShipmentsInStage, isNotEmpty);
      expect(en.noShipmentsInStage, isNotEmpty);
      expect(ar.noShipmentsInStageDesc, isNotEmpty);
      expect(en.noShipmentsInStageDesc, isNotEmpty);

      // All 21 steps
      for (int i = 1; i <= 21; i++) {
        final code = 'STEP_${i.toString().padLeft(2, '0')}';
        expect(ar.lifecycleStepName(code), isNotEmpty);
        expect(en.lifecycleStepName(code), isNotEmpty);
        expect(ar.stepParam1Label(code), isNotEmpty);
        expect(en.stepParam1Label(code), isNotEmpty);
        expect(ar.stepParam2Label(code), isNotEmpty);
        expect(en.stepParam2Label(code), isNotEmpty);
        expect(ar.stepParam3Label(code), isNotEmpty);
        expect(en.stepParam3Label(code), isNotEmpty);
      }

      // 6 Phases
      for (int i = 1; i <= 6; i++) {
        expect(ar.lifecyclePhaseName(i, 'فاز $i', 'Phase $i'), isNotEmpty);
        expect(en.lifecyclePhaseName(i, 'فاز $i', 'Phase $i'), isNotEmpty);
      }

      // Dialog Actions
      expect(ar.stepActionCardTitle('Customs Clearance'), contains('Customs Clearance'));
      expect(en.stepActionCardTitle('Customs Clearance'), contains('Customs Clearance'));
      expect(ar.onHoldStatusTag, isNotEmpty);
      expect(en.onHoldStatusTag, isNotEmpty);
      expect(ar.importFileLabel, isNotEmpty);
      expect(en.importFileLabel, isNotEmpty);
      expect(ar.importingCompanyLabel, isNotEmpty);
      expect(en.importingCompanyLabel, isNotEmpty);
      expect(ar.foreignSupplierLabel, isNotEmpty);
      expect(en.foreignSupplierLabel, isNotEmpty);
      expect(ar.purchaseOrderLabel, isNotEmpty);
      expect(en.purchaseOrderLabel, isNotEmpty);
      expect(ar.estimatedValueLabel, isNotEmpty);
      expect(en.estimatedValueLabel, isNotEmpty);
      expect(ar.currentStepRequirementsHeader, isNotEmpty);
      expect(en.currentStepRequirementsHeader, isNotEmpty);
      expect(ar.targetNextPhasesHeader, isNotEmpty);
      expect(en.targetNextPhasesHeader, isNotEmpty);
      expect(ar.stepNotesHeader, isNotEmpty);
      expect(en.stepNotesHeader, isNotEmpty);
      expect(ar.stepNotesHint, isNotEmpty);
      expect(en.stepNotesHint, isNotEmpty);
      expect(ar.skipStepBtn, isNotEmpty);
      expect(en.skipStepBtn, isNotEmpty);
      expect(ar.resumeShipmentBtn, isNotEmpty);
      expect(en.resumeShipmentBtn, isNotEmpty);
      expect(ar.holdShipmentBtn, isNotEmpty);
      expect(en.holdShipmentBtn, isNotEmpty);
      expect(ar.savingAndAdvancing, isNotEmpty);
      expect(en.savingAndAdvancing, isNotEmpty);
      expect(ar.completeAndAdvanceBtn, isNotEmpty);
      expect(en.completeAndAdvanceBtn, isNotEmpty);

      expect(ar.stepAdvanceSuccessSnack('STEP_02', 'IMP-001'), contains('IMP-001'));
      expect(en.stepAdvanceSuccessSnack('STEP_02', 'IMP-001'), contains('IMP-001'));
      expect(ar.stepAdvanceErrorSnack, isNotEmpty);
      expect(en.stepAdvanceErrorSnack, isNotEmpty);
      expect(ar.skipStepDialogTitle, isNotEmpty);
      expect(en.skipStepDialogTitle, isNotEmpty);
      expect(ar.skipStepConfirmText('STEP_01', 'IMP-001'), contains('IMP-001'));
      expect(en.skipStepConfirmText('STEP_01', 'IMP-001'), contains('IMP-001'));
      expect(ar.skipReasonLabel, isNotEmpty);
      expect(en.skipReasonLabel, isNotEmpty);
      expect(ar.skipReasonHint, isNotEmpty);
      expect(en.skipReasonHint, isNotEmpty);
      expect(ar.skipReasonRequired, isNotEmpty);
      expect(en.skipReasonRequired, isNotEmpty);
      expect(ar.confirmSkipAndAdvanceBtn, isNotEmpty);
      expect(en.confirmSkipAndAdvanceBtn, isNotEmpty);
      expect(ar.stepSkippedSuccessSnack('STEP_03', 'IMP-001'), contains('IMP-001'));
      expect(en.stepSkippedSuccessSnack('STEP_03', 'IMP-001'), contains('IMP-001'));
      expect(ar.shipmentResumedSuccessSnack, isNotEmpty);
      expect(en.shipmentResumedSuccessSnack, isNotEmpty);
      expect(ar.holdDialogTitle, isNotEmpty);
      expect(en.holdDialogTitle, isNotEmpty);
      expect(ar.holdConfirmText('IMP-001', 'STEP_02'), contains('IMP-001'));
      expect(en.holdConfirmText('IMP-001', 'STEP_02'), contains('IMP-001'));
      expect(ar.holdReasonLabel, isNotEmpty);
      expect(en.holdReasonLabel, isNotEmpty);
      expect(ar.holdReasonHint, isNotEmpty);
      expect(en.holdReasonHint, isNotEmpty);
      expect(ar.holdReasonRequired, isNotEmpty);
      expect(en.holdReasonRequired, isNotEmpty);
      expect(ar.confirmHoldBtn, isNotEmpty);
      expect(en.confirmHoldBtn, isNotEmpty);
      expect(ar.shipmentHeldSuccessSnack, isNotEmpty);
      expect(en.shipmentHeldSuccessSnack, isNotEmpty);

      // New Export & Toolbar Getters
      expect(ar.lifecycleExportTsvBtn, isNotEmpty);
      expect(en.lifecycleExportTsvBtn, isNotEmpty);
      expect(ar.lifecycleExportExcelBtn, isNotEmpty);
      expect(en.lifecycleExportExcelBtn, isNotEmpty);
      expect(ar.lifecyclePrintPdfBtn, isNotEmpty);
      expect(en.lifecyclePrintPdfBtn, isNotEmpty);
      expect(ar.lifecycleCopyDossierBtn, isNotEmpty);
      expect(en.lifecycleCopyDossierBtn, isNotEmpty);
      expect(ar.lifecycleCopyDossierSuccess, isNotEmpty);
      expect(en.lifecycleCopyDossierSuccess, isNotEmpty);
      expect(ar.lifecycleDossierHeader, isNotEmpty);
      expect(en.lifecycleDossierHeader, isNotEmpty);
      expect(ar.lifecycleExportTsvDialogTitle, isNotEmpty);
      expect(en.lifecycleExportTsvDialogTitle, isNotEmpty);
      expect(ar.lifecycleExportExcelDialogTitle, isNotEmpty);
      expect(en.lifecycleExportExcelDialogTitle, isNotEmpty);

      // New Radar Helpers & Headers
      expect(ar.radarDossierHeader, isNotEmpty);
      expect(en.radarDossierHeader, isNotEmpty);
      expect(ar.radarExportTsvDialogTitle, isNotEmpty);
      expect(en.radarExportTsvDialogTitle, isNotEmpty);
      expect(ar.radarExportExcelDialogTitle, isNotEmpty);
      expect(en.radarExportExcelDialogTitle, isNotEmpty);
      expect(ar.searchLiveRadarHint, isNotEmpty);
      expect(en.searchLiveRadarHint, isNotEmpty);
      expect(ar.colBillOfLadingPrefix, isNotEmpty);
      expect(en.colBillOfLadingPrefix, isNotEmpty);
      expect(ar.colEtaPrefix, isNotEmpty);
      expect(en.colEtaPrefix, isNotEmpty);
      expect(ar.colCarrierUnderPrep, isNotEmpty);
      expect(en.colCarrierUnderPrep, isNotEmpty);
      expect(ar.demurrageFeesFormatted('100', '5000'), contains('100'));
      expect(en.demurrageFeesFormatted('100', '5000'), contains('100'));
      expect(ar.freeDaysConsumed(5, 14), contains('5'));
      expect(en.freeDaysConsumed(5, 14), contains('5'));
      expect(ar.liveRadarError('Err'), contains('Err'));
      expect(en.liveRadarError('Err'), contains('Err'));

      // 11 Kanban TSV Headers
      expect(ar.lifecycleTsvHeaderFileCode, isNotEmpty);
      expect(en.lifecycleTsvHeaderFileCode, isNotEmpty);
      expect(ar.lifecycleTsvHeaderPreviousStep, isNotEmpty);
      expect(en.lifecycleTsvHeaderPreviousStep, isNotEmpty);
      expect(ar.lifecycleTsvHeaderCurrentStep, isNotEmpty);
      expect(en.lifecycleTsvHeaderCurrentStep, isNotEmpty);
      expect(ar.lifecycleTsvHeaderNextStep, isNotEmpty);
      expect(en.lifecycleTsvHeaderNextStep, isNotEmpty);
      expect(ar.lifecycleTsvHeaderCompany, isNotEmpty);
      expect(en.lifecycleTsvHeaderCompany, isNotEmpty);
      expect(ar.lifecycleTsvHeaderSupplier, isNotEmpty);
      expect(en.lifecycleTsvHeaderSupplier, isNotEmpty);
      expect(ar.lifecycleTsvHeaderPoNumber, isNotEmpty);
      expect(en.lifecycleTsvHeaderPoNumber, isNotEmpty);
      expect(ar.lifecycleTsvHeaderShipmentMode, isNotEmpty);
      expect(en.lifecycleTsvHeaderShipmentMode, isNotEmpty);
      expect(ar.lifecycleTsvHeaderEstimatedCost, isNotEmpty);
      expect(en.lifecycleTsvHeaderEstimatedCost, isNotEmpty);
      expect(ar.lifecycleTsvHeaderStatus, isNotEmpty);
      expect(en.lifecycleTsvHeaderStatus, isNotEmpty);
      expect(ar.lifecycleTsvHeaderNotes, isNotEmpty);
      expect(en.lifecycleTsvHeaderNotes, isNotEmpty);

      // 7 Radar TSV Headers
      expect(ar.radarTsvHeaderFileCode, isNotEmpty);
      expect(en.radarTsvHeaderFileCode, isNotEmpty);
      expect(ar.radarTsvHeaderCarrierVessel, isNotEmpty);
      expect(en.radarTsvHeaderCarrierVessel, isNotEmpty);
      expect(ar.radarTsvHeaderBlRoute, isNotEmpty);
      expect(en.radarTsvHeaderBlRoute, isNotEmpty);
      expect(ar.radarTsvHeaderArrivalStatus, isNotEmpty);
      expect(en.radarTsvHeaderArrivalStatus, isNotEmpty);
      expect(ar.radarTsvHeaderDemurrageRisk, isNotEmpty);
      expect(en.radarTsvHeaderDemurrageRisk, isNotEmpty);
      expect(ar.radarTsvHeaderTestingStatus, isNotEmpty);
      expect(en.radarTsvHeaderTestingStatus, isNotEmpty);
      expect(ar.radarTsvHeaderDocReadiness, isNotEmpty);
      expect(en.radarTsvHeaderDocReadiness, isNotEmpty);
    });

    test('Arabic static strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      expect(latinPattern.hasMatch(ar.lifecycleBoardTitle), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleBoardSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.refreshLiveBoardTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.majorPhasesHeader), isFalse);
      expect(latinPattern.hasMatch(ar.showAllPhasesBtn), isFalse);
      expect(latinPattern.hasMatch(ar.allShipmentsAllPhases), isFalse);
      expect(latinPattern.hasMatch(ar.searchLifecycleTableHint), isFalse);
      expect(latinPattern.hasMatch(ar.colShipmentCode), isFalse);
      expect(latinPattern.hasMatch(ar.colCurrentStep), isFalse);
      expect(latinPattern.hasMatch(ar.colImportCompany), isFalse);
      expect(latinPattern.hasMatch(ar.colForeignSupplier), isFalse);
      expect(latinPattern.hasMatch(ar.colPurchaseOrder), isFalse);
      expect(latinPattern.hasMatch(ar.colModeAndIncoterm), isFalse);
      expect(latinPattern.hasMatch(ar.colEstimatedValue), isFalse);
      expect(latinPattern.hasMatch(ar.colNotesAndActivities), isFalse);
      expect(latinPattern.hasMatch(ar.colActionsAndAdvance), isFalse);
      expect(latinPattern.hasMatch(ar.notesUnderFollowupFallback), isFalse);
      expect(latinPattern.hasMatch(ar.executeAndAdvanceStepBtn), isFalse);
      expect(latinPattern.hasMatch(ar.noShipmentsInStage), isFalse);
      expect(latinPattern.hasMatch(ar.noShipmentsInStageDesc), isFalse);

      for (int i = 1; i <= 21; i++) {
        final code = 'STEP_${i.toString().padLeft(2, '0')}';
        expect(latinPattern.hasMatch(ar.lifecycleStepName(code)), isFalse, reason: 'Failed for step $code');
        expect(latinPattern.hasMatch(ar.stepParam1Label(code)), isFalse, reason: 'Failed for param1 $code');
        expect(latinPattern.hasMatch(ar.stepParam2Label(code)), isFalse, reason: 'Failed for param2 $code');
        expect(latinPattern.hasMatch(ar.stepParam3Label(code)), isFalse, reason: 'Failed for param3 $code');
      }

      for (int i = 1; i <= 6; i++) {
        expect(latinPattern.hasMatch(ar.lifecyclePhaseName(i, '', '')), isFalse, reason: 'Failed for phase $i');
      }

      expect(latinPattern.hasMatch(ar.onHoldStatusTag), isFalse);
      expect(latinPattern.hasMatch(ar.importFileLabel), isFalse);
      expect(latinPattern.hasMatch(ar.importingCompanyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.foreignSupplierLabel), isFalse);
      expect(latinPattern.hasMatch(ar.purchaseOrderLabel), isFalse);
      expect(latinPattern.hasMatch(ar.estimatedValueLabel), isFalse);
      expect(latinPattern.hasMatch(ar.currentStepRequirementsHeader), isFalse);
      expect(latinPattern.hasMatch(ar.targetNextPhasesHeader), isFalse);
      expect(latinPattern.hasMatch(ar.stepNotesHeader), isFalse);
      expect(latinPattern.hasMatch(ar.stepNotesHint), isFalse);
      expect(latinPattern.hasMatch(ar.skipStepBtn), isFalse);
      expect(latinPattern.hasMatch(ar.resumeShipmentBtn), isFalse);
      expect(latinPattern.hasMatch(ar.holdShipmentBtn), isFalse);
      expect(latinPattern.hasMatch(ar.savingAndAdvancing), isFalse);
      expect(latinPattern.hasMatch(ar.completeAndAdvanceBtn), isFalse);
      expect(latinPattern.hasMatch(ar.stepAdvanceErrorSnack), isFalse);
      expect(latinPattern.hasMatch(ar.skipStepDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.skipReasonLabel), isFalse);
      expect(latinPattern.hasMatch(ar.skipReasonHint), isFalse);
      expect(latinPattern.hasMatch(ar.skipReasonRequired), isFalse);
      expect(latinPattern.hasMatch(ar.confirmSkipAndAdvanceBtn), isFalse);
      expect(latinPattern.hasMatch(ar.shipmentResumedSuccessSnack), isFalse);
      expect(latinPattern.hasMatch(ar.holdDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.holdReasonLabel), isFalse);
      expect(latinPattern.hasMatch(ar.holdReasonHint), isFalse);
      expect(latinPattern.hasMatch(ar.holdReasonRequired), isFalse);
      expect(latinPattern.hasMatch(ar.confirmHoldBtn), isFalse);
      expect(latinPattern.hasMatch(ar.shipmentHeldSuccessSnack), isFalse);

      // New Toolbar & Export & TSV getters zero-Latin
      expect(latinPattern.hasMatch(ar.lifecycleExportTsvBtn), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleExportExcelBtn), isFalse);
      expect(latinPattern.hasMatch(ar.lifecyclePrintPdfBtn), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleCopyDossierBtn), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleCopyDossierSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleDossierHeader), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleExportTsvDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleExportExcelDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.radarDossierHeader), isFalse);
      expect(latinPattern.hasMatch(ar.radarExportTsvDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.radarExportExcelDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.searchLiveRadarHint), isFalse);
      expect(latinPattern.hasMatch(ar.colBillOfLadingPrefix), isFalse);
      expect(latinPattern.hasMatch(ar.colEtaPrefix), isFalse);
      expect(latinPattern.hasMatch(ar.colCarrierUnderPrep), isFalse);

      // 11 Kanban TSV Headers zero-Latin
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderFileCode), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderPreviousStep), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderCurrentStep), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderNextStep), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderCompany), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderSupplier), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderPoNumber), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderShipmentMode), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderEstimatedCost), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderStatus), isFalse);
      expect(latinPattern.hasMatch(ar.lifecycleTsvHeaderNotes), isFalse);

      // 7 Radar TSV Headers zero-Latin
      expect(latinPattern.hasMatch(ar.radarTsvHeaderFileCode), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderCarrierVessel), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderBlRoute), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderArrivalStatus), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderDemurrageRisk), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderTestingStatus), isFalse);
      expect(latinPattern.hasMatch(ar.radarTsvHeaderDocReadiness), isFalse);
    });

    test('Zero language stacking: no bilingual slashes in pure Arabic strings', () {
      expect(ar.lifecycleBoardTitle.contains('/'), isFalse);
      expect(ar.holdDialogTitle.contains('/'), isFalse);
      expect(ar.riskFilterWarning.contains('/'), isFalse);
      expect(ar.sampleFilterApproved.contains('/'), isFalse);
      for (int i = 1; i <= 21; i++) {
        final code = 'STEP_${i.toString().padLeft(2, '0')}';
        expect(ar.stepParam1Label(code).contains('/'), isFalse, reason: 'Failed for stepParam1 $code');
        expect(ar.stepParam2Label(code).contains('/'), isFalse, reason: 'Failed for stepParam2 $code');
      }
    });
  });
}
