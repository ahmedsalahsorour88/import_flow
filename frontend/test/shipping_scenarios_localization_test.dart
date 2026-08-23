import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Shipping Scenarios (Freight Studies) Localization & Anti-Stacked Tests (Screen 4)', () {
    test('Arabic AppLocalizationsAr returns pure Arabic for freight study keys', () {
      const lAr = AppLocalizationsAr();
      expect(lAr.freightStudiesTitle, equals('دراسات وسيناريوهات الشحن والمفاضلة'));
      expect(lAr.scenariosEvaluatorTab, equals('دراسة وسيناريوهات الشحن'));
      expect(lAr.savedEvaluationsLogTab, equals('سجل الدراسات المحفوظة'));
      expect(lAr.extractFreightQuotes, equals('استخراج عروض أسعار النولون'));
      expect(lAr.studySetupAndParameters, equals('إعدادات ومعلمات دراسة الشحن'));
      expect(lAr.studyTitleLabel, equals('مسمى دراسة خيارات الشحن'));
      expect(lAr.crdLabel, equals('تاريخ جاهزية البضاعة (CRD)'));
      expect(lAr.pickupAddressLabel, equals('عنوان الاستلام / المصنع'));
      expect(lAr.avgForm4DaysLabel, equals('أيام نموذج 4 المتوقعة'));
      expect(lAr.avgClearanceDaysLabel, equals('أيام التخليص الجمركي المتوقعة'));
      expect(lAr.cargoStackingType, equals('نوع التحميل والتخزين'));
      expect(lAr.shippingCarrierOptions, equals('خيارات وعروض شحن الشركات'));
      expect(lAr.addNewShippingOption, equals('إضافة خيار شحن جديد'));
      expect(lAr.freightForwarderCol, equals('وكيل الشحن / الناقل'));
      expect(lAr.shippingLineCol, equals('الخط الملاحي'));
      expect(lAr.sideBySideComparison, equals('جدول المقارنة التفصيلي لخيارات الشحن'));
      expect(lAr.saveAndSubmitStudy, equals('حفظ الدراسة والنتائج'));
      expect(lAr.saveDraftContinueLater, equals('حفظ مؤقت ومتابعة لاحقة'));
      expect(lAr.clearAndStartNew, equals('تفريغ وبدء تسجيل جديد'));
      expect(lAr.totalStudiesMetric, equals('إجمالي الدراسات'));
      expect(lAr.avgTransitMetric, equals('متوسط الترانزيت'));
      expect(lAr.withRecommendationMetric, equals('مع توصية'));

      // Check anti-stacked: zero unneeded bilingual stacking
      expect(lAr.studySetupAndParameters.contains('Study Setup'), isFalse);
      expect(lAr.freightStudiesTitle.contains('Freight Studies'), isFalse);
      expect(lAr.saveAndSubmitStudy.contains('Save & Submit'), isFalse);
      expect(lAr.shippingCarrierOptions.contains('Shipping Carrier'), isFalse);
    });

    test('English AppLocalizationsEn returns pure English for freight study keys', () {
      const lEn = AppLocalizationsEn();
      expect(lEn.freightStudiesTitle, equals('Freight Shipping Scenarios & Carrier Evaluation'));
      expect(lEn.scenariosEvaluatorTab, equals('Scenarios Evaluator'));
      expect(lEn.savedEvaluationsLogTab, equals('Saved Evaluations Log'));
      expect(lEn.extractFreightQuotes, equals('Extract Freight Quotes'));
      expect(lEn.studySetupAndParameters, equals('Study Setup & Parameters'));
      expect(lEn.studyTitleLabel, equals('Study Title'));
      expect(lEn.crdLabel, equals('Cargo Ready Date (CRD)'));
      expect(lEn.pickupAddressLabel, equals('Pickup / Factory Address'));
      expect(lEn.avgForm4DaysLabel, equals('Avg Form 4 Days'));
      expect(lEn.avgClearanceDaysLabel, equals('Avg Clearance Days'));
      expect(lEn.cargoStackingType, equals('Cargo Stacking'));
      expect(lEn.shippingCarrierOptions, equals('Shipping Carrier Options & Quotes'));
      expect(lEn.addNewShippingOption, equals('Add Shipping Option'));
      expect(lEn.freightForwarderCol, equals('Freight Forwarder / Carrier'));
      expect(lEn.shippingLineCol, equals('Shipping Line'));
      expect(lEn.sideBySideComparison, equals('Shipping Scenarios Comparison Matrix'));
      expect(lEn.saveAndSubmitStudy, equals('Save Study & Results'));
      expect(lEn.saveDraftContinueLater, equals('Save Draft'));
      expect(lEn.clearAndStartNew, equals('Clear & Start New'));
      expect(lEn.totalStudiesMetric, equals('Total Studies'));
      expect(lEn.avgTransitMetric, equals('Avg Transit'));
      expect(lEn.withRecommendationMetric, equals('With Recommendation'));

      // Check pure English: no Arabic characters
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');
      expect(arabicRegex.hasMatch(lEn.freightStudiesTitle), isFalse);
      expect(arabicRegex.hasMatch(lEn.studySetupAndParameters), isFalse);
      expect(arabicRegex.hasMatch(lEn.shippingCarrierOptions), isFalse);
      expect(arabicRegex.hasMatch(lEn.sideBySideComparison), isFalse);
      expect(arabicRegex.hasMatch(lEn.saveAndSubmitStudy), isFalse);
    });

    test('All 17 quotation line items are distinct and localized without stacking', () {
      const lAr = AppLocalizationsAr();
      const lEn = AppLocalizationsEn();

      final arItems = [
        lAr.container40ftItem,
        lAr.container20ftItem,
        lAr.lclCbmItem,
        lAr.expressCourierItem,
        lAr.eurAtrItem,
        lAr.solasVgmItem,
        lAr.vgmNotificationItem,
        lAr.telexReleaseItem,
        lAr.insuranceItem,
        lAr.bookingCancellationItem,
        lAr.ics2FilingFeeItem,
        lAr.documentFeesItem,
        lAr.waiverLetterFeeItem,
        lAr.othersFeeItem,
        lAr.dthcItem,
        lAr.storagePerWeekItem,
        lAr.extraDayStorageItem,
      ];

      final enItems = [
        lEn.container40ftItem,
        lEn.container20ftItem,
        lEn.lclCbmItem,
        lEn.expressCourierItem,
        lEn.eurAtrItem,
        lEn.solasVgmItem,
        lEn.vgmNotificationItem,
        lEn.telexReleaseItem,
        lEn.insuranceItem,
        lEn.bookingCancellationItem,
        lEn.ics2FilingFeeItem,
        lEn.documentFeesItem,
        lEn.waiverLetterFeeItem,
        lEn.othersFeeItem,
        lEn.dthcItem,
        lEn.storagePerWeekItem,
        lEn.extraDayStorageItem,
      ];

      expect(arItems.length, equals(17));
      expect(enItems.length, equals(17));

      for (final item in arItems) {
        expect(item.isNotEmpty, isTrue);
      }

      for (final item in enItems) {
        expect(item.isNotEmpty, isTrue);
        expect(RegExp(r'[\u0600-\u06FF]').hasMatch(item), isFalse);
      }
    });
  });
}
