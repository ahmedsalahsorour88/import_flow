import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 67: Step Config Management Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 67 Arabic strings must be non-empty', () {
      expect(ar.stepConfigTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigSubtitle.isNotEmpty, isTrue);
      expect(ar.stepConfigAccessDeniedTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigAccessDeniedDesc.isNotEmpty, isTrue);
      expect(ar.stepConfigDemoSwitchBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigRefreshTooltip.isNotEmpty, isTrue);
      expect(ar.stepConfigSearchHint.isNotEmpty, isTrue);
      expect(ar.stepConfigPhaseAll.isNotEmpty, isTrue);
      expect(ar.stepConfigPhaseLabel(1).isNotEmpty, isTrue);
      expect(ar.stepConfigEmptySearch.isNotEmpty, isTrue);
      expect(ar.stepConfigColPhaseCode.isNotEmpty, isTrue);
      expect(ar.stepConfigColStepName.isNotEmpty, isTrue);
      expect(ar.stepConfigColSkipPolicy.isNotEmpty, isTrue);
      expect(ar.stepConfigColApproverRoles.isNotEmpty, isTrue);
      expect(ar.stepConfigColPendingRef.isNotEmpty, isTrue);
      expect(ar.stepConfigColReasonCategories.isNotEmpty, isTrue);
      expect(ar.stepConfigColLastModified.isNotEmpty, isTrue);
      expect(ar.stepConfigColActions.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicyBlocked.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicySingleApproval.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicyDualApproval.isNotEmpty, isTrue);
      expect(ar.stepConfigPendingRefAllowed.isNotEmpty, isTrue);
      expect(ar.stepConfigPendingRefBlocked.isNotEmpty, isTrue);
      expect(ar.stepConfigReasonCategoriesCount(3).isNotEmpty, isTrue);
      expect(ar.stepConfigEditTooltip.isNotEmpty, isTrue);
      expect(ar.stepConfigAuditTooltip.isNotEmpty, isTrue);
      expect(ar.stepConfigCopyRowTooltip.isNotEmpty, isTrue);
      expect(ar.stepConfigCopyRowSuccess.isNotEmpty, isTrue);
      expect(ar.stepConfigCopyBadgeSuccess('الكود', 'ST-01').isNotEmpty, isTrue);
      expect(ar.stepConfigSearchCopied.isNotEmpty, isTrue);
      expect(ar.stepConfigExportTsvBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigExportExcelBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigPrintPdfBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigCopyDossierBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigCopiedTsvSuccess.isNotEmpty, isTrue);
      expect(ar.stepConfigCopiedExcelSuccess.isNotEmpty, isTrue);
      expect(ar.stepConfigCopiedDossierSuccess.isNotEmpty, isTrue);
      expect(ar.stepConfigPdfTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigPdfSubtitle.isNotEmpty, isTrue);
      expect(ar.stepConfigDossierHeader.isNotEmpty, isTrue);
      expect(ar.stepConfigDossierKpiSummary.isNotEmpty, isTrue);
      expect(ar.stepConfigDossierRecordsDetails.isNotEmpty, isTrue);
      expect(ar.stepConfigDossierFooter.isNotEmpty, isTrue);
      expect(ar.stepConfigEditDialogTitle('ST-01').isNotEmpty, isTrue);
      expect(ar.stepConfigSkipPolicyLabel.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicyItemBlocked.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicyItemSingleApproval.isNotEmpty, isTrue);
      expect(ar.stepConfigPolicyItemDualApproval.isNotEmpty, isTrue);
      expect(ar.stepConfigPendingRefToggleTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigPendingRefToggleSubtitle.isNotEmpty, isTrue);
      expect(ar.stepConfigApproverRolesTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigApproverRolesSubtitle.isNotEmpty, isTrue);
      expect(ar.stepConfigJustificationTitle.isNotEmpty, isTrue);
      expect(ar.stepConfigJustificationHint.isNotEmpty, isTrue);
      expect(ar.stepConfigJustificationValidator.isNotEmpty, isTrue);
      expect(ar.stepConfigCancelBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigSaveBtn.isNotEmpty, isTrue);
      expect(ar.stepConfigSaveSuccess('ST-01').isNotEmpty, isTrue);
      expect(ar.stepConfigAuditDialogTitle('ST-01').isNotEmpty, isTrue);
      expect(ar.stepConfigAuditEmpty.isNotEmpty, isTrue);
      expect(ar.stepConfigAuditBy('مدير').isNotEmpty, isTrue);
      expect(ar.stepConfigAuditPolicyChange.isNotEmpty, isTrue);
      expect(ar.stepConfigAuditJustification.isNotEmpty, isTrue);
      expect(ar.stepConfigAuditCloseBtn.isNotEmpty, isTrue);
    });

    test('All Screen 67 Arabic strings must have 0 Latin characters [a-zA-Z]', () {
      final latinRegex = RegExp(r'[a-zA-Z]');
      final arabicStrings = [
        ar.stepConfigTitle,
        ar.stepConfigSubtitle,
        ar.stepConfigAccessDeniedTitle,
        ar.stepConfigAccessDeniedDesc,
        ar.stepConfigDemoSwitchBtn,
        ar.stepConfigRefreshTooltip,
        ar.stepConfigSearchHint,
        ar.stepConfigPhaseAll,
        ar.stepConfigPhaseLabel(1),
        ar.stepConfigEmptySearch,
        ar.stepConfigColPhaseCode,
        ar.stepConfigColStepName,
        ar.stepConfigColSkipPolicy,
        ar.stepConfigColApproverRoles,
        ar.stepConfigColPendingRef,
        ar.stepConfigColReasonCategories,
        ar.stepConfigColLastModified,
        ar.stepConfigColActions,
        ar.stepConfigPolicyBlocked,
        ar.stepConfigPolicySingleApproval,
        ar.stepConfigPolicyDualApproval,
        ar.stepConfigPendingRefAllowed,
        ar.stepConfigPendingRefBlocked,
        ar.stepConfigReasonCategoriesCount(3),
        ar.stepConfigEditTooltip,
        ar.stepConfigAuditTooltip,
        ar.stepConfigCopyRowTooltip,
        ar.stepConfigCopyRowSuccess,
        ar.stepConfigSearchCopied,
        ar.stepConfigExportTsvBtn,
        ar.stepConfigExportExcelBtn,
        ar.stepConfigPrintPdfBtn,
        ar.stepConfigCopyDossierBtn,
        ar.stepConfigCopiedTsvSuccess,
        ar.stepConfigCopiedExcelSuccess,
        ar.stepConfigCopiedDossierSuccess,
        ar.stepConfigPdfTitle,
        ar.stepConfigPdfSubtitle,
        ar.stepConfigDossierHeader,
        ar.stepConfigDossierKpiSummary,
        ar.stepConfigDossierRecordsDetails,
        ar.stepConfigDossierFooter,
        ar.stepConfigSkipPolicyLabel,
        ar.stepConfigPolicyItemBlocked,
        ar.stepConfigPolicyItemSingleApproval,
        ar.stepConfigPolicyItemDualApproval,
        ar.stepConfigPendingRefToggleTitle,
        ar.stepConfigPendingRefToggleSubtitle,
        ar.stepConfigApproverRolesTitle,
        ar.stepConfigApproverRolesSubtitle,
        ar.stepConfigJustificationTitle,
        ar.stepConfigJustificationHint,
        ar.stepConfigJustificationValidator,
        ar.stepConfigCancelBtn,
        ar.stepConfigSaveBtn,
        ar.stepConfigAuditEmpty,
        ar.stepConfigAuditPolicyChange,
        ar.stepConfigAuditJustification,
        ar.stepConfigAuditCloseBtn,
      ];

      for (final s in arabicStrings) {
        expect(latinRegex.hasMatch(s), isFalse,
            reason: 'String contains Latin characters: "$s"');
      }
    });

    test('All Screen 67 Arabic strings must have 0 bilingual slashes /', () {
      final arabicStrings = [
        ar.stepConfigTitle,
        ar.stepConfigSubtitle,
        ar.stepConfigAccessDeniedTitle,
        ar.stepConfigAccessDeniedDesc,
        ar.stepConfigDemoSwitchBtn,
        ar.stepConfigRefreshTooltip,
        ar.stepConfigSearchHint,
        ar.stepConfigPhaseAll,
        ar.stepConfigPhaseLabel(1),
        ar.stepConfigEmptySearch,
        ar.stepConfigColPhaseCode,
        ar.stepConfigColStepName,
        ar.stepConfigColSkipPolicy,
        ar.stepConfigColApproverRoles,
        ar.stepConfigColPendingRef,
        ar.stepConfigColReasonCategories,
        ar.stepConfigColLastModified,
        ar.stepConfigColActions,
        ar.stepConfigPolicyBlocked,
        ar.stepConfigPolicySingleApproval,
        ar.stepConfigPolicyDualApproval,
        ar.stepConfigPendingRefAllowed,
        ar.stepConfigPendingRefBlocked,
        ar.stepConfigReasonCategoriesCount(3),
        ar.stepConfigEditTooltip,
        ar.stepConfigAuditTooltip,
        ar.stepConfigCopyRowTooltip,
        ar.stepConfigCopyRowSuccess,
        ar.stepConfigSearchCopied,
        ar.stepConfigExportTsvBtn,
        ar.stepConfigExportExcelBtn,
        ar.stepConfigPrintPdfBtn,
        ar.stepConfigCopyDossierBtn,
        ar.stepConfigCopiedTsvSuccess,
        ar.stepConfigCopiedExcelSuccess,
        ar.stepConfigCopiedDossierSuccess,
        ar.stepConfigPdfTitle,
        ar.stepConfigPdfSubtitle,
        ar.stepConfigDossierHeader,
        ar.stepConfigDossierKpiSummary,
        ar.stepConfigDossierRecordsDetails,
        ar.stepConfigDossierFooter,
        ar.stepConfigSkipPolicyLabel,
        ar.stepConfigPolicyItemBlocked,
        ar.stepConfigPolicyItemSingleApproval,
        ar.stepConfigPolicyItemDualApproval,
        ar.stepConfigPendingRefToggleTitle,
        ar.stepConfigPendingRefToggleSubtitle,
        ar.stepConfigApproverRolesTitle,
        ar.stepConfigApproverRolesSubtitle,
        ar.stepConfigJustificationTitle,
        ar.stepConfigJustificationHint,
        ar.stepConfigJustificationValidator,
        ar.stepConfigCancelBtn,
        ar.stepConfigSaveBtn,
        ar.stepConfigAuditEmpty,
        ar.stepConfigAuditPolicyChange,
        ar.stepConfigAuditJustification,
        ar.stepConfigAuditCloseBtn,
      ];

      for (final s in arabicStrings) {
        expect(s.contains('/'), isFalse,
            reason: 'String contains bilingual slash: "$s"');
      }
    });

    test('All Screen 67 English strings must be non-empty', () {
      expect(en.stepConfigTitle.isNotEmpty, isTrue);
      expect(en.stepConfigSubtitle.isNotEmpty, isTrue);
      expect(en.stepConfigAccessDeniedTitle.isNotEmpty, isTrue);
      expect(en.stepConfigAccessDeniedDesc.isNotEmpty, isTrue);
      expect(en.stepConfigDemoSwitchBtn.isNotEmpty, isTrue);
      expect(en.stepConfigRefreshTooltip.isNotEmpty, isTrue);
      expect(en.stepConfigSearchHint.isNotEmpty, isTrue);
      expect(en.stepConfigPhaseAll.isNotEmpty, isTrue);
      expect(en.stepConfigPhaseLabel(1).isNotEmpty, isTrue);
      expect(en.stepConfigEmptySearch.isNotEmpty, isTrue);
      expect(en.stepConfigColPhaseCode.isNotEmpty, isTrue);
      expect(en.stepConfigColStepName.isNotEmpty, isTrue);
      expect(en.stepConfigColSkipPolicy.isNotEmpty, isTrue);
      expect(en.stepConfigColApproverRoles.isNotEmpty, isTrue);
      expect(en.stepConfigColPendingRef.isNotEmpty, isTrue);
      expect(en.stepConfigColReasonCategories.isNotEmpty, isTrue);
      expect(en.stepConfigColLastModified.isNotEmpty, isTrue);
      expect(en.stepConfigColActions.isNotEmpty, isTrue);
      expect(en.stepConfigPolicyBlocked.isNotEmpty, isTrue);
      expect(en.stepConfigPolicySingleApproval.isNotEmpty, isTrue);
      expect(en.stepConfigPolicyDualApproval.isNotEmpty, isTrue);
      expect(en.stepConfigPendingRefAllowed.isNotEmpty, isTrue);
      expect(en.stepConfigPendingRefBlocked.isNotEmpty, isTrue);
      expect(en.stepConfigReasonCategoriesCount(3).isNotEmpty, isTrue);
      expect(en.stepConfigEditTooltip.isNotEmpty, isTrue);
      expect(en.stepConfigAuditTooltip.isNotEmpty, isTrue);
      expect(en.stepConfigCopyRowTooltip.isNotEmpty, isTrue);
      expect(en.stepConfigCopyRowSuccess.isNotEmpty, isTrue);
      expect(en.stepConfigCopyBadgeSuccess('Code', 'ST-01').isNotEmpty, isTrue);
      expect(en.stepConfigSearchCopied.isNotEmpty, isTrue);
      expect(en.stepConfigExportTsvBtn.isNotEmpty, isTrue);
      expect(en.stepConfigExportExcelBtn.isNotEmpty, isTrue);
      expect(en.stepConfigPrintPdfBtn.isNotEmpty, isTrue);
      expect(en.stepConfigCopyDossierBtn.isNotEmpty, isTrue);
      expect(en.stepConfigCopiedTsvSuccess.isNotEmpty, isTrue);
      expect(en.stepConfigCopiedExcelSuccess.isNotEmpty, isTrue);
      expect(en.stepConfigCopiedDossierSuccess.isNotEmpty, isTrue);
      expect(en.stepConfigPdfTitle.isNotEmpty, isTrue);
      expect(en.stepConfigPdfSubtitle.isNotEmpty, isTrue);
      expect(en.stepConfigDossierHeader.isNotEmpty, isTrue);
      expect(en.stepConfigDossierKpiSummary.isNotEmpty, isTrue);
      expect(en.stepConfigDossierRecordsDetails.isNotEmpty, isTrue);
      expect(en.stepConfigDossierFooter.isNotEmpty, isTrue);
      expect(en.stepConfigEditDialogTitle('ST-01').isNotEmpty, isTrue);
      expect(en.stepConfigSkipPolicyLabel.isNotEmpty, isTrue);
      expect(en.stepConfigPolicyItemBlocked.isNotEmpty, isTrue);
      expect(en.stepConfigPolicyItemSingleApproval.isNotEmpty, isTrue);
      expect(en.stepConfigPolicyItemDualApproval.isNotEmpty, isTrue);
      expect(en.stepConfigPendingRefToggleTitle.isNotEmpty, isTrue);
      expect(en.stepConfigPendingRefToggleSubtitle.isNotEmpty, isTrue);
      expect(en.stepConfigApproverRolesTitle.isNotEmpty, isTrue);
      expect(en.stepConfigApproverRolesSubtitle.isNotEmpty, isTrue);
      expect(en.stepConfigJustificationTitle.isNotEmpty, isTrue);
      expect(en.stepConfigJustificationHint.isNotEmpty, isTrue);
      expect(en.stepConfigJustificationValidator.isNotEmpty, isTrue);
      expect(en.stepConfigCancelBtn.isNotEmpty, isTrue);
      expect(en.stepConfigSaveBtn.isNotEmpty, isTrue);
      expect(en.stepConfigSaveSuccess('ST-01').isNotEmpty, isTrue);
      expect(en.stepConfigAuditDialogTitle('ST-01').isNotEmpty, isTrue);
      expect(en.stepConfigAuditEmpty.isNotEmpty, isTrue);
      expect(en.stepConfigAuditBy('Manager').isNotEmpty, isTrue);
      expect(en.stepConfigAuditPolicyChange.isNotEmpty, isTrue);
      expect(en.stepConfigAuditJustification.isNotEmpty, isTrue);
      expect(en.stepConfigAuditCloseBtn.isNotEmpty, isTrue);
    });
  });
}
