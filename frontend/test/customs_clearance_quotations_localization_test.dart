import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 55: Customs Clearance Quotations & Price Lists Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 55 getters return non-empty strings and no missing translations', () {
      // Titles and tabs
      expect(ar.clearanceQuotesScreenTitle.isNotEmpty, true);
      expect(en.clearanceQuotesScreenTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesScreenSubtitle.isNotEmpty, true);
      expect(en.clearanceQuotesScreenSubtitle.isNotEmpty, true);
      expect(ar.clearanceQuotesEmbeddedTitle.isNotEmpty, true);
      expect(en.clearanceQuotesEmbeddedTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesTabRfqs.isNotEmpty, true);
      expect(en.clearanceQuotesTabRfqs.isNotEmpty, true);
      expect(ar.clearanceQuotesTabPriceLists.isNotEmpty, true);
      expect(en.clearanceQuotesTabPriceLists.isNotEmpty, true);

      // Buttons & Toolbar
      expect(ar.clearanceQuotesSmartExtractorBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSmartExtractorBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesCreateRfqBtn.isNotEmpty, true);
      expect(en.clearanceQuotesCreateRfqBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesSearchHint.isNotEmpty, true);
      expect(en.clearanceQuotesSearchHint.isNotEmpty, true);
      expect(ar.clearanceQuotesStatusAll.isNotEmpty, true);
      expect(en.clearanceQuotesStatusAll.isNotEmpty, true);
      expect(ar.clearanceQuotesStatusDraft.isNotEmpty, true);
      expect(en.clearanceQuotesStatusDraft.isNotEmpty, true);
      expect(ar.clearanceQuotesStatusReceived.isNotEmpty, true);
      expect(en.clearanceQuotesStatusReceived.isNotEmpty, true);
      expect(ar.clearanceQuotesStatusAwarded.isNotEmpty, true);
      expect(en.clearanceQuotesStatusAwarded.isNotEmpty, true);
      expect(ar.clearanceQuotesNoRfqsFound.isNotEmpty, true);
      expect(en.clearanceQuotesNoRfqsFound.isNotEmpty, true);

      // RFQ Card & Badges
      expect(ar.clearanceQuotesAwardedBannerPrefix.isNotEmpty, true);
      expect(en.clearanceQuotesAwardedBannerPrefix.isNotEmpty, true);
      expect(ar.clearanceQuotesReceivedQuotesHeader(3), contains('3'));
      expect(en.clearanceQuotesReceivedQuotesHeader(3), contains('3'));
      expect(ar.clearanceQuotesSmartExtractQuoteBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSmartExtractQuoteBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesAddManualQuoteBtn.isNotEmpty, true);
      expect(en.clearanceQuotesAddManualQuoteBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesNoQuotesYet.isNotEmpty, true);
      expect(en.clearanceQuotesNoQuotesYet.isNotEmpty, true);

      // Table columns
      expect(ar.clearanceQuotesColBroker.isNotEmpty, true);
      expect(en.clearanceQuotesColBroker.isNotEmpty, true);
      expect(ar.clearanceQuotesColClearanceFee.isNotEmpty, true);
      expect(en.clearanceQuotesColClearanceFee.isNotEmpty, true);
      expect(ar.clearanceQuotesColInlandTransport.isNotEmpty, true);
      expect(en.clearanceQuotesColInlandTransport.isNotEmpty, true);
      expect(ar.clearanceQuotesColInspectionFee.isNotEmpty, true);
      expect(en.clearanceQuotesColInspectionFee.isNotEmpty, true);
      expect(ar.clearanceQuotesColPortExpenses.isNotEmpty, true);
      expect(en.clearanceQuotesColPortExpenses.isNotEmpty, true);
      expect(ar.clearanceQuotesColMiscellaneous.isNotEmpty, true);
      expect(en.clearanceQuotesColMiscellaneous.isNotEmpty, true);
      expect(ar.clearanceQuotesColEstimatedTotal.isNotEmpty, true);
      expect(en.clearanceQuotesColEstimatedTotal.isNotEmpty, true);
      expect(ar.clearanceQuotesColDuration.isNotEmpty, true);
      expect(en.clearanceQuotesColDuration.isNotEmpty, true);
      expect(ar.clearanceQuotesColStatusActions.isNotEmpty, true);
      expect(en.clearanceQuotesColStatusActions.isNotEmpty, true);

      // Price list tab
      expect(ar.clearanceQuotesPriceListTitle.isNotEmpty, true);
      expect(en.clearanceQuotesPriceListTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesPriceListSubtitle.isNotEmpty, true);
      expect(en.clearanceQuotesPriceListSubtitle.isNotEmpty, true);
      expect(ar.clearanceQuotesAddPriceItemBtn.isNotEmpty, true);
      expect(en.clearanceQuotesAddPriceItemBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesNoPriceItemsFound.isNotEmpty, true);
      expect(en.clearanceQuotesNoPriceItemsFound.isNotEmpty, true);
      expect(ar.clearanceQuotesColPricePort.isNotEmpty, true);
      expect(en.clearanceQuotesColPricePort.isNotEmpty, true);
      expect(ar.clearanceQuotesColPriceServiceType.isNotEmpty, true);
      expect(en.clearanceQuotesColPriceServiceType.isNotEmpty, true);
      expect(ar.clearanceQuotesColPriceContainerType.isNotEmpty, true);
      expect(en.clearanceQuotesColPriceContainerType.isNotEmpty, true);
      expect(ar.clearanceQuotesColPriceStandardRate.isNotEmpty, true);
      expect(en.clearanceQuotesColPriceStandardRate.isNotEmpty, true);
      expect(ar.clearanceQuotesColPriceNotes.isNotEmpty, true);
      expect(en.clearanceQuotesColPriceNotes.isNotEmpty, true);
      expect(ar.clearanceQuotesColPriceDelete.isNotEmpty, true);
      expect(en.clearanceQuotesColPriceDelete.isNotEmpty, true);

      // Dialogs & Form fields
      expect(ar.clearanceQuotesDialogCreateRfqTitle.isNotEmpty, true);
      expect(en.clearanceQuotesDialogCreateRfqTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldRfqTitle.isNotEmpty, true);
      expect(en.clearanceQuotesFieldRfqTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldRfqTitleRequired.isNotEmpty, true);
      expect(en.clearanceQuotesFieldRfqTitleRequired.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldLinkImportFile.isNotEmpty, true);
      expect(en.clearanceQuotesFieldLinkImportFile.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldClearancePort.isNotEmpty, true);
      expect(en.clearanceQuotesFieldClearancePort.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldShipmentType.isNotEmpty, true);
      expect(en.clearanceQuotesFieldShipmentType.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldContainersCount.isNotEmpty, true);
      expect(en.clearanceQuotesFieldContainersCount.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldGrossWeightKg.isNotEmpty, true);
      expect(en.clearanceQuotesFieldGrossWeightKg.isNotEmpty, true);
      expect(ar.clearanceQuotesFieldCbm.isNotEmpty, true);
      expect(en.clearanceQuotesFieldCbm.isNotEmpty, true);
      expect(ar.clearanceQuotesSubmitCreateRfqBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSubmitCreateRfqBtn.isNotEmpty, true);

      // Smart Extractor
      expect(ar.clearanceQuotesSmartExtractorDialogTitle.isNotEmpty, true);
      expect(en.clearanceQuotesSmartExtractorDialogTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesSmartExtractorPrompt.isNotEmpty, true);
      expect(en.clearanceQuotesSmartExtractorPrompt.isNotEmpty, true);
      expect(ar.clearanceQuotesExtractFromTextBtn.isNotEmpty, true);
      expect(en.clearanceQuotesExtractFromTextBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesUploadDocBtn.isNotEmpty, true);
      expect(en.clearanceQuotesUploadDocBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesApplyExtractedQuoteBtn.isNotEmpty, true);
      expect(en.clearanceQuotesApplyExtractedQuoteBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesUseExtractedQuoteBtn.isNotEmpty, true);
      expect(en.clearanceQuotesUseExtractedQuoteBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesExtractedSuccessToast('Broker A', '5000'), contains('Broker A'));
      expect(en.clearanceQuotesExtractedSuccessToast('Broker A', '5000'), contains('5000'));

      // Export toolbar & linked outputs
      expect(ar.clearanceQuotesExportTsvBtn.isNotEmpty, true);
      expect(en.clearanceQuotesExportTsvBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesExportExcelBtn.isNotEmpty, true);
      expect(en.clearanceQuotesExportExcelBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesPrintPdfBtn.isNotEmpty, true);
      expect(en.clearanceQuotesPrintPdfBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesCopyDossierBtn.isNotEmpty, true);
      expect(en.clearanceQuotesCopyDossierBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesCopiedDossierSuccess.isNotEmpty, true);
      expect(en.clearanceQuotesCopiedDossierSuccess.isNotEmpty, true);
      expect(ar.clearanceQuotesCopiedTsvSuccess.isNotEmpty, true);
      expect(en.clearanceQuotesCopiedTsvSuccess.isNotEmpty, true);
      expect(ar.clearanceQuotesCopiedExcelSuccess.isNotEmpty, true);
      expect(en.clearanceQuotesCopiedExcelSuccess.isNotEmpty, true);
      expect(ar.clearanceQuotesExportTsvDialogTitle.isNotEmpty, true);
      expect(en.clearanceQuotesExportTsvDialogTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesExportExcelDialogTitle.isNotEmpty, true);
      expect(en.clearanceQuotesExportExcelDialogTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesExportPdfDialogTitle.isNotEmpty, true);
      expect(en.clearanceQuotesExportPdfDialogTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesDossierTitle.isNotEmpty, true);
      expect(en.clearanceQuotesDossierTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesCopyRowSuccess.isNotEmpty, true);
      expect(en.clearanceQuotesCopyRowSuccess.isNotEmpty, true);
      expect(ar.clearanceQuotesCopySummarySuccess.isNotEmpty, true);
      expect(en.clearanceQuotesCopySummarySuccess.isNotEmpty, true);

      // TSV headers
      expect(ar.clearanceQuotesTsvHeaderRfqCode.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderRfqCode.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderTitle.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPort.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPort.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderShipmentType.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderShipmentType.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderContainers.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderContainers.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderWeight.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderWeight.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderCbm.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderCbm.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderBroker.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderBroker.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderClearanceFee.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderClearanceFee.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderInlandTransport.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderInlandTransport.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderInspectionFee.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderInspectionFee.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPortExpenses.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPortExpenses.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderMiscFee.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderMiscFee.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderTotal.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderTotal.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderDays.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderDays.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderStatus.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderStatus.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPriceServiceType.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPriceServiceType.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPriceContainerType.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPriceContainerType.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPriceStandardRate.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPriceStandardRate.isNotEmpty, true);
      expect(ar.clearanceQuotesTsvHeaderPriceNotes.isNotEmpty, true);
      expect(en.clearanceQuotesTsvHeaderPriceNotes.isNotEmpty, true);

      // Extractor & breakdown getters
      expect(ar.clearanceQuotesManagePriceListBtn.isNotEmpty, true);
      expect(en.clearanceQuotesManagePriceListBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesPasteClipboardBtn.isNotEmpty, true);
      expect(en.clearanceQuotesPasteClipboardBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesSampleAccBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSampleAccBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesSampleStandardBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSampleStandardBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesClearInputTooltip.isNotEmpty, true);
      expect(en.clearanceQuotesClearInputTooltip.isNotEmpty, true);
      expect(ar.clearanceQuotesOcrUploadingState.isNotEmpty, true);
      expect(en.clearanceQuotesOcrUploadingState.isNotEmpty, true);
      expect(ar.clearanceQuotesOcrStep1.isNotEmpty, true);
      expect(en.clearanceQuotesOcrStep1.isNotEmpty, true);
      expect(ar.clearanceQuotesOcrDialogTitle.isNotEmpty, true);
      expect(en.clearanceQuotesOcrDialogTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesOcrProgressState(45), contains('45'));
      expect(en.clearanceQuotesOcrProgressState(45), contains('45'));
      expect(ar.clearanceQuotesOcrStep2.isNotEmpty, true);
      expect(en.clearanceQuotesOcrStep2.isNotEmpty, true);
      expect(ar.clearanceQuotesOcrStep4State.isNotEmpty, true);
      expect(en.clearanceQuotesOcrStep4State.isNotEmpty, true);
      expect(ar.clearanceQuotesSelectedContainerLabel.isNotEmpty, true);
      expect(en.clearanceQuotesSelectedContainerLabel.isNotEmpty, true);
      expect(ar.clearanceQuotesSaveAsPriceListBtn.isNotEmpty, true);
      expect(en.clearanceQuotesSaveAsPriceListBtn.isNotEmpty, true);
      expect(ar.clearanceQuotesRateOptionsTitle.isNotEmpty, true);
      expect(en.clearanceQuotesRateOptionsTitle.isNotEmpty, true);
      expect(ar.clearanceQuotesBreakdownClearanceFee.isNotEmpty, true);
      expect(en.clearanceQuotesBreakdownClearanceFee.isNotEmpty, true);
      expect(ar.clearanceQuotesBreakdownInlandFee.isNotEmpty, true);
      expect(en.clearanceQuotesBreakdownInlandFee.isNotEmpty, true);
      expect(ar.clearanceQuotesBreakdownInspectionFee.isNotEmpty, true);
      expect(en.clearanceQuotesBreakdownInspectionFee.isNotEmpty, true);
      expect(ar.clearanceQuotesBreakdownPortExpenses.isNotEmpty, true);
      expect(en.clearanceQuotesBreakdownPortExpenses.isNotEmpty, true);
      expect(ar.clearanceQuotesBreakdownEstimatedTotal.isNotEmpty, true);
      expect(en.clearanceQuotesBreakdownEstimatedTotal.isNotEmpty, true);
      expect(ar.clearanceQuotesExpensesCatalogCount(5), contains('5'));
      expect(en.clearanceQuotesExpensesCatalogCount(5), contains('5'));
    });

    test('Arabic translations do not contain Latin characters in static strings', () {
      final staticArabicStrings = [
        ar.clearanceQuotesScreenTitle,
        ar.clearanceQuotesScreenSubtitle,
        ar.clearanceQuotesEmbeddedTitle,
        ar.clearanceQuotesTabRfqs,
        ar.clearanceQuotesTabPriceLists,
        ar.clearanceQuotesSmartExtractorBtn,
        ar.clearanceQuotesCreateRfqBtn,
        ar.clearanceQuotesSearchHint,
        ar.clearanceQuotesStatusAll,
        ar.clearanceQuotesStatusDraft,
        ar.clearanceQuotesStatusReceived,
        ar.clearanceQuotesStatusAwarded,
        ar.clearanceQuotesNoRfqsFound,
        ar.clearanceQuotesAwardedBannerPrefix,
        ar.clearanceQuotesSmartExtractQuoteBtn,
        ar.clearanceQuotesAddManualQuoteBtn,
        ar.clearanceQuotesNoQuotesYet,
        ar.clearanceQuotesColBroker,
        ar.clearanceQuotesColClearanceFee,
        ar.clearanceQuotesColInlandTransport,
        ar.clearanceQuotesColInspectionFee,
        ar.clearanceQuotesColPortExpenses,
        ar.clearanceQuotesColMiscellaneous,
        ar.clearanceQuotesColEstimatedTotal,
        ar.clearanceQuotesColDuration,
        ar.clearanceQuotesColStatusActions,
        ar.clearanceQuotesStatusAwardedBadge,
        ar.clearanceQuotesAwardAndApproveBtn,
        ar.clearanceQuotesBadgePort,
        ar.clearanceQuotesBadgeShipmentType,
        ar.clearanceQuotesBadgeHsCode,
        ar.clearanceQuotesBadgeWeight,
        ar.clearanceQuotesBadgeVolume,
        ar.clearanceQuotesBadgeLowestCost,
        ar.clearanceQuotesBadgeFastestDuration,
        ar.clearanceQuotesPriceListTitle,
        ar.clearanceQuotesPriceListSubtitle,
        ar.clearanceQuotesAddPriceItemBtn,
        ar.clearanceQuotesNoPriceItemsFound,
        ar.clearanceQuotesColPricePort,
        ar.clearanceQuotesColPriceServiceType,
        ar.clearanceQuotesColPriceContainerType,
        ar.clearanceQuotesColPriceStandardRate,
        ar.clearanceQuotesColPriceNotes,
        ar.clearanceQuotesColPriceDelete,
        ar.clearanceQuotesDialogCreateRfqTitle,
        ar.clearanceQuotesFieldRfqTitle,
        ar.clearanceQuotesFieldRfqTitleRequired,
        ar.clearanceQuotesFieldLinkImportFile,
        ar.clearanceQuotesFieldClearancePort,
        ar.clearanceQuotesFieldShipmentType,
        ar.clearanceQuotesFieldContainersCount,
        ar.clearanceQuotesFieldGrossWeightKg,
        ar.clearanceQuotesFieldCbm,
        ar.clearanceQuotesSubmitCreateRfqBtn,
        ar.clearanceQuotesDialogAddQuoteTitle,
        ar.clearanceQuotesFieldCustomsBroker,
        ar.clearanceQuotesFieldClearanceFeeEgp,
        ar.clearanceQuotesFieldInlandFeeEgp,
        ar.clearanceQuotesFieldInspectionFeeEgp,
        ar.clearanceQuotesFieldPortExpEgp,
        ar.clearanceQuotesFieldMiscFeeEgp,
        ar.clearanceQuotesFieldEstimatedDays,
        ar.clearanceQuotesTotalEstimatedQuoteLabel,
        ar.clearanceQuotesSubmitSaveQuoteBtn,
        ar.clearanceQuotesSmartExtractorDialogTitle,
        ar.clearanceQuotesSmartExtractorPrompt,
        ar.clearanceQuotesExtractingState,
        ar.clearanceQuotesExtractFromTextBtn,
        ar.clearanceQuotesUploadDocBtn,
        ar.clearanceQuotesExtractedBrokerPrefix,
        ar.clearanceQuotesExtractedPortPrefix,
        ar.clearanceQuotesExtractedContainerPrefix,
        ar.clearanceQuotesExtractedTotalPrefix,
        ar.clearanceQuotesApplyExtractedQuoteBtn,
        ar.clearanceQuotesUseExtractedQuoteBtn,
        ar.clearanceQuotesDialogAddPriceItemTitle,
        ar.clearanceQuotesFieldServiceCategory,
        ar.clearanceQuotesFieldStandardPriceEgp,
        ar.clearanceQuotesFieldStandardPriceRequired,
        ar.clearanceQuotesSubmitSavePriceItemBtn,
        ar.clearanceQuotesCatClearanceFee,
        ar.clearanceQuotesCatInlandTransport,
        ar.clearanceQuotesCatInspectionFee,
        ar.clearanceQuotesCatPortCharges,
        ar.clearanceQuotesConfirmAwardTitle,
        ar.clearanceQuotesConfirmAwardContent,
        ar.clearanceQuotesConfirmAwardBtn,
        ar.clearanceQuotesAwardSuccessSnackbar,
        ar.clearanceQuotesConfirmDeleteQuoteTitle,
        ar.clearanceQuotesConfirmDeleteQuoteContent,
        ar.clearanceQuotesErrorLoadingRfqs,
        ar.clearanceQuotesErrorLoadingPriceList,
        ar.clearanceQuotesExportTsvBtn,
        ar.clearanceQuotesExportExcelBtn,
        ar.clearanceQuotesPrintPdfBtn,
        ar.clearanceQuotesCopyDossierBtn,
        ar.clearanceQuotesCopiedDossierSuccess,
        ar.clearanceQuotesCopiedTsvSuccess,
        ar.clearanceQuotesCopiedExcelSuccess,
        ar.clearanceQuotesExportTsvDialogTitle,
        ar.clearanceQuotesExportExcelDialogTitle,
        ar.clearanceQuotesExportPdfDialogTitle,
        ar.clearanceQuotesDossierTitle,
        ar.clearanceQuotesCopyRowSuccess,
        ar.clearanceQuotesCopySummarySuccess,
        ar.clearanceQuotesTsvHeaderRfqCode,
        ar.clearanceQuotesTsvHeaderTitle,
        ar.clearanceQuotesTsvHeaderPort,
        ar.clearanceQuotesTsvHeaderShipmentType,
        ar.clearanceQuotesTsvHeaderContainers,
        ar.clearanceQuotesTsvHeaderWeight,
        ar.clearanceQuotesTsvHeaderCbm,
        ar.clearanceQuotesTsvHeaderBroker,
        ar.clearanceQuotesTsvHeaderClearanceFee,
        ar.clearanceQuotesTsvHeaderInlandTransport,
        ar.clearanceQuotesTsvHeaderInspectionFee,
        ar.clearanceQuotesTsvHeaderPortExpenses,
        ar.clearanceQuotesTsvHeaderMiscFee,
        ar.clearanceQuotesTsvHeaderTotal,
        ar.clearanceQuotesTsvHeaderDays,
        ar.clearanceQuotesTsvHeaderStatus,
        ar.clearanceQuotesTsvHeaderPriceServiceType,
        ar.clearanceQuotesTsvHeaderPriceContainerType,
        ar.clearanceQuotesTsvHeaderPriceStandardRate,
        ar.clearanceQuotesTsvHeaderPriceNotes,
        ar.clearanceQuotesManagePriceListBtn,
        ar.clearanceQuotesPasteClipboardBtn,
        ar.clearanceQuotesSampleAccBtn,
        ar.clearanceQuotesSampleStandardBtn,
        ar.clearanceQuotesClearInputTooltip,
        ar.clearanceQuotesOcrUploadingState,
        ar.clearanceQuotesOcrStep1,
        ar.clearanceQuotesOcrDialogTitle,
        ar.clearanceQuotesOcrStep2,
        ar.clearanceQuotesOcrStep4State,
        ar.clearanceQuotesSelectedContainerLabel,
        ar.clearanceQuotesSaveAsPriceListBtn,
        ar.clearanceQuotesRateOptionsTitle,
        ar.clearanceQuotesBreakdownClearanceFee,
        ar.clearanceQuotesBreakdownInlandFee,
        ar.clearanceQuotesBreakdownInspectionFee,
        ar.clearanceQuotesBreakdownPortExpenses,
        ar.clearanceQuotesBreakdownEstimatedTotal,
      ];

      final latinRegex = RegExp(r'[a-zA-Z]');
      for (final str in staticArabicStrings) {
        expect(
          latinRegex.hasMatch(str),
          false,
          reason: 'String "$str" contains Latin characters in pure Arabic locale!',
        );
      }
    });
  });
}
