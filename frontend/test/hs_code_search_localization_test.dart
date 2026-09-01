import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('HS Code Explorer Localization Tests', () {
    late AppLocalizationsAr ar;
    late AppLocalizationsEn en;

    setUp(() {
      ar = AppLocalizationsAr();
      en = AppLocalizationsEn();
    });

    test('Header & search strings are distinct and non-empty', () {
      expect(ar.hsExplorerTitle, isNotEmpty);
      expect(en.hsExplorerTitle, isNotEmpty);
      expect(ar.hsExplorerTitle, isNot(equals(en.hsExplorerTitle)));

      expect(ar.hsExplorerSubtitle, isNotEmpty);
      expect(en.hsExplorerSubtitle, isNotEmpty);

      expect(ar.hsSearchPlaceholder, isNotEmpty);
      expect(en.hsSearchPlaceholder, isNotEmpty);

      expect(ar.hsQuickSearchExamples, isNotEmpty);
      expect(en.hsQuickSearchExamples, isNotEmpty);

      expect(ar.hsMatchingResultsHeader, isNotEmpty);
      expect(ar.hsMatchingResultsHeader, contains('البنود'));
      expect(en.hsMatchingResultsHeader, contains('Matching'));

      expect(ar.hsItemsCount(5), equals('5 بند'));
      expect(en.hsItemsCount(5), equals('5 items'));

      expect(ar.hsNoMatchingItemFound('123'), contains('123'));
      expect(en.hsNoMatchingItemFound('123'), contains('123'));

      expect(ar.hsDutyRateTag('10'), equals('وارد: 10%'));
      expect(en.hsDutyRateTag('10'), equals('Duty: 10%'));
    });

    test('Selected tariff card & tab bar strings', () {
      expect(ar.hsSelectFromListPrompt, isNotEmpty);
      expect(en.hsSelectFromListPrompt, isNotEmpty);

      expect(ar.hsCategoryPrefix('Cat'), contains('Cat'));
      expect(ar.hsCategoryPrefix('Cat'), contains('التصنيف'));
      expect(en.hsCategoryPrefix('Cat'), contains('Category'));

      expect(ar.hsEffectiveFromPrefix('2026-01-01'), contains('2026-01-01'));
      expect(en.hsEffectiveFromPrefix('2026-01-01'), contains('2026-01-01'));

      expect(ar.hsEffectiveToPrefix('2026-12-31'), contains('2026-12-31'));
      expect(en.hsEffectiveToPrefix('2026-12-31'), contains('2026-12-31'));

      expect(ar.hsEffectiveActiveRecord, equals('(سجل معتمد)'));
      expect(en.hsEffectiveActiveRecord, equals('(Approved Live Record)'));

      expect(ar.hsDiffHistoryAction, isNotEmpty);
      expect(en.hsDiffHistoryAction, isNotEmpty);

      expect(ar.hsTabTaxRates, equals('الضرائب والرسوم'));
      expect(en.hsTabTaxRates, equals('Taxes & Duties'));

      expect(ar.hsTabAgreements, equals('الاتفاقيات التفضيلية'));
      expect(en.hsTabAgreements, equals('Trade Agreements'));

      expect(ar.hsTabRegulatory, equals('الاشتراطات الرقابية'));
      expect(en.hsTabRegulatory, equals('Regulatory Requirements'));

      expect(ar.hsTabHistory, equals('سجل التحديثات والتاريخ'));
      expect(en.hsTabHistory, equals('Update History & Timeline'));

      expect(ar.hsTabQuickCalculator, equals('حاسبة فورية للبند'));
      expect(en.hsTabQuickCalculator, equals('Instant Duty Calculator'));
    });

    test('Tax Rates tab strings', () {
      expect(ar.hsTaxRatesSectionHeader, isNotEmpty);
      expect(en.hsTaxRatesSectionHeader, isNotEmpty);

      expect(ar.hsTaxImportDutyTitle, equals('ضريبة الوارد'));
      expect(en.hsTaxImportDutyTitle, equals('Customs Import Duty'));

      expect(ar.hsTaxVatTitle, equals('ضريبة القيمة المضافة'));
      expect(en.hsTaxVatTitle, equals('Value Added Tax (VAT)'));

      expect(ar.hsTaxScheduleTitle, equals('ضريبة الجدول'));
      expect(en.hsTaxScheduleTitle, equals('Schedule Tax'));

      expect(ar.hsTaxDevFeeTitle, equals('رسم التنمية'));
      expect(en.hsTaxDevFeeTitle, equals('Development Fee'));

      expect(ar.hsTaxImportFeeTitle, equals('رسم الوارد'));
      expect(en.hsTaxImportFeeTitle, equals('Import Surcharge Fee'));

      expect(ar.hsTaxServiceFeeTitle, equals('رسوم الخدمات الجمركية'));
      expect(en.hsTaxServiceFeeTitle, equals('Customs Service Fees'));

      expect(ar.hsEgyptianCalculationRule, isNotEmpty);
      expect(en.hsEgyptianCalculationRule, isNotEmpty);
    });

    test('Agreements & Regulatory tabs strings', () {
      expect(ar.hsNoAgreementsFound, isNotEmpty);
      expect(en.hsNoAgreementsFound, isNotEmpty);

      expect(ar.hsDefaultAgreementName, equals('اتفاقية تفضيلية'));
      expect(en.hsDefaultAgreementName, equals('Preferential Agreement'));

      expect(ar.hsRequiredDocPrefix('EUR.1'), contains('EUR.1'));
      expect(en.hsRequiredDocPrefix('EUR.1'), contains('EUR.1'));

      expect(ar.hsConditionsPrefix('Direct transport'), contains('Direct transport'));
      expect(en.hsConditionsPrefix('Direct transport'), contains('Direct transport'));

      expect(ar.hsFullExemptionBadge, equals('إعفاء كامل (0%)'));
      expect(en.hsFullExemptionBadge, equals('Full Exemption (0%)'));

      expect(ar.hsReducedRateBadge(5.0), equals('فئة مخفضة (5.0%)'));
      expect(en.hsReducedRateBadge(5.0), equals('Reduced Rate (5.0%)'));

      expect(ar.hsRegulatorySectionHeader, isNotEmpty);
      expect(en.hsRegulatorySectionHeader, isNotEmpty);

      expect(ar.hsReqAcidSystem, equals('نظام التسجيل المسبق ACID'));
      expect(en.hsReqAcidSystem, equals('ACID Pre-Registration System'));

      expect(ar.hsReqCertificateOfOrigin, equals('شهادة المنشأ (COO)'));
      expect(en.hsReqCertificateOfOrigin, equals('Certificate of Origin (COO)'));

      expect(ar.hsReqQualityInspection, equals('فحص المطابقة النوعي'));
      expect(en.hsReqQualityInspection, equals('Quality Conformity Inspection (COC)'));

      expect(ar.hsRegulatoryAuthorityPrefix('GOEIC'), contains('GOEIC'));
      expect(en.hsRegulatoryAuthorityPrefix('GOEIC'), contains('GOEIC'));

      expect(ar.hsDecreesAndNotesHeader, isNotEmpty);
      expect(en.hsDecreesAndNotesHeader, isNotEmpty);
    });

    test('History & Diffs tab strings', () {
      expect(ar.hsHistorySummaryTitle('8415'), contains('8415'));
      expect(en.hsHistorySummaryTitle('8415'), contains('8415'));

      expect(ar.hsHistoryMultipleVersionsDesc(3), contains('3'));
      expect(en.hsHistoryMultipleVersionsDesc(3), contains('3'));

      expect(ar.hsHistorySingleVersionDesc, isNotEmpty);
      expect(en.hsHistorySingleVersionDesc, isNotEmpty);

      expect(ar.hsVersionsCountTag(2), equals('2 إصدارات'));
      expect(en.hsVersionsCountTag(2), equals('2 versions'));

      expect(ar.hsTimelineSectionTitle, isNotEmpty);
      expect(en.hsTimelineSectionTitle, isNotEmpty);

      expect(ar.hsNoHistoricalVersions, isNotEmpty);
      expect(en.hsNoHistoricalVersions, isNotEmpty);

      expect(ar.hsActiveLiveVersionBadge, equals('الإصدار الحالي الساري'));
      expect(en.hsActiveLiveVersionBadge, equals('Active Live Version'));

      expect(ar.hsArchivedSnapshotBadge, equals('إصدار تاريخي سابق'));
      expect(en.hsArchivedSnapshotBadge, equals('Archived Historical Snapshot'));

      expect(ar.hsRegistrationDatePrefix('2026-01-01'), contains('2026-01-01'));
      expect(en.hsRegistrationDatePrefix('2026-01-01'), contains('2026-01-01'));

      expect(ar.hsValidityPeriodPrefix('2026-01-01', '2026-12-31'), contains('2026-01-01'));
      expect(en.hsValidityPeriodPrefix('2026-01-01', '2026-12-31'), contains('2026-12-31'));

      expect(ar.hsApprovedDescPrefix('Text'), contains('Text'));
      expect(en.hsApprovedDescPrefix('Text'), contains('Text'));

      expect(ar.hsLinkedAgreementsTag(4), equals('الاتفاقيات المربوطة: 4'));
      expect(en.hsLinkedAgreementsTag(4), equals('Linked Agreements: 4'));

      expect(ar.hsVersionDiffsSummaryHeader, isNotEmpty);
      expect(en.hsVersionDiffsSummaryHeader, isNotEmpty);

      expect(ar.hsDiffTitle('v1', 'v2'), contains('v1'));
      expect(en.hsDiffTitle('v1', 'v2'), contains('v2'));

      expect(ar.hsDiffDutyChanged(5.0, 10.0), contains('5.0'));
      expect(ar.hsDiffDutyChanged(5.0, 10.0), contains('10.0'));

      expect(ar.hsDiffVatChanged(14.0, 15.0), contains('14.0'));
      expect(ar.hsDiffVatChanged(14.0, 15.0), contains('15.0'));

      expect(ar.hsDiffScheduleChanged(0.0, 5.0), contains('0.0'));
      expect(ar.hsDiffScheduleChanged(0.0, 5.0), contains('5.0'));

      expect(ar.hsDiffAgreementsChanged(2, 3), contains('2'));
      expect(ar.hsDiffAgreementsChanged(2, 3), contains('3'));

      expect(ar.hsDiffMetadataChanged, isNotEmpty);
      expect(en.hsDiffMetadataChanged, isNotEmpty);

      expect(ar.hsAuditTrailSectionTitle, isNotEmpty);
      expect(en.hsAuditTrailSectionTitle, isNotEmpty);

      expect(ar.hsNoAuditLogsFound, isNotEmpty);
      expect(en.hsNoAuditLogsFound, isNotEmpty);

      expect(ar.hsAuditPerformedBy('Admin', '2026-01-01'), contains('Admin'));
      expect(en.hsAuditPerformedBy('Admin', '2026-01-01'), contains('2026-01-01'));
    });

    test('Quick Calculator tab strings & date helpers', () {
      expect(ar.hsCalculatorSectionHeader, isNotEmpty);
      expect(en.hsCalculatorSectionHeader, isNotEmpty);

      expect(ar.hsCifValueLabel, isNotEmpty);
      expect(en.hsCifValueLabel, isNotEmpty);

      expect(ar.hsFreightValueLabel, isNotEmpty);
      expect(en.hsFreightValueLabel, isNotEmpty);

      expect(ar.hsOriginCountryLabel, isNotEmpty);
      expect(en.hsOriginCountryLabel, isNotEmpty);

      expect(ar.hsOriginItalyEur1, isNotEmpty);
      expect(en.hsOriginItalyEur1, isNotEmpty);

      expect(ar.hsCalculateDutyBtn, equals('احسب الرسوم'));
      expect(en.hsCalculateDutyBtn, equals('Calculate Duties'));

      expect(ar.hsTotalTaxesAndFeesDue('1500.00'), contains('1500.00'));
      expect(en.hsTotalTaxesAndFeesDue('1500.00'), contains('1500.00'));

      expect(ar.hsNotePrefix('Note text'), contains('Note text'));
      expect(en.hsNotePrefix('Note text'), contains('Note text'));

      expect(ar.hsImportDutyBreakdown(10, '500.00'), contains('500.00'));
      expect(en.hsImportDutyBreakdown(10, '500.00'), contains('500.00'));

      expect(ar.hsVatBreakdown(14, '700.00'), contains('700.00'));
      expect(en.hsVatBreakdown(14, '700.00'), contains('700.00'));

      expect(ar.hsScheduleBreakdown('100.00'), contains('100.00'));
      expect(en.hsScheduleBreakdown('100.00'), contains('100.00'));

      expect(ar.hsServiceFeeBreakdown('50.00'), contains('50.00'));
      expect(en.hsServiceFeeBreakdown('50.00'), contains('50.00'));

      expect(ar.hsDatePresentOngoing, equals('الآن (مستمر)'));
      expect(en.hsDatePresentOngoing, equals('Present (Ongoing)'));

      expect(ar.hsDateToday, equals('اليوم'));
      expect(en.hsDateToday, equals('Today'));

      expect(ar.hsDateInitial, equals('البداية'));
      expect(en.hsDateInitial, equals('Initial'));

      expect(ar.hsActionExecuted, equals('تم تنفيذ العملية'));
      expect(en.hsActionExecuted, equals('Action executed'));
    });
  });
}
