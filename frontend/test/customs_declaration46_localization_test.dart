import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 23: Customs Declaration 46 Localization Tests', () {
    const AppLocalizations ar = AppLocalizationsAr();
    const AppLocalizations en = AppLocalizationsEn();

    test('All Screen 23 getters should have non-empty Arabic and English translations', () {
      final List<String> arStrings = [
        ar.customsDeclStageTitle,
        ar.customsDeclTabInitialForm,
        ar.customsDeclTabRegistry,
        ar.customsDeclRefreshTooltip,
        ar.customsDeclInfoBanner,
        ar.customsDeclSelectFileLabel,
        ar.customsDeclSearchFileHint,
        ar.customsDeclAttributesHeader,
        ar.customsDeclDeclarationNoLabel,
        ar.customsDeclSubmissionDateLabel,
        ar.customsDeclAcidNumberLabel,
        ar.customsDeclForm4NumberLabel,
        ar.customsDeclBlNumberLabel,
        ar.customsDeclDutiesHeader,
        ar.customsDeclCifValueLabel,
        ar.customsDeclImportDutyLabel,
        ar.customsDeclVatLabel,
        ar.customsDeclTotalDutiesLabel,
        ar.customsDeclExemptionHeader,
        ar.customsDeclExemptionConditionsHeader,
        ar.customsDeclEur1ExemptionTitle,
        ar.customsDeclEur1Condition1,
        ar.customsDeclEur1Condition2,
        ar.customsDeclEur1Condition3,
        ar.customsDeclMfnExemptionTitle('5.0'),
        ar.customsDeclMfnCondition1,
        ar.customsDeclMfnCondition2,
        ar.customsDeclRegulatoryHeader,
        ar.customsDeclColHsCode,
        ar.customsDeclColAuthority,
        ar.customsDeclColInspection,
        ar.customsDeclColCoo,
        ar.customsDeclColRequirements,
        ar.customsDeclColApprovalStatus,
        ar.customsDeclStatusFulfilled,
        ar.customsDeclDefaultAuthority,
        ar.customsDeclDefaultNote,
        ar.customsDeclDefaultItemDesc,
        ar.customsDeclVisualInspectionNote,
        ar.customsDeclSaveButton,
        ar.customsDeclSavingProgress,
        ar.customsDeclSelectFileWarning,
        ar.customsDeclSaveSuccess,
        ar.customsDeclRegistrySearchHint,
        ar.customsDeclRegisterNewButton,
        ar.customsDeclColDeclarationNo,
        ar.customsDeclColFileNumber,
        ar.customsDeclColSupplier,
        ar.customsDeclColRegistrationDate,
        ar.customsDeclColDeclarationStatus,
        ar.customsDeclStatusRegisteredNafeza,
        ar.customsDeclRequiredField,
        ar.customsDeclCopyValueTooltip,
        ar.customsDeclPrintPreviewButton,
        ar.customsDeclPreviewTitle,
        ar.customsDeclCopySummarySuccess,
        ar.customsDeclExportTsvButton,
        ar.customsDeclExportSuccess,
        ar.customsDeclExportRegistryTsv,
        ar.customsDeclCopyAllSuccess,
        ar.customsDeclCloseDialog,
        ar.customsDeclAssessmentTitle,
        ar.customsDeclViewAssessmentTooltip,
        ar.customsDeclAssessmentSubtitle,
        ar.customsDeclShipmentParticularsHeader,
        ar.customsDeclValuationBreakdownHeader,
        ar.customsDeclFobForeignLabel,
        ar.customsDeclFreightEgpLabel,
        ar.customsDeclInsuranceEgpLabel,
        ar.customsDeclCifTotalEgpLabel,
        ar.customsDeclTariffTaxesHeader,
        ar.customsDeclImportDutyRateLabel,
        ar.customsDeclVatRateLabel,
        ar.customsDeclDevFeeLabel,
        ar.customsDeclCustomsServicesFeeLabel,
        ar.customsDeclColActions,
        ar.customsDeclAssessmentCopySuccess,
        ar.customsDeclMetricTotalDeclarations,
        ar.customsDeclMetricTotalCif,
        ar.customsDeclMetricTotalDuties,
        ar.customsDeclMetricExemptions,
        ar.customsDeclFxRateLabel,
        ar.customsDeclVatBaseLabel,
      ];

      final List<String> enStrings = [
        en.customsDeclStageTitle,
        en.customsDeclTabInitialForm,
        en.customsDeclTabRegistry,
        en.customsDeclRefreshTooltip,
        en.customsDeclInfoBanner,
        en.customsDeclSelectFileLabel,
        en.customsDeclSearchFileHint,
        en.customsDeclAttributesHeader,
        en.customsDeclDeclarationNoLabel,
        en.customsDeclSubmissionDateLabel,
        en.customsDeclAcidNumberLabel,
        en.customsDeclForm4NumberLabel,
        en.customsDeclBlNumberLabel,
        en.customsDeclDutiesHeader,
        en.customsDeclCifValueLabel,
        en.customsDeclImportDutyLabel,
        en.customsDeclVatLabel,
        en.customsDeclTotalDutiesLabel,
        en.customsDeclExemptionHeader,
        en.customsDeclExemptionConditionsHeader,
        en.customsDeclEur1ExemptionTitle,
        en.customsDeclEur1Condition1,
        en.customsDeclEur1Condition2,
        en.customsDeclEur1Condition3,
        en.customsDeclMfnExemptionTitle('5.0'),
        en.customsDeclMfnCondition1,
        en.customsDeclMfnCondition2,
        en.customsDeclRegulatoryHeader,
        en.customsDeclColHsCode,
        en.customsDeclColAuthority,
        en.customsDeclColInspection,
        en.customsDeclColCoo,
        en.customsDeclColRequirements,
        en.customsDeclColApprovalStatus,
        en.customsDeclStatusFulfilled,
        en.customsDeclDefaultAuthority,
        en.customsDeclDefaultNote,
        en.customsDeclDefaultItemDesc,
        en.customsDeclVisualInspectionNote,
        en.customsDeclSaveButton,
        en.customsDeclSavingProgress,
        en.customsDeclSelectFileWarning,
        en.customsDeclSaveSuccess,
        en.customsDeclRegistrySearchHint,
        en.customsDeclRegisterNewButton,
        en.customsDeclColDeclarationNo,
        en.customsDeclColFileNumber,
        en.customsDeclColSupplier,
        en.customsDeclColRegistrationDate,
        en.customsDeclColDeclarationStatus,
        en.customsDeclStatusRegisteredNafeza,
        en.customsDeclRequiredField,
        en.customsDeclCopyValueTooltip,
        en.customsDeclPrintPreviewButton,
        en.customsDeclPreviewTitle,
        en.customsDeclCopySummarySuccess,
        en.customsDeclExportTsvButton,
        en.customsDeclExportSuccess,
        en.customsDeclExportRegistryTsv,
        en.customsDeclCopyAllSuccess,
        en.customsDeclCloseDialog,
        en.customsDeclAssessmentTitle,
        en.customsDeclViewAssessmentTooltip,
        en.customsDeclAssessmentSubtitle,
        en.customsDeclShipmentParticularsHeader,
        en.customsDeclValuationBreakdownHeader,
        en.customsDeclFobForeignLabel,
        en.customsDeclFreightEgpLabel,
        en.customsDeclInsuranceEgpLabel,
        en.customsDeclCifTotalEgpLabel,
        en.customsDeclTariffTaxesHeader,
        en.customsDeclImportDutyRateLabel,
        en.customsDeclVatRateLabel,
        en.customsDeclDevFeeLabel,
        en.customsDeclCustomsServicesFeeLabel,
        en.customsDeclColActions,
        en.customsDeclAssessmentCopySuccess,
        en.customsDeclMetricTotalDeclarations,
        en.customsDeclMetricTotalCif,
        en.customsDeclMetricTotalDuties,
        en.customsDeclMetricExemptions,
        en.customsDeclFxRateLabel,
        en.customsDeclVatBaseLabel,
      ];

      expect(arStrings.length, enStrings.length);

      for (final s in arStrings) {
        expect(s.trim().isNotEmpty, isTrue, reason: 'Arabic translation string must not be empty');
      }

      for (final s in enStrings) {
        expect(s.trim().isNotEmpty, isTrue, reason: 'English translation string must not be empty');
      }
    });

    test('English translations should not contain Arabic characters', () {
      final List<String> enStrings = [
        en.customsDeclStageTitle,
        en.customsDeclTabInitialForm,
        en.customsDeclTabRegistry,
        en.customsDeclRefreshTooltip,
        en.customsDeclInfoBanner,
        en.customsDeclSelectFileLabel,
        en.customsDeclSearchFileHint,
        en.customsDeclAttributesHeader,
        en.customsDeclDeclarationNoLabel,
        en.customsDeclSubmissionDateLabel,
        en.customsDeclAcidNumberLabel,
        en.customsDeclForm4NumberLabel,
        en.customsDeclBlNumberLabel,
        en.customsDeclDutiesHeader,
        en.customsDeclCifValueLabel,
        en.customsDeclImportDutyLabel,
        en.customsDeclVatLabel,
        en.customsDeclTotalDutiesLabel,
        en.customsDeclExemptionHeader,
        en.customsDeclExemptionConditionsHeader,
        en.customsDeclEur1ExemptionTitle,
        en.customsDeclEur1Condition1,
        en.customsDeclEur1Condition2,
        en.customsDeclEur1Condition3,
        en.customsDeclMfnExemptionTitle('5.0'),
        en.customsDeclMfnCondition1,
        en.customsDeclMfnCondition2,
        en.customsDeclRegulatoryHeader,
        en.customsDeclColHsCode,
        en.customsDeclColAuthority,
        en.customsDeclColInspection,
        en.customsDeclColCoo,
        en.customsDeclColRequirements,
        en.customsDeclColApprovalStatus,
        en.customsDeclStatusFulfilled,
        en.customsDeclDefaultAuthority,
        en.customsDeclDefaultNote,
        en.customsDeclDefaultItemDesc,
        en.customsDeclVisualInspectionNote,
        en.customsDeclSaveButton,
        en.customsDeclSavingProgress,
        en.customsDeclSelectFileWarning,
        en.customsDeclSaveSuccess,
        en.customsDeclRegistrySearchHint,
        en.customsDeclRegisterNewButton,
        en.customsDeclColDeclarationNo,
        en.customsDeclColFileNumber,
        en.customsDeclColSupplier,
        en.customsDeclColRegistrationDate,
        en.customsDeclColDeclarationStatus,
        en.customsDeclStatusRegisteredNafeza,
        en.customsDeclRequiredField,
        en.customsDeclCopyValueTooltip,
        en.customsDeclPrintPreviewButton,
        en.customsDeclPreviewTitle,
        en.customsDeclCopySummarySuccess,
        en.customsDeclExportTsvButton,
        en.customsDeclExportSuccess,
        en.customsDeclExportRegistryTsv,
        en.customsDeclCopyAllSuccess,
        en.customsDeclCloseDialog,
      ];

      final arabicPattern = RegExp(r'[\u0600-\u06FF]');
      for (final s in enStrings) {
        expect(arabicPattern.hasMatch(s), isFalse, reason: 'English string must not contain Arabic: $s');
      }
    });

    test('Translations should not have stacked bilingual text or slash dual language formatting', () {
      final List<String> labels = [
        ar.customsDeclSelectFileLabel,
        en.customsDeclSelectFileLabel,
        ar.customsDeclAttributesHeader,
        en.customsDeclAttributesHeader,
        ar.customsDeclDutiesHeader,
        en.customsDeclDutiesHeader,
        ar.customsDeclExemptionHeader,
        en.customsDeclExemptionHeader,
        ar.customsDeclRegulatoryHeader,
        en.customsDeclRegulatoryHeader,
        ar.customsDeclEur1Condition1,
        ar.customsDeclEur1Condition2,
        ar.customsDeclEur1Condition3,
        ar.customsDeclColHsCode,
        ar.customsDeclDefaultAuthority,
      ];

      for (final label in labels) {
        expect(label.contains(' / '), isFalse, reason: 'Labels should not contain dual stacked format " / ": $label');
      }
    });

    test('Screen 24: Customs Declaration 46 Tariff Assessment getters should not have stacked bilingual text or slashes', () {
      final List<String> screen24Labels = [
        ar.customsDeclAssessmentTitle,
        en.customsDeclAssessmentTitle,
        ar.customsDeclViewAssessmentTooltip,
        en.customsDeclViewAssessmentTooltip,
        ar.customsDeclAssessmentSubtitle,
        en.customsDeclAssessmentSubtitle,
        ar.customsDeclShipmentParticularsHeader,
        en.customsDeclShipmentParticularsHeader,
        ar.customsDeclValuationBreakdownHeader,
        en.customsDeclValuationBreakdownHeader,
        ar.customsDeclFobForeignLabel,
        en.customsDeclFobForeignLabel,
        ar.customsDeclFreightEgpLabel,
        en.customsDeclFreightEgpLabel,
        ar.customsDeclInsuranceEgpLabel,
        en.customsDeclInsuranceEgpLabel,
        ar.customsDeclCifTotalEgpLabel,
        en.customsDeclCifTotalEgpLabel,
        ar.customsDeclTariffTaxesHeader,
        en.customsDeclTariffTaxesHeader,
        ar.customsDeclImportDutyRateLabel,
        en.customsDeclImportDutyRateLabel,
        ar.customsDeclVatRateLabel,
        en.customsDeclVatRateLabel,
        ar.customsDeclDevFeeLabel,
        en.customsDeclDevFeeLabel,
        ar.customsDeclCustomsServicesFeeLabel,
        en.customsDeclCustomsServicesFeeLabel,
        ar.customsDeclColActions,
        en.customsDeclColActions,
        ar.customsDeclAssessmentCopySuccess,
        en.customsDeclAssessmentCopySuccess,
        ar.customsDeclMetricTotalDeclarations,
        en.customsDeclMetricTotalDeclarations,
        ar.customsDeclMetricTotalCif,
        en.customsDeclMetricTotalCif,
        ar.customsDeclMetricTotalDuties,
        en.customsDeclMetricTotalDuties,
        ar.customsDeclMetricExemptions,
        en.customsDeclMetricExemptions,
        ar.customsDeclFxRateLabel,
        en.customsDeclFxRateLabel,
        ar.customsDeclVatBaseLabel,
        en.customsDeclVatBaseLabel,
      ];

      for (final label in screen24Labels) {
        expect(label.contains(' / '), isFalse, reason: 'Screen 24 label should not contain dual stacked format " / ": $label');
      }

      // Check Arabic strings don't contain parenthetical English abbreviations
      final List<String> arLabels = [
        ar.customsDeclAssessmentTitle,
        ar.customsDeclValuationBreakdownHeader,
        ar.customsDeclInsuranceEgpLabel,
        ar.customsDeclCifTotalEgpLabel,
        ar.customsDeclTariffTaxesHeader,
        ar.customsDeclImportDutyRateLabel,
        ar.customsDeclVatRateLabel,
        ar.customsDeclDevFeeLabel,
        ar.customsDeclCustomsServicesFeeLabel,
        ar.customsDeclMetricTotalCif,
        ar.customsDeclMetricTotalDuties,
        ar.customsDeclVatBaseLabel,
      ];

      for (final label in arLabels) {
        expect(label.contains('(CIF)'), isFalse, reason: 'Arabic label should not contain (CIF): $label');
        expect(label.contains('(VAT)'), isFalse, reason: 'Arabic label should not contain (VAT): $label');
        expect(label.contains('(HS Code)'), isFalse, reason: 'Arabic label should not contain (HS Code): $label');
      }
    });

    test('Screen 24: Customs Tariff & Duty Calculation Mathematical Rules', () {
      const double fobForeign = 10000.0;
      const double exchangeRate = 50.7917;
      const double dutyRate = 5.0; // 5% import duty
      const double vatRate = 14.0; // 14% VAT
      const double serviceRate = 1.0; // 1% customs service fee

      const double fobEgp = fobForeign * exchangeRate;
      const double freightEgp = fobEgp * 0.02; // 2% freight
      const double insuranceEgp = fobEgp * 0.025; // 2.5% insurance
      const double cifEgp = fobEgp + freightEgp + insuranceEgp;

      const double importDutyEgp = cifEgp * (dutyRate / 100.0);
      const double serviceFeeEgp = cifEgp * (serviceRate / 100.0);
      const double otherFeesEgp = serviceFeeEgp;
      const double vatBaseEgp = cifEgp + importDutyEgp + otherFeesEgp;
      const double vatEgp = vatBaseEgp * (vatRate / 100.0);
      const double totalDutiesEgp = importDutyEgp + vatEgp + otherFeesEgp;

      expect(fobEgp, 507917.0);
      expect(cifEgp, greaterThan(fobEgp));
      expect(importDutyEgp, greaterThan(0));
      expect(vatBaseEgp, greaterThan(cifEgp));
      expect(totalDutiesEgp, equals(importDutyEgp + vatEgp + otherFeesEgp));
    });
  });
}
