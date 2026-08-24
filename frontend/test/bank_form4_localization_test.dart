import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 16: Bank Form 4 Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    final screen16Getters = <String, List<String>>{
      'bankForm4Title': [ar.bankForm4Title, en.bankForm4Title],
      'form4RequestTab': [ar.form4RequestTab, en.form4RequestTab],
      'bankForm4RegistryTab': [ar.bankForm4RegistryTab, en.bankForm4RegistryTab],
      'bankForm4EditingBanner': [ar.bankForm4EditingBanner('DOC-001'), en.bankForm4EditingBanner('DOC-001')],
      'cancelEditNewForm4': [ar.cancelEditNewForm4, en.cancelEditNewForm4],
      'selectImportFileForm4Label': [ar.selectImportFileForm4Label, en.selectImportFileForm4Label],
      'bankApplicationDetailsSection': [ar.bankApplicationDetailsSection, en.bankApplicationDetailsSection],
      'issuingBankLabel': [ar.issuingBankLabel, en.issuingBankLabel],
      'selectBankHint': [ar.selectBankHint, en.selectBankHint],
      'bankAmountLabel': [ar.bankAmountLabel, en.bankAmountLabel],
      'transferCurrencyLabel': [ar.transferCurrencyLabel, en.transferCurrencyLabel],
      'selectCurrencyHint': [ar.selectCurrencyHint, en.selectCurrencyHint],
      'bankRequestDateLabel': [ar.bankRequestDateLabel, en.bankRequestDateLabel],
      'bankNotesLabel': [ar.bankNotesLabel, en.bankNotesLabel],
      'form4ChecklistSectionTitle': [ar.form4ChecklistSectionTitle, en.form4ChecklistSectionTitle],
      'form4ItemProformaInvoice': [ar.form4ItemProformaInvoice, en.form4ItemProformaInvoice],
      'form4ItemPackingList': [ar.form4ItemPackingList, en.form4ItemPackingList],
      'form4ItemCertificateOfOrigin': [ar.form4ItemCertificateOfOrigin, en.form4ItemCertificateOfOrigin],
      'form4ItemBillOfLading': [ar.form4ItemBillOfLading, en.form4ItemBillOfLading],
      'form4ItemAcidNotice': [ar.form4ItemAcidNotice, en.form4ItemAcidNotice],
      'form4ItemMarineInsurance': [ar.form4ItemMarineInsurance, en.form4ItemMarineInsurance],
      'form4ItemBankApplication': [ar.form4ItemBankApplication, en.form4ItemBankApplication],
      'form4ItemAdminFeeReceipt': [ar.form4ItemAdminFeeReceipt, en.form4ItemAdminFeeReceipt],
      'saveForm4Button': [ar.saveForm4Button, en.saveForm4Button],
      'updateForm4Button': [ar.updateForm4Button, en.updateForm4Button],
      'goToBankRegistryButton': [ar.goToBankRegistryButton, en.goToBankRegistryButton],
      'searchBankRegistryHint': [ar.searchBankRegistryHint, en.searchBankRegistryHint],
      'newForm4RequestButton': [ar.newForm4RequestButton, en.newForm4RequestButton],
      'documentCodeCol': [ar.documentCodeCol, en.documentCodeCol],
      'certifiedBankCol': [ar.certifiedBankCol, en.certifiedBankCol],
      'amountAndCurrencyCol': [ar.amountAndCurrencyCol, en.amountAndCurrencyCol],
      'requestDateCol': [ar.requestDateCol, en.requestDateCol],
      'endorsementStatusCol': [ar.endorsementStatusCol, en.endorsementStatusCol],
      'endorsedStatusBadge': [ar.endorsedStatusBadge, en.endorsedStatusBadge],
      'bankProcessingStatusBadge': [ar.bankProcessingStatusBadge, en.bankProcessingStatusBadge],
      'selectImportFileFirstWarning': [ar.selectImportFileFirstWarning, en.selectImportFileFirstWarning],
      'form4SavedSuccess': [ar.form4SavedSuccess, en.form4SavedSuccess],
      'form4SaveError': [ar.form4SaveError, en.form4SaveError],
    };

    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    test('All Screen 16 getters are defined and non-empty in Arabic & English', () {
      expect(screen16Getters.length, greaterThanOrEqualTo(35));
      for (final entry in screen16Getters.entries) {
        final key = entry.key;
        final arVal = entry.value[0];
        final enVal = entry.value[1];

        expect(arVal.trim().isNotEmpty, isTrue, reason: '$key (Arabic) must not be empty');
        expect(enVal.trim().isNotEmpty, isTrue, reason: '$key (English) must not be empty');
      }
    });

    test('English strings must never contain Arabic characters', () {
      for (final entry in screen16Getters.entries) {
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
        '(Bank Application & Endorsement Details)',
        '(Issuing Bank)',
        '(Amount)',
        '(Currency)',
        '(Request Date)',
        '(Required Attachments Checklist)',
        '(Refresh)',
      ];

      for (final entry in screen16Getters.entries) {
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
