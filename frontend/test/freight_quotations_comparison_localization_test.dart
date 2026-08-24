import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 49: Freight Quotations Comparison Localization Tests', () {
    late AppLocalizations ar;
    late AppLocalizations en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('All Screen 49 getters should return non-empty strings in Arabic and English', () {
      expect(ar.freightQuotationsComparisonTitle, isNotEmpty);
      expect(en.freightQuotationsComparisonTitle, isNotEmpty);
      expect(ar.selectImportFileDropdownLabel, isNotEmpty);
      expect(en.selectImportFileDropdownLabel, isNotEmpty);
      expect(ar.selectImportFileDropdownHint, isNotEmpty);
      expect(en.selectImportFileDropdownHint, isNotEmpty);
      expect(ar.unknownSupplierFallback, isNotEmpty);
      expect(en.unknownSupplierFallback, isNotEmpty);
      expect(ar.freightQuotesLoadError('Network error'), contains('Network error'));
      expect(en.freightQuotesLoadError('Network error'), contains('Network error'));
      expect(ar.selectImportFilePrompt, isNotEmpty);
      expect(en.selectImportFilePrompt, isNotEmpty);
      expect(ar.noFreightQuotesForFile, isNotEmpty);
      expect(en.noFreightQuotesForFile, isNotEmpty);
      expect(ar.notSelectedYet, isNotEmpty);
      expect(en.notSelectedYet, isNotEmpty);
      expect(ar.metricCheapestQuote, isNotEmpty);
      expect(en.metricCheapestQuote, isNotEmpty);
      expect(ar.metricFastestQuote, isNotEmpty);
      expect(en.metricFastestQuote, isNotEmpty);
      expect(ar.transitDaysCount(24), contains('24'));
      expect(en.transitDaysCount(24), contains('24'));
      expect(ar.metricCurrentlySelected, isNotEmpty);
      expect(en.metricCurrentlySelected, isNotEmpty);
      expect(ar.badgeBestPrice, isNotEmpty);
      expect(en.badgeBestPrice, isNotEmpty);
      expect(ar.unknownCarrierFallback, isNotEmpty);
      expect(en.unknownCarrierFallback, isNotEmpty);
      expect(ar.totalFreightCostLabel, isNotEmpty);
      expect(en.totalFreightCostLabel, isNotEmpty);
      expect(ar.oceanFreightLabel, isNotEmpty);
      expect(en.oceanFreightLabel, isNotEmpty);
      expect(ar.localChargesLabel, isNotEmpty);
      expect(en.localChargesLabel, isNotEmpty);
      expect(ar.transitDurationLabel, isNotEmpty);
      expect(en.transitDurationLabel, isNotEmpty);
      expect(ar.sailingDateLabel, isNotEmpty);
      expect(en.sailingDateLabel, isNotEmpty);
      expect(ar.estimatedArrivalDateLabel, isNotEmpty);
      expect(en.estimatedArrivalDateLabel, isNotEmpty);
      expect(ar.remarksLabel, isNotEmpty);
      expect(en.remarksLabel, isNotEmpty);
      expect(ar.quoteAwardedBtn, isNotEmpty);
      expect(en.quoteAwardedBtn, isNotEmpty);
      expect(ar.awardQuoteBtn, isNotEmpty);
      expect(en.awardQuoteBtn, isNotEmpty);
      expect(ar.freightQuoteSelectedSuccess, isNotEmpty);
      expect(en.freightQuoteSelectedSuccess, isNotEmpty);
      expect(ar.freightQuoteAwardedSuccess, isNotEmpty);
      expect(en.freightQuoteAwardedSuccess, isNotEmpty);
      expect(ar.freightQuoteAwardError('Server 500'), contains('Server 500'));
      expect(en.freightQuoteAwardError('Server 500'), contains('Server 500'));
    });

    test('Arabic static strings should not contain English or Latin characters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');
      expect(latinPattern.hasMatch(ar.freightQuotationsComparisonTitle), isFalse);
      expect(latinPattern.hasMatch(ar.selectImportFileDropdownLabel), isFalse);
      expect(latinPattern.hasMatch(ar.selectImportFileDropdownHint), isFalse);
      expect(latinPattern.hasMatch(ar.unknownSupplierFallback), isFalse);
      expect(latinPattern.hasMatch(ar.selectImportFilePrompt), isFalse);
      expect(latinPattern.hasMatch(ar.noFreightQuotesForFile), isFalse);
      expect(latinPattern.hasMatch(ar.notSelectedYet), isFalse);
      expect(latinPattern.hasMatch(ar.metricCheapestQuote), isFalse);
      expect(latinPattern.hasMatch(ar.metricFastestQuote), isFalse);
      expect(latinPattern.hasMatch(ar.metricCurrentlySelected), isFalse);
      expect(latinPattern.hasMatch(ar.badgeBestPrice), isFalse);
      expect(latinPattern.hasMatch(ar.unknownCarrierFallback), isFalse);
      expect(latinPattern.hasMatch(ar.totalFreightCostLabel), isFalse);
      expect(latinPattern.hasMatch(ar.oceanFreightLabel), isFalse);
      expect(latinPattern.hasMatch(ar.localChargesLabel), isFalse);
      expect(latinPattern.hasMatch(ar.transitDurationLabel), isFalse);
      expect(latinPattern.hasMatch(ar.sailingDateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.estimatedArrivalDateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.remarksLabel), isFalse);
      expect(latinPattern.hasMatch(ar.quoteAwardedBtn), isFalse);
      expect(latinPattern.hasMatch(ar.awardQuoteBtn), isFalse);
      expect(latinPattern.hasMatch(ar.freightQuoteSelectedSuccess), isFalse);
      expect(latinPattern.hasMatch(ar.freightQuoteAwardedSuccess), isFalse);
    });
  });
}
