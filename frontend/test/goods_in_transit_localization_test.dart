import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 63: Goods In Transit (GIT) Ledger Localization Tests', () {
    const ar = AppLocalizationsAr();
    const en = AppLocalizationsEn();

    test('All Screen 63 getters return non-empty strings and no missing translations', () {
      // Titles and Tabs
      expect(ar.gitLedgerTabTitle.isNotEmpty, true);
      expect(en.gitLedgerTabTitle.isNotEmpty, true);
      expect(ar.gitLedgerScaffoldTitle.isNotEmpty, true);
      expect(en.gitLedgerScaffoldTitle.isNotEmpty, true);
      expect(ar.gitErrorFetchingData('Err').contains('Err'), true);
      expect(en.gitErrorFetchingData('Err').contains('Err'), true);

      // Info Banner
      expect(ar.gitInfoBannerTitle.isNotEmpty, true);
      expect(en.gitInfoBannerTitle.isNotEmpty, true);
      expect(ar.gitInfoBannerSubtitle.isNotEmpty, true);
      expect(en.gitInfoBannerSubtitle.isNotEmpty, true);
      expect(ar.gitExportExcelBtn.isNotEmpty, true);
      expect(en.gitExportExcelBtn.isNotEmpty, true);
      expect(ar.gitExportSuccessMsg.isNotEmpty, true);
      expect(en.gitExportSuccessMsg.isNotEmpty, true);

      // KPI Metrics
      expect(ar.gitKpiInTransitShipments.isNotEmpty, true);
      expect(en.gitKpiInTransitShipments.isNotEmpty, true);
      expect(ar.gitKpiShipmentsValue(5), contains('5'));
      expect(en.gitKpiShipmentsValue(5), contains('5'));
      expect(ar.gitKpiPurchaseOrders.isNotEmpty, true);
      expect(en.gitKpiPurchaseOrders.isNotEmpty, true);
      expect(ar.gitKpiPurchaseOrdersValue(8), contains('8'));
      expect(en.gitKpiPurchaseOrdersValue(8), contains('8'));
      expect(ar.gitKpiInvoicedQuantity.isNotEmpty, true);
      expect(en.gitKpiInvoicedQuantity.isNotEmpty, true);
      expect(ar.gitKpiQuantityValue(1250), contains('1250'));
      expect(en.gitKpiQuantityValue(1250), contains('1250'));
      expect(ar.gitKpiPackagesCount.isNotEmpty, true);
      expect(en.gitKpiPackagesCount.isNotEmpty, true);
      expect(ar.gitKpiPackagesValue(450), contains('450'));
      expect(en.gitKpiPackagesValue(450), contains('450'));
      expect(ar.gitKpiActiveContainers.isNotEmpty, true);
      expect(en.gitKpiActiveContainers.isNotEmpty, true);
      expect(ar.gitKpiContainersValue(3), contains('3'));
      expect(en.gitKpiContainersValue(3), contains('3'));

      // Search & Filters
      expect(ar.gitSearchHint.isNotEmpty, true);
      expect(en.gitSearchHint.isNotEmpty, true);
      expect(ar.gitFilterAll.isNotEmpty, true);
      expect(en.gitFilterAll.isNotEmpty, true);
      expect(ar.gitFilterInTransitOnly.isNotEmpty, true);
      expect(en.gitFilterInTransitOnly.isNotEmpty, true);
      expect(ar.gitFilterDeliveredOnly.isNotEmpty, true);
      expect(en.gitFilterDeliveredOnly.isNotEmpty, true);
      expect(ar.gitRefreshTooltip.isNotEmpty, true);
      expect(en.gitRefreshTooltip.isNotEmpty, true);

      // Table & Columns
      expect(ar.gitTableSectionHeader.isNotEmpty, true);
      expect(en.gitTableSectionHeader.isNotEmpty, true);
      expect(ar.gitNoDataFound.isNotEmpty, true);
      expect(en.gitNoDataFound.isNotEmpty, true);
      expect(ar.gitColFileCode.isNotEmpty, true);
      expect(en.gitColFileCode.isNotEmpty, true);
      expect(ar.gitColPoNumber.isNotEmpty, true);
      expect(en.gitColPoNumber.isNotEmpty, true);
      expect(ar.gitColItemCode.isNotEmpty, true);
      expect(en.gitColItemCode.isNotEmpty, true);
      expect(ar.gitColItemName.isNotEmpty, true);
      expect(en.gitColItemName.isNotEmpty, true);
      expect(ar.gitColInvoicedQty.isNotEmpty, true);
      expect(en.gitColInvoicedQty.isNotEmpty, true);
      expect(ar.gitColPackagesCount.isNotEmpty, true);
      expect(en.gitColPackagesCount.isNotEmpty, true);
      expect(ar.gitColContainers.isNotEmpty, true);
      expect(en.gitColContainers.isNotEmpty, true);
      expect(ar.gitColCertifiedDate.isNotEmpty, true);
      expect(en.gitColCertifiedDate.isNotEmpty, true);
      expect(ar.gitColLedgerStatus.isNotEmpty, true);
      expect(en.gitColLedgerStatus.isNotEmpty, true);
      expect(ar.gitStatusDeliveredToWarehouse.isNotEmpty, true);
      expect(en.gitStatusDeliveredToWarehouse.isNotEmpty, true);
      expect(ar.gitStatusInTransit.isNotEmpty, true);
      expect(en.gitStatusInTransit.isNotEmpty, true);
    });

    test('Arabic translations contain pure Arabic text without Latin characters', () {
      final latinRegex = RegExp(r'[a-zA-Z]');

      final pureArabicStaticStrings = [
        ar.gitLedgerTabTitle,
        ar.gitLedgerScaffoldTitle,
        ar.gitInfoBannerTitle,
        ar.gitInfoBannerSubtitle,
        ar.gitExportExcelBtn,
        ar.gitExportSuccessMsg,
        ar.gitKpiInTransitShipments,
        ar.gitKpiPurchaseOrders,
        ar.gitKpiInvoicedQuantity,
        ar.gitKpiPackagesCount,
        ar.gitKpiActiveContainers,
        ar.gitSearchHint,
        ar.gitFilterAll,
        ar.gitFilterInTransitOnly,
        ar.gitFilterDeliveredOnly,
        ar.gitRefreshTooltip,
        ar.gitTableSectionHeader,
        ar.gitNoDataFound,
        ar.gitColFileCode,
        ar.gitColPoNumber,
        ar.gitColItemCode,
        ar.gitColItemName,
        ar.gitColInvoicedQty,
        ar.gitColPackagesCount,
        ar.gitColContainers,
        ar.gitColCertifiedDate,
        ar.gitColLedgerStatus,
        ar.gitStatusDeliveredToWarehouse,
        ar.gitStatusInTransit,
      ];

      for (final text in pureArabicStaticStrings) {
        expect(
          latinRegex.hasMatch(text),
          false,
          reason: 'String "$text" contains English/Latin characters!',
        );
      }
    });

    test('No stacked bilingual text is present in static labels', () {
      expect(ar.gitLedgerScaffoldTitle.contains('('), false);
      expect(ar.gitInfoBannerTitle.contains('('), false);
      expect(ar.gitKpiPurchaseOrders.contains('('), false);
      expect(ar.gitTableSectionHeader.contains('('), false);
      expect(ar.gitColPoNumber.contains('('), false);
      expect(ar.gitStatusInTransit.contains('('), false);
    });
  });
}
