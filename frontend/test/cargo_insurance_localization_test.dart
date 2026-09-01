import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 65: Marine & Cargo Insurance Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final insuranceGetters = <String, List<String>>{
      'insuranceScreenTitle': [ar.insuranceScreenTitle, en.insuranceScreenTitle],
      'insuranceTabCertificatesRegistry': [ar.insuranceTabCertificatesRegistry, en.insuranceTabCertificatesRegistry],
      'insuranceTabNewCertificate': [ar.insuranceTabNewCertificate, en.insuranceTabNewCertificate],
      'insuranceAiExtractorBtn': [ar.insuranceAiExtractorBtn, en.insuranceAiExtractorBtn],
      'insuranceSmartUploadBtn': [ar.insuranceSmartUploadBtn, en.insuranceSmartUploadBtn],
      'insuranceExtractedSnackbar': [ar.insuranceExtractedSnackbar('TEST-001'), en.insuranceExtractedSnackbar('TEST-001')],
      'insuranceExtractedDone': [ar.insuranceExtractedDone, en.insuranceExtractedDone],
      'insuranceRefreshTooltip': [ar.insuranceRefreshTooltip, en.insuranceRefreshTooltip],
      'insuranceFetchError': [ar.insuranceFetchError('Server Error'), en.insuranceFetchError('Server Error')],
      'insuranceRetryBtn': [ar.insuranceRetryBtn, en.insuranceRetryBtn],
      'insuranceKpiTotalPolicies': [ar.insuranceKpiTotalPolicies, en.insuranceKpiTotalPolicies],
      'insuranceKpiIssuedValid': [ar.insuranceKpiIssuedValid, en.insuranceKpiIssuedValid],
      'insuranceKpiTotalInsured': [ar.insuranceKpiTotalInsured, en.insuranceKpiTotalInsured],
      'insuranceKpiTotalPremiums': [ar.insuranceKpiTotalPremiums, en.insuranceKpiTotalPremiums],
      'insuranceRefreshRegistryBtn': [ar.insuranceRefreshRegistryBtn, en.insuranceRefreshRegistryBtn],
      'insuranceNewCertificateBtn': [ar.insuranceNewCertificateBtn, en.insuranceNewCertificateBtn],
      'insuranceSearchHint': [ar.insuranceSearchHint, en.insuranceSearchHint],
      'insuranceFilterAll': [ar.insuranceFilterAll, en.insuranceFilterAll],
      'insuranceFilterIssued': [ar.insuranceFilterIssued, en.insuranceFilterIssued],
      'insuranceFilterDraft': [ar.insuranceFilterDraft, en.insuranceFilterDraft],
      'insuranceFilterCancelled': [ar.insuranceFilterCancelled, en.insuranceFilterCancelled],
      'insuranceShowDeleted': [ar.insuranceShowDeleted, en.insuranceShowDeleted],
      'insuranceHideDeleted': [ar.insuranceHideDeleted, en.insuranceHideDeleted],
      'insuranceNoMatchingFound': [ar.insuranceNoMatchingFound, en.insuranceNoMatchingFound],
      'insuranceNoDataFound': [ar.insuranceNoDataFound, en.insuranceNoDataFound],
      'insuranceEmptyHint': [ar.insuranceEmptyHint, en.insuranceEmptyHint],
      'insuranceColCertCode': [ar.insuranceColCertCode, en.insuranceColCertCode],
      'insuranceColIssueDate': [ar.insuranceColIssueDate, en.insuranceColIssueDate],
      'insuranceColPolicyFile': [ar.insuranceColPolicyFile, en.insuranceColPolicyFile],
      'insuranceColInsuredEntity': [ar.insuranceColInsuredEntity, en.insuranceColInsuredEntity],
      'insuranceColInsuranceCo': [ar.insuranceColInsuranceCo, en.insuranceColInsuranceCo],
      'insuranceColTransportRoute': [ar.insuranceColTransportRoute, en.insuranceColTransportRoute],
      'insuranceColInsuredValue': [ar.insuranceColInsuredValue, en.insuranceColInsuredValue],
      'insuranceColCoverageClause': [ar.insuranceColCoverageClause, en.insuranceColCoverageClause],
      'insuranceColGrossPremium': [ar.insuranceColGrossPremium, en.insuranceColGrossPremium],
      'insuranceColStatus': [ar.insuranceColStatus, en.insuranceColStatus],
      'insuranceColActions': [ar.insuranceColActions, en.insuranceColActions],
      'insuranceStatusIssuedBadge': [ar.insuranceStatusIssuedBadge, en.insuranceStatusIssuedBadge],
      'insuranceStatusCancelledBadge': [ar.insuranceStatusCancelledBadge, en.insuranceStatusCancelledBadge],
      'insuranceStatusDraftBadge': [ar.insuranceStatusDraftBadge, en.insuranceStatusDraftBadge],
      'insuranceViewTooltip': [ar.insuranceViewTooltip, en.insuranceViewTooltip],
      'insuranceEditTooltip': [ar.insuranceEditTooltip, en.insuranceEditTooltip],
      'insurancePrintTooltip': [ar.insurancePrintTooltip, en.insurancePrintTooltip],
      'insuranceDeleteTooltip': [ar.insuranceDeleteTooltip, en.insuranceDeleteTooltip],
      'insuranceIssueCertificateTooltip': [ar.insuranceIssueCertificateTooltip, en.insuranceIssueCertificateTooltip],
      'insuranceConfirmIssueTitle': [ar.insuranceConfirmIssueTitle, en.insuranceConfirmIssueTitle],
      'insuranceConfirmIssueMsg': [ar.insuranceConfirmIssueMsg('POL-01'), en.insuranceConfirmIssueMsg('POL-01')],
      'insuranceConfirmIssueBtn': [ar.insuranceConfirmIssueBtn, en.insuranceConfirmIssueBtn],
      'insuranceIssueSuccessMsg': [ar.insuranceIssueSuccessMsg, en.insuranceIssueSuccessMsg],
      'insuranceConfirmDeleteTitle': [ar.insuranceConfirmDeleteTitle, en.insuranceConfirmDeleteTitle],
      'insuranceConfirmDeleteMsg': [ar.insuranceConfirmDeleteMsg, en.insuranceConfirmDeleteMsg],
      'insuranceDeleteBtn': [ar.insuranceDeleteBtn, en.insuranceDeleteBtn],
      'insuranceDialogNewTitle': [ar.insuranceDialogNewTitle, en.insuranceDialogNewTitle],
      'insuranceDialogEditTitle': [ar.insuranceDialogEditTitle('POL-01'), en.insuranceDialogEditTitle('POL-01')],
      'insuranceDialogSubtitle': [ar.insuranceDialogSubtitle, en.insuranceDialogSubtitle],
      'insuranceFieldLinkImportFile': [ar.insuranceFieldLinkImportFile, en.insuranceFieldLinkImportFile],
      'insuranceFieldLinkImportFileHint': [ar.insuranceFieldLinkImportFileHint, en.insuranceFieldLinkImportFileHint],
      'insuranceFieldInsuredEntity': [ar.insuranceFieldInsuredEntity, en.insuranceFieldInsuredEntity],
      'insuranceFieldInsuredEntityRequired': [ar.insuranceFieldInsuredEntityRequired, en.insuranceFieldInsuredEntityRequired],
      'insuranceFieldPolicyType': [ar.insuranceFieldPolicyType, en.insuranceFieldPolicyType],
      'insuranceFieldPolicyTypeHint': [ar.insuranceFieldPolicyTypeHint, en.insuranceFieldPolicyTypeHint],
      'insurancePolicyTypeSpecific': [ar.insurancePolicyTypeSpecific, en.insurancePolicyTypeSpecific],
      'insurancePolicyTypeOpen': [ar.insurancePolicyTypeOpen, en.insurancePolicyTypeOpen],
      'insuranceFieldInsuranceCompany': [ar.insuranceFieldInsuranceCompany, en.insuranceFieldInsuranceCompany],
      'insuranceFieldPolicyNumber': [ar.insuranceFieldPolicyNumber, en.insuranceFieldPolicyNumber],
      'insuranceSecVoyageDetails': [ar.insuranceSecVoyageDetails, en.insuranceSecVoyageDetails],
      'insuranceFieldTransportMode': [ar.insuranceFieldTransportMode, en.insuranceFieldTransportMode],
      'insuranceFieldTransportModeHint': [ar.insuranceFieldTransportModeHint, en.insuranceFieldTransportModeHint],
      'insuranceTransportModeOcean': [ar.insuranceTransportModeOcean, en.insuranceTransportModeOcean],
      'insuranceTransportModeAir': [ar.insuranceTransportModeAir, en.insuranceTransportModeAir],
      'insuranceTransportModeRoad': [ar.insuranceTransportModeRoad, en.insuranceTransportModeRoad],
      'insuranceFieldCarrier': [ar.insuranceFieldCarrier, en.insuranceFieldCarrier],
      'insuranceFieldVesselFlight': [ar.insuranceFieldVesselFlight, en.insuranceFieldVesselFlight],
      'insuranceFieldPol': [ar.insuranceFieldPol, en.insuranceFieldPol],
      'insuranceFieldPod': [ar.insuranceFieldPod, en.insuranceFieldPod],
      'insuranceFieldBlTracking': [ar.insuranceFieldBlTracking, en.insuranceFieldBlTracking],
      'insuranceFieldInvoiceValue': [ar.insuranceFieldInvoiceValue, en.insuranceFieldInvoiceValue],
      'insuranceFieldFreightCost': [ar.insuranceFieldFreightCost, en.insuranceFieldFreightCost],
      'insuranceFieldCurrency': [ar.insuranceFieldCurrency, en.insuranceFieldCurrency],
      'insuranceFieldCurrencyHint': [ar.insuranceFieldCurrencyHint, en.insuranceFieldCurrencyHint],
      'insuranceCurrUsd': [ar.insuranceCurrUsd, en.insuranceCurrUsd],
      'insuranceCurrEur': [ar.insuranceCurrEur, en.insuranceCurrEur],
      'insuranceCurrEgp': [ar.insuranceCurrEgp, en.insuranceCurrEgp],
      'insuranceCurrCny': [ar.insuranceCurrCny, en.insuranceCurrCny],
      'insuranceCurrGbp': [ar.insuranceCurrGbp, en.insuranceCurrGbp],
      'insuranceSecCoverageClauses': [ar.insuranceSecCoverageClauses, en.insuranceSecCoverageClauses],
      'insuranceFieldCoverageClause': [ar.insuranceFieldCoverageClause, en.insuranceFieldCoverageClause],
      'insuranceFieldCoverageClauseHint': [ar.insuranceFieldCoverageClauseHint, en.insuranceFieldCoverageClauseHint],
      'insuranceClauseIccA': [ar.insuranceClauseIccA, en.insuranceClauseIccA],
      'insuranceClauseAirAllRisks': [ar.insuranceClauseAirAllRisks, en.insuranceClauseAirAllRisks],
      'insuranceClauseIccB': [ar.insuranceClauseIccB, en.insuranceClauseIccB],
      'insuranceClauseIccC': [ar.insuranceClauseIccC, en.insuranceClauseIccC],
      'insuranceWarAndStrikesTitle': [ar.insuranceWarAndStrikesTitle, en.insuranceWarAndStrikesTitle],
      'insuranceWarAndStrikesSubtitle': [ar.insuranceWarAndStrikesSubtitle, en.insuranceWarAndStrikesSubtitle],
      'insuranceSecBreakdownTitle': [ar.insuranceSecBreakdownTitle, en.insuranceSecBreakdownTitle],
      'insuranceBreakdownCifBase': [ar.insuranceBreakdownCifBase, en.insuranceBreakdownCifBase],
      'insuranceBreakdownInsuredValue': [ar.insuranceBreakdownInsuredValue, en.insuranceBreakdownInsuredValue],
      'insuranceBreakdownBasePremium': [ar.insuranceBreakdownBasePremium('0.25'), en.insuranceBreakdownBasePremium('0.25')],
      'insuranceBreakdownWarStrikes': [ar.insuranceBreakdownWarStrikes, en.insuranceBreakdownWarStrikes],
      'insuranceBreakdownNetPremium': [ar.insuranceBreakdownNetPremium, en.insuranceBreakdownNetPremium],
      'insuranceBreakdownIssuanceFee': [ar.insuranceBreakdownIssuanceFee, en.insuranceBreakdownIssuanceFee],
      'insuranceBreakdownTaxes': [ar.insuranceBreakdownTaxes, en.insuranceBreakdownTaxes],
      'insuranceBreakdownTotalPayable': [ar.insuranceBreakdownTotalPayable, en.insuranceBreakdownTotalPayable],
      'insuranceSecCargoSpecs': [ar.insuranceSecCargoSpecs, en.insuranceSecCargoSpecs],
      'insuranceFieldGoodsDesc': [ar.insuranceFieldGoodsDesc, en.insuranceFieldGoodsDesc],
      'insuranceFieldGoodsDescHint': [ar.insuranceFieldGoodsDescHint, en.insuranceFieldGoodsDescHint],
      'insuranceFieldPackagesCount': [ar.insuranceFieldPackagesCount, en.insuranceFieldPackagesCount],
      'insuranceFieldGrossWeight': [ar.insuranceFieldGrossWeight, en.insuranceFieldGrossWeight],
      'insuranceSavingState': [ar.insuranceSavingState, en.insuranceSavingState],
      'insuranceSaveDraftBtn': [ar.insuranceSaveDraftBtn, en.insuranceSaveDraftBtn],
      'insuranceCreatedSuccessMsg': [ar.insuranceCreatedSuccessMsg, en.insuranceCreatedSuccessMsg],
      'insuranceUpdatedSuccessMsg': [ar.insuranceUpdatedSuccessMsg, en.insuranceUpdatedSuccessMsg],
      'insuranceSaveErrorMsg': [ar.insuranceSaveErrorMsg('Connection timeout'), en.insuranceSaveErrorMsg('Connection timeout')],
      'insurancePreviewCertificateHeader': [ar.insurancePreviewCertificateHeader, en.insurancePreviewCertificateHeader],
      'insurancePreviewOfficialIssuedBadge': [ar.insurancePreviewOfficialIssuedBadge, en.insurancePreviewOfficialIssuedBadge],
      'insurancePreviewDraftBadge': [ar.insurancePreviewDraftBadge, en.insurancePreviewDraftBadge],
      'insurancePreviewSecInsuredDetails': [ar.insurancePreviewSecInsuredDetails, en.insurancePreviewSecInsuredDetails],
      'insurancePreviewInsuredLabel': [ar.insurancePreviewInsuredLabel, en.insurancePreviewInsuredLabel],
      'insurancePreviewCompanyLabel': [ar.insurancePreviewCompanyLabel, en.insurancePreviewCompanyLabel],
      'insurancePreviewPolicyNoLabel': [ar.insurancePreviewPolicyNoLabel, en.insurancePreviewPolicyNoLabel],
      'insurancePreviewPolicyTypeLabel': [ar.insurancePreviewPolicyTypeLabel, en.insurancePreviewPolicyTypeLabel],
      'insurancePreviewSecRouteDetails': [ar.insurancePreviewSecRouteDetails, en.insurancePreviewSecRouteDetails],
      'insurancePreviewTransportModeLabel': [ar.insurancePreviewTransportModeLabel, en.insurancePreviewTransportModeLabel],
      'insurancePreviewVesselFlightLabel': [ar.insurancePreviewVesselFlightLabel, en.insurancePreviewVesselFlightLabel],
      'insurancePreviewPolLabel': [ar.insurancePreviewPolLabel, en.insurancePreviewPolLabel],
      'insurancePreviewPodLabel': [ar.insurancePreviewPodLabel, en.insurancePreviewPodLabel],
      'insurancePreviewTrackingLabel': [ar.insurancePreviewTrackingLabel, en.insurancePreviewTrackingLabel],
      'insurancePreviewSecValuation': [ar.insurancePreviewSecValuation, en.insurancePreviewSecValuation],
      'insurancePreviewInvoiceFobLabel': [ar.insurancePreviewInvoiceFobLabel, en.insurancePreviewInvoiceFobLabel],
      'insurancePreviewFreightLabel': [ar.insurancePreviewFreightLabel, en.insurancePreviewFreightLabel],
      'insurancePreviewCifBaseLabel': [ar.insurancePreviewCifBaseLabel, en.insurancePreviewCifBaseLabel],
      'insurancePreviewInsuredSumLabel': [ar.insurancePreviewInsuredSumLabel, en.insurancePreviewInsuredSumLabel],
      'insurancePreviewSecPremium': [ar.insurancePreviewSecPremium, en.insurancePreviewSecPremium],
      'insurancePreviewCoverageClauseLabel': [ar.insurancePreviewCoverageClauseLabel, en.insurancePreviewCoverageClauseLabel],
      'insurancePreviewBasePremiumLabel': [ar.insurancePreviewBasePremiumLabel, en.insurancePreviewBasePremiumLabel],
      'insurancePreviewWarStrikesLabel': [ar.insurancePreviewWarStrikesLabel, en.insurancePreviewWarStrikesLabel],
      'insurancePreviewFeesTaxesLabel': [ar.insurancePreviewFeesTaxesLabel, en.insurancePreviewFeesTaxesLabel],
      'insurancePreviewTotalGrossPremiumLabel': [ar.insurancePreviewTotalGrossPremiumLabel, en.insurancePreviewTotalGrossPremiumLabel],
      'insurancePreviewSecCargoSpecs': [ar.insurancePreviewSecCargoSpecs, en.insurancePreviewSecCargoSpecs],
      'insurancePreviewDescPrefix': [ar.insurancePreviewDescPrefix, en.insurancePreviewDescPrefix],
      'insurancePreviewPackagesPrefix': [ar.insurancePreviewPackagesPrefix, en.insurancePreviewPackagesPrefix],
      'insurancePreviewGrossWtPrefix': [ar.insurancePreviewGrossWtPrefix, en.insurancePreviewGrossWtPrefix],
      'insurancePreviewSurveyAgentPrefix': [ar.insurancePreviewSurveyAgentPrefix, en.insurancePreviewSurveyAgentPrefix],
      'insurancePreviewClaimsPayablePrefix': [ar.insurancePreviewClaimsPayablePrefix, en.insurancePreviewClaimsPayablePrefix],
      'insurancePreviewLegalDisclaimer': [ar.insurancePreviewLegalDisclaimer, en.insurancePreviewLegalDisclaimer],
      'insurancePreviewPrintBtn': [ar.insurancePreviewPrintBtn, en.insurancePreviewPrintBtn],
      'insurancePreviewPrintReadySnack': [ar.insurancePreviewPrintReadySnack, en.insurancePreviewPrintReadySnack],
    };

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    test('All Screen 65 getters are defined and non-empty in Arabic & English', () {
      expect(insuranceGetters.length, greaterThanOrEqualTo(85));
      for (final entry in insuranceGetters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: ' (Arabic) must not be empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: ' (English) must not be empty');
      }
    });

    test('English strings must never contain Arabic characters', () {
      for (final entry in insuranceGetters.entries) {
        final key = entry.key;
        final enVal = entry.value[1];
        expect(
          arabicRegex.hasMatch(enVal),
          isFalse,
          reason: 'English key "" contains Arabic text: ""',
        );
      }
    });

    test('No getters contain stacked bilingual text patterns', () {
      final stackedBilingualPatterns = [
        '1. INSURED & POLICY DETAILS / بيانات المؤمن له',
        '2. VOYAGE & ROUTE / خط السير والناقل',
        '3. VALUATION & INSURED SUM / القيمة التأمينية',
        '4. PREMIUM BREAKDOWN / تفاصيل القسط',
        '5. CARGO SPECIFICATIONS & CLAUSES / تفاصيل البضاعة والشروط القانونية',
        'رفع واستخراج وثيقة التأمين / البوليصة الذكي',
        'رقم البوليصة / الشحنة',
        'الوسيلة وخط السير / Transport',
        'حذف / إلغاء',
      ];

      for (final entry in insuranceGetters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        for (final pattern in stackedBilingualPatterns) {
          expect(arVal.contains(pattern), isFalse, reason: 'Arabic key "" contains stacked pattern ""');
          expect(enVal.contains(pattern), isFalse, reason: 'English key "" contains stacked pattern ""');
        }
      }
    });
  });
}
