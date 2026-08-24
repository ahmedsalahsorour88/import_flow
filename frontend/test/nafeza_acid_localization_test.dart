import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 11: Nafeza & ACID Operations Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final screen11Getters = <String, List<String>>{
      'nafezaAcidTitle': [ar.nafezaAcidTitle, en.nafezaAcidTitle],
      'acidRequestTab': [ar.acidRequestTab, en.acidRequestTab],
      'smartMtsParserTab': [ar.smartMtsParserTab, en.smartMtsParserTab],
      'discrepancyMatrixTab': [ar.discrepancyMatrixTab, en.discrepancyMatrixTab],
      'acidRegistryTab': [ar.acidRegistryTab, en.acidRegistryTab],
      'expiryTrackerTab': [ar.expiryTrackerTab, en.expiryTrackerTab],
      'acidInfoBanner': [ar.acidInfoBanner, en.acidInfoBanner],
      'selectImportFileAcidLabel': [ar.selectImportFileAcidLabel, en.selectImportFileAcidLabel],
      'searchFileOrSupplierHint': [ar.searchFileOrSupplierHint, en.searchFileOrSupplierHint],
      'importerAndExporterSection': [ar.importerAndExporterSection, en.importerAndExporterSection],
      'importerSectionTitle': [ar.importerSectionTitle, en.importerSectionTitle],
      'importerTaxIdLabel': [ar.importerTaxIdLabel, en.importerTaxIdLabel],
      'importerAddressLabel': [ar.importerAddressLabel, en.importerAddressLabel],
      'foreignExporterSectionTitle': [ar.foreignExporterSectionTitle, en.foreignExporterSectionTitle],
      'foreignExporterIdLabel': [ar.foreignExporterIdLabel, en.foreignExporterIdLabel],
      'regTypeLabel': [ar.regTypeLabel, en.regTypeLabel],
      'countryOfOriginExportLabel': [ar.countryOfOriginExportLabel, en.countryOfOriginExportLabel],
      'cargoxPlatformIdLabel': [ar.cargoxPlatformIdLabel, en.cargoxPlatformIdLabel],
      'proformaPortsBrokerSection': [ar.proformaPortsBrokerSection, en.proformaPortsBrokerSection],
      'proformaInvoiceNoLabel': [ar.proformaInvoiceNoLabel, en.proformaInvoiceNoLabel],
      'proformaInvoiceDateLabel': [ar.proformaInvoiceDateLabel, en.proformaInvoiceDateLabel],
      'invoiceTypeLabel': [ar.invoiceTypeLabel, en.invoiceTypeLabel],
      'portOfLoadingLabel': [ar.portOfLoadingLabel, en.portOfLoadingLabel],
      'portOfDischargeLabel': [ar.portOfDischargeLabel, en.portOfDischargeLabel],
      'customsBrokerResponsibleLabel': [ar.customsBrokerResponsibleLabel, en.customsBrokerResponsibleLabel],
      'brokerPhoneLabel': [ar.brokerPhoneLabel, en.brokerPhoneLabel],
      'acidRequestDateLabel': [ar.acidRequestDateLabel, en.acidRequestDateLabel],
      'saveAcidRequestButton': [ar.saveAcidRequestButton, en.saveAcidRequestButton],
      'updateAcidRequestButton': [ar.updateAcidRequestButton, en.updateAcidRequestButton],
      'goToSmartParserButton': [ar.goToSmartParserButton, en.goToSmartParserButton],
      'brokerDispatchMessageTitle': [ar.brokerDispatchMessageTitle, en.brokerDispatchMessageTitle],
      'brokerDispatchMessageSub': [ar.brokerDispatchMessageSub, en.brokerDispatchMessageSub],
      'copyArabicWhatsApp': [ar.copyArabicWhatsApp, en.copyArabicWhatsApp],
      'copyEnglishRequest': [ar.copyEnglishRequest, en.copyEnglishRequest],
      'emailTemplateButton': [ar.emailTemplateButton, en.emailTemplateButton],
      'smartParserInfoBanner': [ar.smartParserInfoBanner, en.smartParserInfoBanner],
      'linkImportFileResult': [ar.linkImportFileResult, en.linkImportFileResult],
      'pasteRawMtsTextTitle': [ar.pasteRawMtsTextTitle, en.pasteRawMtsTextTitle],
      'loadSampleMtsTextButton': [ar.loadSampleMtsTextButton, en.loadSampleMtsTextButton],
      'pasteFromClipboardButton': [ar.pasteFromClipboardButton, en.pasteFromClipboardButton],
      'runSmartParserButton': [ar.runSmartParserButton, en.runSmartParserButton],
      'clearTextButton': [ar.clearTextButton, en.clearTextButton],
      'parsedMtsSuccessTitle': [ar.parsedMtsSuccessTitle, en.parsedMtsSuccessTitle],
      'parsedMtsNoAcidTitle': [ar.parsedMtsNoAcidTitle, en.parsedMtsNoAcidTitle],
      'goToVerificationButton': [ar.goToVerificationButton, en.goToVerificationButton],
      'saveAndCertifyAcidButton': [ar.saveAndCertifyAcidButton, en.saveAndCertifyAcidButton],
      'saveTempDraftButton': [ar.saveTempDraftButton, en.saveTempDraftButton],
      'editExtractedDataButton': [ar.editExtractedDataButton, en.editExtractedDataButton],
      'codeSupplierButton': [ar.codeSupplierButton, en.codeSupplierButton],
      'acidNumberCol': [ar.acidNumberCol, en.acidNumberCol],
      'issueDateCol': [ar.issueDateCol, en.issueDateCol],
      'expiryDateCol': [ar.expiryDateCol, en.expiryDateCol],
      'foreignExporterCol': [ar.foreignExporterCol, en.foreignExporterCol],
      'importerCompanyCol': [ar.importerCompanyCol, en.importerCompanyCol],
      'actionCol': [ar.actionCol, en.actionCol],
      'daysRemainingCol': [ar.daysRemainingCol, en.daysRemainingCol],
      'validityStatusCol': [ar.validityStatusCol, en.validityStatusCol],
      'runDiscrepancyMatrixButton': [ar.runDiscrepancyMatrixButton, en.runDiscrepancyMatrixButton],
      'perfectMatchTitle': [ar.perfectMatchTitle, en.perfectMatchTitle],
      'discrepancyFoundTitle': [ar.discrepancyFoundTitle, en.discrepancyFoundTitle],
      'customsFieldCol': [ar.customsFieldCol, en.customsFieldCol],
      'requestedValueCol': [ar.requestedValueCol, en.requestedValueCol],
      'generatedValueCol': [ar.generatedValueCol, en.generatedValueCol],
      'matchingStatusCol': [ar.matchingStatusCol, en.matchingStatusCol],
      'discrepancyOverrideJustificationLabel': [ar.discrepancyOverrideJustificationLabel, en.discrepancyOverrideJustificationLabel],
      'verifyAndCertifyAcidButton': [ar.verifyAndCertifyAcidButton, en.verifyAndCertifyAcidButton],
      'searchAcidRegistryHint': [ar.searchAcidRegistryHint, en.searchAcidRegistryHint],
      'newAcidRequestButton': [ar.newAcidRequestButton, en.newAcidRequestButton],
      'totalAcidsCard': [ar.totalAcidsCard, en.totalAcidsCard],
      'validAcidsCard': [ar.validAcidsCard, en.validAcidsCard],
      'expiringSoonAcidsCard': [ar.expiringSoonAcidsCard, en.expiringSoonAcidsCard],
      'expiredAcidsCard': [ar.expiredAcidsCard, en.expiredAcidsCard],
      'searchExpiryTrackerHint': [ar.searchExpiryTrackerHint, en.searchExpiryTrackerHint],
      'validStatusBadge': [ar.validStatusBadge, en.validStatusBadge],
      'expiringSoonStatusBadge': [ar.expiringSoonStatusBadge, en.expiringSoonStatusBadge],
      'expiredStatusBadge': [ar.expiredStatusBadge, en.expiredStatusBadge],
      'matchedStatus': [ar.matchedStatus, en.matchedStatus],
      'discrepancyStatus': [ar.discrepancyStatus, en.discrepancyStatus],
      'issuedAndValidStatus': [ar.issuedAndValidStatus, en.issuedAndValidStatus],
      'tempDraftStatus': [ar.tempDraftStatus, en.tempDraftStatus],
      'underReviewStatus': [ar.underReviewStatus, en.underReviewStatus],
    };

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    test('All Screen 11 getters are defined and non-empty in Arabic & English', () {
      expect(screen11Getters.length, greaterThanOrEqualTo(50));
      for (final entry in screen11Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: '$key (Arabic) must not be empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: '$key (English) must not be empty');
      }
    });

    test('English strings must never contain Arabic characters', () {
      for (final entry in screen11Getters.entries) {
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
        '(Select Import File)',
        '(Importer & Exporter Parties)',
        '(Importer Company)',
        '(Foreign Exporter)',
        '(PI Number)',
        '(PI Date)',
        '(Raw Nafeza MTS Text)',
        '(Parsed MTS Result)',
        '(Edit Extracted MTS Data)',
      ];

      for (final entry in screen11Getters.entries) {
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
