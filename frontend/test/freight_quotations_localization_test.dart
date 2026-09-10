import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/freight_quotations/models/freight_quotation_model.dart';
import 'package:frontend/features/freight_quotations/services/freight_quotations_export_service.dart';

void main() {
  group('Screen 49: Freight Quotations Localization Tests', () {
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
      expect(ar.freightQuotesLoadError('error_msg'), contains('error_msg'));
      expect(en.freightQuotesLoadError('error_msg'), contains('error_msg'));
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
      expect(ar.transitDaysCount(14), contains('14'));
      expect(en.transitDaysCount(14), contains('14'));
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
      expect(ar.freightQuoteAwardError('award_err'), contains('award_err'));
      expect(en.freightQuoteAwardError('award_err'), contains('award_err'));

      // Export toolbar & dialog getters
      expect(ar.freightQuotationsExportTsvBtn, isNotEmpty);
      expect(en.freightQuotationsExportTsvBtn, isNotEmpty);
      expect(ar.freightQuotationsExportExcelBtn, isNotEmpty);
      expect(en.freightQuotationsExportExcelBtn, isNotEmpty);
      expect(ar.freightQuotationsPrintPdfBtn, isNotEmpty);
      expect(en.freightQuotationsPrintPdfBtn, isNotEmpty);
      expect(ar.freightQuotationsCopyDossierBtn, isNotEmpty);
      expect(en.freightQuotationsCopyDossierBtn, isNotEmpty);
      expect(ar.freightQuotationsCopyDossierSuccess, isNotEmpty);
      expect(en.freightQuotationsCopyDossierSuccess, isNotEmpty);
      expect(ar.freightQuotationsDossierHeader, isNotEmpty);
      expect(en.freightQuotationsDossierHeader, isNotEmpty);
      expect(ar.freightQuotationsExportTsvDialogTitle, isNotEmpty);
      expect(en.freightQuotationsExportTsvDialogTitle, isNotEmpty);
      expect(ar.freightQuotationsExportExcelDialogTitle, isNotEmpty);
      expect(en.freightQuotationsExportExcelDialogTitle, isNotEmpty);

      // TSV & export table headers
      expect(ar.freightQuotesTsvHeaderCarrier, isNotEmpty);
      expect(en.freightQuotesTsvHeaderCarrier, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderTotalCost, isNotEmpty);
      expect(en.freightQuotesTsvHeaderTotalCost, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderOceanFreight, isNotEmpty);
      expect(en.freightQuotesTsvHeaderOceanFreight, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderLocalCharges, isNotEmpty);
      expect(en.freightQuotesTsvHeaderLocalCharges, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderInlandCharges, isNotEmpty);
      expect(en.freightQuotesTsvHeaderInlandCharges, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderTransitDays, isNotEmpty);
      expect(en.freightQuotesTsvHeaderTransitDays, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderSailingDate, isNotEmpty);
      expect(en.freightQuotesTsvHeaderSailingDate, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderArrivalDate, isNotEmpty);
      expect(en.freightQuotesTsvHeaderArrivalDate, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderFreeDays, isNotEmpty);
      expect(en.freightQuotesTsvHeaderFreeDays, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderStatus, isNotEmpty);
      expect(en.freightQuotesTsvHeaderStatus, isNotEmpty);
      expect(ar.freightQuotesTsvHeaderRemarks, isNotEmpty);
      expect(en.freightQuotesTsvHeaderRemarks, isNotEmpty);

      // Form Dialog field labels
      expect(ar.vesselNameLabel, isNotEmpty);
      expect(en.vesselNameLabel, isNotEmpty);
      expect(ar.voyageNumberLabel, isNotEmpty);
      expect(en.voyageNumberLabel, isNotEmpty);
      expect(ar.oceanFreightCostLabel, isNotEmpty);
      expect(en.oceanFreightCostLabel, isNotEmpty);
      expect(ar.localChargesCostLabel, isNotEmpty);
      expect(en.localChargesCostLabel, isNotEmpty);
      expect(ar.inlandCostLabel, isNotEmpty);
      expect(en.inlandCostLabel, isNotEmpty);
      expect(ar.sailingDateFormLabel, isNotEmpty);
      expect(en.sailingDateFormLabel, isNotEmpty);
      expect(ar.arrivalDateFormLabel, isNotEmpty);
      expect(en.arrivalDateFormLabel, isNotEmpty);
      expect(ar.freeDaysPodFormLabel, isNotEmpty);
      expect(en.freeDaysPodFormLabel, isNotEmpty);
      expect(ar.remarksFormLabel, isNotEmpty);
      expect(en.remarksFormLabel, isNotEmpty);
    });

    test('Zero Latin characters rule: Arabic strings must contain ZERO [a-zA-Z]', () {
      final latinRegex = RegExp(r'[a-zA-Z]');

      final arabicStrings = [
        ar.freightQuotationsComparisonTitle,
        ar.selectImportFileDropdownLabel,
        ar.selectImportFileDropdownHint,
        ar.unknownSupplierFallback,
        ar.selectImportFilePrompt,
        ar.noFreightQuotesForFile,
        ar.notSelectedYet,
        ar.metricCheapestQuote,
        ar.metricFastestQuote,
        ar.metricCurrentlySelected,
        ar.badgeBestPrice,
        ar.unknownCarrierFallback,
        ar.totalFreightCostLabel,
        ar.oceanFreightLabel,
        ar.localChargesLabel,
        ar.transitDurationLabel,
        ar.sailingDateLabel,
        ar.estimatedArrivalDateLabel,
        ar.remarksLabel,
        ar.quoteAwardedBtn,
        ar.awardQuoteBtn,
        ar.freightQuoteSelectedSuccess,
        ar.freightQuoteAwardedSuccess,
        ar.freightQuotationsExportTsvBtn,
        ar.freightQuotationsExportExcelBtn,
        ar.freightQuotationsPrintPdfBtn,
        ar.freightQuotationsCopyDossierBtn,
        ar.freightQuotationsCopyDossierSuccess,
        ar.freightQuotationsDossierHeader,
        ar.freightQuotationsExportTsvDialogTitle,
        ar.freightQuotationsExportExcelDialogTitle,
        ar.freightQuotesTsvHeaderCarrier,
        ar.freightQuotesTsvHeaderTotalCost,
        ar.freightQuotesTsvHeaderOceanFreight,
        ar.freightQuotesTsvHeaderLocalCharges,
        ar.freightQuotesTsvHeaderInlandCharges,
        ar.freightQuotesTsvHeaderTransitDays,
        ar.freightQuotesTsvHeaderSailingDate,
        ar.freightQuotesTsvHeaderArrivalDate,
        ar.freightQuotesTsvHeaderFreeDays,
        ar.freightQuotesTsvHeaderStatus,
        ar.freightQuotesTsvHeaderRemarks,
        ar.vesselNameLabel,
        ar.voyageNumberLabel,
        ar.oceanFreightCostLabel,
        ar.localChargesCostLabel,
        ar.inlandCostLabel,
        ar.sailingDateFormLabel,
        ar.arrivalDateFormLabel,
        ar.freeDaysPodFormLabel,
        ar.remarksFormLabel,
      ];

      for (final str in arabicStrings) {
        expect(
          latinRegex.hasMatch(str),
          isFalse,
          reason: 'Arabic localization string "$str" contains Latin characters, violating zero-Latin rule!',
        );
      }
    });

    test('Zero bilingual slash rule: Arabic strings must contain ZERO slashes [/]', () {
      final arabicStrings = [
        ar.freightQuotationsComparisonTitle,
        ar.selectImportFileDropdownLabel,
        ar.selectImportFileDropdownHint,
        ar.unknownSupplierFallback,
        ar.selectImportFilePrompt,
        ar.noFreightQuotesForFile,
        ar.notSelectedYet,
        ar.metricCheapestQuote,
        ar.metricFastestQuote,
        ar.metricCurrentlySelected,
        ar.badgeBestPrice,
        ar.unknownCarrierFallback,
        ar.totalFreightCostLabel,
        ar.oceanFreightLabel,
        ar.localChargesLabel,
        ar.transitDurationLabel,
        ar.sailingDateLabel,
        ar.estimatedArrivalDateLabel,
        ar.remarksLabel,
        ar.quoteAwardedBtn,
        ar.awardQuoteBtn,
        ar.freightQuoteSelectedSuccess,
        ar.freightQuoteAwardedSuccess,
        ar.freightQuotationsExportTsvBtn,
        ar.freightQuotationsExportExcelBtn,
        ar.freightQuotationsPrintPdfBtn,
        ar.freightQuotationsCopyDossierBtn,
        ar.freightQuotationsCopyDossierSuccess,
        ar.freightQuotationsDossierHeader,
        ar.freightQuotationsExportTsvDialogTitle,
        ar.freightQuotationsExportExcelDialogTitle,
        ar.freightQuotesTsvHeaderCarrier,
        ar.freightQuotesTsvHeaderTotalCost,
        ar.freightQuotesTsvHeaderOceanFreight,
        ar.freightQuotesTsvHeaderLocalCharges,
        ar.freightQuotesTsvHeaderInlandCharges,
        ar.freightQuotesTsvHeaderTransitDays,
        ar.freightQuotesTsvHeaderSailingDate,
        ar.freightQuotesTsvHeaderArrivalDate,
        ar.freightQuotesTsvHeaderFreeDays,
        ar.freightQuotesTsvHeaderStatus,
        ar.freightQuotesTsvHeaderRemarks,
        ar.vesselNameLabel,
        ar.voyageNumberLabel,
        ar.oceanFreightCostLabel,
        ar.localChargesCostLabel,
        ar.inlandCostLabel,
        ar.sailingDateFormLabel,
        ar.arrivalDateFormLabel,
        ar.freeDaysPodFormLabel,
        ar.remarksFormLabel,
      ];

      for (final str in arabicStrings) {
        expect(
          str.contains('/'),
          isFalse,
          reason: 'Arabic localization string "$str" contains slash [/], violating zero bilingual slash rule!',
        );
      }
    });

    testWidgets('FreightQuotationsExportService buildDossierText builds structured dossier text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppLocalizationsProvider(
            locale: const Locale('ar'),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  final mockQuotes = [
                    FreightQuotationItemModel(
                      providerId: 1,
                      providerName: 'ميرسك للملاحة',
                      oceanFreightCost: 2800.0,
                      localChargesCost: 350.0,
                      inlandCost: 150.0,
                      totalCost: 3300.0,
                      sailingDate: '2026-09-15',
                      estimatedArrivalDate: '2026-10-05',
                      transitDays: 20,
                      freeDaysAtPod: 14,
                      isAwarded: true,
                      remarks: 'سعر شامل التفريغ',
                    ),
                    FreightQuotationItemModel(
                      providerId: 2,
                      providerName: 'سي إم إيه للملاحة',
                      oceanFreightCost: 2600.0,
                      localChargesCost: 400.0,
                      inlandCost: 100.0,
                      totalCost: 3100.0,
                      sailingDate: '2026-09-18',
                      estimatedArrivalDate: '2026-10-12',
                      transitDays: 24,
                      freeDaysAtPod: 21,
                      isAwarded: false,
                      remarks: 'سماح 21 يوم بالميناء',
                    ),
                  ];

                  final dossier = FreightQuotationsExportService.buildDossierText(
                    context: context,
                    quotations: mockQuotes,
                    importFileCode: 'IMP-2026-0049',
                    supplierName: 'شنغهاي للمعدات الثقيلة',
                  );

                  expect(dossier, contains('IMP-2026-0049'));
                  expect(dossier, contains('شنغهاي للمعدات الثقيلة'));
                  expect(dossier, contains('ميرسك للملاحة'));
                  expect(dossier, contains('سي إم إيه للملاحة'));
                  expect(dossier, contains('3100.00')); // cheapest cost
                  expect(dossier, contains('20')); // fastest transit days

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
    });
  });
}
