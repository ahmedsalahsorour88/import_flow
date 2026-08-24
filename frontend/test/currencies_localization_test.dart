import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 38: Currencies & Exchange Rates Localization Tests', () {
    const AppLocalizations ar = AppLocalizationsAr();
    const AppLocalizations en = AppLocalizationsEn();

    test('Screen 38 Getters exist and are non-empty in both AR and EN', () {
      // Screen title and subtitle
      expect(ar.currenciesScreenTitle.isNotEmpty, isTrue);
      expect(en.currenciesScreenTitle.isNotEmpty, isTrue);
      expect(ar.currenciesScreenSubtitle.isNotEmpty, isTrue);
      expect(en.currenciesScreenSubtitle.isNotEmpty, isTrue);

      // Generic pagination
      expect(ar.rowsPerPageLabel.isNotEmpty, isTrue);
      expect(en.rowsPerPageLabel.isNotEmpty, isTrue);
      expect(ar.firstPageTooltip.isNotEmpty, isTrue);
      expect(en.firstPageTooltip.isNotEmpty, isTrue);
      expect(ar.previousPageTooltip.isNotEmpty, isTrue);
      expect(en.previousPageTooltip.isNotEmpty, isTrue);
      expect(ar.pageOfTotal(1, 10).contains('10'), isTrue);
      expect(en.pageOfTotal(1, 10).contains('10'), isTrue);
      expect(ar.nextPageTooltip.isNotEmpty, isTrue);
      expect(en.nextPageTooltip.isNotEmpty, isTrue);
      expect(ar.lastPageTooltip.isNotEmpty, isTrue);
      expect(en.lastPageTooltip.isNotEmpty, isTrue);

      // Buttons
      expect(ar.liveCurrencyConverterBtn.isNotEmpty, isTrue);
      expect(en.liveCurrencyConverterBtn.isNotEmpty, isTrue);
      expect(ar.currencyGainLossBtn.isNotEmpty, isTrue);
      expect(en.currencyGainLossBtn.isNotEmpty, isTrue);
      expect(ar.updateExchangeRatesBtn.isNotEmpty, isTrue);
      expect(en.updateExchangeRatesBtn.isNotEmpty, isTrue);
      expect(ar.addCurrencyBtn.isNotEmpty, isTrue);
      expect(en.addCurrencyBtn.isNotEmpty, isTrue);

      // Search and states
      expect(ar.searchCurrenciesHint.isNotEmpty, isTrue);
      expect(en.searchCurrenciesHint.isNotEmpty, isTrue);
      expect(ar.currenciesFetchError('error').contains('error'), isTrue);
      expect(en.currenciesFetchError('error').contains('error'), isTrue);
      expect(ar.noCurrenciesFound.isNotEmpty, isTrue);
      expect(en.noCurrenciesFound.isNotEmpty, isTrue);

      // Table columns
      expect(ar.isoCodeCol.isNotEmpty, isTrue);
      expect(en.isoCodeCol.isNotEmpty, isTrue);
      expect(ar.currencyNameCol.isNotEmpty, isTrue);
      expect(en.currencyNameCol.isNotEmpty, isTrue);
      expect(ar.currencySymbolCol.isNotEmpty, isTrue);
      expect(en.currencySymbolCol.isNotEmpty, isTrue);
      expect(ar.commercialRateBankCol.isNotEmpty, isTrue);
      expect(en.commercialRateBankCol.isNotEmpty, isTrue);
      expect(ar.customsRateOfficialCol.isNotEmpty, isTrue);
      expect(en.customsRateOfficialCol.isNotEmpty, isTrue);

      // Tooltips & formatted values
      expect(ar.baseCurrencyTooltip.isNotEmpty, isTrue);
      expect(en.baseCurrencyTooltip.isNotEmpty, isTrue);
      expect(ar.viewRateHistoryTooltip.isNotEmpty, isTrue);
      expect(en.viewRateHistoryTooltip.isNotEmpty, isTrue);
      expect(ar.baseCurrencyRateLabel.isNotEmpty, isTrue);
      expect(en.baseCurrencyRateLabel.isNotEmpty, isTrue);
      expect(ar.rateToEgpFormatted('USD', '50.25').contains('50.25'), isTrue);
      expect(en.rateToEgpFormatted('USD', '50.25').contains('50.25'), isTrue);
      expect(ar.rateNotSet.isNotEmpty, isTrue);
      expect(en.rateNotSet.isNotEmpty, isTrue);

      // Dialogs & Actions
      expect(ar.printCurrencyDetailsSnack('USD', 'US Dollar').contains('USD'), isTrue);
      expect(en.printCurrencyDetailsSnack('USD', 'US Dollar').contains('USD'), isTrue);
      expect(ar.confirmDeactivateCurrency('USD', 'US Dollar').contains('USD'), isTrue);
      expect(en.confirmDeactivateCurrency('USD', 'US Dollar').contains('USD'), isTrue);
      expect(ar.confirmActivateCurrency('USD', 'US Dollar').contains('USD'), isTrue);
      expect(en.confirmActivateCurrency('USD', 'US Dollar').contains('USD'), isTrue);
      expect(ar.cannotDeactivateBaseCurrencyTooltip.isNotEmpty, isTrue);
      expect(en.cannotDeactivateBaseCurrencyTooltip.isNotEmpty, isTrue);
      expect(ar.deactivateCurrencyTooltip.isNotEmpty, isTrue);
      expect(en.deactivateCurrencyTooltip.isNotEmpty, isTrue);
      expect(ar.activateCurrencyTooltip.isNotEmpty, isTrue);
      expect(en.activateCurrencyTooltip.isNotEmpty, isTrue);
      expect(ar.showingCurrenciesCount(1, 10, 20).contains('20'), isTrue);
      expect(en.showingCurrenciesCount(1, 10, 20).contains('20'), isTrue);

      // Currency Add/Edit Dialog
      expect(ar.addCurrencyDialogTitle.isNotEmpty, isTrue);
      expect(en.addCurrencyDialogTitle.isNotEmpty, isTrue);
      expect(ar.editCurrencyDialogTitle('EUR').contains('EUR'), isTrue);
      expect(en.editCurrencyDialogTitle('EUR').contains('EUR'), isTrue);
      expect(ar.isoCodeLabel.isNotEmpty, isTrue);
      expect(en.isoCodeLabel.isNotEmpty, isTrue);
      expect(ar.isoCodeHint.isNotEmpty, isTrue);
      expect(en.isoCodeHint.isNotEmpty, isTrue);
      expect(ar.isoCodeLengthError.isNotEmpty, isTrue);
      expect(en.isoCodeLengthError.isNotEmpty, isTrue);
      expect(ar.currencyNameLabel.isNotEmpty, isTrue);
      expect(en.currencyNameLabel.isNotEmpty, isTrue);
      expect(ar.currencyNameHint.isNotEmpty, isTrue);
      expect(en.currencyNameHint.isNotEmpty, isTrue);
      expect(ar.currencySymbolLabel.isNotEmpty, isTrue);
      expect(en.currencySymbolLabel.isNotEmpty, isTrue);
      expect(ar.currencySymbolHint.isNotEmpty, isTrue);
      expect(en.currencySymbolHint.isNotEmpty, isTrue);
      expect(ar.createCurrencySubmitBtn.isNotEmpty, isTrue);
      expect(en.createCurrencySubmitBtn.isNotEmpty, isTrue);

      // History Timeline Dialog
      expect(ar.exchangeRateHistoryTitle('US Dollar').contains('US Dollar'), isTrue);
      expect(en.exchangeRateHistoryTitle('US Dollar').contains('US Dollar'), isTrue);
      expect(ar.baseCurrencySystemDesc.isNotEmpty, isTrue);
      expect(en.baseCurrencySystemDesc.isNotEmpty, isTrue);
      expect(ar.rateHistorySubtitle.isNotEmpty, isTrue);
      expect(en.rateHistorySubtitle.isNotEmpty, isTrue);
      expect(ar.currentCommercialRateStat.isNotEmpty, isTrue);
      expect(en.currentCommercialRateStat.isNotEmpty, isTrue);
      expect(ar.currentCustomsRateStat.isNotEmpty, isTrue);
      expect(en.currentCustomsRateStat.isNotEmpty, isTrue);
      expect(ar.rateSpreadStat.isNotEmpty, isTrue);
      expect(en.rateSpreadStat.isNotEmpty, isTrue);
      expect(ar.historicalUpdatesCountStat.isNotEmpty, isTrue);
      expect(en.historicalUpdatesCountStat.isNotEmpty, isTrue);
      expect(ar.recordsCountBadge(5).contains('5'), isTrue);
      expect(en.recordsCountBadge(5).contains('5'), isTrue);
      expect(ar.notSetLabel.isNotEmpty, isTrue);
      expect(en.notSetLabel.isNotEmpty, isTrue);
      expect(ar.exchangeRateTimelineHeader.isNotEmpty, isTrue);
      expect(en.exchangeRateTimelineHeader.isNotEmpty, isTrue);
      expect(ar.recordNewExchangeRateBtn.isNotEmpty, isTrue);
      expect(en.recordNewExchangeRateBtn.isNotEmpty, isTrue);
      expect(ar.baseCurrencyNoticeTitle.isNotEmpty, isTrue);
      expect(en.baseCurrencyNoticeTitle.isNotEmpty, isTrue);
      expect(ar.baseCurrencyNoticeSubtitle.isNotEmpty, isTrue);
      expect(en.baseCurrencyNoticeSubtitle.isNotEmpty, isTrue);
      expect(ar.noRateHistoryForCurrency('GBP').contains('GBP'), isTrue);
      expect(en.noRateHistoryForCurrency('GBP').contains('GBP'), isTrue);
      expect(ar.recordFirstExchangeRateBtn.isNotEmpty, isTrue);
      expect(en.recordFirstExchangeRateBtn.isNotEmpty, isTrue);
      expect(ar.currentActiveRateBadge.isNotEmpty, isTrue);
      expect(en.currentActiveRateBadge.isNotEmpty, isTrue);
      expect(ar.commercialBankRateLabel.isNotEmpty, isTrue);
      expect(en.commercialBankRateLabel.isNotEmpty, isTrue);
      expect(ar.customsExchangeRateLabel.isNotEmpty, isTrue);
      expect(en.customsExchangeRateLabel.isNotEmpty, isTrue);
      expect(ar.spreadVarianceLabel.isNotEmpty, isTrue);
      expect(en.spreadVarianceLabel.isNotEmpty, isTrue);
      expect(ar.rateSourcePrefix('Admin').contains('Admin'), isTrue);
      expect(en.rateSourcePrefix('Admin').contains('Admin'), isTrue);

      // Add Rate Dialog
      expect(ar.updateExchangeRatesDialogTitle.isNotEmpty, isTrue);
      expect(en.updateExchangeRatesDialogTitle.isNotEmpty, isTrue);
      expect(ar.selectForeignCurrencyLabel.isNotEmpty, isTrue);
      expect(en.selectForeignCurrencyLabel.isNotEmpty, isTrue);
      expect(ar.commercialRateInputLabel.isNotEmpty, isTrue);
      expect(en.commercialRateInputLabel.isNotEmpty, isTrue);
      expect(ar.customsRateInputLabel.isNotEmpty, isTrue);
      expect(en.customsRateInputLabel.isNotEmpty, isTrue);
      expect(ar.rateInputHint.isNotEmpty, isTrue);
      expect(en.rateInputHint.isNotEmpty, isTrue);
      expect(ar.enterValidRateError.isNotEmpty, isTrue);
      expect(en.enterValidRateError.isNotEmpty, isTrue);
      expect(ar.effectiveDateLabel('2026-08-24').contains('2026-08-24'), isTrue);
      expect(en.effectiveDateLabel('2026-08-24').contains('2026-08-24'), isTrue);
      expect(ar.saveRateSubmitBtn.isNotEmpty, isTrue);
      expect(en.saveRateSubmitBtn.isNotEmpty, isTrue);

      // Multi-Currency Converter
      expect(ar.liveCurrencyConverterDialogTitle.isNotEmpty, isTrue);
      expect(en.liveCurrencyConverterDialogTitle.isNotEmpty, isTrue);
      expect(ar.liveCurrencyConverterDialogSubtitle.isNotEmpty, isTrue);
      expect(en.liveCurrencyConverterDialogSubtitle.isNotEmpty, isTrue);
      expect(ar.amountToConvertLabel.isNotEmpty, isTrue);
      expect(en.amountToConvertLabel.isNotEmpty, isTrue);
      expect(ar.amountToConvertHint.isNotEmpty, isTrue);
      expect(en.amountToConvertHint.isNotEmpty, isTrue);
      expect(ar.enterValidAmountError.isNotEmpty, isTrue);
      expect(en.enterValidAmountError.isNotEmpty, isTrue);
      expect(ar.fromCurrencyLabel.isNotEmpty, isTrue);
      expect(en.fromCurrencyLabel.isNotEmpty, isTrue);
      expect(ar.toCurrencyLabel.isNotEmpty, isTrue);
      expect(en.toCurrencyLabel.isNotEmpty, isTrue);
      expect(ar.appliedRateTypeLabel.isNotEmpty, isTrue);
      expect(en.appliedRateTypeLabel.isNotEmpty, isTrue);
      expect(ar.rateTypeCommercialOption.isNotEmpty, isTrue);
      expect(en.rateTypeCommercialOption.isNotEmpty, isTrue);
      expect(ar.rateTypeCustomsOption.isNotEmpty, isTrue);
      expect(en.rateTypeCustomsOption.isNotEmpty, isTrue);
      expect(ar.convertCurrencyNowBtn.isNotEmpty, isTrue);
      expect(en.convertCurrencyNowBtn.isNotEmpty, isTrue);
      expect(ar.convertedAmountLabel.isNotEmpty, isTrue);
      expect(en.convertedAmountLabel.isNotEmpty, isTrue);
      expect(ar.appliedRatePrefix('50.25').contains('50.25'), isTrue);
      expect(en.appliedRatePrefix('50.25').contains('50.25'), isTrue);
      expect(ar.baseEgpEquivalentPrefix('50250').contains('50250'), isTrue);
      expect(en.baseEgpEquivalentPrefix('50250').contains('50250'), isTrue);

      // FX Gain/Loss
      expect(ar.fxGainLossDialogTitle.isNotEmpty, isTrue);
      expect(en.fxGainLossDialogTitle.isNotEmpty, isTrue);
      expect(ar.fxGainLossDialogSubtitle.isNotEmpty, isTrue);
      expect(en.fxGainLossDialogSubtitle.isNotEmpty, isTrue);
      expect(ar.foreignAmountLabel.isNotEmpty, isTrue);
      expect(en.foreignAmountLabel.isNotEmpty, isTrue);
      expect(ar.currencyLabel.isNotEmpty, isTrue);
      expect(en.currencyLabel.isNotEmpty, isTrue);
      expect(ar.initialRateLabel.isNotEmpty, isTrue);
      expect(en.initialRateLabel.isNotEmpty, isTrue);
      expect(ar.initialRateHint.isNotEmpty, isTrue);
      expect(en.initialRateHint.isNotEmpty, isTrue);
      expect(ar.settlementRateLabel.isNotEmpty, isTrue);
      expect(en.settlementRateLabel.isNotEmpty, isTrue);
      expect(ar.settlementRateHint.isNotEmpty, isTrue);
      expect(en.settlementRateHint.isNotEmpty, isTrue);
      expect(ar.calculateGainLossBtn.isNotEmpty, isTrue);
      expect(en.calculateGainLossBtn.isNotEmpty, isTrue);
      expect(ar.initialCostAtBooking('1000', '50.0').contains('1000'), isTrue);
      expect(en.initialCostAtBooking('1000', '50.0').contains('1000'), isTrue);
      expect(ar.actualCostAtSettlement('980', '49.0').contains('980'), isTrue);
      expect(en.actualCostAtSettlement('980', '49.0').contains('980'), isTrue);
    });

    test('Arabic static translations contain ZERO Latin characters (Pure Arabic)', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      expect(latinPattern.hasMatch(ar.currenciesScreenTitle), isFalse);
      expect(latinPattern.hasMatch(ar.currenciesScreenSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.rowsPerPageLabel), isFalse);
      expect(latinPattern.hasMatch(ar.firstPageTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.previousPageTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.nextPageTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.lastPageTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.liveCurrencyConverterBtn), isFalse);
      expect(latinPattern.hasMatch(ar.currencyGainLossBtn), isFalse);
      expect(latinPattern.hasMatch(ar.updateExchangeRatesBtn), isFalse);
      expect(latinPattern.hasMatch(ar.addCurrencyBtn), isFalse);
      expect(latinPattern.hasMatch(ar.searchCurrenciesHint), isFalse);
      expect(latinPattern.hasMatch(ar.noCurrenciesFound), isFalse);
      expect(latinPattern.hasMatch(ar.isoCodeCol), isFalse);
      expect(latinPattern.hasMatch(ar.currencyNameCol), isFalse);
      expect(latinPattern.hasMatch(ar.currencySymbolCol), isFalse);
      expect(latinPattern.hasMatch(ar.commercialRateBankCol), isFalse);
      expect(latinPattern.hasMatch(ar.customsRateOfficialCol), isFalse);
      expect(latinPattern.hasMatch(ar.baseCurrencyTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.viewRateHistoryTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.baseCurrencyRateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.rateNotSet), isFalse);
      expect(latinPattern.hasMatch(ar.cannotDeactivateBaseCurrencyTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.deactivateCurrencyTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.activateCurrencyTooltip), isFalse);
      expect(latinPattern.hasMatch(ar.addCurrencyDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.isoCodeLabel), isFalse);
      expect(latinPattern.hasMatch(ar.isoCodeHint), isFalse);
      expect(latinPattern.hasMatch(ar.isoCodeLengthError), isFalse);
      expect(latinPattern.hasMatch(ar.currencyNameLabel), isFalse);
      expect(latinPattern.hasMatch(ar.currencyNameHint), isFalse);
      expect(latinPattern.hasMatch(ar.currencySymbolLabel), isFalse);
      expect(latinPattern.hasMatch(ar.currencySymbolHint), isFalse);
      expect(latinPattern.hasMatch(ar.createCurrencySubmitBtn), isFalse);
      expect(latinPattern.hasMatch(ar.baseCurrencySystemDesc), isFalse);
      expect(latinPattern.hasMatch(ar.rateHistorySubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.currentCommercialRateStat), isFalse);
      expect(latinPattern.hasMatch(ar.currentCustomsRateStat), isFalse);
      expect(latinPattern.hasMatch(ar.rateSpreadStat), isFalse);
      expect(latinPattern.hasMatch(ar.historicalUpdatesCountStat), isFalse);
      expect(latinPattern.hasMatch(ar.notSetLabel), isFalse);
      expect(latinPattern.hasMatch(ar.exchangeRateTimelineHeader), isFalse);
      expect(latinPattern.hasMatch(ar.recordNewExchangeRateBtn), isFalse);
      expect(latinPattern.hasMatch(ar.baseCurrencyNoticeTitle), isFalse);
      expect(latinPattern.hasMatch(ar.baseCurrencyNoticeSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.recordFirstExchangeRateBtn), isFalse);
      expect(latinPattern.hasMatch(ar.currentActiveRateBadge), isFalse);
      expect(latinPattern.hasMatch(ar.commercialBankRateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.customsExchangeRateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.spreadVarianceLabel), isFalse);
      expect(latinPattern.hasMatch(ar.updateExchangeRatesDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.selectForeignCurrencyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.commercialRateInputLabel), isFalse);
      expect(latinPattern.hasMatch(ar.customsRateInputLabel), isFalse);
      expect(latinPattern.hasMatch(ar.rateInputHint), isFalse);
      expect(latinPattern.hasMatch(ar.enterValidRateError), isFalse);
      expect(latinPattern.hasMatch(ar.saveRateSubmitBtn), isFalse);
      expect(latinPattern.hasMatch(ar.liveCurrencyConverterDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.liveCurrencyConverterDialogSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.amountToConvertLabel), isFalse);
      expect(latinPattern.hasMatch(ar.enterValidAmountError), isFalse);
      expect(latinPattern.hasMatch(ar.fromCurrencyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.toCurrencyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.appliedRateTypeLabel), isFalse);
      expect(latinPattern.hasMatch(ar.rateTypeCommercialOption), isFalse);
      expect(latinPattern.hasMatch(ar.rateTypeCustomsOption), isFalse);
      expect(latinPattern.hasMatch(ar.convertCurrencyNowBtn), isFalse);
      expect(latinPattern.hasMatch(ar.convertedAmountLabel), isFalse);
      expect(latinPattern.hasMatch(ar.fxGainLossDialogTitle), isFalse);
      expect(latinPattern.hasMatch(ar.fxGainLossDialogSubtitle), isFalse);
      expect(latinPattern.hasMatch(ar.foreignAmountLabel), isFalse);
      expect(latinPattern.hasMatch(ar.currencyLabel), isFalse);
      expect(latinPattern.hasMatch(ar.initialRateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.settlementRateLabel), isFalse);
      expect(latinPattern.hasMatch(ar.calculateGainLossBtn), isFalse);
    });
  });
}
