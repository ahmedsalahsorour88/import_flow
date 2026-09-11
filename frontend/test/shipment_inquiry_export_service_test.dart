import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';
import 'package:frontend/features/import_files/models/import_file_model.dart';
import 'package:frontend/features/shipment_inquiry/services/shipment_inquiry_export_service.dart';

void main() {
  group('Screen 68: Shipment Inquiry Export Service & Report Row Tests', () {
    late AppLocalizationsAr ar;
    late AppLocalizationsEn en;

    setUp(() {
      ar = const AppLocalizationsAr();
      en = const AppLocalizationsEn();
    });

    final testFile1 = ImportFileModel(
      importFileId: 101,
      importFileCode: 'IMP-2026-00101',
      supplierId: 1,
      supplierName: 'Siemens Healthineers Germany',
      companyId: 2,
      companyName: 'الشركة المتحدة للمستلزمات الطبية',
      shipmentMode: 'FCL',
      incotermCode: 'CIF',
      status: 'Customs',
      estimatedCost: 15400.0,
      estimatedCostCurrency: 'USD',
      fileOpeningDate: '2026-02-15',
      portOfLoading: 'Hamburg',
      portOfDischarge: 'Alexandria',
      hsCode: '9018.90.00',
      productCategory: 'Medical Devices',
      customFileNumber: 'CFN-9988',
      notes: 'Main Shipment Batch\nUrgent medical delivery',
      currentModule: 'Phase 1',
      currentStage: 'Phase 1',
      nextAction: 'None',
      createdAt: '2026-02-15',
      updatedAt: '2026-02-15',
    );

    final testFile2 = ImportFileModel(
      importFileId: 102,
      importFileCode: 'IMP-2026-00102',
      supplierId: 2,
      supplierName: 'Ningbo Machinery Co',
      companyId: 3,
      companyName: 'سحر الاستيراد والتصدير',
      shipmentMode: 'LCL',
      incotermCode: 'FOB',
      status: 'Shipment',
      estimatedCost: 4500.0,
      estimatedCostCurrency: 'USD',
      fileOpeningDate: '2026-03-01',
      portOfLoading: '',
      portOfDischarge: '',
      hsCode: null,
      productCategory: null,
      customFileNumber: null,
      notes: null,
      currentModule: 'Phase 1',
      currentStage: 'Phase 1',
      nextAction: 'None',
      createdAt: '2026-03-01',
      updatedAt: '2026-03-01',
    );

    test('ShipmentInquiryReportRow.fromImportFile maps correctly with populated data', () {
      final row = ShipmentInquiryReportRow.fromImportFile(testFile1, ar);

      expect(row.shipmentName, equals('Main Shipment Batch'));
      expect(row.importFileCode, equals('IMP-2026-00101'));
      expect(row.supplierName, equals('Siemens Healthineers Germany'));
      expect(row.companyName, equals('الشركة المتحدة للمستلزمات الطبية'));
      expect(row.itemAndHs, equals('Medical Devices (9018.90.00)'));
      expect(row.route, equals('Hamburg → Alexandria'));
      expect(row.shippingMode, equals('FCL'));
      expect(row.incoterm, equals('CIF'));
      expect(row.freightCost, equals(15400.0));
      expect(row.currency, equals('USD'));
      expect(row.fileDate, equals('2026-02-15'));
    });

    test('ShipmentInquiryReportRow.fromImportFile safely handles missing/null data without crashes', () {
      final row = ShipmentInquiryReportRow.fromImportFile(testFile2, ar);

      expect(row.shipmentName, equals('IMP-2026-00102'));
      expect(row.itemAndHs, equals('-'));
      expect(row.route, equals('-'));
      expect(row.freightCost, equals(4500.0));
    });

    test('toRowSummary includes localized headers in Arabic and English', () {
      final row = ShipmentInquiryReportRow.fromImportFile(testFile1, ar);

      final summaryAr = row.toRowSummary(ar);
      expect(summaryAr, contains(ar.inqColShipmentName));
      expect(summaryAr, contains(ar.inqColSupplier));
      expect(summaryAr, contains(ar.inqColImporter));
      expect(summaryAr, contains(ar.inqColItemAndHs));
      expect(summaryAr, contains(ar.inqColRoute));
      expect(summaryAr, contains(ar.inqColFreightCost));

      final summaryEn = row.toRowSummary(en);
      expect(summaryEn, contains(en.inqColShipmentName));
      expect(summaryEn, contains(en.inqColSupplier));
      expect(summaryEn, contains(en.inqColImporter));
      expect(summaryEn, contains(en.inqColItemAndHs));
      expect(summaryEn, contains(en.inqColRoute));
      expect(summaryEn, contains(en.inqColFreightCost));
    });

    test('Dossier summary text generator outputs structured text with localized labels', () {
      const totalCount = 2;
      final totalCost = testFile1.estimatedCost + testFile2.estimatedCost;
      final avgCost = totalCost / totalCount;

      final kpiSummaryAr = ar.inqDossierKpiSummary(
        totalCount,
        '${totalCost.toStringAsFixed(0)} ${ar.inqCurrencyUsd}',
        '${avgCost.toStringAsFixed(0)} ${ar.inqCurrencyUsd}',
      );

      expect(kpiSummaryAr, contains('$totalCount'));
      expect(kpiSummaryAr, contains(ar.inqCurrencyUsd));
      // In Arabic mode, zero Latin letters in the KPI template
      final latinPattern = RegExp(r'[a-zA-Z]');
      expect(latinPattern.hasMatch(ar.inqDossierCriteria), isFalse);
    });

    test('TSV headers reflect active localization properly', () {
      final tsvHeadersAr = [
        ar.inqColShipmentName,
        ar.inqTsvHeaderFileCode,
        ar.inqColSupplier,
        ar.inqColImporter,
        ar.inqColItemAndHs,
        ar.inqColRoute,
        ar.inqColShippingMode,
        ar.inqColIncoterm,
        ar.inqColFreightCost,
        ar.inqTsvHeaderCurrency,
        ar.inqTsvHeaderDate,
      ].join('\t');

      expect(tsvHeadersAr.split('\t').length, equals(11));
      expect(tsvHeadersAr, contains(ar.inqColShipmentName));
      expect(tsvHeadersAr, contains(ar.inqTsvHeaderFileCode));

      final tsvHeadersEn = [
        en.inqColShipmentName,
        en.inqTsvHeaderFileCode,
        en.inqColSupplier,
        en.inqColImporter,
        en.inqColItemAndHs,
        en.inqColRoute,
        en.inqColShippingMode,
        en.inqColIncoterm,
        en.inqColFreightCost,
        en.inqTsvHeaderCurrency,
        en.inqTsvHeaderDate,
      ].join('\t');

      expect(tsvHeadersEn.split('\t').length, equals(11));
      expect(tsvHeadersEn, contains(en.inqColShipmentName));
      expect(tsvHeadersEn, contains(en.inqTsvHeaderFileCode));
    });
  });
}
