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
      ];

      for (final label in labels) {
        expect(label.contains(' / '), isFalse, reason: 'Labels should not contain dual stacked format " / ": $label');
      }
    });
  });
}
