import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 68: Smart Shipment Inquiry Localization Tests', () {
    late AppLocalizationsAr ar;
    late AppLocalizationsEn en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    test('Header, Subtitle and Filter Panel getters are non-empty and distinct', () {
      expect(ar.inqScreenTitle, isNotEmpty);
      expect(en.inqScreenTitle, isNotEmpty);
      expect(ar.inqScreenTitle, isNot(equals(en.inqScreenTitle)));

      expect(ar.inqSubtitle, isNotEmpty);
      expect(en.inqSubtitle, isNotEmpty);
      expect(ar.inqSubtitle, isNot(equals(en.inqSubtitle)));

      expect(ar.inqFilterPanelTitle, isNotEmpty);
      expect(en.inqFilterPanelTitle, isNotEmpty);

      expect(ar.inqSupplier, isNotEmpty);
      expect(en.inqSupplier, isNotEmpty);

      expect(ar.inqImporter, isNotEmpty);
      expect(en.inqImporter, isNotEmpty);

      expect(ar.inqHsCodeOrProduct, isNotEmpty);
      expect(en.inqHsCodeOrProduct, isNotEmpty);

      expect(ar.inqIncoterm, isNotEmpty);
      expect(en.inqIncoterm, isNotEmpty);

      expect(ar.inqShippingMode, isNotEmpty);
      expect(en.inqShippingMode, isNotEmpty);

      expect(ar.inqSearchBtn, isNotEmpty);
      expect(en.inqSearchBtn, isNotEmpty);

      expect(ar.inqResetBtn, isNotEmpty);
      expect(en.inqResetBtn, isNotEmpty);
    });

    test('KPI and Toolbar action getters are non-empty and distinct', () {
      expect(ar.inqTotalMatchingShipments, isNotEmpty);
      expect(en.inqTotalMatchingShipments, isNotEmpty);

      expect(ar.inqAverageFreightCost, isNotEmpty);
      expect(en.inqAverageFreightCost, isNotEmpty);

      expect(ar.inqTotalIncurredCost, isNotEmpty);
      expect(en.inqTotalIncurredCost, isNotEmpty);

      expect(ar.inqExportPdfBtn, isNotEmpty);
      expect(en.inqExportPdfBtn, isNotEmpty);

      expect(ar.inqExportExcelBtn, isNotEmpty);
      expect(en.inqExportExcelBtn, isNotEmpty);

      expect(ar.inqExportTsvBtn, isNotEmpty);
      expect(en.inqExportTsvBtn, isNotEmpty);

      expect(ar.inqCopyDossierTooltip, isNotEmpty);
      expect(en.inqCopyDossierTooltip, isNotEmpty);
    });

    test('Table Column, Actions and Empty State strings are localized', () {
      expect(ar.inqColShipmentName, isNotEmpty);
      expect(en.inqColShipmentName, isNotEmpty);

      expect(ar.inqColSupplier, isNotEmpty);
      expect(en.inqColSupplier, isNotEmpty);

      expect(ar.inqColImporter, isNotEmpty);
      expect(en.inqColImporter, isNotEmpty);

      expect(ar.inqColItemAndHs, isNotEmpty);
      expect(en.inqColItemAndHs, isNotEmpty);

      expect(ar.inqColRoute, isNotEmpty);
      expect(en.inqColRoute, isNotEmpty);

      expect(ar.inqColShippingMode, isNotEmpty);
      expect(en.inqColShippingMode, isNotEmpty);

      expect(ar.inqColIncoterm, isNotEmpty);
      expect(en.inqColIncoterm, isNotEmpty);

      expect(ar.inqColFreightCost, isNotEmpty);
      expect(en.inqColFreightCost, isNotEmpty);

      expect(ar.inqColActions, isNotEmpty);
      expect(en.inqColActions, isNotEmpty);

      expect(ar.inqActionClone, isNotEmpty);
      expect(en.inqActionClone, isNotEmpty);

      expect(ar.inqActionDetails, isNotEmpty);
      expect(en.inqActionDetails, isNotEmpty);

      expect(ar.inqResultsTableTitle, isNotEmpty);
      expect(en.inqResultsTableTitle, isNotEmpty);

      expect(ar.inqShowingMatchingCount(7), contains('7'));
      expect(en.inqShowingMatchingCount(7), contains('7'));

      expect(ar.inqEmptyShipmentsTitle, isNotEmpty);
      expect(en.inqEmptyShipmentsTitle, isNotEmpty);
    });

    test('Clone Dialog and Notification strings are localized', () {
      expect(ar.inqCloneDialogTitle, isNotEmpty);
      expect(en.inqCloneDialogTitle, isNotEmpty);

      expect(ar.inqCloneDialogSubtitle('FILE-01'), contains('FILE-01'));
      expect(en.inqCloneDialogSubtitle('FILE-01'), contains('FILE-01'));

      expect(ar.inqCloneSuccessBanner('FILE-01'), contains('FILE-01'));
      expect(en.inqCloneSuccessBanner('FILE-01'), contains('FILE-01'));

      expect(ar.inqCloneSuccessToast('FILE-01'), contains('FILE-01'));
      expect(en.inqCloneSuccessToast('FILE-01'), contains('FILE-01'));

      expect(ar.inqCloneValidationName, isNotEmpty);
      expect(en.inqCloneValidationName, isNotEmpty);

      expect(ar.inqCloneValidationCode, isNotEmpty);
      expect(en.inqCloneValidationCode, isNotEmpty);

      expect(ar.inqCloneConfirmBtn, isNotEmpty);
      expect(en.inqCloneConfirmBtn, isNotEmpty);
    });

    test('Zero Latin characters [a-zA-Z] in pure Arabic getters', () {
      final latinPattern = RegExp(r'[a-zA-Z]');

      final pureArabicStrings = [
        ar.inqScreenTitle,
        ar.inqSubtitle,
        ar.inqFilterPanelTitle,
        ar.inqSupplier,
        ar.inqAllSuppliers,
        ar.inqImporter,
        ar.inqAllImporters,
        ar.inqHsCodeHint,
        ar.inqIncoterm,
        ar.inqAllIncoterms,
        ar.inqPortOfLoading,
        ar.inqPortOfDischarge,
        ar.inqShippingMode,
        ar.inqAllShippingModes,
        ar.inqCarrier,
        ar.inqDateRange,
        ar.inqAllDates,
        ar.inqSearchBtn,
        ar.inqResetBtn,
        ar.inqAdvancedFilters,
        ar.inqHideAdvancedFilters,
        ar.inqExportPrintBtn,
        ar.inqExportExcelBtn,
        ar.inqSaveFilterPreset,
        ar.inqPresetSaved,
        ar.inqColShipmentName,
        ar.inqColSupplier,
        ar.inqColImporter,
        ar.inqColItemAndHs,
        ar.inqColRoute,
        ar.inqColShippingMode,
        ar.inqColIncoterm,
        ar.inqColFreightCost,
        ar.inqColActions,
        ar.inqActionClone,
        ar.inqActionDetails,
        ar.inqTotalMatchingShipments,
        ar.inqAverageFreightCost,
        ar.inqTotalIncurredCost,
        ar.inqCloneDialogTitle,
        ar.inqCloneSuccessHeader,
        ar.inqCloneCopiedDataTitle,
        ar.inqCloneClearedDataTitle,
        ar.inqCloneLastRecordedCost,
        ar.inqCloneNewShipmentName,
        ar.inqCloneNewFileCode,
        ar.inqCloneNewInvoiceNumber,
        ar.inqCloneNewFreightCost,
        ar.inqCloneConfirmBtn,
        ar.inqCloneOpenFormBtn,
        ar.inqReportTitle,
        ar.inqReportGeneratedAt,
        ar.inqReportGeneratedBy,
        ar.inqLiveRefreshTooltip,
        ar.inqLoadError,
        ar.inqAllRegisteredShipments,
        ar.inqSearchPrefix,
        ar.inqOperatorManagerDefault,
        ar.inqCopyDossierTooltip,
        ar.inqResultsTableTitle,
        ar.inqEmptyShipmentsTitle,
        ar.inqCopyCodeTooltip,
        ar.inqCopyRowTooltip,
        ar.inqCopiedCodeSuccess,
        ar.inqCopiedRowSuccess,
        ar.inqCopiedDossierSuccess,
        ar.inqCopiedTsvSuccess,
        ar.inqCopiedExcelSuccess,
        ar.inqCurrencyUsd,
        ar.inqCurrencyEur,
        ar.inqCurrencyEgp,
        ar.inqIncotermExw,
        ar.inqIncotermFob,
        ar.inqIncotermCfr,
        ar.inqIncotermCif,
        ar.inqIncotermCip,
        ar.inqIncotermDpu,
        ar.inqIncotermDap,
        ar.inqIncotermDdp,
        ar.inqModeSeaFcl,
        ar.inqModeSeaLcl,
        ar.inqModeAir,
        ar.inqModeLand,
        ar.inqAllModes,
        ar.inqCloneCopyInvoicesLabel,
        ar.inqCloneCopyPackingListsLabel,
        ar.inqCloneValidationName,
        ar.inqCloneValidationCode,
        ar.inqCloneInvoiceHint,
        ar.inqCloneNotesLabel,
        ar.inqCloneNewShipmentSuffix,
        ar.inqExportTsvDialogTitle,
        ar.inqExportExcelDialogTitle,
        ar.inqExportPdfDialogTitle,
        ar.inqPdfSystemBranding,
        ar.inqPdfOfficialBadge,
        ar.inqPdfFilterCriteria,
        ar.inqTsvHeaderFileCode,
        ar.inqTsvHeaderCurrency,
        ar.inqTsvHeaderDate,
        ar.inqDossierCriteria,
        ar.inqDossierRowSupplier,
        ar.inqDossierRowImporter,
        ar.inqDossierRowItemAndHs,
        ar.inqDossierRowRoute,
        ar.inqDossierRowShippingMode,
        ar.inqDossierRowIncoterm,
        ar.inqDossierRowFreight,
      ];

      for (final str in pureArabicStrings) {
        expect(latinPattern.hasMatch(str), isFalse, reason: 'String "$str" contains Latin characters in Arabic mode');
      }
    });

    test('Zero bilingual slashes (" / ") in Arabic getters', () {
      final slashPattern = RegExp(r'\s/\s');

      final arabicStrings = [
        ar.inqScreenTitle,
        ar.inqSubtitle,
        ar.inqFilterPanelTitle,
        ar.inqColShipmentName,
        ar.inqColItemAndHs,
        ar.inqColShippingMode,
        ar.inqColIncoterm,
        ar.inqCloneDialogTitle,
        ar.inqExportPdfBtn,
        ar.inqExportExcelBtn,
      ];

      for (final str in arabicStrings) {
        expect(slashPattern.hasMatch(str), isFalse, reason: 'String "$str" contains bilingual slash in Arabic mode');
      }
    });
  });
}
