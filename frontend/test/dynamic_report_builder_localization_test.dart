import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Dynamic Report Builder Localization Tests', () {
    late AppLocalizationsAr ar;
    late AppLocalizationsEn en;

    setUp(() {
      ar = AppLocalizationsAr();
      en = AppLocalizationsEn();
    });

    test('Header, Toolbar, and Button strings are localized and distinct', () {
      expect(ar.dynReportBuilderTitle, isNotEmpty);
      expect(en.dynReportBuilderTitle, isNotEmpty);
      expect(ar.dynReportBuilderTitle, isNot(equals(en.dynReportBuilderTitle)));

      expect(ar.dynReportBuilderSubtitle, isNotEmpty);
      expect(en.dynReportBuilderSubtitle, isNotEmpty);

      expect(ar.dynCustomizeColumnsBtn(5, 16), equals('تخصيص الأعمدة (5/16)'));
      expect(en.dynCustomizeColumnsBtn(5, 16), equals('Customize Columns (5/16)'));

      expect(ar.dynExportExcelBtn(10), equals('تصدير Excel [10]'));
      expect(en.dynExportExcelBtn(10), equals('Export Excel [10]'));

      expect(ar.dynExportPdfBtn(10), equals('تصدير PDF [10]'));
      expect(en.dynExportPdfBtn(10), equals('Export PDF [10]'));

      expect(ar.dynFilterModeLabel, isNotEmpty);
      expect(en.dynFilterModeLabel, isNotEmpty);

      expect(ar.dynFilterPriorityLabel, isNotEmpty);
      expect(en.dynFilterPriorityLabel, isNotEmpty);

      expect(ar.dynSearchPlaceholder, isNotEmpty);
      expect(en.dynSearchPlaceholder, isNotEmpty);
    });

    test('Filter items and Column Picker modal strings', () {
      expect(ar.dynModeAll, equals('الكل'));
      expect(en.dynModeAll, equals('All'));

      expect(ar.dynModeSeaFcl, equals('بحري FCL'));
      expect(en.dynModeSeaFcl, equals('Ocean FCL'));

      expect(ar.dynModeAir, equals('شحن جوي'));
      expect(en.dynModeAir, equals('Air Freight'));

      expect(ar.dynPriorityAll, equals('الكل'));
      expect(en.dynPriorityAll, equals('All'));

      expect(ar.dynPriorityHigh, equals('مرتفعة'));
      expect(en.dynPriorityHigh, equals('High'));

      expect(ar.dynColumnPickerTitle, isNotEmpty);
      expect(en.dynColumnPickerTitle, isNotEmpty);

      expect(ar.dynApplyColumnsBtn, isNotEmpty);
      expect(en.dynApplyColumnsBtn, isNotEmpty);

      expect(ar.dynExportCsvTitle, isNotEmpty);
      expect(en.dynExportCsvTitle, isNotEmpty);

      expect(ar.dynExportCsvGeneratedMsg, isNotEmpty);
      expect(en.dynExportCsvGeneratedMsg, isNotEmpty);

      expect(ar.dynFetchReportError('Connection timeout'), contains('Connection timeout'));
      expect(en.dynFetchReportError('Connection timeout'), contains('Connection timeout'));

      expect(ar.dynNoMatchingShipments, isNotEmpty);
      expect(en.dynNoMatchingShipments, isNotEmpty);

      expect(ar.dynPdfReportTitle, isNotEmpty);
      expect(en.dynPdfReportTitle, isNotEmpty);

      expect(ar.dynPdfConfidential, isNotEmpty);
      expect(en.dynPdfConfidential, isNotEmpty);

      expect(ar.dynPdfGenerated('2026-09-01', 5), contains('2026-09-01'));
      expect(en.dynPdfGenerated('2026-09-01', 5), contains('2026-09-01'));
    });

    test('All 16 Dynamic Report Column Headers are localized and distinct', () {
      expect(ar.dynColImportFileCode, equals('كود الملف'));
      expect(en.dynColImportFileCode, equals('File Code'));

      expect(ar.dynColCompanyName, equals('الشركة المستوردة'));
      expect(en.dynColCompanyName, equals('Importing Company'));

      expect(ar.dynColSupplierName, equals('المورد الأجنبي'));
      expect(en.dynColSupplierName, equals('Foreign Supplier'));

      expect(ar.dynColBrokerName, equals('المخلص الجمركي'));
      expect(en.dynColBrokerName, equals('Customs Broker'));

      expect(ar.dynColAcidNumber, equals('رقم ACID'));
      expect(en.dynColAcidNumber, equals('ACID Number'));

      expect(ar.dynColForm4No, equals('رقم نموذج 4'));
      expect(en.dynColForm4No, equals('Form 4 Number'));

      expect(ar.dynColForm46No, equals('إقرار 46 جمارك'));
      expect(en.dynColForm46No, equals('Customs Declaration 46'));

      expect(ar.dynColShipmentMode, equals('وسيلة النقل'));
      expect(en.dynColShipmentMode, equals('Shipping Mode'));

      expect(ar.dynColIncotermCode, equals('الشرط التجاري'));
      expect(en.dynColIncotermCode, equals('Incoterm Rule'));

      expect(ar.dynColPriority, equals('الأولوية'));
      expect(en.dynColPriority, equals('Priority'));

      expect(ar.dynColEstimatedCost, equals('القيمة التقديرية'));
      expect(en.dynColEstimatedCost, equals('Estimated Value (PI)'));

      expect(ar.dynColRequiredEta, equals('تاريخ الوصول المتوقع'));
      expect(en.dynColRequiredEta, equals('Estimated Arrival (ETA)'));

      expect(ar.dynColCurrentStage, equals('المرحلة الحالية'));
      expect(en.dynColCurrentStage, equals('Current Stage'));

      expect(ar.dynColProgressPercent, equals('نسبة الإنجاز %'));
      expect(en.dynColProgressPercent, equals('Progress %'));

      expect(ar.dynColOwner, equals('المسؤول'));
      expect(en.dynColOwner, equals('Owner / Assignee'));

      expect(ar.dynColStatus, equals('حالة الملف'));
      expect(en.dynColStatus, equals('File Status'));
    });
  });
}
